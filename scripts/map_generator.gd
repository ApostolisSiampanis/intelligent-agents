extends TileMap


@onready var timer = %Timer


const AGENT = preload("res://scenes/agent.tscn")
const RESOURCE_COLLIDER = preload("res://scenes/resource_collider.tscn")

const TILE_SIZE := Vector2i(64,64)
const MAX_Y := 100

var agents_array := [] # stores all created agent instances


''' Tiles coordinates based on medieval_tilesheet (TileSet) '''
const village_1_tile_coords := {'x': 5, 'y': 6}
const village_2_tile_coords := {'x': 7, 'y': 6}

const stone_tile_coords := {'x': 7, 'y': 4}
const gold_tile_coords := {'x': 9, 'y': 5}
const wood_tile_coords := {'x': 1, 'y': 4}

const grass_tile_coords := {'x': 0, 'y': 0}
const obstacle_tile_coords := {'x': 3, 'y': 1}


''' Input fields '''
static var rows: int # rows
static var cols: int # columns
static var stone: int # number of gold resources
static var wood: int # number of wood resources 
static var gold: int # number of gold resources
static var agents: int # number of agents per village
static var obstacles: int  # number of obstacles


''' Functions '''
static func set_input_arguments(
	rows_arg: int, cols_arg: int, stone_arg: int,
	wood_arg: int, gold_arg: int, agents_arg: int
) -> void:
	"""
		- This static method sets the values of static variables
		  rows, cols, stone, wood, gold, and agents based on user input.
		- Calculates the number of obstacles based on rows and cols.
	"""
	rows = rows_arg
	cols = cols_arg
	stone = stone_arg
	wood = wood_arg
	gold = gold_arg
	agents = agents_arg
	obstacles = ceili(rows * cols * 0.2)

func _ready():
	# Center the tile map
	var viewport_size: Vector2 = get_viewport_rect().size
	self.set_position(Vector2(
		viewport_size.x / 2 - (float(cols) * 64) / 2,
		viewport_size.y / 2 - (float(rows) * 64) / 2))
	
	# Arrays initialization
	var map: Array
	var available_rows: Array
	
	for y in rows:
		if y >= 1 and y <= rows-2: # first and last row are boundaries
			available_rows.append(y)
		map.append([])
		for x in range(1, cols-1):
			map[y].append(x)
	
	# Map generation
	generate_map(map, available_rows)

	# Place agents into the tile map to start exploring
	for agent in agents_array:
		add_child(agent)

func generate_map(map: Array, available_rows: Array) -> void:
	"""
		This function generates a map populated with villages, resources, obstacles, and agents.
	"""
	var village_1_coords := add_foreground_tile(map, available_rows, village_1_tile_coords) # village_1 tile placement
	var village_2_coords := add_foreground_tile(map, available_rows, village_2_tile_coords) # village_2 tile placement
	var resource_coords: Dictionary
	
	for y in rows:
		for x in cols:
			add_background_tile(x, y) # background tile placement
			
			if stone > 0: # stone tile placement
				resource_coords = add_foreground_tile(map, available_rows, stone_tile_coords)
				add_collider_for_resource(resource_coords, stone + ((y+1) * (x+1)), "stone")
				stone -= 1
			if gold > 0: # gold tile placement
				resource_coords = add_foreground_tile(map, available_rows, gold_tile_coords)
				add_collider_for_resource(resource_coords, gold + ((y+1) * (x+1)), "gold")
				gold -= 1
			if wood > 0: # wood tile placement
				resource_coords = add_foreground_tile(map, available_rows, wood_tile_coords)
				add_collider_for_resource(resource_coords, wood + ((y+1) * (x+1)), "wood")
				wood -= 1
			if agents > 0: # in each iteration create one agent for each village
				agents_array.append(create_agent(AGENT.instantiate(), 0, village_1_coords)) # agent for village 1
				agents_array.append(create_agent(AGENT.instantiate(), 1, village_2_coords)) # agent for village 2
				agents -= 1
			if obstacles > 0: # obstacles tile placement
				add_foreground_tile(map, available_rows, obstacle_tile_coords)
				obstacles -= 1

func add_foreground_tile(map: Array, available_rows: Array,	tile_coords: Dictionary) -> Dictionary:
	"""
		- This function randomly adds a foreground tile into the map.
		- It chooses a random row from available_rows and then a random position
		  within that row from map.
		- If the chosen row becomes empty after removing the selected position,
		  it's also removed from available_rows.
		- Returns a dictionary containing the placed tile's x and y coordinates in the map.
	"""
	var idx_of_y: int = randi_range(0, len(available_rows)-1)
	var y: int = available_rows[idx_of_y]
	
	var idx_of_x: int = randi_range(0, len(map[y])-1)
	var x: int = map[y].pop_at(idx_of_x)
	
	if len(map[y]) == 0:
		available_rows.pop_at(idx_of_y)
	
	set_cell(1, Vector2i(x, y), 0, Vector2i(tile_coords.x, tile_coords.y))
	
	return {'x': x, 'y': y}

func add_background_tile(x: int, y: int) -> void:
	"""
		This function adds the appropriate background tile (obstacle or grass)
		into the map, based on current x,y values.
	"""
	# If current (x,y) is a boundary, add obstacle tile
	if x == 0 or x == cols-1 or y == 0 or y == rows-1:
		set_cell(0, Vector2i(x, y),
				 0, Vector2i(obstacle_tile_coords.x, obstacle_tile_coords.y))
	
	# else add grass tile.
	else:
		set_cell(0, Vector2i(x, y),
				 0, Vector2i(grass_tile_coords.x, grass_tile_coords.y))

func add_collider_for_resource(resource_coords: Dictionary, quantity: int, type: String) -> void:
	"""
		Adds a collider for a resource at the specified coordinates with quantity and type.
	"""
	var resource_collider := RESOURCE_COLLIDER.instantiate()
	var coords := map_to_local(Vector2i(resource_coords.x, resource_coords.y))
	resource_collider.position = coords
	resource_collider.set_total_quantity(quantity)
	resource_collider.type = type
	resource_collider.z_index = 3
	add_child(resource_collider)

func create_agent(agent: Node, agent_idx: int, village_coords: Dictionary) -> Node:
	"""
		Initializes and positions an agent at the village with a reference to the tile map and timer.
	"""
	agent.position = map_to_local(Vector2(village_coords.x, village_coords.y))
	agent.tile_map = self
	agent.get_child(agent_idx).visible = true
	agent.timer = timer
	agent.z_index = 4
	return agent


class TileInfo:	
	var type = ""
	var position = Vector2i.ZERO

func get_adjacent_tiles(current_tile, available_tile_steps):
	var adjacent_tiles = []
	
	for step in available_tile_steps:
		var new_pos = current_tile + step
		
		var adj_tile_data = get_cell_tile_data(1, new_pos)
		
		if adj_tile_data == null:
			adj_tile_data = get_cell_tile_data(0, new_pos)
		
		if adj_tile_data == null:
			continue
		
		var tile_info = TileInfo.new()
		tile_info.position = new_pos
		tile_info.type = adj_tile_data.get_custom_data("type")
		
		adjacent_tiles.append(tile_info)
	
	return adjacent_tiles
