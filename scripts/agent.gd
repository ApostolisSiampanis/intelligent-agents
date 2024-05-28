extends CharacterBody2D

@onready var tile_map = %TileMap

const SPEED = 50
const GOAL_TYPE = "sand"
const EPSILON = 2

var available_tile_steps = [
	Vector2i(1, 0), Vector2i(-1, 0),  # Horizontal movement
	Vector2i(0, 1), Vector2i(0, -1),  # Vertical movement
	Vector2i(1, 1), Vector2i(-1, 1),  # Diagonal movement
	Vector2i(1, -1), Vector2i(-1, -1)   # Diagonal movement
]

enum State { WALKING, STANDING, DISCOVERING }

var current_state
var next_tile
var tile_dif
var destination_pos

func _on_ready():
	current_state = State.DISCOVERING
	print("Agent is at x: " + str(position.x) + " y: " + str(position.y))
	

func choose_next_step(tiles):
	var found = false
	
	for tile in tiles:
		if tile.type == GOAL_TYPE:
			next_tile = tile
			found = true
			break
	
	if !found:
		next_tile = tiles[randi() % tiles.size()]
	
	current_state = State.WALKING

func calculate_destination(next_tile, current_position):
	tile_dif = next_tile.position - current_position
	destination_pos = Vector2i(position) + tile_dif * tile_map.get_tile_size()
	print("Destination: " + str(destination_pos))

func _process(delta):
	if current_state == State.DISCOVERING:
		var current_position = tile_map.local_to_map(position)
		var adj_tiles = tile_map.get_adjacent_tiles(current_position, available_tile_steps)
		choose_next_step(adj_tiles)
		calculate_destination(next_tile, current_position)
		return
	elif current_state == State.WALKING:
		position += tile_dif * SPEED * delta
		if (Vector2i(position) - destination_pos).length() <= EPSILON:
			position = destination_pos
			current_state = State.DISCOVERING
			return
