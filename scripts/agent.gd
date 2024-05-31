extends CharacterBody2D

@onready var tile_map = %TileMap

const SPEED: int = 100
const GOAL_TYPE: String = "sand"

enum State { WALKING, IDLE, EXPLORING }

var available_tile_steps: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0),  # Horizontal movement
	Vector2i(0, 1), Vector2i(0, -1)  # Vertical movement
]

var current_state: State
var prev_state: State

var destination_pos: Vector2i

var astar: AStar2D

var not_visited = []
# TODO: remove
var visited = []

var current_tile_pos


func _on_ready():
	current_tile_pos = tile_map.local_to_map(position)
	var current_tile_data = tile_map.get_cell_tile_data(0, current_tile_pos)
	
	# Initialize AStar
	astar = AStar2D.new()
	
	# Initialize the path
	not_visited.append(current_tile_pos)
	
	explore()
	
	print("Agent is at x: " + str(position.x) + " y: " + str(position.y))
	

func filter_tiles(tiles):
	tiles.shuffle()
	for i in range(tiles.size()):
		if tiles[i].type == GOAL_TYPE:
			tiles.push_front(tiles.pop_at(i))
			break
	return tiles

func calculate_destination(next_tile_position, current_tile_position):
	var tile_dif = next_tile_position - current_tile_position
	return (Vector2i(position) + tile_dif * tile_map.get_tile_size())

func _physics_process(delta):
	if current_state == State.EXPLORING:
		
		var next_tile_position = not_visited.front()
		while visited.has(next_tile_position):
			not_visited.pop_front()
			next_tile_position = not_visited.front()
		
		destination_pos = calculate_destination(next_tile_position, tile_map.local_to_map(position))
		
		prev_state = State.EXPLORING
		current_state = State.WALKING
		
		return
	elif current_state == State.WALKING:
		
		global_position = global_position.move_toward(destination_pos, SPEED * delta)
		
		if Vector2i(global_position.x, global_position.y) == destination_pos:
			
			position = destination_pos
			
			if prev_state == State.EXPLORING:
				var current_tile_pos = not_visited.front()
				visited.push_back(current_tile_pos)
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
	var next_tile_pos = not_visited.pop_front()
	
	# Add next tile point to AStar
	var next_tile_id = get_point_id(next_tile_pos)
	if !astar.has_point(next_tile_id):
		astar.add_point(next_tile_id, next_tile_pos)
	
	var adj_tiles = tile_map.get_adjacent_tiles(next_tile_pos, available_tile_steps)
	
	var filtered_tiles = filter_tiles(adj_tiles)
	
	var next_tile_connections = astar.get_point_connections(next_tile_id)
	# Append front to non_visited
	for i in range(filtered_tiles.size()-1, -1, -1):
		var child_tile_pos = filtered_tiles[i].position
		not_visited.push_front(child_tile_pos)
		
		# Add children points to AStart
		var child_tile_id = get_point_id(child_tile_pos)
		if !astar.has_point(child_tile_id):
			astar.add_point(child_tile_id, child_tile_pos)
		
		# Make the connections
		if child_tile_id not in next_tile_connections:
			astar.connect_points(next_tile_id, child_tile_id)
	
	current_state = State.EXPLORING

func get_point_id(vector: Vector2i):
	return vector.x * tile_map.MAX_Y + vector.y
