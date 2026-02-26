@tool
extends Node3D

class_name Terrain

enum CombinationMethod {
	SIMPLE_SUBTRACTION,      # Erosion simply subtracts from elevation
	SLOPE_BASED,             # Erosion affects lower areas more
	DETAIL_ADDITION,         # Erosion adds/subtracts fine detail
	WEIGHTED_BLEND,          # Weighted average of both noises
	MULTIPLICATIVE,          # Erosion scales elevation
	TERRACES,                # Erosion creates terrace effects
	RIDGES                   # Erosion emphasizes ridges
}

var Climate: ClimateData = load("res://Climate Maps/climate_data.tres")
var Elevation: ElevationData = load("res://Terrain Maps/elevation_data.tres")

var shader: Shader = load("res://terrain_painter.gdshader")

var terrain: MeshInstance3D
var mesh: ArrayMesh

@export var Config: WorldConfigResource = load("res://world_config.tres")

@export var combination_method: CombinationMethod = CombinationMethod.SLOPE_BASED

@export var erosion_strength: float = 0.4

@export var blend_weight: float = 0.7

@export var terrace_count: int = 5

@export var update = true:
	set(value):
		update = value
		if Engine.is_editor_hint() or is_inside_tree():
			regenerate()

func _ready() -> void:
	terrain = $MeshInstance3D
	mesh = ArrayMesh.new()
	terrain.mesh = mesh
	generate_terrain()

func generate_terrain():
	if not is_inside_tree() or terrain == null:
		terrain = get_node_or_null("MeshInstance3D") 
		if terrain == null: return
	
	print("Terrain node check: Passed")
	
	# Get configuration values
	var size := Config.size
	var subdivisions := Config.subdivisions
	var amplitude := Config.amplitude
	
	# Calculate grid parameters
	var step := size / float(subdivisions)
	var vertex_count_x := subdivisions + 1
	var vertex_count_z := subdivisions + 1
	var total_vertices := vertex_count_x * vertex_count_z
	var total_indices := subdivisions * subdivisions * 6
	
	# Get noise instances
	var base_noise = get_base_noise()
	var erosion_noise = get_erosion_noise()
	
	# METHOD 1: Using MeshDataTool (Cleaner approach)
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate vertices
	for z in range(vertex_count_z):
		for x in range(vertex_count_x):
			var world_x := (x - subdivisions/2.0) * step
			var world_z := (z - subdivisions/2.0) * step
			
			# Sample noise
			var base_value := base_noise.get_noise_2d(world_x, world_z) as float
			var erosion_value := erosion_noise.get_noise_2d(world_x, world_z) as float
			
			# Calculate height
			var height = combine_terrain(base_value, erosion_value, world_x, world_z, amplitude)
			
			# Set UV
			var uv = Vector2(float(x) / subdivisions, float(z) / subdivisions)
			
			# Add vertex with SurfaceTool
			surface_tool.set_uv(uv)
			surface_tool.add_vertex(Vector3(world_x, height, world_z))
	
	# Generate triangles
	for z in range(subdivisions):
		for x in range(subdivisions):
			var i := z * vertex_count_x + x
			
			# Add two triangles
			surface_tool.add_index(i)
			surface_tool.add_index(i + 1)
			surface_tool.add_index(i + vertex_count_x)
			
			surface_tool.add_index(i + 1)
			surface_tool.add_index(i + vertex_count_x + 1)
			surface_tool.add_index(i + vertex_count_x)
	
	# Generate normals and commit mesh
	surface_tool.generate_normals()
	
	# Clear old mesh and add new surface
	mesh.clear_surfaces()
	surface_tool.commit(mesh)
	
	# Optional: Generate collision
	textureize(size)
	create_collision()
	
	print(Config.noise_type, " Terrain Generated")
	print("Terrain generated with ", total_vertices, " vertices using method: ", CombinationMethod.keys()[combination_method])


