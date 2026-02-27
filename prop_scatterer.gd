@tool
extends Node3D

class_name BiomeScatterer

var Config: WorldConfigResource = load("res://world_config.tres")

# Prop data structure
class BiomeProp:
	var scene_path: String
	var proportionality: float = 1.0
	
	func _init(p_path: String, p_proportionality: float = 1.0):
		scene_path = p_path
		proportionality = p_proportionality

@export var terrain_mesh: MeshInstance3D
@export var water_mesh: MeshInstance3D
@export var terrain_size: int = Config.size
@export var grid_spacing: float = 10.0
@export var base_spawn_density: float = 0.2

# Variance for natural placement
@export var position_variance: float = 2.0  # Units of variance in X/Z
@export var height_variance: float = 0.5    # Units of variance in Y
@export var rotation_variance: float = 0.3  # Radians of variance
@export var scale_variance: float = 0.1     # Percentage variance (0.1 = 10%)

# Boreal forest props
@export var boreal_forest_props: Array[Dictionary] = [
	{"scene_path": "res://addons/proton_scatter/demos/assets/pine_tree.tscn", "proportionality": 0.7},
]

@export var test_spawn: bool = false:
	set(_val):
		if _val:
			test_biome_scatter()

# Boreal forest thresholds
var boreal_forest_t_min = Config.boreal_forest_t_min
var boreal_forest_t_max = Config.boreal_forest_t_max
var boreal_forest_e_min = Config.boreal_forest_e_min
var boreal_forest_e_max = Config.boreal_forest_e_max
var boreal_forest_p_min = Config.boreal_forest_p_min
var boreal_forest_p_max = Config.boreal_forest_p_max

func test_biome_scatter():
	# Clear previous assets
	var old_container = get_node_or_null("BoreaForestScatter")
	if old_container:
		old_container.queue_free()
		print("Cleared previous boreal forest scatter")
	
	if not terrain_mesh:
		print("ERROR: No terrain mesh assigned!")
		return
	
	if not water_mesh:
		print("ERROR: No water mesh assigned!")
		return
	
	print("=== Scattering Boreal Forest Assets ===")
	
	var scatter_container = Node3D.new()
	scatter_container.name = "BoreaForestScatter"
	add_child(scatter_container)
	
	var shader_material = terrain_mesh.get_surface_override_material(0)
	if not shader_material:
		print("ERROR: No shader material!")
		return
	
	var water_top = water_mesh.global_position.y + (water_mesh.mesh.get_aabb().size.y / 2.0)
	
	# Load all prop scenes
	var loaded_props = []
	for prop_data in boreal_forest_props:
		var scene = load(prop_data["scene_path"])
		if scene:
			loaded_props.append({
				"scene": scene,
				"proportionality": prop_data["proportionality"]
			})
		else:
			print("WARNING: Could not load scene: ", prop_data["scene_path"])
	
	if loaded_props.is_empty():
		print("ERROR: No valid props loaded!")
		return
	
	# Calculate total proportionality for weighted selection
	var total_proportionality = 0.0
	for prop in loaded_props:
		total_proportionality += prop["proportionality"]
	
	var spawned_count = 0
	var boreal_count = 0
	var water_blocked = 0
	
	# Generate grid across terrain
	var x = -terrain_size / 2.0
	while x < terrain_size / 2.0:
		var z = -terrain_size / 2.0
		while z < terrain_size / 2.0:
			if is_boreal_forest(x, z, shader_material):
				boreal_count += 1
				
				if randf() < base_spawn_density:
					var height = sample_terrain_height(x, z)
					
					if height <= water_top:
						water_blocked += 1
					else:
						# Select random prop based on proportionality
						var selected_prop = select_weighted_prop(loaded_props, total_proportionality)
						
						# Apply variance
						var final_pos = Vector3(x, height, z)
						final_pos.x += randf_range(-position_variance, position_variance)
						final_pos.y += randf_range(-height_variance, height_variance)
						final_pos.z += randf_range(-position_variance, position_variance)
						
						var asset = selected_prop["scene"].instantiate()
						asset.position = final_pos
						
						# Random rotation with variance
						asset.rotation.y = randf() * TAU + randf_range(-rotation_variance, rotation_variance)
						asset.rotation.x = randf_range(-rotation_variance, rotation_variance)
						asset.rotation.z = randf_range(-rotation_variance, rotation_variance)
						
						# Random scale with variance
						var scale_factor = 1.0 + randf_range(-scale_variance, scale_variance)
						asset.scale = Vector3.ONE * scale_factor
						
						scatter_container.add_child(asset)
						spawned_count += 1
			z += grid_spacing
		x += grid_spacing
	
	print("Found ", boreal_count, " boreal forest grid points")
	print("Blocked ", water_blocked, " assets from spawning underwater")
	print("✓ Spawned ", spawned_count, " assets in boreal forest!")

func select_weighted_prop(props: Array, total_proportionality: float) -> Dictionary:
	var random_value = randf() * total_proportionality
	var cumulative = 0.0
	
	for prop in props:
		cumulative += prop["proportionality"]
		if random_value <= cumulative:
			return prop
	
	return props[0]  # Fallback

func is_boreal_forest(x: float, z: float, shader_material: Material) -> bool:
	var shader_mat = shader_material as ShaderMaterial
	if not shader_mat:
		return false
	
	var uv = Vector2(
		(x + terrain_size / 2.0) / terrain_size,
		(z + terrain_size / 2.0) / terrain_size
	)
	uv = uv.clamp(Vector2.ZERO, Vector2.ONE)
	
	var temperature_tex = shader_mat.get_shader_parameter("temperature_map") as Texture2D
	var elevation_tex = shader_mat.get_shader_parameter("elevation_map") as Texture2D
	var precipitation_tex = shader_mat.get_shader_parameter("precipitation_map") as Texture2D
	
	if not temperature_tex or not elevation_tex or not precipitation_tex:
		return false
	
	var temp_img = temperature_tex.get_image()
	var elev_img = elevation_tex.get_image()
	var precip_img = precipitation_tex.get_image()
	
	var temp_pixel_x = int(uv.x * temp_img.get_width())
	var temp_pixel_y = int(uv.y * temp_img.get_height())
	var temperature = temp_img.get_pixel(temp_pixel_x, temp_pixel_y).r
	
	var elev_pixel_x = int(uv.x * elev_img.get_width())
	var elev_pixel_y = int(uv.y * elev_img.get_height())
	var elevation = elev_img.get_pixel(elev_pixel_x, elev_pixel_y).r
	
	var precip_pixel_x = int(uv.x * precip_img.get_width())
	var precip_pixel_y = int(uv.y * precip_img.get_height())
	var precipitation = precip_img.get_pixel(precip_pixel_x, precip_pixel_y).r
	
	var in_temp = temperature >= boreal_forest_t_min and temperature <= boreal_forest_t_max
	var in_elev = elevation >= boreal_forest_e_min and elevation <= boreal_forest_e_max
	var in_precip = precipitation >= boreal_forest_p_min and precipitation <= boreal_forest_p_max
	
	return in_temp and in_elev and in_precip

func sample_terrain_height(x: float, z: float) -> float:
	if not is_inside_tree():
		return 0.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		Vector3(x, 500, z),
		Vector3(x, -500, z)
	)
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position.y
	
	return 0.0
