extends CharacterBody2D

#var tile_map
@onready var tile_map = %TileMap
@onready var label = $Label
@onready var timer = %Timer

const SPEED: int = 150
var energy := MAX_ENERGY_LEVEL
var current_goal_type: String = "stone"

enum State { WALKING, DECIDING, REFILLING, IDLE }
enum SearchAlgorithm { EXPLORE, ASTAR, NONE }

var available_tile_steps: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0),  # Horizontal movement
	Vector2i(0, 1), Vector2i(0, -1)  # Vertical movement
]

var current_state: State
var current_search_algorithm: SearchAlgorithm

var destination_pos: Vector2i

var astar: AStar2D
var is_backtracking: bool = false
var astar_path_queue: PackedInt64Array = []
var valuable_tile_point_ids: Dictionary = {}

var not_visited = []
var visited = []

var spawn_tile_type: String

const MAX_ENERGY_LEVEL := 100
const SPAWN_REFILL_ENERGY_THRESHOLD := MAX_ENERGY_LEVEL / 2
const RETURN_TO_SPAWN_ENERGY_THRESHOLD := MAX_ENERGY_LEVEL / 3
const ENERGY_LOSS_VALUE := 1
const ENERGY_GAIN_VALUE := 10

func _on_ready():
	var current_tile_pos = tile_map.local_to_map(position)
	spawn_tile_type = get_tile_type(current_tile_pos)
	valuable_tile_point_ids[spawn_tile_type] = [get_point_id(current_tile_pos)]
	
	label.text = str(energy) + "%"
	
	# Connect timer signal
	timer.timeout.connect(_on_timer_timeout)
	
	# Initialize AStar
	astar = AStar2D.new()
	
	# Initialize not_visited tiles
	not_visited.append(current_tile_pos)
	
	current_state = State.DECIDING
	choose_search_algorithm()
	print("Agent is at x: " + str(position.x) + " y: " + str(position.y))

func _physics_process(delta):
	if current_state == State.IDLE || current_state == State.REFILLING: return
	match current_state:
		State.WALKING: walk(delta)
		State.DECIDING: decide()

func filter_tiles(tiles):
	tiles.shuffle()
	var walkable_tiles: Array = []
	for i in range(tiles.size()):
		if tiles[i].type == "wall":
			continue
		if tiles[i].type == current_goal_type:
			walkable_tiles.push_front(tiles[i])
		elif !visited.has(tiles[i].position):
			walkable_tiles.append(tiles[i])
	return walkable_tiles

func calculate_destination(current_tile_position, next_tile_position):
	var tile_dif = calculate_dif(Vector2i(current_tile_position), Vector2i(next_tile_position))
	return (Vector2i(position) + tile_dif * tile_map.get_tile_size())

func calculate_dif(vector1: Vector2i, vector2: Vector2i):
	return vector2 - vector1

func is_one_step_away(current_tile_position, next_tile_position):
	var tile_dif = calculate_dif(Vector2i(current_tile_position), Vector2i(next_tile_position))
	return available_tile_steps.has(tile_dif)

func walk(delta):
	position = position.move_toward(destination_pos, SPEED * delta)
	if Vector2i(position.x, position.y) == destination_pos:
		current_state = State.DECIDING

func decide():
	var current_tile_pos = tile_map.local_to_map(position)
	var tile_type = get_tile_type(current_tile_pos)
	
	if is_backtracking && astar_path_queue.is_empty():
		is_backtracking = false
		choose_search_algorithm()
	
	var goal_reached = tile_type == current_goal_type
	
	if current_search_algorithm == SearchAlgorithm.EXPLORE:
		visited.push_back(current_tile_pos)
	elif current_search_algorithm == SearchAlgorithm.ASTAR:
		goal_reached = goal_reached && astar_path_queue.is_empty()
	
	if goal_reached:
		if current_search_algorithm == SearchAlgorithm.EXPLORE:
			update_valuable_tiles(current_tile_pos, tile_type)
		# If the agent is at spawn
		elif get_point_id(current_tile_pos) == valuable_tile_point_ids[spawn_tile_type][0]:
			# TODO: Check if the agent has any resources to leave at spawn
			if energy <= SPAWN_REFILL_ENERGY_THRESHOLD:
				current_state = State.REFILLING
				return
	
	redefine_goal(goal_reached)
	
	match current_search_algorithm:
		SearchAlgorithm.EXPLORE: explore(current_tile_pos)	
		SearchAlgorithm.ASTAR: use_astar(current_tile_pos)
	
	if current_goal_type.is_empty():
		current_state = State.IDLE
	else:
		current_state = State.WALKING