func combine_terrain(base_value: float, erosion_value: float, x: float, z: float, amplitude: float) -> float:
	match combination_method:
		CombinationMethod.SIMPLE_SUBTRACTION:
			return base_value * amplitude - erosion_value * (amplitude * erosion_strength)
			
		CombinationMethod.SLOPE_BASED:
			var erosion_factor = clamp((base_value + 1.0) / 2.0, 0.0, 1.0)
			erosion_factor = 1.0 - erosion_factor
			return base_value * amplitude - erosion_value * (amplitude * erosion_strength * erosion_factor)
			
		CombinationMethod.DETAIL_ADDITION:
			var base_height = base_value * amplitude
			var erosion_detail = (erosion_value) * (amplitude * erosion_strength * 0.3)
			return base_height + erosion_detail
			
		CombinationMethod.WEIGHTED_BLEND:
			var combined_noise = base_value * blend_weight + erosion_value * (1.0 - blend_weight)
			return combined_noise * amplitude
			
		CombinationMethod.MULTIPLICATIVE:
			var erosion_factor = 1.0 - (erosion_value + 1.0) / 2.0 * erosion_strength
			return base_value * amplitude * erosion_factor
			
		CombinationMethod.TERRACES:
			var base_height = base_value * amplitude
			var terrace_height = floor(base_height / (amplitude / terrace_count)) * (amplitude / terrace_count)
			var erosion_influence = erosion_value * erosion_strength * (amplitude / terrace_count * 0.5)
			return terrace_height + erosion_influence
			
		CombinationMethod.RIDGES:
			var ridge_mask = abs(base_value)
			var ridge_height = ridge_mask * amplitude
			var erosion_influence = erosion_value * erosion_strength * amplitude * 0.2
			return ridge_height + erosion_influence
	
	return base_value * amplitude

func create_collision():
	var static_body = get_node_or_null("StaticBody3D")
	if not static_body:
		static_body = StaticBody3D.new()
		static_body.name = "StaticBody3D"
		add_child(static_body)
	
	var collision = static_body.get_node_or_null("CollisionShape3D")
	if not collision:
		collision = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		static_body.add_child(collision)
	
	var collision_shape = mesh.create_trimesh_shape()
	collision.shape = collision_shape
	static_body.position = terrain.position

func textureize(size):
	var elevation = _combine_elevation_with_erosion(size, get_base_noise(), get_erosion_noise())
	var temperature = _noise_to_texture(size, 
		SimplexTexture.new() if Config.noise_type == 0 else NoiseTexture2D.new(), 
		Climate.temperature_simplex if Config.noise_type == 0 else Climate.temperature_perlin
	)
	var precipitation = _noise_to_texture(size, 
		SimplexTexture.new() if Config.noise_type == 0 else NoiseTexture2D.new(), 
		Climate.precipitation_simplex if Config.noise_type == 0 else Climate.precipitation_perlin
	)
	var humidity = _noise_to_texture(size, 
		SimplexTexture.new() if Config.noise_type == 0 else NoiseTexture2D.new(), 
		Climate.humidity_simplex if Config.noise_type == 0 else Climate.humidity_perlin
	)
	
	var shadermat := ShaderMaterial.new()
	shadermat.shader = shader
	shadermat.set_shader_parameter("elevation_map", elevation)
	shadermat.set_shader_parameter("temperature_map", temperature)
	shadermat.set_shader_parameter("precipitation_map", precipitation)
	shadermat.set_shader_parameter("humidity_map", humidity)
	shadermat.set_shader_parameter("max_height", Config.amplitude)
	
	_set_biome_thresholds(shadermat, Config)
	
	terrain.set_surface_override_material(0, shadermat)


func _combine_elevation_with_erosion(size: int, base_noise, erosion_noise) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RF)
	
	# Use the same step and offset as in generate_terrain()
	var step = Config.size / float(Config.subdivisions)
	var half_size = Config.size / 2.0

	for x in range(size):
		for y in range(size):
			# Map pixel to world coordinates (x → world_x, y → world_z)
			var world_x = (x - Config.subdivisions / 2.0) * step
			var world_z = (y - Config.subdivisions / 2.0) * step

			# Get raw noise values (range -1..1)
			var base_val = base_noise.get_noise_2d(world_x, world_z)
			var erosion_val = erosion_noise.get_noise_2d(world_x, world_z)

			# Combine using the same method and parameters as the terrain
			var height = combine_terrain(
				base_val,
				erosion_val,
				world_x,
				world_z,
				Config.amplitude
			)

			# Normalize to 0..1 for the texture
			var normalized = (height + Config.amplitude) / (2.0 * Config.amplitude)
			normalized = clamp(normalized, 0.0, 1.0)
			image.set_pixel(x, y, Color(normalized, normalized, normalized))

	return ImageTexture.create_from_image(image)

