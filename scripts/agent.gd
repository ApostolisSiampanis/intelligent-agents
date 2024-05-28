extends CharacterBody2D

@onready var tile_map = %TileMap

const goal_type = "sand"

var available_tile_steps = [
	Vector2i(1, 0), Vector2i(-1, 0),  # Horizontal movement
	Vector2i(0, 1), Vector2i(0, -1),  # Vertical movement
	Vector2i(1, 1), Vector2i(-1, 1),  # Diagonal movement
	Vector2i(1, -1), Vector2i(-1, -1)   # Diagonal movement
]

func _on_ready():
	print("Agent is at x: " + str(position.x) + " y: " + str(position.y))
	var current_tile = tile_map.local_to_map(position)
	
	var tiles = tile_map.get_adjacent_tiles(current_tile, available_tile_steps)
	var next_tile = choose_next_step(tiles)
	print(str(next_tile.position) + ": " + next_tile.type)
		

func choose_next_step(tiles):
	for tile in tiles:
		if tile.type == goal_type:
			return tile
	
	return tiles[randi() % tiles.size()]

func move_to_tile(next_tile, current_tile):
	var dif = next_tile.position - current_tile.position
