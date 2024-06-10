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
		speed = 300 if bits[3] == "0" else 350
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

var available_for_knowledge_exchange := true

var chromosome: Chromosome
@export var bits: String
var village: Village

var knowledge_ver := 1
var agent_knowledge_vers := {}
var has_new_knowledge := true

# TODO: Remove
#var timer: Timer
@onready var timer = %Timer

#var game_manager: GameManager
@onready var game_manager = %GameManager

#var tile_map: TileMap
@onready var tile_map = %TileMap

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

enum State { WALKING, DECIDING, REFILLING, IDLE }
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
	
	# TODO: Remove
	chromosome = Chromosome.new(bits)
	village = game_manager.get_village(self)
	village.set_target_resource_quantity({'wood': 10, 'stone': 30, 'gold': 5})
	
	var current_tile_pos = tile_map.local_to_map(position)
	spawn_tile_type = Common.get_tile_type(get_tile_type_str(current_tile_pos))
	valuable_tile_point_ids[spawn_tile_type] = get_point_id(current_tile_pos)
	
	label.text = str(energy) + "%"
	
	# Connect timer signal
	timer.timeout.connect(_on_timer_timeout)
	
	# Initialize AStar
	astar = AStar2D.new()
	
	current_goal = Common.TileType.STONE
	
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
	var tile_dif = calculate_dif(Vector2i(current_tile_position), Vector2i(next_tile_position))
	return (Vector2i(position) + tile_dif * Common.TILE_SIZE)

func calculate_dif(vector1: Vector2i, vector2: Vector2i):
	return vector2 - vector1

func is_one_step_away(current_tile_position, next_tile_position):
	var tile_dif = calculate_dif(Vector2i(current_tile_position), Vector2i(next_tile_position))
	return available_tile_steps.has(tile_dif)

func walk(delta):
	position = position.move_toward(destination_pos, chromosome.speed * delta)
	if Vector2i(position.x, position.y) == destination_pos:
		current_state = State.DECIDING

func decide():
	var current_tile_pos = tile_map.local_to_map(position)
	var tile_type = Common.get_tile_type(get_tile_type_str(current_tile_pos))
	
	if is_backtracking && astar_path_queue.is_empty():
		is_backtracking = false
		choose_search_algorithm()
	
	var goal_reached = tile_type == current_goal
	
	if current_search_algorithm == SearchAlgorithm.EXPLORE:
		if has_new_knowledge:
			has_new_knowledge = false
			knowledge_ver
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
		# TODO: Save important tiles to valuable_tiles
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
		# TODO: Change goal based on team goals
		return
	
	if is_one_step_away(tile_map.local_to_map(position), next_tile_pos):
		destination_pos = calculate_destination(tile_map.local_to_map(position), next_tile_pos)
	else:
		is_backtracking = true
		choose_search_algorithm()
		use_astar(current_tile_pos)

func use_astar(current_tile_pos: Vector2i):
	var target_tile_id
	if astar_path_queue.is_empty():
		# Create the path queue
		
		var target_tile_availability
		if is_backtracking:
			target_tile_id = get_point_id(not_visited[0])
		else:
			target_tile_id = find_closest_tile_id(current_tile_pos, current_goal)
		
		astar_path_queue = astar.get_id_path(get_point_id(current_tile_pos), target_tile_id).slice(1)
	 
	# Calculate destination for the next tile
	destination_pos = calculate_destination(current_tile_pos, astar.get_point_position(astar_path_queue[0]))
	astar_path_queue.remove_at(0)

func get_point_id(vector: Vector2i):
	return vector.x * Common.MAX_Y + vector.y

func redefine_goal(goal_reached: bool):
	if !goal_reached: return
	
	# If the agent is at spawn, blah
	if current_goal == Common.TileType.VILLAGE:
		
		# Drop any carrying resources
		if current_carrying_resource:
			print("Drop resource: " + str(current_carrying_resource.quantity) + " " + str(current_carrying_resource.type))
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
	current_goal = goal_type
	choose_search_algorithm()

func choose_search_algorithm():
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
	var tile_data = tile_map.get_cell_tile_data(1, current_tile_pos)
	if tile_data == null: tile_data = tile_map.get_cell_tile_data(0, current_tile_pos)
	return tile_data.get_custom_data("type")

func update_valuable_tiles(current_tile_pos: Vector2i, tile_type: Common.TileType, is_available: bool):
	var current_tile_point_id = get_point_id(current_tile_pos)
	var tile = {
		current_tile_point_id: is_available
	}
	if !valuable_tile_point_ids.has(tile_type):
		valuable_tile_point_ids[tile_type] = tile
	else:
		valuable_tile_point_ids[tile_type].merge(tile, true)

func has_valuable_tile(tile_pos, tile_type: Common.TileType):
	var tile_type_s = Common.TileType.find_key(tile_type)
	if !valuable_tile_point_ids.has(tile_type_s): return false
	return valuable_tile_point_ids[tile_type_s].keys().has(get_point_id(tile_pos))

func _on_timer_timeout():
	#print("ID " + str(id) + " AStar: " + str(astar.get_point_ids()))
	#print("ID " + str(id) + " valuable_tile_point_ids: " + str(valuable_tile_point_ids))
	if !available_for_knowledge_exchange:
		available_for_knowledge_exchange = !available_for_knowledge_exchange
	if current_state == State.REFILLING:
		var new_energy = energy + chromosome.energy_gain_value
		energy = MAX_ENERGY_LEVEL if new_energy > MAX_ENERGY_LEVEL else new_energy
		if energy == MAX_ENERGY_LEVEL:
			current_state = State.DECIDING
	else:
		energy -= chromosome.energy_loss_value
		if current_goal != spawn_tile_type && energy <= RETURN_TO_SPAWN_ENERGY_THRESHOLD:
			change_goal(spawn_tile_type)
	
	label.text = str(energy) + "% ID " + str(id)
	
	if energy <= 0:
		queue_free()

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
	
	var available_for_fertilization = false
	if not available_for_knowledge_exchange and not available_for_fertilization:
		return
	
	var other_agent_id = body.id
	if not (agent_knowledge_vers.has(other_agent_id) && agent_knowledge_vers[other_agent_id] == body.knowledge_ver):
		game_manager.merge_knowledge(self, body)
		
	var want_to_fertilize = true
	if want_to_fertilize:
		pass
