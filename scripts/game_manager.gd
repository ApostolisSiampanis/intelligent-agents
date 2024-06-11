extends Node

class_name GameManager

var village_1: Village
var village_2: Village

func drop_resource(agent: Agent) -> void:
	var resource = agent.current_carrying_resource
	if resource == null: return
	
	var village = agent.village
	
	village.add_resource(resource)
	agent.current_carrying_resource = null
	
	# Check for game end
	if is_game_finished(village): finish_game()

func eliminate(agent: Agent) -> void:
	var village = agent.village
	village.remove_agent(agent)
	if village.agents.is_empty(): finish_game()

func assign_resource_goal(agent: Agent) -> void:
	var village = get_village(agent)
	var next_resource_goal = Village.ResourceType.get(village.calc_capability_dict(agent).keys()[0])
	var tile_type
	match next_resource_goal:
		Village.ResourceType.WOOD: tile_type = Common.TileType.WOOD
		Village.ResourceType.STONE: tile_type = Common.TileType.STONE
		Village.ResourceType.GOLD: tile_type = Common.TileType.GOLD
	
	agent.change_goal(tile_type)

func is_game_finished(village: Village) -> bool:
	return village.is_goal_completed()

func merge_knowledge(caller_agent: Agent, target_agent: Agent) -> void:
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
	print("Knowledge exchange: " + str(caller_agent.id) + "-" + str(target_agent.id))

func update_astar(caller_agent: Agent, target_agent: Agent) -> void:
	for point_id in target_agent.astar.get_point_ids():
		
		if !caller_agent.astar.has_point(point_id):
			caller_agent.astar.add_point(point_id, target_agent.astar.get_point_position(point_id))
		
		for connected_point_id in target_agent.astar.get_point_connections(point_id):
			
			if !caller_agent.astar.has_point(connected_point_id):
				caller_agent.astar.add_point(connected_point_id, target_agent.astar.get_point_position(connected_point_id))
			
			if !caller_agent.astar.are_points_connected(point_id, connected_point_id):
				caller_agent.astar.connect_points(point_id, connected_point_id)

func merge_valuable_point_ids(caller_agent: Agent, target_agent: Agent) -> void:
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

func fertilize(caller_agent: Agent, target_agent: Agent, caller_wants_to_fertilize: bool):
	if !(caller_wants_to_fertilize && target_agent.wants_to_fertilize(caller_agent)): return
	
	# Both want to fertilize
	Fertilizer.fertilize(caller_agent, target_agent)

func finish_game():
	# TODO: Add reason
	print("Game finished")
