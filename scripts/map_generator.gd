extends TileMap


class_name MapGenerator


@onready var v_box_container_village_1_info_cards = %VBoxContainerVillage1InfoCards
@onready var v_box_container_village_2_info_cards = %VBoxContainerVillage2InfoCards

@onready var timer = %Timer
@onready var game_manager = %GameManager
@onready var camera_2d = $"../Camera2D"

var agents_array := [] # stores all created agent instances

const INFO_CARD = preload("res://scenes/info_card.tscn")
const AGENT = preload("res://scenes/agent.tscn")
const RESOURCE_COLLIDER = preload("res://scenes/resource_collider.tscn")


''' Tiles coordinates based on medieval_tilesheet (TileSet) '''
const village_1_tile_coords := {'x': 5, 'y': 6}
const village_2_tile_coords := {'x': 7, 'y': 6}
const stone_tile_coords := {'x': 7, 'y': 4}
const gold_tile_coords := {'x': 9, 'y': 5}
const wood_tile_coords := {'x': 7, 'y': 3}
const grass_tile_coords := {'x': 0, 'y': 0}
const obstacle_tile_coords := {'x': 3, 'y': 1}
const highlight_tile_coords := {'x': 4, 'y': 5}


''' Input fields '''
static var rows: int # rows
static var cols: int # columns
static var stone: int # number of gold resources
static var wood: int # number of wood resources 
static var gold: int # number of gold resources
static var agents: int # number of agents per village
static var obstacles: int  # number of obstacles
static var resource_quantity_per_source: Dictionary # resource quantity per source


''' Functions '''
static func set_input_arguments(
	rows_arg: int, cols_arg: int, stone_arg: int,
	wood_arg: int, gold_arg: int, agents_arg: int,
	resource_quantity_per_source_arg: Dictionary
) -> void:
	"""
		- This static method sets the values of static variables rows, cols, stone,
		  wood, gold, agents and resource_quantity_per_source based on user input.
		- Calculates the number of obstacles based on rows and cols.
	"""
	rows = rows_arg
	cols = cols_arg
	stone = stone_arg
	wood = wood_arg
	gold = gold_arg
	agents = agents_arg
	resource_quantity_per_source = resource_quantity_per_source_arg
	obstacles = ceili(rows * cols * 0.2)

func _ready():
	# Center the tile map
	var viewport_size: Vector2 = get_viewport_rect().size
	camera_2d.center_on_tile_map()
	
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
	
	v_box_container_village_1_info_cards.set("custom_constants/separation", 10)
	v_box_container_village_2_info_cards.set("custom_constants/separation", 10)

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
			
			if wood > 0: # wood tile placement
				resource_coords = add_foreground_tile(map, available_rows, wood_tile_coords)
				add_collider_for_resource(resource_coords, resource_quantity_per_source.wood, "wood")
				wood -= 1
			if stone > 0: # stone tile placement
				resource_coords = add_foreground_tile(map, available_rows, stone_tile_coords)
				add_collider_for_resource(resource_coords, resource_quantity_per_source.stone, "stone")
				stone -= 1
			if gold > 0: # gold tile placement
				resource_coords = add_foreground_tile(map, available_rows, gold_tile_coords)
				add_collider_for_resource(resource_coords, resource_quantity_per_source.gold, "gold")
				gold -= 1
			if agents > 0: # in each iteration create one agent for each village
				var agent_1 := create_agent(AGENT.instantiate(), 0, village_1_coords, agents*2-1) # agent for village 1
				var agent_2 := create_agent(AGENT.instantiate(), 1, village_2_coords, agents*2) # agent for village 2
				agents_array.append_array([agent_1, agent_2])
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

func add_collider_for_resource(resource_coords: Dictionary, quantity: int, type_str: String) -> void:
	"""
		Adds a collider for a resource at the specified coordinates with quantity and type.
	"""
	var resource_collider := RESOURCE_COLLIDER.instantiate()
	var coords := map_to_local(Vector2i(resource_coords.x, resource_coords.y))
	resource_collider.position = coords
	resource_collider.set_total_quantity(quantity)
	resource_collider.type = Common.get_tile_type(type_str)
	resource_collider.z_index = 3
	add_child(resource_collider)

