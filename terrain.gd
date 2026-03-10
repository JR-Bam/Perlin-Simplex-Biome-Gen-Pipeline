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

# Add this signal
signal terrain_progress(percent: float, stage: String)

var Climate: ClimateData = load("res://Climate Maps/climate_data.tres")
var Elevation: ElevationData = load("res://Terrain Maps/elevation_data.tres")
var AssetNoiseMaps: AssetMaps = load("res://Asset Placement/asset_maps.tres")

var shader: Shader = load("res://terrain_painter.gdshader")
var water_material: ShaderMaterial = load("res://Asset Placement/water_mat.tres")

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
			
@export var global_visibility_distance: float = 100.0  # Global far distance

@onready var prop_scatterer: PropScatterer = $PropScatterer
@onready var water: MeshInstance3D = $Water
var execution_times = {}

func _ready() -> void:
	print("Terrain generating with noise: %d" % Config.noise_type)
	terrain = $MeshInstance3D
	mesh = ArrayMesh.new()
	terrain.mesh = mesh
	await generate_terrain_async()
	update_water()
	await prop_scatterer.test_biome_scatter()
	#Monitor.start_logging()

func generate_terrain_async():
	var start_time = Time.get_ticks_msec()
	if not is_inside_tree() or terrain == null:
		terrain = get_node_or_null("MeshInstance3D") 
		if terrain == null: return
	
	print("Terrain node check: Passed")
	terrain_progress.emit(0, "Starting terrain generation")
	
	var size := Config.size
	var subdivisions := Config.subdivisions
	var amplitude := Config.amplitude
	
	var step := size / float(subdivisions)
	var vertex_count_x := subdivisions + 1
	var vertex_count_z := subdivisions + 1
	var total_vertices := vertex_count_x * vertex_count_z
	var total_indices := subdivisions * subdivisions * 6
	
	var base_noise = get_base_noise()
	var erosion_noise = get_erosion_noise()
	
	base_noise.set_seed(Config.seed)
	erosion_noise.set_seed(Config.seed)
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate vertices with async breaks
	var vertex_gen_start = Time.get_ticks_msec()
	var total_rows = vertex_count_z
	for z in range(vertex_count_z):
		for x in range(vertex_count_x):
			var world_x := (x - subdivisions/2.0) * step
			var world_z := (z - subdivisions/2.0) * step
			
			var base_value := base_noise.get_noise_2d(world_x, world_z) as float
			var erosion_value := erosion_noise.get_noise_2d(world_x, world_z) as float
			
			if Config.noise_type != 0:
				base_value = base_value * 2.5  # empirical adjustment
			else:
				base_value = base_value * 1.4
			var height = combine_terrain(base_value, erosion_value, world_x, world_z, amplitude)
			
			var uv = Vector2(float(x) / subdivisions, float(z) / subdivisions)
			surface_tool.set_uv(uv)
			surface_tool.add_vertex(Vector3(world_x, height, world_z))
		
		# Update progress - vertex generation is about 20% of total work
		var progress = 10.0 + (float(z) / total_rows) * 15.0  # 10-25%
		terrain_progress.emit(progress, "Generating vertices")
		
		# Yield every few rows to prevent freezing
		if z % 10 == 0:
			await get_tree().process_frame
	
	execution_times["vertex_generation"] = Time.get_ticks_msec() - vertex_gen_start
	
	# Generate triangles
	var triangle_gen_start = Time.get_ticks_msec()
	var total_triangle_rows = subdivisions
	for z in range(subdivisions):
		for x in range(subdivisions):
			var i := z * vertex_count_x + x
			surface_tool.add_index(i)
			surface_tool.add_index(i + 1)
			surface_tool.add_index(i + vertex_count_x)
			
			surface_tool.add_index(i + 1)
			surface_tool.add_index(i + vertex_count_x + 1)
			surface_tool.add_index(i + vertex_count_x)
		
		# Update progress - triangle generation is about 15% of total work
		var progress = 25.0 + (float(z) / total_triangle_rows) * 15.0  # 25-40%
		terrain_progress.emit(progress, "Generating triangles")
		
		if z % 10 == 0:
			await get_tree().process_frame
	
	execution_times["triangle_generation"] = Time.get_ticks_msec() - triangle_gen_start
	
	# Generate normals and commit
	terrain_progress.emit(42, "Generating normals")
	surface_tool.generate_normals()
	mesh.clear_surfaces()
	surface_tool.commit(mesh)
	await get_tree().process_frame
	
	# Textureize (40% of total work)
	terrain_progress.emit(45, "Texturing terrain")
	var texture_start = Time.get_ticks_msec()
	await get_tree().process_frame
	await textureize(size)  # Make this async and track progress inside
	
	# Create collision (15% of total work)
	terrain_progress.emit(85, "Creating collision")
	var collision_start = Time.get_ticks_msec()
	await get_tree().process_frame
	create_collision()
	execution_times["collision_creation"] = Time.get_ticks_msec() - collision_start
	
	# Water update (will be called separately, but we'll log it there)
	
	# Complete
	execution_times["TOTAL"] = Time.get_ticks_msec() - start_time
	terrain_progress.emit(100, "Complete")
	print(Config.noise_type, " Terrain Generated")
	print("Execution times: ", execution_times)

