extends TileMap


@onready var tile_map := $"."
@onready var button_exit = $"../ButtonExit"


''' Random number generator '''
var rng := RandomNumberGenerator.new()

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
static var agents: int # number of agents
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
	# Set a random seed for the RandomNumberGenerator
	randomize()
	
	# Center the tile_map
	var viewport_size: Vector2 = get_viewport_rect().size
	tile_map.set_position(Vector2(
		viewport_size.x / 2 - (cols * 64) / 2,
		viewport_size.y / 2 - (rows * 64) / 2))
	
	# Arrays initialization
	var map : Array
	var available_rows: Array
	var obstacles_per_row: Array
	var obstacles_per_col: Array
	
	for y in rows:
		if y >= 1 and y <= rows-2: # first and last row are boundaries
			available_rows.append(y)
			obstacles_per_row.append(cols-2) # cols-2 because first and last column are boundaries
		map.append([])
		for x in range(1, cols-1):
			obstacles_per_col.append(rows-2) # rows-2 because first and last row are boundaries
			map[y].append(x)
	
	# Tiles placement into the map
	tiles_placement_into_the_map(map, available_rows, obstacles_per_row, obstacles_per_col)

func tiles_placement_into_the_map(
	map: Array, available_rows: Array,
	obstacles_per_row: Array, obstacles_per_col: Array
) -> void:
	"""
		
	"""
	add_foreground_tile(map, available_rows, village_1_tile_coords,
						obstacles_per_row, obstacles_per_col) # village 1 placement
	add_foreground_tile(map, available_rows, village_2_tile_coords,
						obstacles_per_row, obstacles_per_col) # village 2 placement
	
	for y in rows:
		for x in cols:
			add_background_tile(x, y) # background tile placement
			
			if stone > 0: # stone placement
				add_foreground_tile(map, available_rows, stone_tile_coords,
									obstacles_per_row, obstacles_per_col)
				stone -= 1
			if gold > 0: # gold placement
				add_foreground_tile(map, available_rows, gold_tile_coords,
									obstacles_per_row, obstacles_per_col)
				gold -= 1
			if wood > 0: # wood placement
				add_foreground_tile(map, available_rows, wood_tile_coords,
									obstacles_per_row, obstacles_per_col)
				wood -= 1
			if agents > 0: # agents placement
				# Todo: Agents placement
				agents -= 1
			if obstacles > 0: # obstacles placement
				add_obstacle_tile(map, available_rows, obstacles_per_row, obstacles_per_col)
				obstacles -= 1

func find_foreground_tile_coords(
	map: Array, available_rows: Array, obstacles_per_row: Array, obstacles_per_col: Array
) -> Dictionary:
	"""
		- This function randomly adds a foreground tile into the map.
		- It chooses a random row from available_rows and then a random position
		  within that row from map.
		- ...
		- If the chosen row becomes empty after removing the selected position,
		  it's also removed from available_rows.
		- ...
		- Returns a dictionary containing the x and y coordinates.
	"""
	var idx_of_y: int = rng.randi_range(0, len(available_rows)-1)
	var y: int = available_rows[idx_of_y]
	obstacles_per_row[idx_of_y] -= 1
	
	var idx_of_x: int = rng.randi_range(0, len(map[y])-1)
	var x: int = map[y].pop_at(idx_of_x)
	obstacles_per_col[idx_of_x] -= 1
	
	if len(map[y]) == 0:
		available_rows.pop_at(idx_of_y)
	
	return {'x': x, 'y': y, 'idx_of_x': idx_of_x, 'idx_of_y': idx_of_y}

func add_foreground_tile(
	map: Array, available_rows: Array,	tile_coords: Dictionary,
	obstacles_per_row: Array, obstacles_per_col: Array
) -> void:
	"""
		
	"""
	var coords := find_foreground_tile_coords(map, available_rows, obstacles_per_row, obstacles_per_col)
	set_cell(1, Vector2i(coords.x, coords.y), 0, Vector2i(tile_coords.x, tile_coords.y))

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

func add_obstacle_tile(
	map: Array, available_rows: Array, obstacles_per_row: Array, obstacles_per_col: Array
) -> void:
	"""
		
	"""
	var coords: Dictionary
	
	while true:
		coords = find_foreground_tile_coords(map, available_rows, obstacles_per_row, obstacles_per_col)
		
		# Check if obstacle can be placed in the specific coords
		if obstacles_per_row[coords.idx_of_y] > 0 and obstacles_per_col[coords.idx_of_x] > 0:
			if (len(map[coords.y]) == 0):
				obstacles_per_row.pop_at(coords.idx_of_y)
			break
		
		# Rollback the steps executed in find_foreground_tile_coords
		# because if obstacle be placed at coords (x,y), the map will
		# be splitted in two sections.
		if len(map[coords.y]) == 0:
			available_rows.append(coords.y)
		map[coords.y].append(coords.x)
	
	set_cell(1, Vector2i(coords.x, coords.y), 0,
			 Vector2i(obstacle_tile_coords.x, obstacle_tile_coords.y))
