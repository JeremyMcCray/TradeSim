extends MeshInstance3D
#
#@export var size : Vector2i = Vector2i(150, 150)
#@export var noise : FastNoiseLite
#@export var should_update : bool = true
#@export var smooth : bool = true
#@export var grid : bool = true
#@export var edge_height : float = -2.5
#@export var workable_node_scenes : Array[PackedScene] = []
#@export var village_spawn_minimum_distance := 45
#
## New terrain modification parameters
#@export var modify_radius : float = 2.0
#@export var modify_strength : float = 1.0
#
#@export_group("Terrain Noise")
#@export_range(0.0, 10.0, 0.1) var noise_scale : float = 1.0
#@export_range(0.0, 1.0, 0.01) var flatness : float = 0.3
#
#var max_spawn_slope : float = 0.0
#var existing_villages = []
#
#var coords : Array[Vector3] = []
#var static_body : StaticBody3D
#var collision_shape : ConcavePolygonShape3D
#@onready var camera = $"../RTSCamera"
#
#
#var mod_mesh_instance: MeshInstance3D = null
#var is_modifying := false
#var modification_timer := 0.0
#var modification_duration := 0.1  # Time before applying changes
#var temp_coords: Array[Vector3] = []  # Add this to store temporary modifications
#var modified_area := Rect2i()  # Add this to track modified area
#
#
#
#func _ready() -> void:
	## Create StaticBody3D 
	#static_body = StaticBody3D.new()
	#add_child(static_body)
	#
	## Create ConcavePolygonShape3D
	#collision_shape = ConcavePolygonShape3D.new()
	#
	## Create CollisionShape3D and add to StaticBody
	#var collision_node = CollisionShape3D.new()
	#collision_node.shape = collision_shape
	#static_body.add_child(collision_node)
	#
	## Configure noise if not already set
	#if noise == null:
		#noise = FastNoiseLite.new()
	#
	## Initialize with more controllable defaults
	#noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	#
	#should_update = true
	#
	#temp_coords.resize((size.x + 1) * (size.y + 1))
	#
	## Create modification mesh instance
	#mod_mesh_instance = MeshInstance3D.new()
	#add_child(mod_mesh_instance)
	#
	## Use the same shader
	#var mod_material = ShaderMaterial.new()
	#mod_material.shader = load("res://shaders/terrain.gdshader")
	#mod_material.set_shader_parameter("grassTexture", load("res://assets/grass.jpg"))
	#mod_material.set_shader_parameter("rockTexture", load("res://assets/rock.jpg"))
	#mod_material.set_shader_parameter("sandTexture", load("res://assets/sand.jpg"))
	#mod_material.set_shader_parameter("lineThickness", 0.02)
	#mod_material.set_shader_parameter("lineVisibility", 0.0)  # No grid on mod mesh
	#mod_mesh_instance.material_override = mod_material
	#
#func _process(delta: float) -> void:
	#if is_modifying:
		#modification_timer += delta
		#if modification_timer >= modification_duration:
			#apply_modification()
			#is_modifying = false
			#modification_timer = 0.0
			#mod_mesh_instance.mesh = null  # Clear modification mesh
	#if Input.is_action_just_pressed("toggle_smooth"):
		#smooth = !smooth
		#should_update = true
	#if Input.is_action_just_pressed("toggle_grid"):
		#grid = !grid
		#should_update = true
	#
	#if Input.is_action_just_pressed("toggle_regen"):
		## Generate a more controlled random seed
		#noise.seed = randi()
		#should_update = true
	#if should_update:
		#generate_coords()
		#spawn_villages()
		#should_update = false
	## Terrain modification
	#if Input.is_action_just_pressed("left_click"):
		#modify_terrain(1)  # Raise terrain
	#elif Input.is_action_just_pressed("right_click"):
		#modify_terrain(-1)  # Lower terrain
#
#func generate_coords() -> void:
	#coords.resize((size.x + 1) * (size.y + 1))
	#
	## Calculate offsets to center the terrain
	#var x_offset = -size.x / 2.0
	#var z_offset = -size.y / 2.0
	#
	## Configure noise parameters
	#noise.frequency = 0.01 * noise_scale
	#
	#for x in range(size.x + 1):
		#for z in range(size.y + 1):
			## Calculate world coordinates with offset
			#var world_x = x + x_offset
			#var world_z = z + z_offset
			#
			## Generate multi-octave noise with controlled flatness
			#var y = generate_noise_height(world_x, world_z)
			#
			## Apply edge height to the borders
			#if x == 0 or x == size.x or z == 0 or z == size.y:
				#y = edge_height
			#
			## Store vertex 
			#coords[x * size.y + z] = Vector3(world_x, y, world_z)
	#
	#generate_mesh()
	#generate_collision()