# Modified textureize to be async and emit progress
func textureize(size):
	var times = {}
	var section_start
	
	# Temperature texture (10% of texturization work)
	section_start = Time.get_ticks_msec()
	print("Generate Temperature Texture")
	terrain_progress.emit(47, "Generating temperature map")
	var temperature = Helpers._noise_to_texture(size, 
		SimplexTexture.new() if Config.noise_type == 0 else NoiseTexture2D.new(), 
		Climate.temperature_simplex if Config.noise_type == 0 else Climate.temperature_perlin
	)
	await _wait_for_texture(temperature)
	times["temperature_texture"] = Time.get_ticks_msec() - section_start
	
	# Precipitation texture (10% of texturization work)
	section_start = Time.get_ticks_msec()
	print("Generate Precipitation Texture")
	terrain_progress.emit(57, "Generating precipitation map")
	var precipitation = Helpers._noise_to_texture(size, 
		SimplexTexture.new() if Config.noise_type == 0 else NoiseTexture2D.new(), 
		Climate.precipitation_simplex if Config.noise_type == 0 else Climate.precipitation_perlin
	)
	await _wait_for_texture(precipitation)
	times["precipitation_texture"] = Time.get_ticks_msec() - section_start
	
	# Humidity texture (10% of texturization work)
	section_start = Time.get_ticks_msec()
	print("Generate Humidity Texture")
	terrain_progress.emit(67, "Generating humidity map")
	var humidity = Helpers._noise_to_texture(size, 
		SimplexTexture.new() if Config.noise_type == 0 else NoiseTexture2D.new(), 
		Climate.humidity_simplex if Config.noise_type == 0 else Climate.humidity_perlin
	)
	await _wait_for_texture(humidity)
	times["humidity_texture"] = Time.get_ticks_msec() - section_start
	
	# Shader material creation (5% of texturization work)
	section_start = Time.get_ticks_msec()
	print("Creating shader material")
	terrain_progress.emit(77, "Creating shader material")
	var shadermat := ShaderMaterial.new()
	shadermat.shader = shader
	shadermat.set_shader_parameter("temperature_map", temperature)
	shadermat.set_shader_parameter("precipitation_map", precipitation)
	shadermat.set_shader_parameter("humidity_map", humidity)
	shadermat.set_shader_parameter("max_height", Config.amplitude)
	
	Helpers._set_biome_thresholds(shadermat, Config)
	setup_biome_textures(shadermat)
	times["shader_creation"] = Time.get_ticks_msec() - section_start
	
	# Apply material (5% of texturization work)
	section_start = Time.get_ticks_msec()
	terrain_progress.emit(82, "Applying material")
	terrain.set_surface_override_material(0, shadermat)
	times["apply_material"] = Time.get_ticks_msec() - section_start
	
	# Calculate total
	var total = 0
	for key in times:
		total += times[key]
	times["total_texturization"] = total
	
	execution_times["texturization"] = times

# Helper function to wait for a texture to generate
func _wait_for_texture(texture: Texture2D):
	while texture.get_image() == null or texture.get_image().is_empty():
		await get_tree().process_frame

