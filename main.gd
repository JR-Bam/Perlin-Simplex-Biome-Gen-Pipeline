@tool
extends Node

class_name WorldConfiguration

var terrain: MeshInstance3D
var mesh: ArrayMesh
@export var noise: Simplex
@export var fnoise: FastNoiseLite

@export_enum("Simplex", "FastNoiseLite") var noise_type: int = 0:
	set(_type):
		noise_type = _type
		generate_terrain()

@export_range(1, 100, 1) var subdivisions: int = 50:
	set(subdiv):
		subdivisions = subdiv
		generate_terrain()

@export_range(1, 1000, 1) var size: int = 500:
	set(_size):
		size = _size
		generate_terrain()

@export var amplitude = 100

func _ready() -> void:
	# Initialize Simplex here, not at parse time
	if noise == null:
		noise = Simplex.new()
	if fnoise == null:
		fnoise = FastNoiseLite.new()
	
	generate_terrain()

# ==============================================================
# Terrain Generation Logic (Toggleable Between Simplex and FNL)
# ==============================================================

func generate_terrain():
	# Ensure the node exists before assigning to it
	if not is_inside_tree() or terrain == null:
		terrain = get_node_or_null("Main") 
		if terrain == null: return
	
	# Make sure noise is initialized
	print("Terrain node check: Passed")
	if noise == null:
		noise = Simplex.new()
	if fnoise == null:
		fnoise = FastNoiseLite.new()
	
	# Update mesh properties
	#var plane = PlaneMesh.new()
	#plane.size = Vector2(size, size)
	#plane.subdivide_width = subdivisions
	#plane.subdivide_depth = subdivisions
	#
	#var data_tool = MeshDataTool.new()
	#var array_mesh = ArrayMesh.new()
	#array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())
	#data_tool.create_from_surface(array_mesh, 0)
	#
	#for i in range(data_tool.get_vertex_count()):
		#var vertex = data_tool.get_vertex(i)
		#var x = vertex.x
		#var z = vertex.z
		#
		#var base_height: float
		#if elevation_map != null:
			#var uv = Vector2(
				#(x + size / 2.0) / size,
				#(z + size / 2.0) / size
			#)
			#uv = uv.clamp(Vector2.ZERO, Vector2.ONE)
			#
			## Get the image from the texture and sample it to form ELEVATION
			#var image = elevation_map.get_image()
			#var pixel_x = int(uv.x * (image.get_width() - 1))
			#var pixel_y = int(uv.y * (image.get_height() - 1))
			#var color = image.get_pixel(pixel_x, pixel_y)
			#base_height = color.r * amplitude
			#
			## Apply EROSION if erosion map exists
			#if erosion_map != null:
				#var erosion_image = erosion_map.get_image()
				#var erosion_color = erosion_image.get_pixel(pixel_x, pixel_y)
				#var erosion_value = erosion_color.r
				#
				## Blend elevation with erosion (erosion flattens the terrain)
				#base_height = lerp(base_height, base_height * erosion_value, erosion_strength)
		#else:
			## Fallback to noise if no elevation map
			#if noise_type == 1:  # FastNoiseLite
				#base_height = fnoise.get_noise_2d(x, z) * amplitude
			#else:  # Simplex
				#base_height = noise.get_noise_2d(x, z) * amplitude
		#
		#vertex.y = base_height
		#data_tool.set_vertex(i, vertex)
		#
		#vertex.y = base_height
		#data_tool.set_vertex(i, vertex)
	#
	## Commit changes to mesh
	#array_mesh.clear_surfaces()
	#data_tool.commit_to_surface(array_mesh)
	#
	#var surface_tool = SurfaceTool.new()
	#surface_tool.create_from(array_mesh, 0)
	#surface_tool.generate_normals()
	#
	#surface_tool.get_primitive_type()
	#
	#mesh = surface_tool.commit()
	## IMPORTANT: Reassign the mesh to trigger the update
	#terrain.mesh = mesh
