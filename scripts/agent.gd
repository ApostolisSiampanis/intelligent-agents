extends CharacterBody2D

class_name Agent

class Chromosome:
	var bits: String
	var energy_loss_value: int
	var energy_gain_value: int
	var speed: int
	var wood_carry_capacity: int
	var stone_carry_capacity: int
	var gold_carry_capacity: int
	
	func _init(bits: String):
		self.bits = bits
		decode()
	
	func decode():
		"""
			Method to decode chromosome and initialize its state
		"""
		energy_loss_value = 1 if bits[1] == "0" else 2
		energy_gain_value = 5 if bits[2] == "0" else 10
		speed = 250 if bits[3] == "0" else 300
		gold_carry_capacity = 1 if get_carry_capacity_bits(Village.ResourceType.GOLD) == "0" else 3
		
		var wood_bits = get_carry_capacity_bits(Village.ResourceType.WOOD)
		match wood_bits:
			"00": wood_carry_capacity = 10
			"01": wood_carry_capacity = 20
			"10": wood_carry_capacity = 30
			"11": wood_carry_capacity = 40
		
		var stone_bits = get_carry_capacity_bits(Village.ResourceType.STONE)
		match stone_bits:
			"00": stone_carry_capacity = 5
			"01": stone_carry_capacity = 10
			"10": stone_carry_capacity = 15
			"11": stone_carry_capacity = 20
	
	func get_carry_capacity_bits(resource: Village.ResourceType) -> String:
		"""
			Returns the bits string representing the carry capacity for the given resource type.
		"""
		match resource:
			Village.ResourceType.WOOD: return bits.substr(4,2)
			Village.ResourceType.STONE: return bits.substr(6,2)
			Village.ResourceType.GOLD: return bits[8]
		return ""

class CarryingResource:
	var type: Village.ResourceType
	var quantity: int

	func _init(type: Village.ResourceType, quantity: int):
		self.type = type
		self.quantity = quantity

@onready var label = $Label
@export var id: int

@onready var agent_1 = $Agent_1
@onready var agent_2 = $Agent_2
@onready var grave = $Grave
@onready var collision_shape_2d = $CollisionShape2D
@onready var area_2d = $Area2D

var available_for_knowledge_exchange := true

var chromosome: Chromosome
var village: Village
var knowledge_ver := 1
var agent_knowledge_vers := {}
var has_new_knowledge := true

var timer: Timer
var game_manager: GameManager
var tile_map: TileMap
var energy := MAX_ENERGY_LEVEL

const MAX_ENERGY_LEVEL := 100
const SPAWN_REFILL_ENERGY_THRESHOLD := MAX_ENERGY_LEVEL / 2
const RETURN_TO_SPAWN_ENERGY_THRESHOLD := MAX_ENERGY_LEVEL / 3

var current_goal: Common.TileType

var current_carrying_resource: CarryingResource

var available_tile_steps: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0),  # Horizontal movement
	Vector2i(0, 1), Vector2i(0, -1)  # Vertical movement
]

enum State { WALKING, DECIDING, REFILLING, IDLE, ELIMINATED }
enum SearchAlgorithm { EXPLORE, ASTAR, NONE }

var current_state: State
var current_search_algorithm: SearchAlgorithm

var destination_pos: Vector2i

var astar: AStar2D
var is_backtracking := false
var astar_path_queue: PackedInt64Array = []

var valuable_tile_point_ids: Dictionary = {}

var not_visited = []
var visited = []

var spawn_tile_type: Common.TileType

func _on_ready():
	"""
		- Initializes the agent when it's added to the scene. 
		- Sets up the initial state, connects signals, and initializes variables.
	"""
	village = game_manager.get_village(self)
	
	var current_tile_pos = tile_map.local_to_map(position)
	spawn_tile_type = Common.get_tile_type(get_tile_type_str(current_tile_pos))
	valuable_tile_point_ids[spawn_tile_type] = get_point_id(current_tile_pos)
	
	label.text = str(energy) + "%"
	
	# Connect timer signal
	timer.timeout.connect(_on_timer_timeout)
	
	# Initialize AStar
	astar = AStar2D.new()
	
	# Initialize not_visited tiles
	not_visited.append(current_tile_pos)
	
	current_state = State.DECIDING
	choose_search_algorithm()

