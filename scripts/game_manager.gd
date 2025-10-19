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
@onready var label_win_probability = %LabelWinProbability
@onready var label_ai_difficulty = %LabelAIDifficulty

var village_1: Village
var village_2: Village

# Adaptive difficulty state (continuous 0..1 for AI village)
var ai_difficulty: float = 0.5
var last_adjust_time: float = 0.0
var adjust_interval_sec: float = 2.0

signal resource_depleted(resource_type: Village.ResourceType)
signal village_1_priority_changed(resource_type: Village.ResourceType, is_auto: bool)

func _ready():
	set_goal_labels()
	_update_remaining_resources()
	_update_win_probability()
	last_adjust_time = Time.get_ticks_msec() / 1000.0

func setup_villages():
	"""
		Sets up village references after both villages are created.
		Called after all agents are initialized.
	"""
	if village_1 != null and village_2 != null:
		# Link villages so they can access each other for strategy
		village_1.opponent_village = village_2
		village_2.opponent_village = village_1
	
func drop_resource(agent: Agent) -> void:
	""" 
		- Handles the dropping of resources by an agent. 
		- Updates the resource counts for the village and checks if the game has finished. 
	"""
	var resource = agent.current_carrying_resource
	if resource == null: return
	
	DebugLogger.write_log("[GAME_MGR] Agent " + str(agent.id) + " dropping " + str(resource.quantity) + " " + str(Village.ResourceType.find_key(resource.type)))
	
	var village = agent.village
	
	village.add_resource(resource)
	agent.current_carrying_resource = null
	
	DebugLogger.write_log("[GAME_MGR] Village " + str(village.control_mode) + " now has - Wood: " + str(village.current_wood_quantity) + ", Stone: " + str(village.current_stone_quantity) + ", Gold: " + str(village.current_gold_quantity))
	
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
	var next_resource_goal: Village.ResourceType
	# If user assigned per-agent task, honor it
	if village.control_mode == Village.ControlMode.USER_CONTROLLED and agent.has_user_selection:
		next_resource_goal = agent.user_selected_resource
	else:
		next_resource_goal = Village.ResourceType.get(village.calc_capability_dict(agent).keys()[0])
	var tile_type
	match next_resource_goal:
		Village.ResourceType.WOOD: tile_type = Common.TileType.WOOD
		Village.ResourceType.STONE: tile_type = Common.TileType.STONE
		Village.ResourceType.GOLD: tile_type = Common.TileType.GOLD
	
	agent.change_goal(tile_type)
	
func _update_remaining_resources():
	set_village_labels(label_village_1_stone, label_village_1_wood, label_village_1_gold, village_1)
	set_village_labels(label_village_2_stone, label_village_2_wood, label_village_2_gold, village_2)
	_update_win_probability()
	_maybe_adjust_difficulty()

func _maybe_adjust_difficulty() -> void:
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_adjust_time < adjust_interval_sec:
		return
	last_adjust_time = now
	_adaptive_difficulty_tick()

func _adaptive_difficulty_tick() -> void:
	# Evaluate user tactic quality vs optimal, compute fuzzy adjustment, and apply to AI village
	if village_1 == null or village_2 == null:
		return
	var tactic_quality = evaluate_user_tactic()
	var game_pressure = 1.0 - calculate_winning_probability()  # if user is likely to win, pressure low
	var delta = fuzzy_adjustment(tactic_quality, game_pressure)
	ai_difficulty = clamp(ai_difficulty + delta, 0.0, 1.0)
	# Apply on AI village (Village 2)
	village_2.apply_difficulty(ai_difficulty)
	# Optional: small UI feedback could be added

func evaluate_user_tactic() -> float:
	"""
		Returns a score in [0,1] measuring how close user's per-agent selections are
		to the optimal auto-mode evaluation.
		1. For each agent in Village 1:
		   - Compute optimal resource via Village.get_optimal_resource_for_agent
		   - Compare to current chosen resource (user-selected if any, else current goal mapping)
		2. Weight by capability differences to reward high-impact correct choices.
	"""
	if village_1 == null or village_1.agents.is_empty():
		return 0.5
	var total_weight := 0.0
	var matched_weight := 0.0
	for agent in village_1.agents:
		if agent.current_state == Agent.State.ELIMINATED:
			continue
		var optimal_res: Village.ResourceType = village_1.get_optimal_resource_for_agent(agent)
		# Determine current user choice
		var current_res: Village.ResourceType = optimal_res
		if agent.has_user_selection:
			current_res = agent.user_selected_resource
		else:
			# Infer from current goal
			match agent.current_goal:
				Common.TileType.WOOD: current_res = Village.ResourceType.WOOD
				Common.TileType.STONE: current_res = Village.ResourceType.STONE
				Common.TileType.GOLD: current_res = Village.ResourceType.GOLD
				_: current_res = optimal_res
		# Capability weight
		var opt_cap = village_1.calc_capability_for_eval(agent, optimal_res)
		var cur_cap = village_1.calc_capability_for_eval(agent, current_res)
		var weight = max(opt_cap, cur_cap)
		if weight <= 0:
			weight = 0.1
		total_weight += weight
		if current_res == optimal_res:
			matched_weight += weight
		else:
			# Partial credit if close: ratio of cur_cap to opt_cap
			if opt_cap > 0:
				matched_weight += clamp(cur_cap / opt_cap, 0.0, 1.0) * weight * 0.5
	if total_weight == 0:
		return 0.5
	return clamp(matched_weight / total_weight, 0.0, 1.0)

