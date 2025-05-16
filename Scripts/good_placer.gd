class_name GoodPlacer
extends Node3D

@export var placement_area: Vector2 = Vector2(100, 100)  # Area size in which to place goods
@export var min_distance: float = 1.0  # Minimum distance between goods
@export var max_distance: float = 80.0  # Minimum distance between goods
@export var number_of_goods: int = 30  # How many goods to place
@export var height: float = 10.0  # Length of ray for ground check
@export var flatness = 0.5

var factory: GoodFactory
var placed_positions: Array[Vector3] = []

func _ready() -> void:
	factory = GoodFactory.new()
	add_child(factory)

func spawn_workable_nodes(village,noise) -> void:
	factory = GoodFactory.new()
	add_child(factory)
	var spawned_workable_nodes = []
	var weighted_types: Array = []
	for good_type in factory.get_good_types():
		var weight = factory._config[good_type]["spawn_weight"]
		for i in range(int(weight * 10)):  # Multiply by 10 to allow for decimal weights
			weighted_types.append(good_type)
			
	for i in range(number_of_goods):
		var attempts = 0
		var max_attempts = 50
		
		while attempts < max_attempts:
			var angle = randf() * 2 * PI
			var distance = lerp(min_distance, max_distance, randf())
			
			var x = village.global_position.x + cos(angle) * distance
			var z = village.global_position.z + sin(angle) * distance
			var y = get_chunk_height(x, z, noise)
			
			var spawn_point = Vector3(x, y , z)
			
			if is_valid_workable_spawn(spawn_point, spawned_workable_nodes,noise):
				var good_type = weighted_types[randi() % weighted_types.size()]
				var good = factory.create_good(good_type)
				if good:
					var good_path = good.resource_paths[randi_range(0, good.resource_paths.size() - 1)]
					var visable_good = load(good_path).instantiate()
					village.add_child(good)
					village.add_child(visable_good)
					good.global_position = spawn_point
					visable_good.global_position = spawn_point
					good.add_to_group("WorkableNode")
					spawned_workable_nodes.append(spawn_point)
					break
				
			attempts += 1

func is_valid_workable_spawn(point: Vector3, existing_nodes: Array, noise) -> bool:
	var slope = calculate_terrain_slope(point, noise)
	if slope > deg_to_rad(10.0):
		return false
	
	return true

func get_chunk_height(world_x: float, world_z: float, noise) -> float:
	var noise_value = noise.get_noise_2d(world_x, world_z)
	var height = noise_value * 15
	height = lerp(height, 0.0, flatness)
	height = floor(height) / 2.0
	return height
	
func calculate_terrain_slope(point: Vector3, noise) -> float:
	var sample_distance = 1.0
	var points = [
		Vector3(point.x + sample_distance, 0, point.z),
		Vector3(point.x - sample_distance, 0, point.z),
		Vector3(point.x, 0, point.z + sample_distance),
		Vector3(point.x, 0, point.z - sample_distance)
	]
	
	var heights = []
	for p in points:
		p.y = get_chunk_height(p.x, p.z, noise)
		heights.append(p.y)
	
	var max_height_diff = abs(heights.max() - heights.min())
	return atan(max_height_diff / (sample_distance * 2))