#
#func get_height_at_point(x: float, z: float) -> float:
	## Find the closest vertices to interpolate height
	#var x_floor = floor(x)
	#var z_floor = floor(z)
	#
	## Get the four surrounding vertices
	#var v00 = get_vertex_at(x_floor, z_floor)
	#var v10 = get_vertex_at(x_floor + 1, z_floor)
	#var v01 = get_vertex_at(x_floor, z_floor + 1)
	#var v11 = get_vertex_at(x_floor + 1, z_floor + 1)
	#
	## Bilinear interpolation
	#var u = x - x_floor
	#var v = z - z_floor
	#
	#var h0 = lerp(v00.y, v10.y, u)
	#var h1 = lerp(v01.y, v11.y, u)
	#
	#return lerp(h0, h1, v)
#
#func get_vertex_at(x: float, z: float) -> Vector3:
	## Clamp to terrain bounds
	#x = clamp(x, -size.x/2.0, size.x/2.0)
	#z = clamp(z, -size.y/2.0, size.y/2.0)
	#
	## Find the closest index
	#var index_x = int(x + size.x/2.0)
	#var index_z = int(z + size.y/2.0)
	#
	#return coords[index_x * size.y + index_z]
#
#func calculate_terrain_slope(center_point: Vector3) -> float:
	## Sample points around the center to calculate slope
	#var sample_distance = 1.0  # Adjust this for more or less precise slope calculation
	#
	## Sample surrounding points
	#var points = [
		#Vector3(center_point.x + sample_distance, 0, center_point.z),
		#Vector3(center_point.x - sample_distance, 0, center_point.z),
		#Vector3(center_point.x, 0, center_point.z + sample_distance),
		#Vector3(center_point.x, 0, center_point.z - sample_distance)
	#]
	#
	## Get heights for these points
	#var heights = []
	#for point in points:
		#point.y = get_height_at_point(point.x, point.z)
		#heights.append(point.y)
	#
	## Calculate the maximum height difference
	#var max_height_diff = abs(heights.max() - heights.min())
	#
	## Convert height difference to slope angle
	#return atan(max_height_diff / (sample_distance * 2))
#
#func generate_noise_height(x: float, z: float) -> float:
	## Base noise value
	#var noise_value = noise.get_noise_2d(x, z)
	#
	## Apply flatness control
	## This creates more flat areas by reducing the impact of height variations
	#var height = noise_value * 15
	#
	## Flatten the terrain based on the flatness parameter
	#height = lerp(height, 0.0, flatness)
	#
	## Optional: floor the height for more distinct flat areas
	#height = floor(height) / 2.0
	#
	#return height
#
#func generate_collision() -> void:
	#var collision_vertices = PackedVector3Array()
	#
	#for x in range(size.x - 1):
		#for z in range(size.y - 1):
			#var coord_id := x * size.y + z
			#var top_left_vertex := coords[coord_id]
			#var top_right_vertex := coords[coord_id + 1]
			#var bottom_left_vertex := coords[coord_id + size.x]
			#var bottom_right_vertex := coords[coord_id + size.x + 1]
			#
			## First triangle
			#collision_vertices.append(bottom_left_vertex)
			#collision_vertices.append(bottom_right_vertex)
			#collision_vertices.append(top_left_vertex)
			#
			## Second triangle
			#collision_vertices.append(bottom_right_vertex)
			#collision_vertices.append(top_right_vertex)
			#collision_vertices.append(top_left_vertex)
	#
	## Set the collision shape's vertices
	#collision_shape.set_faces(collision_vertices)
#
#func vertex_color(height: float) -> Color:
	#if height > 2:
		#return Color.RED
	#if height > -2:
		#return Color.BLACK
	#
	#return Color.GREEN