func fuzzy_adjustment(tactic_quality: float, game_pressure: float) -> float:
	"""
		Fuzzy logic to compute difficulty delta per tick.
		Inputs:
		  - tactic_quality (0..1): Low=0..0.4, Medium=0.3..0.7, High=0.6..1.0
		  - game_pressure (0..1): Low=0..0.4 (user ahead), High=0.6..1.0 (AI ahead)
		Output:
		  - delta in [-0.05, +0.05] to adjust ai_difficulty gradually.
	"""
	var tq_low = tri(0.0, 0.0, 0.4, tactic_quality)
	var tq_med = tri(0.3, 0.5, 0.7, tactic_quality)
	var tq_high = tri(0.6, 1.0, 1.0, tactic_quality)

	var gp_low = tri(0.0, 0.0, 0.4, game_pressure)
	var gp_med = tri(0.3, 0.5, 0.7, game_pressure)
	var gp_high = tri(0.6, 1.0, 1.0, game_pressure)

	# Rules (Mamdani):
	# 1) If tactic is Low and pressure is High -> increase difficulty strongly
	# 2) If tactic is Low and pressure is Low -> small increase (keep some challenge)
	# 3) If tactic is High and pressure is High -> small decrease (user good but still pressured)
	# 4) If tactic is High and pressure is Low -> decrease strongly
	# 5) If both Medium -> slight increase or decrease depending on relative values
	var inc_strong = min(tq_low, gp_high)
	var inc_small = min(tq_low, gp_low)
	var dec_small = min(tq_high, gp_high)
	var dec_strong = min(tq_high, gp_low)
	var med_mix = min(tq_med, gp_med)

	# Defuzzify to delta [-0.05, +0.05]
	var num = 0.0
	var den = 0.0
	if inc_strong > 0.0:
		num += inc_strong * 0.05
		den += inc_strong
	if inc_small > 0.0:
		num += inc_small * 0.02
		den += inc_small
	if dec_small > 0.0:
		num += dec_small * -0.02
		den += dec_small
	if dec_strong > 0.0:
		num += dec_strong * -0.05
		den += dec_strong
	# medium mix: push slightly towards balancing based on (0.5 - tq_med) (+/-)
	if med_mix > 0.0:
		var mid_val = (0.5 - tactic_quality) * 0.04
		num += med_mix * mid_val
		den += med_mix
	if den == 0:
		return 0.0
	return clamp(num / den, -0.05, 0.05)

static func tri(a: float, b: float, c: float, x: float) -> float:
	if x <= a or x >= c:
		return 0.0
	if x == b:
		return 1.0
	if x < b:
		return (x - a) / max(0.0001, (b - a))
	return (c - x) / max(0.0001, (c - b))

func _update_win_probability():
	if label_win_probability == null:
		return
	var probability = calculate_winning_probability()
	label_win_probability.text = "Win Probability: %d%%" % int(probability * 100)
	if label_ai_difficulty != null:
		label_ai_difficulty.text = "AI Difficulty: %d%%" % int(ai_difficulty * 100)

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
			if village_1 == null:
				village_1 = Village.new()
				village_1.control_mode = Village.ControlMode.USER_CONTROLLED  # Village 1 is user-controlled
			village_1.add_agent(agent)
			village = village_1
		"1":
			if village_2 == null:
				village_2 = Village.new()
				village_2.control_mode = Village.ControlMode.AI_CONTROLLED  # Village 2 is AI-controlled
			village_2.add_agent(agent)
			village = village_2
	
	# Setup village links if both exist
	if village_1 != null and village_2 != null:
		setup_villages()
	
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

