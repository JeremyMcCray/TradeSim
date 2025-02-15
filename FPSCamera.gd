extends Node3D

# Camera Parameters
@export_range(0, 1000) var movement_speed: float = 100
@export_range(0, 1000) var rotation_speed: float = 5
@export_range(0, 1000) var zoom_speed: float = 50
@export_range(10, 1000) var min_zoom: float = 5
@export_range(10, 1000) var max_zoom: float = -30
@export_range(-179, 179) var min_elevation_angle: float = 1
@export_range(-179, 179) var max_elevation_angle: float = 179
@export var edge_margin: float = 50
@export var allow_rotation: bool = true
@export var allow_zoom: bool = true
@export var allow_pan: bool = true

@onready var camera: Camera3D = $Camera3D

# Runtime State
var is_rotating: bool = false
var is_panning: bool = false
var last_mouse_position: Vector2
var zoom_level: float = 1

func _ready() -> void:
	# Initialize camera distance
	zoom_level = camera.position.z

func _process(delta: float) -> void:
	if !visible:
		return
		
	if not is_panning:
		handle_edge_movement(delta)
		handle_keyboard_movement(delta)
		if allow_rotation:
			handle_rotation(delta)
		if allow_zoom:
			handle_zoom(delta)
	else:
		if allow_pan:
			handle_panning(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_rotate"):
		is_rotating = true
		last_mouse_position = get_viewport().get_mouse_position()
	elif event.is_action_released("camera_rotate"):
		is_rotating = false

	if event.is_action_pressed("camera_pan"):
		is_panning = true
		last_mouse_position = get_viewport().get_mouse_position()
	elif event.is_action_released("camera_pan"):
		is_panning = false
		
	if event.is_action_pressed("camera_zoom_in"):
		if zoom_level <= min_zoom:
			zoom_level += 1
			# Move camera along its forward vector
			var zoom_dir = -camera.global_transform.basis.z
			position += zoom_dir * zoom_speed * 0.1
	elif event.is_action_pressed("camera_zoom_out"):
		if zoom_level >= max_zoom:
			zoom_level -= 1
			# Move camera along its backward vector
			var zoom_dir = camera.global_transform.basis.z
			position += zoom_dir * zoom_speed * 0.1


func get_camera_right() -> Vector3:
	return global_transform.basis.x

func get_camera_forward() -> Vector3:
	# Get forward vector parallel to XZ plane
	var forward = -global_transform.basis.z
	forward.y = 0
	return forward.normalized()

func handle_keyboard_movement(delta: float) -> void:
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("camera_forward"):
		input_dir += get_camera_forward()
	if Input.is_action_pressed("camera_backward"):
		input_dir -= get_camera_forward()
	if Input.is_action_pressed("camera_left"):
		input_dir -= get_camera_right()
	if Input.is_action_pressed("camera_right"):
		input_dir += get_camera_right()

	if input_dir != Vector3.ZERO:
		position += input_dir.normalized() * movement_speed * delta

func handle_edge_movement(delta: float) -> void:
	var viewport = get_viewport()
	var mouse_pos = viewport.get_mouse_position()
	var screen_rect = viewport.get_visible_rect()

	if not screen_rect.has_point(mouse_pos):
		return

	var input_dir = Vector3.ZERO

	if mouse_pos.x < edge_margin:
		input_dir -= get_camera_right()
	elif mouse_pos.x > screen_rect.size.x - edge_margin:
		input_dir += get_camera_right()

	if mouse_pos.y < edge_margin:
		input_dir += get_camera_forward()
	elif mouse_pos.y > screen_rect.size.y - edge_margin:
		input_dir -= get_camera_forward()

	if input_dir != Vector3.ZERO:
		position += input_dir.normalized() * movement_speed * delta

func handle_rotation(delta: float) -> void:
	if is_rotating:
		var mouse_displacement = get_viewport().get_mouse_position() - last_mouse_position
		last_mouse_position = get_viewport().get_mouse_position()

		# Horizontal rotation around Y axis
		rotate_y(-deg_to_rad(mouse_displacement.x * rotation_speed * delta))

		# Vertical rotation (camera tilt)
		camera.rotate_x(-deg_to_rad(mouse_displacement.y * rotation_speed * delta))
		camera.rotation.x = clamp(
			camera.rotation.x,
			deg_to_rad(min_elevation_angle),
			deg_to_rad(max_elevation_angle)
		)

func handle_zoom(delta: float) -> void:
	if Input.is_action_pressed("camera_zoom_in"):
		zoom_level -= zoom_speed * delta
	if Input.is_action_pressed("camera_zoom_out"):
		zoom_level += zoom_speed * delta

func handle_panning(delta: float) -> void:
	if is_panning:
		var current_mouse_pos = get_viewport().get_mouse_position()
		var displacement = current_mouse_pos - last_mouse_position
		last_mouse_position = current_mouse_pos

		var right_movement = get_camera_right() * displacement.x
		var forward_movement = get_camera_forward() * displacement.y

		position -= (right_movement + forward_movement) * 0.1

func enable() -> void:
	visible = true
	camera.current = true

func disable() -> void:
	visible = false
	camera.current = false
