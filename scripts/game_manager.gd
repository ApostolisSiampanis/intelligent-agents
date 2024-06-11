extends Node

class_name GameManager

@onready var label_village_1_stone = %LabelVillage1Stone
@onready var label_village_1_wood = %LabelVillage1Wood
@onready var label_village_1_gold = %LabelVillage1Gold

@onready var label_village_2_stone = %LabelVillage2Stone
@onready var label_village_2_wood = %LabelVillage2Wood
@onready var label_village_2_gold = %LabelVillage2Gold

@onready var label_goal_stone = %LabelGoalStone
@onready var label_goal_wood = %LabelGoalWood
@onready var label_goal_gold = %LabelGoalGold

@onready var label_finished_game_message = %LabelFinishedGameMessage

var village_1: Village
var village_2: Village

func _ready():
	set_goal_labels()
	_update_remaining_resources()
	
func drop_resource(agent: Agent) -> void:
	""" 
		- Handles the dropping of resources by an agent. 
		- Updates the resource counts for the village and checks if the game has finished. 
	"""
	var resource = agent.current_carrying_resource
	if resource == null: return
	
	var village = agent.village
	
	village.add_resource(resource)
	agent.current_carrying_resource = null
	
	_update_remaining_resources()
	
	# Check for game end
	if is_game_finished(village): finish_game()
	
	
func set_goal_labels():
	label_goal_stone.text = "Stone: %s " % str(village_2.target_stone_quantity)
	label_goal_wood.text = "Wood: %s " % str(village_2.target_wood_quantity)
	label_goal_gold.text = "Gold: %s " % str(village_2.target_gold_quantity)
	
func set_village_labels(label_stone, label_wood, label_gold, village):
	var remaining_wood: int = village.target_wood_quantity - village.current_wood_quantity
	remaining_wood = 0 if remaining_wood < 0 else remaining_wood
	
	var remaining_stone: int = village.target_stone_quantity - village.current_stone_quantity
	remaining_stone = 0 if remaining_stone < 0 else remaining_stone
	
	var remaining_gold: int = village.target_gold_quantity - village.current_gold_quantity
	remaining_gold = 0 if remaining_gold < 0 else remaining_gold
	
	var village_wood = remaining_wood
	var village_stone = remaining_stone
	var village_gold = remaining_gold
	
	label_stone.text = "Stone: %s " % str(village_stone)
	label_wood.text = "Wood: %s " % str(village_wood)
	label_gold.text = "Gold: %s " % str(village_gold)

func eliminate(agent: Agent) -> void:
	""" 
		- Removes an agent from its village. 
		- If the village has no more agents, finishes the game.
	"""

	var village = agent.village
	village.remove_agent(agent)
	if village.agents.is_empty(): finish_game()

func assign_resource_goal(agent: Agent) -> void:
	""" 
		Assigns a new resource goal to an agent based on its village's needs.
	"""

	var village = get_village(agent)
	var next_resource_goal = Village.ResourceType.get(village.calc_capability_dict(agent).keys()[0])
	var tile_type
	match next_resource_goal:
		Village.ResourceType.WOOD: tile_type = Common.TileType.WOOD
		Village.ResourceType.STONE: tile_type = Common.TileType.STONE
		Village.ResourceType.GOLD: tile_type = Common.TileType.GOLD
	
	agent.change_goal(tile_type)
	
func _update_remaining_resources():
	set_village_labels(label_village_1_stone, label_village_1_wood, label_village_1_gold, village_1)
	set_village_labels(label_village_2_stone, label_village_2_wood, label_village_2_gold, village_2)

func is_game_finished(village: Village) -> bool:
	return village.is_goal_completed()

func merge_knowledge(caller_agent: Agent, target_agent: Agent) -> void:
	""" 
		Merges the knowledge between two agents. 
	"""

	if !target_agent.available_for_knowledge_exchange: return
	
	if caller_agent.agent_knowledge_vers.has(target_agent.id) && caller_agent.agent_knowledge_vers[target_agent.id] == target_agent.knowledge_ver: return
	
	caller_agent.available_for_knowledge_exchange = false
	target_agent.available_for_knowledge_exchange = false
	
	# Merge AStar
	update_astar(caller_agent, target_agent)
	update_astar(target_agent, caller_agent)
	
	# Merge valuable_tile_point_ids
	merge_valuable_point_ids(caller_agent, target_agent)
	# Merge visited and not_visited
	merge_explore_tiles(caller_agent, target_agent)
	
	caller_agent.knowledge_ver += 1
	target_agent.knowledge_ver += 1
	caller_agent.agent_knowledge_vers[target_agent.id] = target_agent.knowledge_ver
	target_agent.agent_knowledge_vers[caller_agent.id] = caller_agent.knowledge_ver