func _physics_process(delta):
	"""
		Handles the agent's state and movement logic each frame.
	"""
	if current_state == State.IDLE || current_state == State.REFILLING: return
	match current_state:
		State.WALKING: walk(delta)
		State.DECIDING: decide()

func filter_tiles(tiles):
	"""
		Filters the given tiles to remove walls and prioritize tiles based on the current goal and whether they have been visited.
	"""
	tiles.shuffle()
	var walkable_tiles := []
	for i in range(tiles.size()):
		if tiles[i].type == "wall":
			continue
		
		var adj_tile_type = Common.get_tile_type(tiles[i].type)
		if adj_tile_type == current_goal:
			walkable_tiles.push_front(tiles[i])
		elif !visited.has(tiles[i].position):
			walkable_tiles.append(tiles[i])
		
		if adj_tile_type in [Common.TileType.WOOD, Common.TileType.STONE, Common.TileType.GOLD] && !has_valuable_tile(tiles[i].position, adj_tile_type):
			update_valuable_tiles(tiles[i].position, adj_tile_type, true)
	return walkable_tiles

func calculate_destination(current_tile_position, next_tile_position):
	"""
		Calculates the destination position based on the difference between the current and next tile positions.
	"""
	var tile_dif = calculate_dif(Vector2i(current_tile_position), Vector2i(next_tile_position))
	return (Vector2i(position) + tile_dif * Common.TILE_SIZE)

func calculate_dif(vector1: Vector2i, vector2: Vector2i):
	"""
		Calculates the difference between two vectors.
	"""
	return vector2 - vector1

func is_one_step_away(current_tile_position, next_tile_position):
	"""
		Checks if the next tile position is one step away from the current tile position.
	"""
	var tile_dif = calculate_dif(Vector2i(current_tile_position), Vector2i(next_tile_position))
	return available_tile_steps.has(tile_dif)

func walk(delta):
	"""
		Handles the walking logic of the agent towards the destination position.
	"""
	position = position.move_toward(destination_pos, chromosome.speed * delta)
	if Vector2i(position.x, position.y) == destination_pos:
		current_state = State.DECIDING

func decide():
	"""
		Makes a decision on what action the agent should take based on its current state and goal.
	"""
	var current_tile_pos = tile_map.local_to_map(position)
	var tile_type = Common.get_tile_type(get_tile_type_str(current_tile_pos))
	
	if is_backtracking && astar_path_queue.is_empty():
		is_backtracking = false
		choose_search_algorithm()
	
	var goal_reached = tile_type == current_goal
	
	if current_search_algorithm == SearchAlgorithm.EXPLORE:
		if has_new_knowledge:
			has_new_knowledge = false
			knowledge_ver += 1
		visited.push_back(current_tile_pos)
	elif current_search_algorithm == SearchAlgorithm.ASTAR:
		goal_reached = goal_reached && astar_path_queue.is_empty()
	
	redefine_goal(goal_reached)
	
	if current_state != State.DECIDING: return
	
	match current_search_algorithm:
		SearchAlgorithm.EXPLORE: explore(current_tile_pos)
		SearchAlgorithm.ASTAR: use_astar(current_tile_pos)
	
	current_state = State.WALKING

func explore(current_tile_pos: Vector2i):
	"""
		Explores the environment by finding the next tile to move to and updating the AStar graph.
	"""
	var next_tile_pos = not_visited.pop_front()
	
	if next_tile_pos == null:
		change_goal(spawn_tile_type)
		return
	
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
		change_goal(spawn_tile_type)
		return
	
	if is_one_step_away(tile_map.local_to_map(position), next_tile_pos):
		destination_pos = calculate_destination(tile_map.local_to_map(position), next_tile_pos)
	else:
		is_backtracking = true
		choose_search_algorithm()
		use_astar(current_tile_pos)

func use_astar(current_tile_pos: Vector2i):
	"""
		Uses the A* algorithm to find the shortest path to the goal and updates the destination.
	"""
	var target_tile_id
	if astar_path_queue.is_empty():
		# Create the path queue
		
		var target_tile_availability
		if is_backtracking:
			target_tile_id = get_point_id(not_visited[0])
		else:
			target_tile_id = find_closest_tile_id(current_tile_pos, current_goal)
		
		astar_path_queue = astar.get_id_path(get_point_id(current_tile_pos), target_tile_id).slice(1)
		
		if astar_path_queue.is_empty():
			change_goal(spawn_tile_type)
			return
		
	# Calculate destination for the next tile
	destination_pos = calculate_destination(current_tile_pos, astar.get_point_position(astar_path_queue[0]))
	astar_path_queue.remove_at(0)