func explore(current_tile_pos: Vector2i):
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
	
	next_tile_pos = not_visited.front()
	while visited.has(next_tile_pos):
		not_visited.pop_front()
		next_tile_pos = not_visited.front()
	
	if next_tile_pos == null:
		print("I don't have anything to explore")
		change_goal("")
		return
	
	if is_one_step_away(tile_map.local_to_map(position), next_tile_pos):
		destination_pos = calculate_destination(tile_map.local_to_map(position), next_tile_pos)
	else:
		is_backtracking = true
		choose_search_algorithm()
		use_astar(current_tile_pos)

func use_astar(current_tile_pos: Vector2i):
	if astar_path_queue.is_empty():
		# Create the path queue
		# TODO: Find closest point
		var target_tile_id
		if is_backtracking:
			target_tile_id = get_point_id(not_visited[0])
		else:
			target_tile_id = valuable_tile_point_ids[current_goal_type][0]
		astar_path_queue = astar.get_id_path(get_point_id(current_tile_pos), target_tile_id).slice(1)
	
	# Calculate destination for the next tile
	destination_pos = calculate_destination(current_tile_pos, astar.get_point_position(astar_path_queue[0]))
	astar_path_queue.remove_at(0)

func get_point_id(vector: Vector2i):
	return vector.x * tile_map.MAX_Y + vector.y

func redefine_goal(goal_reached: bool):
	
	# TODO: Check for energy level
	
	if goal_reached:
		# TODO: Change goal based on team goals
		# TODO: Call choose_search_algorithm()
		if current_goal_type == "stone":
			change_goal(spawn_tile_type)
		else:
			change_goal("stone")
		return

func change_goal(goal_type: String):
	if goal_type == null || goal_type.is_empty():
		current_goal_type = ""
		choose_search_algorithm()
		return
		
	current_goal_type = goal_type
	choose_search_algorithm()

func choose_search_algorithm():
	if current_goal_type == null || current_goal_type.is_empty():
		current_search_algorithm = SearchAlgorithm.NONE
		return
	if is_backtracking:
		current_search_algorithm = SearchAlgorithm.ASTAR
		return
	current_search_algorithm = SearchAlgorithm.EXPLORE if !valuable_tile_point_ids.has(current_goal_type) else SearchAlgorithm.ASTAR

func get_tile_type(current_tile_pos: Vector2i):
	var tile_data = tile_map.get_cell_tile_data(1, current_tile_pos)
	if tile_data == null: tile_data = tile_map.get_cell_tile_data(0, current_tile_pos)
	return tile_data.get_custom_data("type")

func update_valuable_tiles(current_tile_pos: Vector2i, tile_type: String):
	var current_tile_pos_id = get_point_id(current_tile_pos)
	if valuable_tile_point_ids.has(tile_type):
		valuable_tile_point_ids[tile_type].append(current_tile_pos_id)
	else:
		valuable_tile_point_ids[tile_type] = [current_tile_pos_id]

func set_tile_map(tile_map: TileMap):
	self.tile_map = tile_map

func _on_timer_timeout():
	if current_state == State.REFILLING:
		var new_energy = energy + ENERGY_GAIN_VALUE
		energy = MAX_ENERGY_LEVEL if new_energy > MAX_ENERGY_LEVEL else new_energy
		if energy == MAX_ENERGY_LEVEL:
			current_state = State.DECIDING
	else:
		energy -= ENERGY_LOSS_VALUE
		if current_goal_type != spawn_tile_type && energy <= RETURN_TO_SPAWN_ENERGY_THRESHOLD:
			change_goal(spawn_tile_type)
	
	label.text = str(energy) + "%"
	
	if energy <= 0:
		queue_free()
