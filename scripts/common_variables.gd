extends Node

static var TILE_SIZE = Vector2i(64, 64)
static var MAX_Y = 100
static var RESOURCE_MAXIMUM_CAPACITY_PER_AGENT := { 'wood': 40, 'stone': 20, 'gold': 3 }

enum TileType { WOOD, STONE, GOLD, VILLAGE, OTHER }

static func get_tile_type_from_resource(resource_type: Village.ResourceType) -> TileType:
	var tile_type: TileType = TileType.OTHER
	match resource_type:
		Village.ResourceType.WOOD: tile_type = get_tile_type("wood")
		Village.ResourceType.STONE: tile_type = get_tile_type("stone")
		Village.ResourceType.GOLD: tile_type = get_tile_type("gold")
	return tile_type

static func get_tile_type(tile_type_str: String) -> TileType:
	var tile_type: TileType
	match tile_type_str:
		"wood": tile_type = TileType.WOOD
		"stone": tile_type = TileType.STONE
		"gold": tile_type = TileType.GOLD
		"village": tile_type = TileType.VILLAGE
		_: tile_type = TileType.OTHER
	return tile_type
