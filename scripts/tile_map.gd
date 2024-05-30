extends TileMap


class TileInfo:	
	var type = ""
	var position = Vector2i.ZERO

func _ready():
	pass
	
func get_adjacent_tiles(agent_pos, available_tile_steps):
	var adjacent_tiles = []
	var tile_pos = local_to_map(agent_pos)
	
	for step in available_tile_steps:
		var new_pos = tile_pos + step
		
		var adj_tile_data = get_cell_tile_data(0, new_pos)
		
		if adj_tile_data == null:
			continue
		
		var tile_info = TileInfo.new()
		tile_info.position = new_pos
		tile_info.type = adj_tile_data.get_custom_data("type")
		
		adjacent_tiles.append(tile_info)
	
	return adjacent_tiles