#
#func generate_mesh() -> void:
	#var surface_tool := SurfaceTool.new()
	#surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	#for x in range(size.x - 1):
		#for z in range(size.y - 1):
			#var coord_id := x * size.y + z
			#var top_left_vertex := coords[coord_id]
			#var top_left_uv := Vector2(0, 0)
			#var top_right_vertex := coords[coord_id + 1]
			#var top_right_uv := Vector2(1, 0)
			#var bottom_left_vertex := coords[coord_id + size.x]
			#var bottom_left_uv := Vector2(0, 1)
			#var bottom_right_vertex := coords[coord_id + size.x + 1]
			#var bottom_right_uv := Vector2(1, 1)
			#var vertices: Array[Vector3]
			#var uvs: Array[Vector2]
			#if triangulation_check(top_left_vertex, bottom_right_vertex):
				#vertices = [
					#bottom_left_vertex,
					#bottom_right_vertex,
					#top_left_vertex,
					#bottom_right_vertex,
					#top_right_vertex,
					#top_left_vertex,
				#]
				#uvs = [
					#bottom_left_uv,
					#bottom_right_uv,
					#top_left_uv,
					#bottom_right_uv,
					#top_right_uv,
					#top_left_uv,
				#]
			#else:
				#vertices = [
					#bottom_left_vertex,
					#top_right_vertex,
					#top_left_vertex,
					#bottom_left_vertex,
					#bottom_right_vertex,
					#top_right_vertex,
				#]
				#uvs = [
					#bottom_left_uv,
					#top_right_uv,
					#top_left_uv,
					#bottom_left_uv,
					#bottom_right_uv,
					#top_right_uv,
				#]
			#
			#for i in range(vertices.size()):
				#surface_tool.set_uv(uvs[i])
				#surface_tool.set_color(vertex_color(vertices[i].y))
				#if (!smooth):
					#surface_tool.set_smooth_group(-1)
				#surface_tool.add_vertex(vertices[i])
		#
	#surface_tool.generate_normals()
	#var array_mesh := ArrayMesh.new()
	#surface_tool.commit(array_mesh)
	#mesh = array_mesh
	#var shader := ShaderMaterial.new()
	#shader.shader = load("res://shaders/terrain.gdshader")
	#shader.set_shader_parameter("grassTexture", load("res://assets/grass.jpg"))
	#shader.set_shader_parameter("rockTexture", load("res://assets/rock.jpg"))
	#shader.set_shader_parameter("sandTexture", load("res://assets/sand.jpg"))
	#shader.set_shader_parameter("lineThickness", 0.02)
	#shader.set_shader_parameter("lineVisibility", 0.5 if grid else 0.0)
	#mesh.surface_set_material(0, shader)
#
#func triangulation_check(coord0: Vector3, coord1: Vector3) -> bool:
	#return coord0.y == coord1.y
#
#func modify_terrain(direction: float) -> void:
	#pass
	##var mouse_pos = get_viewport().get_mouse_position()
	##var ray_origin = camera.project_ray_origin(mouse_pos)
	##var ray_normal = camera.project_ray_normal(mouse_pos)
	##
	##var space_state = get_world_3d().direct_space_state
	##var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal * 1000)
	##query.collision_mask = 1
	##
	##var result = space_state.intersect_ray(query)
	##
	##if result:
		##var hit_point = result.position
		##generate_modification_mesh(hit_point, direction)
		##is_modifying = true
		##modification_timer = 0.0