func get_point_id(vector: Vector2i):
	"""
		Returns a unique point ID for the specified position.
	"""
	return vector.x * Common.MAX_Y + vector.y

func redefine_goal(goal_reached: bool):
	"""
		Redefines the goal based on whether the current goal is reached and the agent's energy level.
	"""
	if !goal_reached: return
	
	if current_goal == Common.TileType.VILLAGE:
		
		# Drop any carrying resources
		if current_carrying_resource:
			game_manager.drop_resource(self)
		
		# Check if agent needs to refill
		if energy <= SPAWN_REFILL_ENERGY_THRESHOLD:
			current_state = State.REFILLING
			return
		
		game_manager.assign_resource_goal(self)
	else:
		if current_carrying_resource:
			change_goal(spawn_tile_type)
		else:
			choose_search_algorithm()

func change_goal(goal_type: Common.TileType):
	"""
		Changes the agent's goal to the specified goal.
	"""
	current_goal = goal_type
	choose_search_algorithm()

func choose_search_algorithm():
	"""
		Chooses the search algorithm based on the agent's state and goal.
	"""
	if current_goal == null:
		current_search_algorithm = SearchAlgorithm.NONE
		return
	
	if is_backtracking:
		current_search_algorithm = SearchAlgorithm.ASTAR
		return
	
	# Choose EXPLORE algorithm if the current_goal_type doesn't exist or all the tiles do not have available loot
	if !valuable_tile_point_ids.has(current_goal):
		current_search_algorithm = SearchAlgorithm.EXPLORE
		has_new_knowledge = true
		return
	
	if current_goal == spawn_tile_type:
		current_search_algorithm = SearchAlgorithm.ASTAR
		return
	
	var has_available_point = false
	for point in valuable_tile_point_ids[current_goal].keys():
		if valuable_tile_point_ids[current_goal][point] == true:
			has_available_point = true
			break
	
	current_search_algorithm = SearchAlgorithm.ASTAR if has_available_point else SearchAlgorithm.EXPLORE
	if current_search_algorithm == SearchAlgorithm.EXPLORE:
		has_new_knowledge = true

func get_tile_type_str(current_tile_pos: Vector2i):
	"""
		Returns the tile type string for the specified position.
	"""
	var tile_data = tile_map.get_cell_tile_data(1, current_tile_pos)
	if tile_data == null: tile_data = tile_map.get_cell_tile_data(0, current_tile_pos)
	return tile_data.get_custom_data("type")

func update_valuable_tiles(current_tile_pos: Vector2i, tile_type: Common.TileType, is_available: bool):
	"""
		Updates the list of valuable tiles based on the specified resource and whether to add or remove the tile.
	"""
	var current_tile_point_id = get_point_id(current_tile_pos)
	var tile = {
		current_tile_point_id: is_available
	}
	if !valuable_tile_point_ids.has(tile_type):
		valuable_tile_point_ids[tile_type] = tile
	else:
		valuable_tile_point_ids[tile_type].merge(tile, true)

func has_valuable_tile(tile_pos, tile_type: Common.TileType):
	"""
		Checks if the specified tile is a valuable tile for the given resource.
	"""
	var tile_type_s = Common.TileType.find_key(tile_type)
	if !valuable_tile_point_ids.has(tile_type_s): return false
	return valuable_tile_point_ids[tile_type_s].keys().has(get_point_id(tile_pos))

func _on_timer_timeout():
	"""
		Handles the timer timeout signal by reducing the agent's energy and updating the label.
	"""
	if !available_for_knowledge_exchange:
		available_for_knowledge_exchange = !available_for_knowledge_exchange
	if current_state == State.REFILLING:
		var new_energy = energy + chromosome.energy_gain_value
		energy = MAX_ENERGY_LEVEL if new_energy > MAX_ENERGY_LEVEL else new_energy
		if energy == MAX_ENERGY_LEVEL:
			current_state = State.DECIDING
	else:
		var new_energy := energy - chromosome.energy_loss_value
		energy = 0 if new_energy < 0 else new_energy
		if current_goal != spawn_tile_type && energy <= RETURN_TO_SPAWN_ENERGY_THRESHOLD:
			change_goal(spawn_tile_type)
	
	label.text = str(energy) + "% ID " + str(id)
	
	if energy <= 0: self.get_eliminated()

