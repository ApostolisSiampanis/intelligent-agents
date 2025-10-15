extends Node

class_name Village

static var target_wood_quantity: int
static var target_stone_quantity: int
static var target_gold_quantity: int
var current_wood_quantity := 0
var current_stone_quantity := 0
var current_gold_quantity := 0

enum ResourceType { WOOD, STONE, GOLD }
enum ControlMode { USER_CONTROLLED, AI_CONTROLLED }

var agents := []
var assigned_goals := {}
var control_mode: ControlMode = ControlMode.AI_CONTROLLED
var user_selected_resource: ResourceType = ResourceType.WOOD
var is_auto_mode: bool = false
var is_priority_selected: bool = false  # Track if user has selected initial priority
var opponent_village: Village = null  # Reference to opponent village for AI strategy

static func set_target_resource_quantity(goal: Dictionary) -> void:
	"""
		Sets the target quantities for wood, stone, and gold based on
		the provided dictionary.
	"""
	target_wood_quantity = goal.wood
	target_stone_quantity = goal.stone
	target_gold_quantity = goal.gold

static func resource_type_to_str(type: ResourceType) -> String:
	"""
		Converts a ResourceType enum value to its corresponding string representation.
	"""
	match type:
		ResourceType.WOOD: return 'wood'
		ResourceType.STONE: return 'stone'
		ResourceType.GOLD: return 'gold'
		_: return 'resource'

func add_agent(agent):
	if agents.has(agent): return
	agents.append(agent)

func remove_agent(agent):
	agents.erase(agent)

func is_goal_completed() -> bool:
	if current_wood_quantity < target_wood_quantity: return false
	if current_stone_quantity < target_stone_quantity: return false
	if current_gold_quantity < target_gold_quantity: return false
	return true

func add_resource(resource: Agent.CarryingResource):
	""" 
		Adds the quantity of a specific resource to the village's current resources.
	"""

	match resource.type:
		Village.ResourceType.WOOD:
			current_wood_quantity += resource.quantity
		Village.ResourceType.STONE:
			current_stone_quantity += resource.quantity
		Village.ResourceType.GOLD:
			current_gold_quantity += resource.quantity

func calc_capability_dict(agent: Agent):
	""" 
		Calculates a dictionary of resource types and their corresponding capabilities for an agent. 
		For user-controlled villages, respects the user's resource priority selection.
		For AI-controlled villages, adapts strategy based on game state and opponent behavior.
	"""
	var cap_dict = {}
	
	# User-controlled village with manual resource selection
	if control_mode == ControlMode.USER_CONTROLLED && !is_auto_mode:
		var resource_key = ResourceType.find_key(user_selected_resource)
		cap_dict = {resource_key: 1.0}  # Force selected resource
		return cap_dict
	
	# Auto mode or AI-controlled village - calculate best resource
	for resource_type in ResourceType.keys():
		var temp = ResourceType.get(resource_type)
		var capability = calc_capability(agent, temp)
		if cap_dict.is_empty():
			cap_dict = {resource_type: capability}
		else:
			if capability > cap_dict.values()[0]:
				cap_dict = {resource_type: capability}
	
	return cap_dict

func calc_capability(agent: Agent, resource_type: ResourceType) -> float:
	""" 
		Calculates the capability of an agent for a specific resource type.
		For AI-controlled villages, adapts strategy based on opponent's behavior.
	"""

	var capability = calc_resource_significance_metric(resource_type)
	if capability == 0.0: return capability
	
	if !has_knowledge(agent, resource_type): capability * 0.5
	
	capability *= calc_working_agents_metric(resource_type)
	
	capability *= calc_chromosome_metric(agent, resource_type)
	
	# AI adaptation: If this is an AI-controlled village, adjust based on game state
	if control_mode == ControlMode.AI_CONTROLLED:
		capability *= calc_ai_strategy_multiplier(resource_type)
	
	return capability

func calc_resource_significance_metric(resource_type: ResourceType) -> float:
	""" 
		Calculates the significance of a resource type based on remaining quantity and agents' carrying capacity.
	"""

	var remaining_resource_quantity = 0
	var agents_total_carry_cap = 0
	match resource_type:
		ResourceType.WOOD:
			remaining_resource_quantity = target_wood_quantity - current_wood_quantity
			if remaining_resource_quantity <= 0: return 0
			
			for agent in agents:
				agents_total_carry_cap += agent.chromosome.wood_carry_capacity
			
		ResourceType.STONE:
			remaining_resource_quantity = target_stone_quantity - current_stone_quantity
			if remaining_resource_quantity <= 0: return 0
			
			for agent in agents:
				agents_total_carry_cap += agent.chromosome.stone_carry_capacity
			
		ResourceType.GOLD:
			remaining_resource_quantity = target_gold_quantity - current_gold_quantity
			if remaining_resource_quantity <= 0: return 0
			
			for agent in agents:
				agents_total_carry_cap += agent.chromosome.gold_carry_capacity
			
	return remaining_resource_quantity / float(agents_total_carry_cap)

func has_knowledge(agent: Agent, resource_type: ResourceType) -> bool:
	var resource_tile_type = Common.get_tile_type_from_resource(resource_type)
	var found := false
	for tile_type in agent.valuable_tile_point_ids.keys():
		if tile_type != resource_tile_type: continue
		
		for resource_is_available in agent.valuable_tile_point_ids[tile_type].values():
			if resource_is_available:
				found = true
				break
		
	return found

func calc_working_agents_metric(resource_type: ResourceType) -> float:
	""" 
		Calculates the metric based on the number of agents assigned to a resource type.
	"""

	if assigned_goals.is_empty(): return 1.0
	if !assigned_goals.has(resource_type): return 1.0
	return 1 - (assigned_goals[resource_type].size() / agents.size())