func update_astar(caller_agent: Agent, target_agent: Agent) -> void:
	""" 
		- Updates the Astar pathfinding graph of the caller agent with information from the target agent.
	"""

	for point_id in target_agent.astar.get_point_ids():
		
		if !caller_agent.astar.has_point(point_id):
			caller_agent.astar.add_point(point_id, target_agent.astar.get_point_position(point_id))
		
		for connected_point_id in target_agent.astar.get_point_connections(point_id):
			
			if !caller_agent.astar.has_point(connected_point_id):
				caller_agent.astar.add_point(connected_point_id, target_agent.astar.get_point_position(connected_point_id))
			
			if !caller_agent.astar.are_points_connected(point_id, connected_point_id):
				caller_agent.astar.connect_points(point_id, connected_point_id)

func merge_valuable_point_ids(caller_agent: Agent, target_agent: Agent) -> void:
	""" 
		Merges the valuable point IDs of resources between two agents. 
	"""

	var merged_valuable_point_ids = caller_agent.valuable_tile_point_ids.duplicate(true)
	var target_village_point = target_agent.valuable_tile_point_ids[Common.TileType.VILLAGE] 
	
	for tile_type in target_agent.valuable_tile_point_ids.keys():
		if tile_type == Common.TileType.VILLAGE: continue
		
		var target_points = target_agent.valuable_tile_point_ids[tile_type]
		if !merged_valuable_point_ids.has(tile_type):
			merged_valuable_point_ids[tile_type] = target_points
		else:
			var caller_points = caller_agent.valuable_tile_point_ids[tile_type]
			for point in target_points.keys():
				if !caller_points.has(point) || target_points[point] == false:
					caller_points[point] = target_points[point]
	
	caller_agent.valuable_tile_point_ids = merged_valuable_point_ids
	
	# Change the village point if they're from a different one
	merged_valuable_point_ids = merged_valuable_point_ids.duplicate(true)
	if caller_agent.valuable_tile_point_ids[Common.TileType.VILLAGE] != target_village_point:
		merged_valuable_point_ids[Common.TileType.VILLAGE] = target_village_point
	
	target_agent.valuable_tile_point_ids = merged_valuable_point_ids

func merge_explore_tiles(caller_agent: Agent, target_agent: Agent) -> void:
	""" 
		Merges the explored and unexplored tiles between two agents. 
	"""

	var merged_visited_tiles_pos = caller_agent.visited.duplicate()
	for tile in target_agent.visited:
		if !merged_visited_tiles_pos.has(tile):
			merged_visited_tiles_pos.append(tile)
			
	var merged_not_visited_tiles_pos = caller_agent.not_visited.duplicate()
	for tile in target_agent.not_visited:
		if !merged_not_visited_tiles_pos.has(tile):
			merged_not_visited_tiles_pos.append(tile)
			
	caller_agent.visited = merged_visited_tiles_pos
	target_agent.visited = merged_visited_tiles_pos.duplicate()
	
	caller_agent.not_visited = merged_not_visited_tiles_pos
	target_agent.not_visited = merged_not_visited_tiles_pos.duplicate()

func get_village(agent: Agent) -> Village:
	""" 
		Returns the village to which an agent belongs, based on its chromosome. 
	"""

	var village
	match agent.chromosome.bits[0]:
		"0":
			if village_1 == null: village_1 = Village.new()
			village_1.add_agent(agent)
			village = village_1
		"1":
			if village_2 == null: village_2 = Village.new()
			village_2.add_agent(agent)
			village = village_2
	return village

func reproduce(caller_agent: Agent, target_agent: Agent, caller_wants_to_reproduce: bool):
	""" 
		Handles the reproduction process between two agents if both are willing to reproduce. 
	"""

	if !(caller_wants_to_reproduce && target_agent.wants_to_reproduce(caller_agent)): return
	
	# Both want to reproduce
	Reproducer.reproduce(caller_agent, target_agent)

func finish_game():
	""" 
		- Ends the game.
		- Determines the winning village
		- Updates the UI accordingly.
	"""

	# Determine which village won
	var village_1_won = village_1.is_goal_completed()
	var village_2_won = village_2.is_goal_completed()
	
	if village_1_won and not village_2.agents.is_empty():
		label_finished_game_message.text = "Village 1 WON!"
		# Update remaining resources to 0 for Village 1
		label_village_1_stone.text = "Stone: 0"
		label_village_1_wood.text = "Wood: 0"
		label_village_1_gold.text = "Gold: 0"
	elif village_2_won and not village_1.agents.is_empty():
		label_finished_game_message.text = "Village 2 WON!"
		# Update remaining resources to 0 for Village 2
		label_village_2_stone.text = "Stone: 0"
		label_village_2_wood.text = "Wood: 0"
		label_village_2_gold.text = "Gold: 0"
	else:
		if village_1_won:
			label_finished_game_message.text = "Village 1 WON!"
		else:
			label_finished_game_message.text = "Village 2 WON!"
	
	## Stop the physics processing
	Engine.time_scale = 0