#
#func generate_modification_mesh(center: Vector3, direction: float) -> void:
	#var surface_tool := SurfaceTool.new()
	#surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	#
	## Calculate the area to modify
	#var radius_in_vertices = ceil(modify_radius)
	#var center_x = int(center.x + size.x/2.0)
	#var center_z = int(center.z + size.y/2.0)
	#
	#var min_x = max(1, center_x - radius_in_vertices)
	#var max_x = min(size.x - 1, center_x + radius_in_vertices)
	#var min_z = max(1, center_z - radius_in_vertices)
	#var max_z = min(size.y - 1, center_z + radius_in_vertices)
	#
	## Store the modified area
	#modified_area = Rect2i(min_x, min_z, max_x - min_x, max_z - min_z)
	#
	## Copy current coords to temp_coords
	#temp_coords = coords.duplicate()
	#
	## Modify vertices in temp_coords
	#for x in range(min_x - 1, max_x + 2):
		#for z in range(min_z - 1, max_z + 2):
			#var vertex_index = x * size.y + z
			#if vertex_index >= 0 and vertex_index < temp_coords.size():
				#var vertex = coords[vertex_index]
				#var distance = vertex.distance_to(center)
				#
				#if distance <= modify_radius:
					#var falloff = 1.0 - (distance / modify_radius)
					#falloff = smoothstep(0.0, 1.0, falloff)
					#temp_coords[vertex_index].y += direction * modify_strength * falloff
	#
	## Generate mesh for modified area
	#for x in range(min_x - 1, max_x + 1):
		#for z in range(min_z - 1, max_z + 1):
			#if x < 0 or x >= size.x or z < 0 or z >= size.y:
				#continue
				#
			#var coord_id := x * size.y + z
			#var top_left_vertex := temp_coords[coord_id]
			#var top_right_vertex := temp_coords[coord_id + 1]
			#var bottom_left_vertex := temp_coords[coord_id + size.x]
			#var bottom_right_vertex := temp_coords[coord_id + size.x + 1]
			#
			## Use existing UV mapping code
			#var top_left_uv := Vector2(0, 0)
			#var top_right_uv := Vector2(1, 0)
			#var bottom_left_uv := Vector2(0, 1)
			#var bottom_right_uv := Vector2(1, 1)
			#
			## Add vertices using your existing triangulation logic
			#var vertices: Array[Vector3]
			#var uvs: Array[Vector2]
			#if triangulation_check(top_left_vertex, bottom_right_vertex):
				#vertices = [
					#bottom_left_vertex,
					#bottom_right_vertex,
					#top_left_vertex,
					#bottom_right_vertex,
					#top_right_vertex,
					#top_left_vertex,
				#]
				#uvs = [
					#bottom_left_uv,
					#bottom_right_uv,
					#top_left_uv,
					#bottom_right_uv,
					#top_right_uv,
					#top_left_uv,
				#]
			#else:
				#vertices = [
					#bottom_left_vertex,
					#top_right_vertex,
					#top_left_vertex,
					#bottom_left_vertex,
					#bottom_right_vertex,
					#top_right_vertex,
				#]
				#uvs = [
					#bottom_left_uv,
					#top_right_uv,
					#top_left_uv,
					#bottom_left_uv,
					#bottom_right_uv,
					#top_right_uv,
				#]
			#
			#for i in range(vertices.size()):
				#surface_tool.set_uv(uvs[i])
				#surface_tool.set_color(vertex_color(vertices[i].y))
				#if (!smooth):
					#surface_tool.set_smooth_group(-1)
				#surface_tool.add_vertex(vertices[i])
	#
	#surface_tool.generate_normals()
	#
	## Create mesh and assign to modification instance
	#var array_mesh := ArrayMesh.new()
	#surface_tool.commit(array_mesh)
	#mod_mesh_instance.mesh = array_mesh
#
#func apply_modification() -> void:
	## Apply changes from temp_coords to main coords
	#if modified_area.size.x > 0 and modified_area.size.y > 0:
		#for x in range(modified_area.position.x - 1, modified_area.position.x + modified_area.size.x + 2):
			#for z in range(modified_area.position.y - 1, modified_area.position.y + modified_area.size.y + 2):
				#if x >= 0 and x < size.x and z >= 0 and z < size.y:
					#var vertex_index = x * size.y + z
					#if vertex_index < coords.size():
						#coords[vertex_index] = temp_coords[vertex_index]
		#
		## Regenerate main terrain mesh and collision for the modified area
		#generate_mesh()
		#generate_collision()
	#
	## Clear modification mesh
	#mod_mesh_instance.mesh = null
#
## Smooth interpolation function
#func smoothstep(edge0: float, edge1: float, x: float) -> float:
	#var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	#return t * t * (3.0 - 2.0 * t)
#
#func is_valid_spawn_point(point: Vector3) -> bool:
	## Check height is reasonable (not too high or low)
	#if point.y < edge_height + 1 or point.y > 5:
		#return false
	#
	## Calculate terrain slope at the spawn point
	#var slope = calculate_terrain_slope(point)
	#
	## Check if slope is within acceptable range
	#if slope > deg_to_rad(max_spawn_slope):
		#return false
	#
	## Optional: Add additional checks like minimum distance between villages
	#return true
