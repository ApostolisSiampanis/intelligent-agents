extends Node

class_name Village

static var target_wood_quantity: int
static var target_stone_quantity: int
static var target_gold_quantity: int
var current_wood_quantity := 0
var current_stone_quantity := 0
var current_gold_quantity := 0

enum ResourceType { WOOD, STONE, GOLD }

var agents := []
var assigned_goals := {}

static func set_target_resource_quantity(goal: Dictionary) -> void:
	"""
		
	"""
	target_wood_quantity = goal.wood
	target_stone_quantity = goal.stone
	target_gold_quantity = goal.gold

func add_agent(agent):
	if agents.has(agent): return
	agents.append(agent)

func is_goal_completed() -> bool:
	if current_wood_quantity < target_wood_quantity: return false
	if current_stone_quantity < target_stone_quantity: return false
	if current_gold_quantity < target_gold_quantity: return false
	return true

func add_resource(resource: Agent.CarryingResource):
	match resource.type:
		Village.ResourceType.WOOD:
			current_wood_quantity += resource.quantity
		Village.ResourceType.STONE:
			current_stone_quantity += resource.quantity
		Village.ResourceType.GOLD:
			current_gold_quantity += resource.quantity

func calc_capability_dict(agent: Agent):
	var cap_dict = {}
	
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
	# TODO: Do not calculate capability if one resource is left
	var capability = calc_resource_significance_metric(resource_type)
	if capability == 0.0: return capability
	
	if !has_knowledge(agent, resource_type): capability * 0.5
	
	capability *= calc_working_agents_metric(resource_type)
	
	capability *= calc_chromosome_metric(agent, resource_type)
	
	return capability

func calc_resource_significance_metric(resource_type: ResourceType) -> float:
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
	var resource_tile_type = CommonVariables.get_tile_type_from_resource(resource_type)
	var found := false
	for tile_type in agent.valuable_tile_point_ids.keys():
		if tile_type != resource_tile_type: continue
		
		for resource_is_available in agent.valuable_tile_point_ids[tile_type].values():
			if resource_is_available:
				found = true
				break
		
	return found

func calc_working_agents_metric(resource_type: ResourceType) -> float:
	if assigned_goals.is_empty(): return 1.0
	if !assigned_goals.has(resource_type): return 1.0
	return 1 - (assigned_goals[resource_type].size() / agents.size())

func calc_chromosome_metric(agent: Agent, resource_type: ResourceType) -> float:
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