func calculate_winning_probability() -> float:
	"""
		Calculates the winning probability for Village 1 (user-controlled).
		Based on:
		- Resource gap between villages
		- Number of agents alive
		- Agent capabilities (carry capacity, speed, energy)
		Returns a value between 0.0 and 1.0 (0% to 100%)
	"""
	if village_1 == null or village_2 == null:
		return 0.5
	
	var score_v1 = 0.0
	var score_v2 = 0.0
	
	# Factor 1: Resource completion percentage (weight: 40%)
	var v1_completion = calculate_completion_percentage(village_1)
	var v2_completion = calculate_completion_percentage(village_2)
	score_v1 += v1_completion * 0.4
	score_v2 += v2_completion * 0.4
	
	# Factor 2: Number of active agents (weight: 30%)
	var v1_agent_count = village_1.agents.size()
	var v2_agent_count = village_2.agents.size()
	var total_agents = v1_agent_count + v2_agent_count
	if total_agents > 0:
		score_v1 += (float(v1_agent_count) / total_agents) * 0.3
		score_v2 += (float(v2_agent_count) / total_agents) * 0.3
	
	# Factor 3: Agent capabilities (weight: 30%)
	var v1_capability = calculate_village_capability(village_1)
	var v2_capability = calculate_village_capability(village_2)
	var total_capability = v1_capability + v2_capability
	if total_capability > 0:
		score_v1 += (v1_capability / total_capability) * 0.3
		score_v2 += (v2_capability / total_capability) * 0.3
	
	# Normalize to probability (0.0 to 1.0)
	var total_score = score_v1 + score_v2
	if total_score > 0:
		return score_v1 / total_score
	return 0.5

func calculate_completion_percentage(village: Village) -> float:
	"""
		Calculates how close a village is to completing its goal (0.0 to 1.0).
	"""
	var wood_pct = 0.0 if Village.target_wood_quantity == 0 else min(1.0, float(village.current_wood_quantity) / Village.target_wood_quantity)
	var stone_pct = 0.0 if Village.target_stone_quantity == 0 else min(1.0, float(village.current_stone_quantity) / Village.target_stone_quantity)
	var gold_pct = 0.0 if Village.target_gold_quantity == 0 else min(1.0, float(village.current_gold_quantity) / Village.target_gold_quantity)
	
	return (wood_pct + stone_pct + gold_pct) / 3.0

func calculate_village_capability(village: Village) -> float:
	"""
		Calculates overall capability score for a village based on agent attributes.
	"""
	var total_capability = 0.0
	
	for agent in village.agents:
		if agent.current_state != Agent.State.ELIMINATED:
			# Sum up carry capacities
			total_capability += agent.chromosome.wood_carry_capacity * 0.1
			total_capability += agent.chromosome.stone_carry_capacity * 0.2
			total_capability += agent.chromosome.gold_carry_capacity * 1.0
			# Add speed factor
			total_capability += agent.chromosome.speed * 0.01
			# Add energy factor
			total_capability += agent.energy * 0.01
	
	return total_capability

func set_village_1_priority(resource_type: Village.ResourceType, auto_mode: bool = false) -> void:
	"""
		Sets the resource priority for Village 1.
		Called from the UI when user selects a resource.
		Resumes the game after initial selection.
	"""
	DebugLogger.write_log("[GAME MANAGER] set_village_1_priority called - Type: " + str(Village.ResourceType.find_key(resource_type)) + " Auto: " + str(auto_mode))
	
	if village_1 != null:
		DebugLogger.write_log("[GAME MANAGER] Village 1 found, calling set_user_resource_priority")
		village_1.set_user_resource_priority(resource_type, auto_mode)
		village_1_priority_changed.emit(resource_type, auto_mode)
		
		DebugLogger.write_log("[GAME MANAGER] Village 1 state - is_priority_selected: " + str(village_1.is_priority_selected))
		DebugLogger.write_log("[GAME MANAGER] Village 1 state - control_mode: " + str(village_1.control_mode))
		DebugLogger.write_log("[GAME MANAGER] Village 1 state - user_selected_resource: " + str(Village.ResourceType.find_key(village_1.user_selected_resource)))
		
		# Resume game after initial selection
		if Engine.time_scale == 0:
			DebugLogger.write_log("[GAME MANAGER] Resuming game (Engine.time_scale = 1.0)")
			Engine.time_scale = 1.0
	else:
		DebugLogger.write_log("[GAME MANAGER] ERROR: village_1 is null!")

func check_resource_availability(resource_type: Village.ResourceType) -> bool:
	"""
		Checks if there are any available resources of the given type on the map.
		Returns true if at least one resource source has quantity > 0.
	"""
	# This will be called from the map to check resource availability
	# For now, we'll emit a signal that can be caught by the UI
	return true
