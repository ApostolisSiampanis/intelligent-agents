extends TileMap


var rng: RandomNumberGenerator = RandomNumberGenerator.new() # random number generator


# Tiles coordinates based on medieval_tilesheet (TileSet)
const village_1_tile_coords: Dictionary = {'x': 5, 'y': 6}
const village_2_tile_coords: Dictionary = {'x': 7, 'y': 6}

const villager_1_tile_coords: Dictionary =  {'x': 12, 'y': 5}
const villager_2_tile_coords: Dictionary =  {'x': 12, 'y': 4}

const stone_tile_coords: Dictionary = {'x': 7, 'y': 4}
const gold_tile_coords: Dictionary = {'x': 9, 'y': 5}
const wood_tile_coords: Dictionary = {'x': 1, 'y': 4}

const vertical_boundary_tile_coords: Dictionary = {'x': 4, 'y': 0}
const horizontal_boundary_tile_coords: Dictionary = {'x': 5, 'y': 0}
const top_left_corner_boundary_tile_coords: Dictionary = {'x': 4, 'y': 1}
const top_right_corner_boundary_tile_coords: Dictionary = {'x': 5, 'y': 1}
const bottom_left_corner_boundary_tile_coords: Dictionary = {'x': 4, 'y': 2}
const bottom_right_corner_boundary_tile_coords: Dictionary = {'x': 5, 'y': 2}


func _ready():
	randomize() # set a random seed for the RandomNumberGenerator
	
	# Input fields
	const N: int = 15 # rows
	const M: int = 29 # columns
	var stone: int = 5 # number of gold resources
	var wood: int = 6 # number of wood resources 
	var gold: int = 3 # number of gold resources
	var K: int = 4 # number of agents for each village
	
	# Initialize a 2D array representing the map
	var map: Array = []
	var available_rows: Array = range(1, N-1)
	for y in N:
		map.append([])
		for x in range(1, M-1):
			map[y].append(x)
	
	# Tiles placement into the map
	add_tile_into_the_map(1, map, available_rows, village_1_tile_coords)
	add_tile_into_the_map(1, map, available_rows, village_2_tile_coords)
	
	for y in N:
		for x in M:
			set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0)) # grass placement
			add_boundary_in_the_map(x, y, N, M) # boundary placement
			if stone > 0: # stone placement
				add_tile_into_the_map(1, map, available_rows, stone_tile_coords)
				stone -= 1
			if gold > 0: # gold placement
				add_tile_into_the_map(1, map, available_rows, gold_tile_coords)
				gold -= 1
			if wood > 0: # wood placement
				add_tile_into_the_map(1, map, available_rows, wood_tile_coords)
				wood -= 1
			if K > 0: # agents placement
				# Todo: Agents placement
				K -= 1 

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

func add_boundary_in_the_map(x: int, y: int, N: int, M: int):
	"""
		This function adds a boundary to the map.
	"""
	if x == 0 and y == 0: # top-left corner
		set_cell(1, Vector2i(x, y),
					0, Vector2i(top_left_corner_boundary_tile_coords.x,
								top_left_corner_boundary_tile_coords.y))
	elif x == M-1 and y == 0: # top-right corner
		set_cell(1, Vector2i(x, y),
					0, Vector2i(top_right_corner_boundary_tile_coords.x,
								top_right_corner_boundary_tile_coords.y))
	elif x == 0 and y == N-1: # bottom-left corner
		set_cell(1, Vector2i(x, y),
					0, Vector2i(bottom_left_corner_boundary_tile_coords.x,
								bottom_left_corner_boundary_tile_coords.y))
	elif x == M-1 and y == N-1: # bottom-right corner
		set_cell(1, Vector2i(x, y),
					0, Vector2i(bottom_right_corner_boundary_tile_coords.x,
								bottom_right_corner_boundary_tile_coords.y))
	elif x == 0 or x == M-1: # first/last column
		set_cell(1, Vector2i(x, y),
					0, Vector2i(vertical_boundary_tile_coords.x,
								vertical_boundary_tile_coords.y))
	elif y == 0 or y == N-1: # first/last row
		set_cell(1, Vector2i(x, y),
					0, Vector2i(horizontal_boundary_tile_coords.x,
								horizontal_boundary_tile_coords.y))
