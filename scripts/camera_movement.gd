extends Camera2D


@onready var tile_map = $"../TileMap"

@export var zoom_speed: float = 10

var zoom_target: Vector2
var drag_start_mouse_pos := Vector2.ZERO
var drag_start_camera_pos := Vector2.ZERO
var is_dragging := false

func _ready():
	zoom_target = zoom

func _process(delta):
	zoom_camera(delta)
	simple_pan(delta)
	click_and_drag()

func zoom_camera(delta):
	if Input.is_action_just_pressed("camera_zoom_in"):
		zoom_camera_to_cursor(0.025)
	
	if Input.is_action_just_pressed("camera_zoom_out"):
		zoom_camera_to_cursor(-0.025)

func simple_pan(delta):
	var move_amount := Vector2.ZERO
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
		var move_vector: Vector2 = get_viewport().get_mouse_position() - drag_start_mouse_pos
		position = drag_start_camera_pos - move_vector * 1/zoom.x

func zoom_camera_to_cursor(direction: float) -> void:
	"""
		This function adjusts the camera's zoom level and position
		to create a zooming effect centered on the cursor's location.
	"""
	var previous_mouse_position: Vector2 = get_local_mouse_position()

	zoom += zoom * zoom_speed * direction
	
	var diff: Vector2 = previous_mouse_position - get_local_mouse_position()
	offset += diff