#
#func is_valid_workable_node_spawn(point: Vector3, existing_nodes: Array) -> bool:
	## Check height is reasonable (not too high or low)
	#if point.y < edge_height + 1 or point.y > 5:
		#return false
	#
	## Calculate terrain slope at the spawn point
	#var slope = calculate_terrain_slope(point)
	#
	## Check if slope is within acceptable range
	#if slope > deg_to_rad(max_spawn_slope):
		#return false
	#
	## Check for existing villages
	#for child in get_parent_node_3d().get_children():
		#if child.is_in_group("Village"):
			#if child.global_position.distance_to(point) < 2:  # Adjust distance as needed
				#return false
	#
	## Check for existing workable nodes
	#for existing_point in existing_nodes:
		#if existing_point.distance_to(point) < 2:  # Adjust distance as needed
			#return false
	#
	#return true
#
#func spawn_workable_nodes(village):
	## List to track spawned workable nodes to prevent overlapping
	#var spawned_workable_nodes = []
	#
	## Get all village nodes
	#var villages = get_parent_node_3d().get_children().filter(func(child): return child.is_in_group("Village"))
	#
	## Define spawn range parameters
	#var min_village_distance : float = 3.0  # Minimum distance from village
	#var max_village_distance : float = 18.0  # Maximum distance from village
	#
	## Attempt to spawn 5 workable nodes
	#for i in range(9):
		#var attempts = 0
		#var max_attempts = 100
		#var spawn_point : Vector3
		#
		#while attempts < max_attempts:
			## If no villages exist, break the loop
			#if villages.is_empty():
				#break
			#
			## Generate a point within the specified range from the village
			#var angle = randf() * 2 * PI  # Random angle
			#var distance = lerp(min_village_distance, max_village_distance, randf())  # Random distance
			#
			## Calculate spawn coordinates relative to the village
			#var x = village.global_position.x + cos(angle) * distance
			#var z = village.global_position.z + sin(angle) * distance
			#
			## Clamp to terrain bounds
			#x = clamp(x, -size.x/2.0, size.x/2.0)
			#z = clamp(z, -size.y/2.0, size.y/2.0)
			#
			## Get the height at this point
			#var y = get_height_at_point(x, z)
			#
			## Create a potential spawn point
			#spawn_point = Vector3(x, y + 1, z)
			#
			## Check if this is a valid spawn point 
			#if is_valid_workable_node_spawn(spawn_point, spawned_workable_nodes):
				## Randomly select a workable node scene
				#var workable_node_scene = workable_node_scenes.pick_random()
				#var workable_node = workable_node_scene.instantiate()
				#
				## Add to tracking and scene
				#village.add_child(workable_node)
				#spawned_workable_nodes.append(spawn_point)
				#workable_node.add_to_group("WorkableNode")
				#workable_node.global_position = spawn_point
				#
				#break
			#
			#attempts += 1
		#
		#if attempts >= max_attempts:
			#print("Could not find valid spawn point for workable node ", i)
#
#func spawn_villages() -> void:
	#
	## Remove any existing villages first
	#for child in get_parent_node_3d().get_children():
		#if child.is_in_group("Village") or child.is_in_group("WorkableNode"):
			#child.queue_free()
	#existing_villages = []
	#
	## Attempt to spawn 3 villages
	#for i in range(3):
		#var attempts = 0
		#var max_attempts = 100
		#var spawn_point : Vector3
		##Using reduced size so villages don't spawn on the border
		#var reduced_size = size * .8
		#
		#while attempts < max_attempts:
			#var x = randf_range(-reduced_size.x/2.0, reduced_size.x/2.0)
			#var z = randf_range(-reduced_size.y/2.0, reduced_size.y/2.0)
			#var y = get_height_at_point(x, z)
			#
			#spawn_point = Vector3(x, y + 1, z)
			#
			## Check if this is a valid spawn point
			#if is_valid_spawn_point(spawn_point):
				## Additional check for minimum distance between villages
				#var is_valid_distance = true
				#for village_pos in existing_villages:
					#if spawn_point.distance_to(village_pos) < village_spawn_minimum_distance:  # Adjust minimum distance as needed
						#is_valid_distance = false
						#break
				#
				#if is_valid_distance:
					#var village = load("res://Scenes/village_center.tscn").instantiate()
					#village.add_to_group("Village")
					#village.global_position = spawn_point
					#get_parent_node_3d().add_child(village)
					#spawn_workable_nodes(village)
					#
					## Store the village's position
					#existing_villages.append(spawn_point)
					#break
			#
			#attempts += 1
		#
		#if attempts >= max_attempts:
			#print("Could not find valid spawn point for village ", i)
