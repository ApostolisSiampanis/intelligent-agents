extends Camera2D

@onready var tile_map = $"../TileMap"
@export var zoom_speed : float = 10
@onready var v_box_container_village_1_agents_list = %VBoxContainerVillage1AgentsList
@onready var v_box_container_village_2_agents_list = %VBoxContainerVillage2AgentsList

var zoom_target : Vector2

var drag_start_mouse_pos = Vector2.ZERO
var drag_start_camera_pos = Vector2.ZERO
var is_dragging : bool = false
var followed_agent : Agent = null

func _ready():
	zoom_target = zoom
	center_on_tile_map()

func _process(delta):
	if followed_agent:
		var viewport_size = get_viewport().get_visible_rect().size
		position = followed_agent.global_position - viewport_size / 2
	else:
		if not is_mouse_over_gui():
			zoom_camera()
			simple_pan(delta)
			click_and_drag()

func is_mouse_over_gui() -> bool:
	var mouse_pos = get_global_mouse_position()
	return v_box_container_village_1_agents_list.get_global_rect().has_point(mouse_pos) or v_box_container_village_2_agents_list.get_global_rect().has_point(mouse_pos)

func zoom_camera():
	if Input.is_action_just_pressed("camera_zoom_in"):
		zoom_camera_to_cursor(0.015)

	if Input.is_action_just_pressed("camera_zoom_out"):
		zoom_camera_to_cursor(-0.015)

func simple_pan(delta):
	var move_amount = Vector2.ZERO
	if Input.is_action_pressed("camera_move_right"):
		move_amount.x += 1

	if Input.is_action_pressed("camera_move_left"):
		move_amount.x -= 1

	if Input.is_action_pressed("camera_move_up"):
		move_amount.y -= 1

	if Input.is_action_pressed("camera_move_down"):
		move_amount.y += 1

	move_amount = move_amount.normalized()
	position += move_amount * delta * 1000 * (1/zoom.x)

func click_and_drag():
	if !is_dragging and Input.is_action_just_pressed("camera_pan"):
		drag_start_mouse_pos = get_viewport().get_mouse_position()
		drag_start_camera_pos = position
		is_dragging = true

	if is_dragging and Input.is_action_just_released("camera_pan"):
		is_dragging = false

	if is_dragging:
		var move_vector = get_viewport().get_mouse_position() - drag_start_mouse_pos
		position = drag_start_camera_pos - move_vector * 1/zoom.x

func follow_agent(agent):
	followed_agent = agent

func stop_following_agent():
	followed_agent = null

func center_on_tile_map():
	# Ensure that cols and rows are initialized
	if tile_map == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var tile_map_size: Vector2 = Vector2(tile_map.cols * 64, tile_map.rows * 64)
	position = tile_map.position + (tile_map_size - viewport_size) / 2

func zoom_camera_to_cursor(direction: float) -> void:
	"""
		This function adjusts the camera's zoom level and position
		to create a zooming effect centered on the cursor's location.
	"""
	var previous_mouse_position: Vector2 = get_local_mouse_position()

	zoom += zoom * zoom_speed * direction
	
	var diff: Vector2 = previous_mouse_position - get_local_mouse_position()
	offset += diff
