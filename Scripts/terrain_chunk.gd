extends MeshInstance3D

var chunk_position := Vector2i.ZERO
var chunk_size := 32
var chunk_manager : Node = null
var smooth : bool = true
var grid : bool = false

var coords : Array[Vector3] = []
var static_body : StaticBody3D
var collision_shape : ConcavePolygonShape3D

func _ready() -> void:
	# Create physics body and collision
	static_body = StaticBody3D.new()
	add_child(static_body)
	
	collision_shape = ConcavePolygonShape3D.new()
	
	var collision_node = CollisionShape3D.new()
	collision_node.shape = collision_shape
	static_body.add_child(collision_node)

func generate() -> void:
	coords.resize((chunk_size + 1) * (chunk_size + 1))
	
	# Calculate world space offset for this chunk
	var world_offset_x = chunk_position.x * chunk_size
	var world_offset_z = chunk_position.y * chunk_size
	
	# Generate vertices with overlapping edges
	for x in range(chunk_size + 1):
		for z in range(chunk_size + 1):
			var world_x = x + world_offset_x
			var world_z = z + world_offset_z
			
			var y = chunk_manager.get_chunk_height(world_x, world_z)
			coords[x * (chunk_size + 1) + z] = Vector3(x, y, z)
	
	generate_mesh()
	generate_collision()

func generate_mesh() -> void:
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var uv_scale = 0.1  # Adjust this to control texture tiling
	
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

func calculate_vertex_color(vertex: Vector3) -> Color:
	# Height thresholds
	var water_level = -2.0      # Pure sand below this
	var sand_blend = -1.9       # Very narrow sand blend zone
	var rock_level = 1.0        # Rock starts
	
	var height = vertex.y
	
	if height > rock_level:
		# Rock terrain (RED in your setup)
		return Color.RED
	elif height < water_level:
		# Sand near water (GREEN in your setup)
		return Color.GREEN
	elif height < sand_blend:
		# Very narrow sand blend band
		var t = smoothstep(water_level, sand_blend, height)
		return Color.GREEN.lerp(Color.BLACK, t)
	else:
		# Default grass (BLACK in your setup)
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
