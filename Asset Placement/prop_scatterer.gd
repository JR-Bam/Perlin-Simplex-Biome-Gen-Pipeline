@tool
extends Node3D

class_name PropScatterer

var Config: WorldConfigResource = load("res://world_config.tres")
var temp_img: Image
var hum_img: Image
var precip_img: Image

@export var terrain_mesh: MeshInstance3D
@export var water_mesh: MeshInstance3D
@export var terrain_size: int = Config.size
@export var grid_spacing: float = 10.0
@export var base_spawn_density: float = 0.2
@export var boundary_margin: float = 0.1

# Variance for natural placement
@export var position_variance: float = 2.0
@export var height_variance: float = 0.5
@export var rotation_variance: float = 0.3
@export var scale_variance: float = 0.1

# Boreal forest props - now using Resource array
@export var boreal_forest_props: Array[BiomePropData] = []

@export var test_spawn: bool = false:
	set(_val):
		if _val:
			test_biome_scatter()

# Boreal forest thresholds
var boreal_forest_t_min = Config.boreal_forest_t_min
var boreal_forest_t_max = Config.boreal_forest_t_max
var boreal_forest_h_min = Config.boreal_forest_h_min
var boreal_forest_h_max = Config.boreal_forest_h_max
var boreal_forest_p_min = Config.boreal_forest_p_min
var boreal_forest_p_max = Config.boreal_forest_p_max

func test_biome_scatter():
	# Clear previous assets
	var old_container = get_node_or_null("BorealForestScatter")
	if old_container:
		old_container.queue_free()
		print("Cleared previous boreal forest scatter")
		await get_tree().process_frame
	
	if not terrain_mesh:
		print("ERROR: No terrain mesh assigned!")
		return
	
	if not water_mesh:
		print("ERROR: No water mesh assigned!")
		return
	
	if boreal_forest_props.is_empty():
		print("ERROR: No boreal forest props assigned!")
		return
	
	print("=== Scattering Boreal Forest Assets ===")
	
	var scatter_container = Node3D.new()
	scatter_container.name = "BorealForestScatter"
	add_child(scatter_container)
	
	var shader_material = terrain_mesh.get_surface_override_material(0)
	if not shader_material:
		print("ERROR: No shader material!")
		return
	
	var water_top = water_mesh.global_position.y + (water_mesh.mesh.get_aabb().size.y / 2.0)
	
	# Load all prop scenes
	var loaded_props = []
	for prop_data in boreal_forest_props:
		if not prop_data.scene:
			print("WARNING: Prop has no scene assigned!")
			continue
		loaded_props.append({
			"scene": prop_data.scene,
			"proportionality": prop_data.proportionality
		})
	
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
	
	var shader_mat = shader_material as ShaderMaterial
		
	var temperature_tex = shader_mat.get_shader_parameter("temperature_map") as Texture2D
	var humidity_tex = shader_mat.get_shader_parameter("humidity_map") as Texture2D
	var precipitation_tex = shader_mat.get_shader_parameter("precipitation_map") as Texture2D
	
	temp_img = temperature_tex.get_image()
	hum_img = humidity_tex.get_image()
	precip_img = precipitation_tex.get_image()
	
	if not temp_img or temp_img.is_empty():
		print("ERROR: Temperature image is invalid!")
		return
	if not hum_img or hum_img.is_empty():
		print("ERROR: Humidity image is invalid!")
		return
	if not precip_img or precip_img.is_empty():
		print("ERROR: Precipitation image is invalid!")
		return
	
	# Dictionary to store transforms for each prop type
	var prop_instances: Dictionary = {}  # scene_path -> array of transforms
	
	# Generate grid across terrain - constrain within bounds
	var max_offset = terrain_size / 2.0 - (grid_spacing * boundary_margin)
	var x = -max_offset
	while x < max_offset:
		var z = -max_offset
		while z < max_offset:
			if is_boreal_forest(x, z):
				boreal_count += 1
				
				if randf() < base_spawn_density:
					# Apply XZ variance to offset from grid
					var varied_x = x + randf_range(-position_variance, position_variance)
					var varied_z = z + randf_range(-position_variance, position_variance)
					
					# Clamp to terrain bounds
					varied_x = clamp(varied_x, -max_offset, max_offset)
					varied_z = clamp(varied_z, -max_offset, max_offset)
					
					var height = sample_terrain_height(varied_x, varied_z)
					
					if height <= water_top:
						water_blocked += 1
					else:
						# Select random prop based on proportionality
						var selected_prop = select_weighted_prop(loaded_props, total_proportionality)
						
						# Only apply small height variance (not full range)
						var final_pos = Vector3(varied_x, height + randf_range(-height_variance * 0.2, height_variance * 0.2), varied_z)
						
						# Random rotation with variance
						var rotation = Vector3(
							randf_range(-rotation_variance, rotation_variance),
							randf() * TAU + randf_range(-rotation_variance, rotation_variance),
							randf_range(-rotation_variance, rotation_variance)
						)
						
						# Random scale with variance
						var scale_factor = 1.0 + randf_range(-scale_variance, scale_variance)
						var scale = Vector3.ONE * scale_factor
						
						# Create transform
						var transform = Transform3D()
						transform.origin = final_pos
						transform.basis = Basis.from_euler(rotation).scaled(scale)
						
						# Store transform for this prop type
						var scene_key = selected_prop["scene"].resource_path
						if not prop_instances.has(scene_key):
							prop_instances[scene_key] = []
						prop_instances[scene_key].append(transform)
						
						spawned_count += 1
			z += grid_spacing
		x += grid_spacing
	
	# Create MultiMesh instances for each prop type
	for scene_path in prop_instances:
		var scene = load(scene_path)
		if not scene:
			print("ERROR: Could not load scene: ", scene_path)
			continue
		
		var scene_instance = scene.instantiate()
		
		# Collect all meshes in the scene (not just first one)
		var all_meshes = find_all_mesh_instances(scene_instance)
		if all_meshes.is_empty():
			print("ERROR: Scene has no meshes: ", scene_path)
			scene_instance.queue_free()
			continue
		
		# Create a MultiMesh for each unique mesh found
		for mesh_data in all_meshes:
			var mesh = mesh_data["mesh"]
			var material = mesh_data["material"]
			
			var multi_mesh = MultiMesh.new()
			multi_mesh.mesh = mesh
			multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
			multi_mesh.instance_count = prop_instances[scene_path].size()
			
			# Set all transforms
			for i in range(prop_instances[scene_path].size()):
				multi_mesh.set_instance_transform(i, prop_instances[scene_path][i])
			
			# Create and add MultiMeshInstance3D
			var multi_mesh_instance = MultiMeshInstance3D.new()
			multi_mesh_instance.multimesh = multi_mesh
			
			# Apply material
			if material:
				multi_mesh_instance.material_override = material
			
			scatter_container.add_child(multi_mesh_instance)
		
		scene_instance.queue_free()
		print("Created MultiMesh for ", scene_path, " with ", prop_instances[scene_path].size(), " instances")
	
	print("Found ", boreal_count, " boreal forest grid points")
	print("Blocked ", water_blocked, " assets from spawning underwater")
	print("✓ Spawned ", spawned_count, " assets in boreal forest using MultiMesh!")

