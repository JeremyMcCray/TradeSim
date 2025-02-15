extends MeshInstance3D

# Terrain Parameters
@export var height_scale: float = 1.0
@export var vertical_offset: float = 0.0
@export var max_height: float = 20.0
@export var min_depth: float = -10.0

# Biome Thresholds
@export var water_level: float = -2.0
@export var sand_blend: float = -1.9
@export var rock_level: float = 1.0

# Existing variables
var chunk_position := Vector2i.ZERO
var chunk_size := 32
var chunk_manager : Node = null
var smooth : bool = true
var grid : bool = false

var coords : Array[Vector3] = []
var static_body : StaticBody3D
var collision_shape : ConcavePolygonShape3D

func _ready() -> void:
	static_body = StaticBody3D.new()
	add_child(static_body)
	
	collision_shape = ConcavePolygonShape3D.new()
	var collision_node = CollisionShape3D.new()
	collision_node.shape = collision_shape
	static_body.add_child(collision_node)

func generate() -> void:
	coords.resize((chunk_size + 1) * (chunk_size + 1))
	var world_offset_x = chunk_position.x * chunk_size
	var world_offset_z = chunk_position.y * chunk_size
	
	for x in range(chunk_size + 1):
		for z in range(chunk_size + 1):
			var world_x = x + world_offset_x
			var world_z = z + world_offset_z
			
			# Apply height scaling, offset, and clamping
			var base_y = chunk_manager.get_chunk_height(world_x, world_z)
			var scaled_y = base_y * height_scale + vertical_offset
			var y = clamp(scaled_y, min_depth, max_height)
			coords[x * (chunk_size + 1) + z] = Vector3(x, y, z)
	
	generate_mesh()
	generate_collision()

func calculate_vertex_color(vertex: Vector3) -> Color:
	var height = vertex.y
	
	if height > rock_level:
		return Color.RED
	elif height < water_level:
		return Color.GREEN
	elif height < sand_blend:
		var t = smoothstep(water_level, sand_blend, height)
		return Color.GREEN.lerp(Color.BLACK, t)
	else:
		return Color.BLACK
func add_smooth_quad(surface_tool: SurfaceTool,
					top_left: Vector3, top_right: Vector3,
					bottom_left: Vector3, bottom_right: Vector3,
					top_left_uv: Vector2, top_right_uv: Vector2,
					bottom_left_uv: Vector2, bottom_right_uv: Vector2,
					top_left_color: Color, top_right_color: Color,
					bottom_left_color: Color, bottom_right_color: Color) -> void:
	
	# First triangle
	surface_tool.set_uv(bottom_left_uv)
	surface_tool.set_color(bottom_left_color)
	if (!smooth):
		surface_tool.set_smooth_group(-1)
	surface_tool.add_vertex(bottom_left)
	
	surface_tool.set_uv(bottom_right_uv)
	surface_tool.set_color(bottom_right_color)
	if (!smooth):
		surface_tool.set_smooth_group(-1)
	surface_tool.add_vertex(bottom_right)
	
	surface_tool.set_uv(top_left_uv)
	surface_tool.set_color(top_left_color)
	if (!smooth):
		surface_tool.set_smooth_group(-1)
	surface_tool.add_vertex(top_left)
	
	# Second triangle
	surface_tool.set_uv(bottom_right_uv)
	surface_tool.set_color(bottom_right_color)
	if (!smooth):
		surface_tool.set_smooth_group(-1)
	surface_tool.add_vertex(bottom_right)
	
	surface_tool.set_uv(top_right_uv)
	surface_tool.set_color(top_right_color)
	if (!smooth):
		surface_tool.set_smooth_group(-1)
	surface_tool.add_vertex(top_right)
	
	surface_tool.set_uv(top_left_uv)
	surface_tool.set_color(top_left_color)
	if (!smooth):
		surface_tool.set_smooth_group(-1)
	surface_tool.add_vertex(top_left)

func generate_mesh() -> void:
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var uv_scale = 0.1 # Adjust this to control texture tiling
	
	for x in range(chunk_size):
		for z in range(chunk_size):
			var coord_id := x * (chunk_size + 1) + z
			var top_left_vertex := coords[coord_id]
			var top_right_vertex := coords[coord_id + 1]
			var bottom_left_vertex := coords[coord_id + chunk_size + 1]
			var bottom_right_vertex := coords[coord_id + chunk_size + 2]
			
			# Calculate world position for proper UV mapping
			var world_x = chunk_position.x * chunk_size + x
			var world_z = chunk_position.y * chunk_size + z
			
			# Calculate UVs based on world position for seamless texturing
			var top_left_uv := Vector2(world_x * uv_scale, world_z * uv_scale)
			var top_right_uv := Vector2((world_x + 1) * uv_scale, world_z * uv_scale)
			var bottom_left_uv := Vector2(world_x * uv_scale, (world_z + 1) * uv_scale)
			var bottom_right_uv := Vector2((world_x + 1) * uv_scale, (world_z + 1) * uv_scale)
			
			# Calculate vertex colors with smoother transitions
			var top_left_color = calculate_vertex_color(top_left_vertex)
			var top_right_color = calculate_vertex_color(top_right_vertex)
			var bottom_left_color = calculate_vertex_color(bottom_left_vertex)
			var bottom_right_color = calculate_vertex_color(bottom_right_vertex)
			
			# Add triangles with smooth color transitions
			add_smooth_quad(surface_tool,
				top_left_vertex, top_right_vertex,
				bottom_left_vertex, bottom_right_vertex,
				top_left_uv, top_right_uv,
				bottom_left_uv, bottom_right_uv,
				top_left_color, top_right_color,
				bottom_left_color, bottom_right_color)
	
	surface_tool.generate_normals()
	surface_tool.generate_tangents()
	
	var array_mesh := ArrayMesh.new()
	surface_tool.commit(array_mesh)
	mesh = array_mesh
	
	# Apply material
	var shader := ShaderMaterial.new()
	shader.shader = load("res://shaders/terrain.gdshader")
	shader.set_shader_parameter("grassTexture", load("res://assets/grass.jpg"))
	shader.set_shader_parameter("rockTexture", load("res://assets/rock.jpg"))
	shader.set_shader_parameter("sandTexture", load("res://assets/sand.jpg"))
	shader.set_shader_parameter("lineThickness", 0.02)
	shader.set_shader_parameter("lineVisibility", 0.5 if grid else 0.0)
	mesh.surface_set_material(0, shader)

func smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func generate_collision() -> void:
	var collision_vertices = PackedVector3Array()
	
	for x in range(chunk_size):  # Note: chunk_size instead of chunk_size + 1
		for z in range(chunk_size):
			var coord_id := x * (chunk_size + 1) + z
			var top_left_vertex := coords[coord_id]
			var top_right_vertex := coords[coord_id + 1]
			var bottom_left_vertex := coords[coord_id + chunk_size + 1]
			var bottom_right_vertex := coords[coord_id + chunk_size + 2]
			
			# First triangle
			collision_vertices.append(bottom_left_vertex)
			collision_vertices.append(bottom_right_vertex)
			collision_vertices.append(top_left_vertex)
			
			# Second triangle
			collision_vertices.append(bottom_right_vertex)
			collision_vertices.append(top_right_vertex)
			collision_vertices.append(top_left_vertex)
	
	collision_shape.set_faces(collision_vertices)
