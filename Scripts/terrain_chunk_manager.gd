extends Node3D

@export var world_seed := randi_range(10000000,20000000)
@export var chunk_size := 32  # Size of each chunk in vertices
@export var view_distance := 10  # Number of chunks to load in each direction
@export var noise : FastNoiseLite
@export var max_villages := 15
@export var village_spawn_minimum_distance := 200.0
@export var flatness = 0.5
var chunks := {}  # Dictionary to store active chunks
var current_center_chunk := Vector2i.ZERO
var existing_villages := []  # Store village positions
@onready var camera = $"../FPSCamera/Camera3D"

var good_placer

var village_names : Array

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
	village_names = load("res://configs/agot_vil_names.json").get_data()
	village_names.shuffle()

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
		# Convert to world coordinates with some randomness within the chunk
		var world_x = chunk_pos.x * chunk_size + randi_range(5, chunk_size - 5)
		var world_z = chunk_pos.y * chunk_size + randi_range(5, chunk_size - 5)
		var world_y = get_chunk_height(world_x, world_z)
		
		var spawn_point = Vector3(world_x, world_y + 1, world_z)
		
		if is_valid_village_spawn(spawn_point):
			#Makes sure there is ground around the entire village
			update_chunks_around_position(Vector2i(chunk_pos.x,chunk_pos.y), 10)
			var village = load("res://Scenes/village_center.tscn").instantiate()
			village.add_to_group("Village")
			add_child(village)
			village.global_position = spawn_point
			village.id = village_names.pop_front()
			Global.add_village(village)
			existing_villages.append(spawn_point)
			good_placer.spawn_workable_nodes(village, noise)
			LogBox.add_message("ChunkLoader","New Village Created: " + str(village.id))
			break
			
		attempts += 1

func is_valid_village_spawn(point: Vector3) -> bool:
	# Check if the area is sufficiently flat in a 10 unit radius
	if not is_area_flat(point, 10.0):
		return false
	
	# Check distance to other villages
	for village_pos in existing_villages:
		if point.distance_to(village_pos) < village_spawn_minimum_distance:
			return false
	
	return true

func is_area_flat(center: Vector3, radius: float) -> bool:
	var sample_points = 8  # Number of points to check around the circle
	var max_slope = deg_to_rad(5.0)  # Even stricter slope requirement for village area
	
	# First check the center point height
	var center_height = get_chunk_height(center.x, center.z)
	
	# Check points around the circumference
	for i in range(sample_points):
		var angle = (2 * PI * i) / sample_points
		var offset_x = radius * cos(angle)
		var offset_z = radius * sin(angle)
		var check_x = center.x + offset_x
		var check_z = center.z + offset_z
		
		# Get height at this point
		var check_height = get_chunk_height(check_x, check_z)
		
		# Calculate slope from center to this point
		var horizontal_dist = Vector2(offset_x, offset_z).length()
		var height_diff = abs(check_height - center_height)
		var slope = atan(height_diff / horizontal_dist)
		
		if slope > max_slope:
			return false
	
	# Additional check: sample some random points within the circle
	for i in range(4):  # 4 random internal points
		var rand_radius = randf_range(0, radius)
		var rand_angle = randf_range(0, 2 * PI)
		var rand_x = center.x + rand_radius * cos(rand_angle)
		var rand_z = center.z + rand_radius * sin(rand_angle)
		var rand_height = get_chunk_height(rand_x, rand_z)
		var rand_slope = atan(abs(rand_height - center_height) / rand_radius)
		
		if rand_slope > max_slope:
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
	for x in range(-view_distance, view_distance + 1):
		for z in range(-view_distance, view_distance + 1):
			var chunk_pos = current_center_chunk + Vector2i(x, z)
			
			if not chunks.has(chunk_pos):
				create_chunk(chunk_pos)
				var rand = randi_range(1,1000)
				if rand > 899:
					try_spawn_village(chunk_pos)  # Try to spawn a village in the new chunk
	
	# Remove chunks that are too far away
	# var needed_chunks := {}
	# needed_chunks[chunk_pos] = true
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

func update_chunks_around_position(chunk_vector : Vector2i, build_range: int) -> void:
	for x in range(-build_range, build_range + 1):
		for z in range(-build_range, build_range + 1):
			var chunk_pos = chunk_vector + Vector2i(x, z)
			
			if not chunks.has(chunk_pos):
				create_chunk(chunk_pos)
