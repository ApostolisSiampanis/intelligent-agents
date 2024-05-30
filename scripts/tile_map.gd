extends TileMap

const tile_size = Vector2i(64,64)

func get_tile_size():
	return tile_size

class TileInfo:	
	var type = ""
	var position = Vector2i.ZERO

func _ready():
	pass
	
func get_adjacent_tiles(current_tile, available_tile_steps):
	var adjacent_tiles = []
	
	for step in available_tile_steps:
		var new_pos = current_tile + step
		
		var adj_tile_data = get_cell_tile_data(0, new_pos)
		
		if adj_tile_data == null:
			continue
		
		var tile_info = TileInfo.new()
		tile_info.position = new_pos
		tile_info.type = adj_tile_data.get_custom_data("type")
		
		adjacent_tiles.append(tile_info)
	
	adjacent_tiles.shuffle()
	return adjacent_tiles