func find_closest_tile_id(current_tile_pos: Vector2i, tile_goal_type: Common.TileType):
	"""
		Returns the closest tile id based on AStar knowledge
		
		{
			"spawn": 1234,
			...,
			"stone": {
				2345: true,
				...,
				6789: false
			}
		}
		
	"""
	var saved_tiles = valuable_tile_point_ids[tile_goal_type]
	
	if saved_tiles == null:
		return null
	
	# If the goal tile type is spawn tile, return it. Spawn tile can only be one
	if tile_goal_type == spawn_tile_type:
		return valuable_tile_point_ids[tile_goal_type]
		
	# If only one resource of the given tile_type exists, return that as the closest
	var dict_keys = saved_tiles.keys()
	var first_key = dict_keys[0]
	if dict_keys.size() == 1:
		return first_key
	
	# Find the closest among all tiles
	var closest_tile_point
	var point_id
	var is_available
	var steps
	for i in range(valuable_tile_point_ids[tile_goal_type].size()):
		point_id = dict_keys[i]
		is_available = saved_tiles[point_id]
		# If the tile is not available then skip. Not available means there is no quantity left on that resource
		if !is_available: continue
		steps = astar.get_id_path(get_point_id(current_tile_pos), point_id).size()
		if closest_tile_point == null:
			closest_tile_point = {
				"id": point_id,
				"steps": steps
			}
		elif steps < closest_tile_point["steps"]:
			closest_tile_point["id"] = point_id
			closest_tile_point["steps"] = steps
	
	return closest_tile_point["id"]

func on_resource_interact(resource):
	if current_goal == resource.type && !current_carrying_resource:
		var carry_capacity = 0
		match resource.type:
			Common.TileType.WOOD: carry_capacity = chromosome.wood_carry_capacity
			Common.TileType.STONE: carry_capacity = chromosome.stone_carry_capacity
			Common.TileType.GOLD: carry_capacity = chromosome.gold_carry_capacity
		
		var loot_quantity = resource.loot(carry_capacity)
		var current_tile_pos = tile_map.local_to_map(position)
		
		if resource.current_quantity == 0:
			update_valuable_tiles(current_tile_pos, resource.type, false)
		
		if loot_quantity > 0:	
			current_carrying_resource = CarryingResource.new(resource.type, loot_quantity)

func _on_body_entered(body):
	if body == self: return
	
	# No one can interact at spawn
	var current_tile_pos = tile_map.local_to_map(position)
	if current_tile_pos == Vector2i(astar.get_point_position(valuable_tile_point_ids[spawn_tile_type])):
		return
	
	var available_for_reproduction = false
	if not available_for_knowledge_exchange and not available_for_reproduction:
		return
	
	var other_agent_id = body.id
	if not (agent_knowledge_vers.has(other_agent_id) && agent_knowledge_vers[other_agent_id] == body.knowledge_ver):
		game_manager.merge_knowledge(self, body)
	
	game_manager.reproduce(self, body, self.wants_to_reproduce(body))

func wants_to_reproduce(other_agent: Agent):
	var counter = 0
	
	if other_agent.chromosome.energy_loss_value < chromosome.energy_loss_value:
		counter += 1
	
	if other_agent.chromosome.energy_gain_value > chromosome.energy_gain_value:
		counter += 1
	
	if other_agent.chromosome.speed > chromosome.speed:
		counter += 1
	
	if (village.target_wood_quantity - village.current_wood_quantity) > 0 && other_agent.chromosome.wood_carry_capacity > chromosome.wood_carry_capacity:
		counter += 1
	
	if (village.target_stone_quantity - village.current_stone_quantity) > 0 && other_agent.chromosome.stone_carry_capacity > chromosome.stone_carry_capacity:
		counter += 1
	
	if (village.target_gold_quantity - village.current_gold_quantity) > 0 && other_agent.chromosome.gold_carry_capacity > chromosome.gold_carry_capacity:
		counter += 1
	
	return counter > 0

func get_eliminated():
	timer.timeout.disconnect(_on_timer_timeout)
	set_physics_process(false)
	collision_shape_2d.disabled = true
	area_2d.monitoring = false
	
	current_state = State.ELIMINATED
	
	if chromosome.bits[0] == "0":
		agent_1.visible = false
	else:
		agent_2.visible = false
	grave.visible = true
	
	game_manager.eliminate(self)