func create_agent(agent: Agent, agent_idx: int, village_coords: Dictionary, agent_id: int) -> Agent:
	"""
		Initializes and positions an agent at the village with a reference to the tile map and timer.
	"""
	agent.id = agent_id
	agent.position = map_to_local(Vector2(village_coords.x, village_coords.y))
	agent.tile_map = self
	agent.get_child(agent_idx).visible = true
	agent.timer = timer
	agent.game_manager = game_manager
	agent.z_index = 4

	var chromosome := generate_random_chromosome(str(agent_idx)) # agent_idx can be used too for village bit
	agent.chromosome = agent.Chromosome.new(chromosome)
	
	# Create an InfoCard for the agent
	var info_card = INFO_CARD.instantiate()
	
	info_card.agent = agent
	info_card.connect("highlight_agent", Callable(self, "_on_highlight_agent"))
	info_card.connect("highlight_map", Callable(self, "_on_highlight_map"))
	
	timer.connect("timeout", Callable(info_card, "_on_timer_timeout"))
	timer.connect("timeout", Callable(self, "_update_remaining_resources"))
	
	# Wrap the info_card in a MarginContainer
	var margin_container = MarginContainer.new()
	margin_container.add_child(info_card)
	
	# Add spacing (adjust the values to your preference)
	margin_container.add_theme_constant_override("margin_bottom", 205)
	
	# Add the margin container to the VBoxContainer
	if agent_idx == 0:
		v_box_container_village_1_info_cards.add_child(margin_container)
	else:
		v_box_container_village_2_info_cards.add_child(margin_container)

	return agent

func generate_random_chromosome(village_bit: String) -> String:
	"""
		- This function generates a random chromosome string starting with a given village bit.
		- It appends random bits for various traits: energy consumption (1 bit), energy production (1 bit),
		  speed (1 bit), wood carrying capacity (2 bits), stone carrying capacity (2 bits), and gold
		  carrying capacity (1 bit).
		- Returns the complete chromosome string.
	"""
	var one_bit := ["0", "1"]
	var two_bits := ["00", "01", "10", "11"]
	
	# Initialize chromosome with the village bit
	var chromosome := village_bit
	
	# Energy Consumption (1 bit)
	chromosome += one_bit.pick_random()
	
	# Energy Production (1 bit)
	chromosome += one_bit.pick_random()
	
	# Speed (1 bit)
	chromosome += one_bit.pick_random()
	
	# Wood Carrying Capacity (2 bits)
	chromosome += two_bits.pick_random()
	
	# Stone Carrying Capacity (2 bits)
	chromosome += two_bits.pick_random()
	
	#  Gold Carrying Capacity (1 bit)
	chromosome += one_bit.pick_random()
	
	return chromosome

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

func _on_highlight_agent(agent, highlight):
	# Clear previous highlight
	for other_agent in agents_array:
		other_agent.modulate = Color.WHITE
	
	if highlight:
		agent.modulate = Color.FIREBRICK  # or another suitable color
		camera_2d.follow_agent(agent)
	else:
		camera_2d.stop_following_agent()

func _on_highlight_map(agent, mode):
	match mode:
		"known":
			highlight_known_tiles(agent)
		"all":
			clear_tile_highlights()

func highlight_known_tiles(agent):
	clear_tile_highlights()

	# Get the points the agent knows about
	var known_points :Array = agent.astar.get_point_ids()
	for point_id in known_points:
		var tile_coords :Vector2 = agent.astar.get_point_position(point_id)
		if get_cell_tile_data(2, tile_coords) == null:  
			set_cell(2, tile_coords, 0, Vector2i(highlight_tile_coords.x, highlight_tile_coords.y)) 
	set_layer_enabled(2, true)

func clear_tile_highlights():
	for y in rows:
		for x in cols:
			var cell := get_cell_source_id(2, Vector2i(x, y))
			if cell != null:
				set_cell(2, Vector2i(x, y), -1)
