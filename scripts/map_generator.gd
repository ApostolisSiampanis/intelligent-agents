extends TileMap


var rng: RandomNumberGenerator = RandomNumberGenerator.new() # random number generator
# Tiles coordinates based on medieval_tilesheet (TileSet)
const village_1_tile_coords: Dictionary = {'x': 5, 'y': 6}
const village_2_tile_coords: Dictionary = {'x': 7, 'y': 6}

const stone_tile_coords: Dictionary = {'x': 7, 'y': 4}
const gold_tile_coords: Dictionary = {'x': 9, 'y': 5}
const wood_tile_coords: Dictionary = {'x': 1, 'y': 4}

const vertical_boundary_tile_coords: Dictionary = {'x': 4, 'y': 0}
const horizontal_boundary_tile_coords: Dictionary = {'x': 5, 'y': 0}
const top_left_corner_boundary_tile_coords: Dictionary = {'x': 4, 'y': 1}
const top_right_corner_boundary_tile_coords: Dictionary = {'x': 5, 'y': 1}
const bottom_left_corner_boundary_tile_coords: Dictionary = {'x': 4, 'y': 2}
const bottom_right_corner_boundary_tile_coords: Dictionary = {'x': 5, 'y': 2}

# Input fields
static var rows: int; # rows
static var cols: int; # columns
static var stone: int; # number of gold resources
static var wood: int; # number of wood resources 
static var gold: int; # number of gold resources
static var agents: int; # number of agents for each village

static func set_input_arguments(
	rows_arg: int, cols_arg: int, stone_arg: int,
	wood_arg: int, gold_arg: int, agents_arg: int
):
	rows = rows_arg
	cols = cols_arg
	stone = stone_arg
	wood = wood_arg
	gold = gold_arg
	agents = agents_arg


func _ready():
	randomize() # set a random seed for the RandomNumberGenerator
	
	# Initialize a 2D array representing the map
	var map: Array = []
	var available_rows: Array = range(1, rows-1)
	for y in rows:
		map.append([])
		for x in range(1, cols-1):
			map[y].append(x)
	
	# Tiles placement into the map
	add_tile_into_the_map(1, map, available_rows, village_1_tile_coords)
	add_tile_into_the_map(1, map, available_rows, village_2_tile_coords)
	
	for y in rows:
		for x in cols:
			set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0)) # grass placement
			add_boundary_in_the_map(x, y) # boundary placement
			if stone > 0: # stone placement
				add_tile_into_the_map(1, map, available_rows, stone_tile_coords)
				stone -= 1
			if gold > 0: # gold placement
				add_tile_into_the_map(1, map, available_rows, gold_tile_coords)
				gold -= 1
			if wood > 0: # wood placement
				add_tile_into_the_map(1, map, available_rows, wood_tile_coords)
				wood -= 1
			if agents > 0: # agents placement
				# Todo: Agents placement
				agents -= 1 

func add_tile_into_the_map(layer: int, map: Array, available_rows: Array,
				tile_coords: Dictionary):
	"""
		This function randomly adds a given tile into the map.
	"""
	var index_of_y: int = rng.randi_range(0, len(available_rows)-1)
	var y: int = available_rows[index_of_y]
	var x: int = map[y].pop_at(rng.randi_range(0, len(map[y])-1))
	
	if len(map[y]) == 0:
		available_rows.pop_at(index_of_y)

	set_cell(1, Vector2i(x, y), 0, Vector2i(tile_coords.x, tile_coords.y))

func add_boundary_in_the_map(x: int, y: int):
	"""
		This function adds a boundary to the map.
	"""
	if x == 0 and y == 0: # top-left corner
		set_cell(1, Vector2i(x, y),
					0, Vector2i(top_left_corner_boundary_tile_coords.x,
								top_left_corner_boundary_tile_coords.y))
	elif x == cols-1 and y == 0: # top-right corner
		set_cell(1, Vector2i(x, y),
					0, Vector2i(top_right_corner_boundary_tile_coords.x,
								top_right_corner_boundary_tile_coords.y))
	elif x == 0 and y == rows-1: # bottom-left corner
		set_cell(1, Vector2i(x, y),
					0, Vector2i(bottom_left_corner_boundary_tile_coords.x,
								bottom_left_corner_boundary_tile_coords.y))
	elif x == cols-1 and y == rows-1: # bottom-right corner
		set_cell(1, Vector2i(x, y),
					0, Vector2i(bottom_right_corner_boundary_tile_coords.x,
								bottom_right_corner_boundary_tile_coords.y))
	elif x == 0 or x == cols-1: # first/last column
		set_cell(1, Vector2i(x, y),
					0, Vector2i(vertical_boundary_tile_coords.x,
								vertical_boundary_tile_coords.y))
	elif y == 0 or y == rows-1: # first/last row
		set_cell(1, Vector2i(x, y),
					0, Vector2i(horizontal_boundary_tile_coords.x,
								horizontal_boundary_tile_coords.y))
