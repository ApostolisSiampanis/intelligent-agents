extends CharacterBody2D

@onready var tile_map = %TileMap

const SPEED = 50
const GOAL_TYPE = "sand"
const EPSILON = 2

enum State { WALKING, IDLE, EXPLORING }

var available_tile_steps = [
	Vector2i(1, 0), Vector2i(-1, 0),  # Horizontal movement
	Vector2i(0, 1), Vector2i(0, -1),  # Vertical movement
	Vector2i(1, 1), Vector2i(-1, 1),  # Diagonal movement
	Vector2i(1, -1), Vector2i(-1, -1)   # Diagonal movement
]

var current_state
var prev_state

var destination_pos
var tile_dif
var current_speed
var visited_tiles = {}


var dfs_not_visited = []

var dfs_visited = []
var current_tile_pos


func _on_ready():
	current_tile_pos = tile_map.local_to_map(position)
	var current_tile_data = tile_map.get_cell_tile_data(0, current_tile_pos)
	
	# Initialize the path
	dfs_not_visited.append(current_tile_pos)
	
	explore()
	
	print("Agent is at x: " + str(position.x) + " y: " + str(position.y))
	

func filter_tiles(tiles):
	for i in range(tiles.size()):
		if tiles[i].type == GOAL_TYPE:
			tiles.push_front(tiles.pop_at(i))
			break
	return tiles

func calculate_destination(next_tile_position, current_tile_position):
	tile_dif = next_tile_position - current_tile_position
	return (Vector2i(position) + tile_dif * tile_map.get_tile_size())

func calculate_max_abs(tile_dif):
	var max_abs = abs(tile_dif.x) # Default abs, abs_x
	var abs_y = abs(tile_dif.y)
	if abs_y > max_abs:
		max_abs = abs_y
	return max_abs	

func _process(delta):
	if current_state == State.EXPLORING:
		
		var next_tile_position = dfs_not_visited.front()
		while dfs_visited.has(next_tile_position):
			dfs_not_visited.pop_front()
			next_tile_position = dfs_not_visited.front()
		
		destination_pos = calculate_destination(next_tile_position, tile_map.local_to_map(position))
		current_speed = SPEED / calculate_max_abs(tile_dif)
		
		prev_state = State.EXPLORING
		current_state = State.WALKING
		
		return
	elif current_state == State.WALKING:
		position += tile_dif * current_speed * delta
		if (Vector2i(position) - destination_pos).length() <= EPSILON:
			
			position = destination_pos
			
			if prev_state == State.EXPLORING:
				var current_tile_pos = dfs_not_visited.front()
				dfs_visited.push_back(current_tile_pos)
				# Check if final dest before exploring
				var tile_type = tile_map.get_cell_tile_data(0, current_tile_pos).get_custom_data("type")
				if tile_type == GOAL_TYPE:
					current_state = State.IDLE
					print("Found sand!")
				else:
					explore()
			
			prev_state = State.WALKING
			
			return

func explore():
	var next_tile_pos = dfs_not_visited.pop_front()
	var adj_tiles = tile_map.get_adjacent_tiles(next_tile_pos, available_tile_steps)
	
	var filtered_tiles = filter_tiles(adj_tiles)
	
	# Append front to dfs_non_visited
	for i in range(filtered_tiles.size()-1, -1, -1):
		dfs_not_visited.push_front(filtered_tiles[i].position)
	
	current_state = State.EXPLORING

func update_visited_tiles(tiles):
	for tile in tiles:
		if !visited_tiles.has(tile.position):
			visited_tiles[tile.position] = tile.type
	print(visited_tiles)
