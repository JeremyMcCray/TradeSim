extends Node3D

@export var world_seed := randi_range(10000000,20000000)
@export var chunk_size := 64  # Size of each chunk in vertices
@export var view_distance := 10  # Number of chunks to load in each direction
@export var noise : FastNoiseLite
@export var edge_height : float = -2.5
@export var max_villages := 15
@export var village_spawn_minimum_distance := 200.0
@export var flatness = 0.5
var chunks := {}  # Dictionary to store active chunks
var current_center_chunk := Vector2i.ZERO
var existing_villages := []  # Store village positions
@onready var camera = $"../FPSCamera/Camera3D"

var good_placer

var world_boarder
# Pass through configuration
@export var smooth : bool = true:
	set(value):
		smooth = value
		for chunk in chunks.values():
			chunk.smooth = value

@export var grid : bool = false:
	set(value):
		grid = value
		for chunk in chunks.values():
			chunk.grid = value

func _ready() -> void:
	if noise == null:
		noise = FastNoiseLite.new()
	noise.frequency = 0.01
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	good_placer = GoodPlacer.new()
	update_chunks()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_r"):  # Regenerate terrain
		regenerate_terrain()
	
	var camera_pos = camera.global_position
	var new_center_chunk = Vector2i(
		floor(camera_pos.x / chunk_size),
		floor(camera_pos.z / chunk_size)
	)
	#
	if new_center_chunk != current_center_chunk:
		current_center_chunk = new_center_chunk
		update_chunks()

func try_spawn_village(chunk_pos: Vector2i) -> void:
	var r = randi_range(1,10)
	if r < 9:
		return
	if existing_villages.size() >= max_villages:
		return
	
	var attempts = 0
	var max_attempts = 3
	
	while attempts < max_attempts:
		
		# Convert to world coordinates
		var world_x = chunk_pos.x * chunk_size 
		var world_z = chunk_pos.y * chunk_size
		var world_y = get_chunk_height(world_x, world_z)
		
		var spawn_point = Vector3(world_x, world_y + 1, world_z)
		
		if is_valid_village_spawn(spawn_point):
			var village = load("res://Scenes/village_center.tscn").instantiate()
			village.add_to_group("Village")
			village.global_position = spawn_point
			add_child(village)
			existing_villages.append(spawn_point)
			good_placer.spawn_workable_nodes(village,noise)
			break
			
		attempts += 1

func is_valid_village_spawn(point: Vector3) -> bool:
	# Check slope
	var slope = calculate_terrain_slope(point)
	if slope > deg_to_rad(10.0):  # Max slope of 10 degrees
		return false
	
	# Check distance to other villages
	for village_pos in existing_villages:
		if point.distance_to(village_pos) < village_spawn_minimum_distance:
			return false
	
	return true

func calculate_terrain_slope(point: Vector3) -> float:
	var sample_distance = 1.0
	var points = [
		Vector3(point.x + sample_distance, 0, point.z),
		Vector3(point.x - sample_distance, 0, point.z),
		Vector3(point.x, 0, point.z + sample_distance),
		Vector3(point.x, 0, point.z - sample_distance)
	]
	
	var heights = []
	for p in points:
		p.y = get_chunk_height(p.x, p.z)
		heights.append(p.y)
	
	var max_height_diff = abs(heights.max() - heights.min())
	return atan(max_height_diff / (sample_distance * 2))

func get_chunk_height(world_x: float, world_z: float) -> float:
	var noise_value = noise.get_noise_2d(world_x, world_z)
	var height = noise_value * 15
	height = lerp(height, 0.0, flatness)
	height = floor(height) / 2.0
	return height

func update_chunks() -> void:
	var needed_chunks := {}
	var rand
	for x in range(-view_distance, view_distance + 1):
		for z in range(-view_distance, view_distance + 1):
			var chunk_pos = current_center_chunk + Vector2i(x, z)
			needed_chunks[chunk_pos] = true
			
			if not chunks.has(chunk_pos):
				create_chunk(chunk_pos)
				rand = randi_range(1,10)
				try_spawn_village(chunk_pos)  # Try to spawn a village in the new chunk
	
	# Remove chunks that are too far away
	#for chunk_pos in chunks.keys():
		#if not needed_chunks.has(chunk_pos):
			#chunks[chunk_pos].queue_free()
			#chunks.erase(chunk_pos)

func create_chunk(chunk_pos: Vector2i) -> void:
	var chunk = preload("res://Scenes/terrain_chunk.tscn").instantiate()
	add_child(chunk)
	
	chunk.chunk_manager = self
	chunk.chunk_position = chunk_pos
	chunk.chunk_size = chunk_size
	chunk.smooth = smooth
	chunk.grid = grid
	
	chunk.position = Vector3(
		chunk_pos.x * chunk_size,
		0,
		chunk_pos.y * chunk_size
	)
	
	chunks[chunk_pos] = chunk
	chunk.generate()

func regenerate_terrain() -> void:
	noise.seed = world_seed
	
	# Clear existing villages
	for child in get_children():
		if child.is_in_group("Village") or child.is_in_group("WorkableNode"):
			child.queue_free()
	existing_villages.clear()
	
	# Clear and regenerate chunks
	for chunk in chunks.values():
		chunk.queue_free()
	chunks.clear()
	update_chunks()

func get_height_at_point(x: float, z: float) -> float:
	var chunk_pos = Vector2i(
		floor(x / chunk_size),
		floor(z / chunk_size)
	)
	
	if chunks.has(chunk_pos):
		var chunk = chunks[chunk_pos]
		var local_x = x - (chunk_pos.x * chunk_size)
		var local_z = z - (chunk_pos.y * chunk_size)
		return chunk.get_height_at_point(local_x, local_z)
	
	return get_chunk_height(x, z)