# Texture Setup for Shader
func setup_biome_textures(shader_material: ShaderMaterial):
	var biome_names = ["ocean", "desert", "grassland", "savanna", "tundra", "boreal_forest", "temperate_forest", "rainforest", "mountain", "woodland"]
	
	for i in range(biome_names.size()):
		var biome = biome_names[i]
		var texture_path = "res://Assets/Materials/" + biome + ".tres"
		var texture = load(texture_path) as Texture2D
		
		if texture:
			shader_material.set_shader_parameter(biome + "_texture", texture)
			print("Loaded texture for: ", biome)
		else:
			print("WARNING: Could not load texture for: ", biome, " from ", texture_path)
		
		# Optional: emit progress for biome texture loading
		# terrain_progress.emit(82.0 + (float(i) / biome_names.size()) * 3.0, "Loading biome textures")

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

func regenerate():
	print("Regenerating terrain with method: ", CombinationMethod.keys()[combination_method])
	terrain_progress.emit(0, "Regenerating terrain")
	await generate_terrain_async()
	update_water()
	prop_scatterer.test_biome_scatter()


func update_water():
	var water_start_time = Time.get_ticks_msec()
	var water_times = {}
	
	if not water.mesh: 
		execution_times["water_update"] = {"error": "No water mesh"}
		return
	
	# Mesh configuration
	var mesh_config_start = Time.get_ticks_msec()
	water.mesh.size = Vector3(Config.size, Config.amplitude / 2, Config.size)
	water.global_position = Vector3(0, (Config.ocean_e_max - 1) * Config.amplitude, 0)
	water.mesh.subdivide_width = Config.subdivisions
	water.mesh.subdivide_depth = Config.subdivisions
	water_times["mesh_configuration"] = Time.get_ticks_msec() - mesh_config_start
	
	# Refraction texture creation (including noise retrieval)
	var refraction_start = Time.get_ticks_msec()
	var refraction_noise = AssetNoiseMaps.water_refraction_simplex if Config.noise_type == 0 else AssetNoiseMaps.water_refraction_perlin
	refraction_noise.set_seed(Config.seed)
	var refraction_texture = SimplexTexture.new() if Config.noise_type == 0 else NoiseTexture2D.new()
	refraction_texture.set_noise(refraction_noise)
	refraction_texture.set_seamless(true)
	water_times["refraction_texture"] = Time.get_ticks_msec() - refraction_start
	
	# Normal texture creation (including noise retrieval)
	var normal_start = Time.get_ticks_msec()
	var normal_noise = AssetNoiseMaps.water_normal_simplex if Config.noise_type == 0 else AssetNoiseMaps.water_normal_perlin
	normal_noise.set_seed(Config.seed)
	var normal_texture = SimplexTexture.new() if Config.noise_type == 0 else NoiseTexture2D.new()
	normal_texture.set_noise(normal_noise)
	normal_texture.set_seamless(true)
	normal_texture.set_as_normal_map(true)
	normal_texture.set_in_3d_space(true)
	water_times["normal_texture"] = Time.get_ticks_msec() - normal_start
	
	# Wait for textures to generate
	var texture_wait_start = Time.get_ticks_msec()
	await _wait_for_texture(refraction_texture)
	await _wait_for_texture(normal_texture)
	water_times["texture_generation_wait"] = Time.get_ticks_msec() - texture_wait_start
	
	# Shader parameter application
	var shader_apply_start = Time.get_ticks_msec()
	water_material.set_shader_parameter("texture_refraction", refraction_texture)
	water_material.set_shader_parameter("texture_normal", normal_texture)
	
	water.mesh.material = water_material
	water_times["shader_application"] = Time.get_ticks_msec() - shader_apply_start
	
	# Calculate total water update time
	water_times["total_water_update"] = Time.get_ticks_msec() - water_start_time
	
	# Add to main execution_times dictionary
	execution_times["water_update"] = water_times
	
	print("Water update times: ", water_times)

func get_base_noise() -> Variant:
	return Elevation.base_simplex if Config.noise_type == 0 else Elevation.base_perlin

func get_erosion_noise() -> Variant:
	return Elevation.erosion_simplex if Config.noise_type == 0 else Elevation.erosion_perlin
