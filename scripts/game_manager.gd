extends Node

class VillageScore:
	static var target_wood_quantity: int
	static var target_stone_quantity: int
	static var targer_gold_quantity: int
	var current_wood_quantity := 0
	var current_stone_quantity := 0
	var current_gold_quantity := 0
	
	static func set_target_resource_quantity(goal: Dictionary) -> void:
		"""
			
		"""
		target_wood_quantity = goal.wood
		target_stone_quantity = goal.stone
		targer_gold_quantity = goal.gold

func merge_knowledge(caller_agent, target_agent):
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

func update_astar(caller_agent, target_agent):
	for point_id in target_agent.astar.get_point_ids():
		
		if !caller_agent.astar.has_point(point_id):
			caller_agent.astar.add_point(point_id, target_agent.astar.get_point_position(point_id))
		
		for connected_point_id in target_agent.astar.get_point_connections(point_id):
			
			if !caller_agent.astar.has_point(connected_point_id):
				caller_agent.astar.add_point(connected_point_id, target_agent.astar.get_point_position(connected_point_id))
			
			if !caller_agent.astar.are_points_connected(point_id, connected_point_id):
				caller_agent.astar.connect_points(point_id, connected_point_id)

func merge_valuable_point_ids(caller_agent, target_agent):
	var merged_valuable_point_ids = caller_agent.valuable_tile_point_ids.duplicate(true)
	var target_village_point = target_agent.valuable_tile_point_ids["village"] 
	
	for tile_type in target_agent.valuable_tile_point_ids.keys():
		if tile_type == "village": continue
		
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
	if caller_agent.valuable_tile_point_ids["village"] != target_village_point:
		merged_valuable_point_ids["village"] = target_village_point
	
	target_agent.valuable_tile_point_ids = merged_valuable_point_ids

func merge_explore_tiles(caller_agent, target_agent):
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