func select_weighted_prop(props: Array, total_proportionality: float) -> Dictionary:
	var random_value = randf() * total_proportionality
	var cumulative = 0.0
	
	for prop in props:
		cumulative += prop["proportionality"]
		if random_value <= cumulative:
			return prop
	
	return props[0]

func is_boreal_forest(x: float, z: float) -> bool:
	var uv = Vector2(
		(x + terrain_size / 2.0) / terrain_size,
		(z + terrain_size / 2.0) / terrain_size
	)
	uv = uv.clamp(Vector2.ZERO, Vector2.ONE)
	
	var temp_pixel_x = int(uv.x * temp_img.get_width())
	var temp_pixel_y = int(uv.y * temp_img.get_height())
	var temperature = temp_img.get_pixel(temp_pixel_x, temp_pixel_y).r
	
	var hum_pixel_x = int(uv.x * hum_img.get_width())
	var hum_pixel_y = int(uv.y * hum_img.get_height())
	var humidity = hum_img.get_pixel(hum_pixel_x, hum_pixel_y).r
	
	var precip_pixel_x = int(uv.x * precip_img.get_width())
	var precip_pixel_y = int(uv.y * precip_img.get_height())
	var precipitation = precip_img.get_pixel(precip_pixel_x, precip_pixel_y).r
	
	var in_temp = temperature >= boreal_forest_t_min and temperature <= boreal_forest_t_max
	var in_hum = humidity >= boreal_forest_h_min and humidity <= boreal_forest_h_max
	var in_precip = precipitation >= boreal_forest_p_min and precipitation <= boreal_forest_p_max
	
	return in_temp and in_hum and in_precip

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

func find_all_mesh_instances(node: Node) -> Array:
	var meshes = []
	
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		meshes.append({
			"mesh": mesh_instance.mesh,
			"material": mesh_instance.material_override if mesh_instance.material_override else mesh_instance.get_surface_override_material(0)
		})
	
	for child in node.get_children():
		meshes.append_array(find_all_mesh_instances(child))
	
	return meshes