func _noise_to_texture(size, texture, noise):
	texture.set_width(size)
	texture.set_height(size)
	texture.set_noise(noise)
	return texture

func _set_biome_thresholds(shader_material: ShaderMaterial, config: WorldConfigResource):
	# Ocean Thresholds
	shader_material.set_shader_parameter("ocean_e_min", config.ocean_e_min)
	shader_material.set_shader_parameter("ocean_e_max", config.ocean_e_max)
	shader_material.set_shader_parameter("ocean_t_min", config.ocean_t_min)
	shader_material.set_shader_parameter("ocean_t_max", config.ocean_t_max)
	shader_material.set_shader_parameter("ocean_p_min", config.ocean_p_min)
	shader_material.set_shader_parameter("ocean_p_max", config.ocean_p_max)
	shader_material.set_shader_parameter("ocean_h_min", config.ocean_h_min)
	shader_material.set_shader_parameter("ocean_h_max", config.ocean_h_max)
	
	# Desert Thresholds
	shader_material.set_shader_parameter("desert_e_min", config.desert_e_min)
	shader_material.set_shader_parameter("desert_e_max", config.desert_e_max)
	shader_material.set_shader_parameter("desert_t_min", config.desert_t_min)
	shader_material.set_shader_parameter("desert_t_max", config.desert_t_max)
	shader_material.set_shader_parameter("desert_p_min", config.desert_p_min)
	shader_material.set_shader_parameter("desert_p_max", config.desert_p_max)
	shader_material.set_shader_parameter("desert_h_min", config.desert_h_min)
	shader_material.set_shader_parameter("desert_h_max", config.desert_h_max)
	
	# Grassland Thresholds
	shader_material.set_shader_parameter("grassland_e_min", config.grassland_e_min)
	shader_material.set_shader_parameter("grassland_e_max", config.grassland_e_max)
	shader_material.set_shader_parameter("grassland_t_min", config.grassland_t_min)
	shader_material.set_shader_parameter("grassland_t_max", config.grassland_t_max)
	shader_material.set_shader_parameter("grassland_p_min", config.grassland_p_min)
	shader_material.set_shader_parameter("grassland_p_max", config.grassland_p_max)
	shader_material.set_shader_parameter("grassland_h_min", config.grassland_h_min)
	shader_material.set_shader_parameter("grassland_h_max", config.grassland_h_max)
	
	# Savanna Thresholds
	shader_material.set_shader_parameter("savanna_e_min", config.savanna_e_min)
	shader_material.set_shader_parameter("savanna_e_max", config.savanna_e_max)
	shader_material.set_shader_parameter("savanna_t_min", config.savanna_t_min)
	shader_material.set_shader_parameter("savanna_t_max", config.savanna_t_max)
	shader_material.set_shader_parameter("savanna_p_min", config.savanna_p_min)
	shader_material.set_shader_parameter("savanna_p_max", config.savanna_p_max)
	shader_material.set_shader_parameter("savanna_h_min", config.savanna_h_min)
	shader_material.set_shader_parameter("savanna_h_max", config.savanna_h_max)
	
	# Tundra Thresholds
	shader_material.set_shader_parameter("tundra_e_min", config.tundra_e_min)
	shader_material.set_shader_parameter("tundra_e_max", config.tundra_e_max)
	shader_material.set_shader_parameter("tundra_t_min", config.tundra_t_min)
	shader_material.set_shader_parameter("tundra_t_max", config.tundra_t_max)
	shader_material.set_shader_parameter("tundra_p_min", config.tundra_p_min)
	shader_material.set_shader_parameter("tundra_p_max", config.tundra_p_max)
	shader_material.set_shader_parameter("tundra_h_min", config.tundra_h_min)
	shader_material.set_shader_parameter("tundra_h_max", config.tundra_h_max)
	
	# Boreal Forest Thresholds
	shader_material.set_shader_parameter("boreal_forest_e_min", config.boreal_forest_e_min)
	shader_material.set_shader_parameter("boreal_forest_e_max", config.boreal_forest_e_max)
	shader_material.set_shader_parameter("boreal_forest_t_min", config.boreal_forest_t_min)
	shader_material.set_shader_parameter("boreal_forest_t_max", config.boreal_forest_t_max)
	shader_material.set_shader_parameter("boreal_forest_p_min", config.boreal_forest_p_min)
	shader_material.set_shader_parameter("boreal_forest_p_max", config.boreal_forest_p_max)
	shader_material.set_shader_parameter("boreal_forest_h_min", config.boreal_forest_h_min)
	shader_material.set_shader_parameter("boreal_forest_h_max", config.boreal_forest_h_max)
	
	# Temperate Forest Thresholds
	shader_material.set_shader_parameter("temperate_forest_e_min", config.temperate_forest_e_min)
	shader_material.set_shader_parameter("temperate_forest_e_max", config.temperate_forest_e_max)
	shader_material.set_shader_parameter("temperate_forest_t_min", config.temperate_forest_t_min)
	shader_material.set_shader_parameter("temperate_forest_t_max", config.temperate_forest_t_max)
	shader_material.set_shader_parameter("temperate_forest_p_min", config.temperate_forest_p_min)
	shader_material.set_shader_parameter("temperate_forest_p_max", config.temperate_forest_p_max)
	shader_material.set_shader_parameter("temperate_forest_h_min", config.temperate_forest_h_min)
	shader_material.set_shader_parameter("temperate_forest_h_max", config.temperate_forest_h_max)
	
	# Rainforest Thresholds
	shader_material.set_shader_parameter("rainforest_e_min", config.rainforest_e_min)
	shader_material.set_shader_parameter("rainforest_e_max", config.rainforest_e_max)
	shader_material.set_shader_parameter("rainforest_t_min", config.rainforest_t_min)
	shader_material.set_shader_parameter("rainforest_t_max", config.rainforest_t_max)
	shader_material.set_shader_parameter("rainforest_p_min", config.rainforest_p_min)
	shader_material.set_shader_parameter("rainforest_p_max", config.rainforest_p_max)
	shader_material.set_shader_parameter("rainforest_h_min", config.rainforest_h_min)
	shader_material.set_shader_parameter("rainforest_h_max", config.rainforest_h_max)
	
	# Mountain Thresholds
	shader_material.set_shader_parameter("mountain_e_min", config.mountain_e_min)
	shader_material.set_shader_parameter("mountain_e_max", config.mountain_e_max)
	shader_material.set_shader_parameter("mountain_t_min", config.mountain_t_min)
	shader_material.set_shader_parameter("mountain_t_max", config.mountain_t_max)
	shader_material.set_shader_parameter("mountain_p_min", config.mountain_p_min)
	shader_material.set_shader_parameter("mountain_p_max", config.mountain_p_max)
	shader_material.set_shader_parameter("mountain_h_min", config.mountain_h_min)
	shader_material.set_shader_parameter("mountain_h_max", config.mountain_h_max)
	
	# Alpine Tundra Thresholds
	shader_material.set_shader_parameter("alpine_tundra_e_min", config.alpine_tundra_e_min)
	shader_material.set_shader_parameter("alpine_tundra_e_max", config.alpine_tundra_e_max)
	shader_material.set_shader_parameter("alpine_tundra_t_min", config.alpine_tundra_t_min)
	shader_material.set_shader_parameter("alpine_tundra_t_max", config.alpine_tundra_t_max)
	shader_material.set_shader_parameter("alpine_tundra_p_min", config.alpine_tundra_p_min)
	shader_material.set_shader_parameter("alpine_tundra_p_max", config.alpine_tundra_p_max)
	shader_material.set_shader_parameter("alpine_tundra_h_min", config.alpine_tundra_h_min)
	shader_material.set_shader_parameter("alpine_tundra_h_max", config.alpine_tundra_h_max)
	
	shader_material.set_shader_parameter("blend_radius", config.blend_radius)


func regenerate():
	print("Regenerating terrain with method: ", CombinationMethod.keys()[combination_method])
	if mesh:
		mesh.clear_surfaces()
	generate_terrain()

func get_base_noise() -> Variant:
	return Elevation.base_simplex if Config.noise_type == 0 else Elevation.base_perlin

func get_erosion_noise() -> Variant:
	return Elevation.erosion_simplex if Config.noise_type == 0 else Elevation.erosion_perlin
