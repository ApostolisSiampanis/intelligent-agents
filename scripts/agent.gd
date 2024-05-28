extends CharacterBody2D

@onready var tile_map = %TileMap

const goal_type = "sand"

var available_tile_steps = [
	Vector2i(1, 0), Vector2i(-1, 0),  # Horizontal movement
	Vector2i(0, 1), Vector2i(0, -1),  # Vertical movement
	Vector2i(1, 1), Vector2i(-1, 1),  # Diagonal movement
	Vector2i(1, -1), Vector2i(-1, -1)   # Diagonal movement
]

enum State { WALKING, STANDING }

var current_state = State.STANDING
var next_tile

func _on_ready():
	print("Agent is at x: " + str(position.x) + " y: " + str(position.y))
	var current_position = tile_map.local_to_map(position)
	
	var tiles = tile_map.get_adjacent_tiles(current_position, available_tile_steps)
	choose_next_step(tiles)
	find_destination(next_tile,current_position)
	#print(str(next_tile.position) + ": " + next_tile.type)
	

func choose_next_step(tiles):
	var found = false
	
	for tile in tiles:
		if tile.type == goal_type:
			next_tile = tile
			found = true
			break
	
	if !found:
		next_tile = tiles[randi() % tiles.size()]
	
	current_state = State.WALKING

func find_destination(next_tile, current_position):
	var tile_dif = next_tile.position - current_position
	var destination_pos = Vector2i(position) + tile_dif * tile_map.get_tile_size()
	print("Destination: " + str(destination_pos))
	position = destination_pos

func _process(delta):
	if current_state == State.STANDING:
		return
	elif current_state == State.WALKING:
		
		pass
	