func calc_chromosome_metric(agent: Agent, resource_type: ResourceType) -> float:
	""" 
		Calculates the chromosome metric for an agent based on its carrying capacity bits. 
	"""

	var capacity_bits = agent.chromosome.get_carry_capacity_bits(resource_type)
	var factor = 0.0
	
	if capacity_bits.length() == 2:
		match capacity_bits:
			"00": factor = 0.25
			"01": factor = 0.5
			"10": factor = 0.75
			"11": factor = 1
	elif capacity_bits.length() == 1:
		match capacity_bits:
			"0": factor = 0.5
			"1": factor = 1
	
	return factor

func set_user_resource_priority(resource: ResourceType, auto_mode: bool = false) -> void:
	"""
		Sets the resource priority for user-controlled village.
		Called when user selects a resource button in the UI.
	"""
	DebugLogger.write_log("[VILLAGE] set_user_resource_priority called - Resource: " + str(ResourceType.find_key(resource)) + " Auto: " + str(auto_mode))
	user_selected_resource = resource
	is_auto_mode = auto_mode
	is_priority_selected = true
	DebugLogger.write_log("[VILLAGE] Updated state - is_priority_selected: " + str(is_priority_selected) + " control_mode: " + str(control_mode))

func get_current_priority_resource() -> ResourceType:
	"""
		Returns the current priority resource for this village.
	"""
	if is_auto_mode || control_mode == ControlMode.AI_CONTROLLED:
		# Calculate best resource based on capabilities
		var best_resource = ResourceType.WOOD
		var best_capability = 0.0
		
		for resource_type in ResourceType.keys():
			var temp = ResourceType.get(resource_type)
			var remaining = get_remaining_quantity(temp)
			if remaining > 0:
				# Simple heuristic: prioritize resource with most remaining need
				if remaining > best_capability:
					best_capability = remaining
					best_resource = temp
		
		return best_resource
	else:
		return user_selected_resource

func get_remaining_quantity(resource_type: ResourceType) -> int:
	"""
		Returns the remaining quantity needed for a specific resource type.
	"""
	match resource_type:
		ResourceType.WOOD:
			return max(0, target_wood_quantity - current_wood_quantity)
		ResourceType.STONE:
			return max(0, target_stone_quantity - current_stone_quantity)
		ResourceType.GOLD:
			return max(0, target_gold_quantity - current_gold_quantity)
	return 0

func calc_ai_strategy_multiplier(resource_type: ResourceType) -> float:
	"""
		AI strategy adaptation for Village 2.
		Analyzes game state and opponent behavior to adjust resource priorities.
		
		Strategy combines:
		1. Counter-strategy: Compete for resources opponent needs
		2. Race strategy: Focus on resources we can collect fastest
		3. Defensive strategy: Protect our lead if we have one
	"""
	var multiplier = 1.0
	
	# Get opponent village (assuming this is Village 2, opponent is Village 1)
	var opponent_village = get_opponent_village()
	if opponent_village == null:
		return multiplier
	
	# Factor 1: Counter-strategy - prioritize what opponent is targeting (50% weight)
	if opponent_village.control_mode == ControlMode.USER_CONTROLLED:
		if not opponent_village.is_auto_mode:
			# If opponent is manually selecting this resource, increase priority
			if opponent_village.user_selected_resource == resource_type:
				multiplier *= 1.5  # Compete for same resource
		
	# Factor 2: Race strategy - focus on resources with best completion ratio (30% weight)
	var our_completion = get_resource_completion_ratio(resource_type)
	var opponent_completion = opponent_village.get_resource_completion_ratio(resource_type)
	
	if our_completion > opponent_completion:
		# We're ahead on this resource, slight boost to finish it
		multiplier *= 1.2
	elif opponent_completion > our_completion + 0.3:
		# Opponent is significantly ahead, reduce priority
		multiplier *= 0.7
	
	# Factor 3: Adaptive strategy - if we're losing overall, take risks (20% weight)
	var our_overall_completion = (
		get_resource_completion_ratio(ResourceType.WOOD) +
		get_resource_completion_ratio(ResourceType.STONE) +
		get_resource_completion_ratio(ResourceType.GOLD)
	) / 3.0
	
	var opponent_overall = (
		opponent_village.get_resource_completion_ratio(ResourceType.WOOD) +
		opponent_village.get_resource_completion_ratio(ResourceType.STONE) +
		opponent_village.get_resource_completion_ratio(ResourceType.GOLD)
	) / 3.0
	
	if opponent_overall > our_overall_completion + 0.2:
		# We're losing, focus more on what we can complete fastest
		var remaining = get_remaining_quantity(resource_type)
		if remaining > 0 and remaining < target_wood_quantity * 0.3:  # Less than 30% left
			multiplier *= 1.4  # Push to finish close resources
	
	return multiplier

func get_resource_completion_ratio(resource_type: ResourceType) -> float:
	"""
		Returns completion ratio (0.0 to 1.0) for a specific resource.
	"""
	match resource_type:
		ResourceType.WOOD:
			return 0.0 if target_wood_quantity == 0 else min(1.0, float(current_wood_quantity) / target_wood_quantity)
		ResourceType.STONE:
			return 0.0 if target_stone_quantity == 0 else min(1.0, float(current_stone_quantity) / target_stone_quantity)
		ResourceType.GOLD:
			return 0.0 if target_gold_quantity == 0 else min(1.0, float(current_gold_quantity) / target_gold_quantity)
	return 0.0

func get_opponent_village() -> Village:
	"""
		Returns the opponent village reference.
		This assumes there are only 2 villages in the game.
	"""
	return opponent_village
