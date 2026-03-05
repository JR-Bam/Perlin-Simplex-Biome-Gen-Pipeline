@tool
extends Node3D

class_name PropScatterer

var Config: WorldConfigResource = load("res://world_config.tres")
var temp_img: Image
var hum_img: Image
var precip_img: Image

@export_group("Debug")
@export var debug_spawn: bool = false:
	set(_val):
		if _val:
			verify_biome_spawn()

@export_group("Spawn Control")
@export var test_spawn: bool = false:
	set(_val):
		if _val:
			test_biome_scatter()

@export var spawn_seed: int = 1

@export_group("Conditions Settings")
@export var terrain_mesh: MeshInstance3D
@export var water_mesh: MeshInstance3D
@export var terrain_size: int = Config.size
@export var grid_spacing: float = 10.0
@export var base_spawn_density: float = 0.2
@export var boundary_margin: float = 0.1

@export var position_variance: float = 2.0
@export var height_variance: float = 0.5
@export var rotation_variance: float = 0.3
@export var scale_variance: float = 0.1

@export_group("LOD Settings")
@export var lod_near_distance: float = 0.0
@export var lod_mid_distance: float = 60.0
@export var lod_far_distance: float = 150.0
@export var lod_max_distance: float = 300.0
@export var lod_mid_density: float = 0.5
@export var lod_far_density: float = 0.25

@export_group("Chunk Loading Settings")
@export var chunk_size: float = 50.0
@export var chunk_load_distance: float = 200.0
@export var chunk_unload_distance: float = 250.0

@export_group("Ocean")
@export var ocean_props: Array[BiomePropData]
@export var ocean_counts: Array[int]

@export_group("Desert")
@export var desert_props: Array[BiomePropData]
@export var desert_counts: Array[int]

@export_group("Grassland")
@export var grassland_props: Array[BiomePropData]
@export var grassland_counts: Array[int]

@export_group("Savanna")
@export var savanna_props: Array[BiomePropData]
@export var savanna_counts: Array[int]

@export_group("Tundra")
@export var tundra_props: Array[BiomePropData]
@export var tundra_counts: Array[int]

@export_group("Boreal Forest")
@export var boreal_forest_props: Array[BiomePropData]
@export var boreal_forest_counts: Array[int]

@export_group("Temperate Forest")
@export var temperate_forest_props: Array[BiomePropData]
@export var temperate_forest_counts: Array[int]

@export_group("Rainforest")
@export var rainforest_props: Array[BiomePropData]
@export var rainforest_counts: Array[int]

@export_group("Mountain")
@export var mountain_props: Array[BiomePropData]
@export var mountain_counts: Array[int]

@export_group("Woodland")
@export var woodland_props: Array[BiomePropData]
@export var woodland_counts: Array[int]

var biome_thresholds = {
	"boreal_forest": {"t_min": Config.boreal_forest_t_min, "t_max": Config.boreal_forest_t_max, "h_min": Config.boreal_forest_h_min, "h_max": Config.boreal_forest_h_max, "p_min": Config.boreal_forest_p_min, "p_max": Config.boreal_forest_p_max},
	"desert": {"t_min": Config.desert_t_min, "t_max": Config.desert_t_max, "h_min": Config.desert_h_min, "h_max": Config.desert_h_max, "p_min": Config.desert_p_min, "p_max": Config.desert_p_max},
	"grassland": {"t_min": Config.grassland_t_min, "t_max": Config.grassland_t_max, "h_min": Config.grassland_h_min, "h_max": Config.grassland_h_max, "p_min": Config.grassland_p_min, "p_max": Config.grassland_p_max},
	"savanna": {"t_min": Config.savanna_t_min, "t_max": Config.savanna_t_max, "h_min": Config.savanna_h_min, "h_max": Config.savanna_h_max, "p_min": Config.savanna_p_min, "p_max": Config.savanna_p_max},
	"temperate_forest": {"t_min": Config.temperate_forest_t_min, "t_max": Config.temperate_forest_t_max, "h_min": Config.temperate_forest_h_min, "h_max": Config.temperate_forest_h_max, "p_min": Config.temperate_forest_p_min, "p_max": Config.temperate_forest_p_max},
	"rainforest": {"t_min": Config.rainforest_t_min, "t_max": Config.rainforest_t_max, "h_min": Config.rainforest_h_min, "h_max": Config.rainforest_h_max, "p_min": Config.rainforest_p_min, "p_max": Config.rainforest_p_max},
	"tundra": {"t_min": Config.tundra_t_min, "t_max": Config.tundra_t_max, "h_min": Config.tundra_h_min, "h_max": Config.tundra_h_max, "p_min": Config.tundra_p_min, "p_max": Config.tundra_p_max},
	"woodland": {"t_min": Config.woodland_t_min, "t_max": Config.woodland_t_max, "h_min": Config.woodland_h_min, "h_max": Config.woodland_h_max, "p_min": Config.woodland_p_min, "p_max": Config.woodland_p_max},
	"ocean": {"t_min": Config.ocean_t_min, "t_max": Config.ocean_t_max, "h_min": Config.ocean_h_min, "h_max": Config.ocean_h_max, "p_min": Config.ocean_p_min, "p_max": Config.ocean_p_max},
	"mountain": {"t_min": Config.mountain_t_min, "t_max": Config.mountain_t_max, "h_min": Config.mountain_h_min, "h_max": Config.mountain_h_max, "p_min": Config.mountain_p_min, "p_max": Config.mountain_p_max},
}

var current_biome_thresholds: Dictionary

func _ready():
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		test_biome_scatter()

func _enter_tree():
	if Engine.is_editor_hint():
		await get_tree().process_frame
		test_biome_scatter()

func test_biome_scatter():
	var biome_names = ["ocean", "desert", "grassland", "savanna", "tundra", "boreal_forest", "temperate_forest", "rainforest", "mountain", "woodland"]
	var biome_props_list = [ocean_props, desert_props, grassland_props, savanna_props, tundra_props, boreal_forest_props, temperate_forest_props, rainforest_props, mountain_props, woodland_props]
	var biome_counts_list = [ocean_counts, desert_counts, grassland_counts, savanna_counts, tundra_counts, boreal_forest_counts, temperate_forest_counts, rainforest_counts, mountain_counts, woodland_counts]

	seed(spawn_seed)
	print("=== Scattering ALL Biomes (Seed: %d) ===" % spawn_seed)

	var old_containers = get_tree().get_nodes_in_group("scatter_container")
	for container in old_containers:
		container.queue_free()
	
	print("Cleared %d old scatter containers" % old_containers.size())
	await get_tree().process_frame
	
	if not terrain_mesh or not water_mesh:
		print("ERROR: Missing terrain or water mesh!")
		return
	
	var shader_material = terrain_mesh.get_surface_override_material(0)
	if not shader_material:
		print("ERROR: No shader material!")
		return
	
	var shader_mat = shader_material as ShaderMaterial
	var temperature_tex = shader_mat.get_shader_parameter("temperature_map") as Texture2D
	var humidity_tex = shader_mat.get_shader_parameter("humidity_map") as Texture2D
	var precipitation_tex = shader_mat.get_shader_parameter("precipitation_map") as Texture2D
	
	temp_img = temperature_tex.get_image()
	hum_img = humidity_tex.get_image()
	precip_img = precipitation_tex.get_image()
	
	if not temp_img or not hum_img or not precip_img:
		print("ERROR: Invalid texture images!")
		return
	
	var water_top = water_mesh.global_position.y + (water_mesh.mesh.get_aabb().size.y / 2.0)
	
	print("LOD: near=%.0f mid=%.0f far=%.0f max=%.0f" % [lod_near_distance, lod_mid_distance, lod_far_distance, lod_max_distance])
	print("")
	
	var total_spawned = 0
	
	for i in range(biome_names.size()):
		var biome_name = biome_names[i]
		var selected_props = biome_props_list[i]
		var selected_counts = biome_counts_list[i]
		
		if selected_props.is_empty():
			print("⊘ Skipped %s (no props assigned)" % biome_name)
			continue
		
		var loaded_props = []
		for j in range(selected_props.size()):
			var prop_data = selected_props[j]
			var count = selected_counts[j] if j < selected_counts.size() else 1
			
			if prop_data and prop_data.scene and count > 0:
				for _k in range(count):
					loaded_props.append({
						"scene": prop_data.scene,
						"proportionality": prop_data.proportionality
					})
		
		if loaded_props.is_empty():
			print("⊘ Skipped %s (no valid props)" % biome_name)
			continue
		
		var total_proportionality = 0.0
		for prop in loaded_props:
			total_proportionality += prop["proportionality"]
		
		var scatter_container = Node3D.new()
		scatter_container.name = "%sScatter" % biome_name
		scatter_container.add_to_group("scatter_container")
		add_child(scatter_container)
		
		var spawned_count = 0
		
		current_biome_thresholds = biome_thresholds[biome_name]
		
		var prop_instances: Dictionary = {}
		var max_offset = terrain_size / 2.0 - (grid_spacing * boundary_margin)
		
		var x = -max_offset
		while x < max_offset:
			var z = -max_offset
			while z < max_offset:
				if is_selected_biome(x, z):
					if randf() < base_spawn_density:
						var varied_x = clamp(x + randf_range(-position_variance, position_variance), -max_offset, max_offset)
						var varied_z = clamp(z + randf_range(-position_variance, position_variance), -max_offset, max_offset)
						
						if not is_selected_biome(varied_x, varied_z):
							z += grid_spacing
							continue
						
						var height = sample_terrain_height(varied_x, varied_z)
						
						if height > water_top:
							var selected_prop = select_weighted_prop(loaded_props, total_proportionality)
							var final_pos = Vector3(varied_x, height + randf_range(-height_variance * 0.2, height_variance * 0.2), varied_z)
							var rotation = Vector3(randf_range(-rotation_variance, rotation_variance), randf() * TAU + randf_range(-rotation_variance, rotation_variance), randf_range(-rotation_variance, rotation_variance))
							var scale = Vector3.ONE * (1.0 + randf_range(-scale_variance, scale_variance))
							
							var transform = Transform3D()
							transform.origin = final_pos
							transform.basis = Basis.from_euler(rotation).scaled(scale)
							
							var scene_key = selected_prop["scene"].resource_path
							if not prop_instances.has(scene_key):
								prop_instances[scene_key] = []
							prop_instances[scene_key].append(transform)
							spawned_count += 1
				z += grid_spacing
			x += grid_spacing
		
		for scene_path in prop_instances:
			var scene = load(scene_path)
			if not scene:
				continue
			
			var scene_instance = scene.instantiate()
			var all_meshes = find_all_mesh_instances(scene_instance)
			
			if all_meshes.size() > 0:
				_create_chunked_lods(scatter_container, all_meshes, prop_instances[scene_path])
			
			scene_instance.queue_free()
		
		print("✓ %s: %d assets" % [biome_name, spawned_count])
		total_spawned += spawned_count
	
	print("\n=== SPAWN COMPLETE ===")
	print("✓ Total spawned: %d assets" % total_spawned)
	await get_tree().process_frame
	var lod_instances = get_tree().get_nodes_in_group("lod_instance")
	print("✓ Total LOD instances: %d" % lod_instances.size())

func _create_chunked_lods(parent: Node3D, meshes: Array, transforms: Array) -> void:
	if transforms.is_empty():
		return
	
	var chunks: Dictionary = {}
	for t in transforms:
		var key = _get_chunk_key(t.origin)
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(t)
	
	for chunk_key in chunks:
		for mesh_data in meshes:
			var mesh = mesh_data["mesh"]
			var material = mesh_data["material"]
			var chunk_transforms = chunks[chunk_key]
			
			_make_lod(parent, mesh, material, chunk_transforms, 1.0, lod_near_distance, lod_mid_distance + 20.0, chunk_key)
			_make_lod(parent, mesh, material, chunk_transforms, lod_mid_density, lod_mid_distance - 20.0, lod_far_distance + 20.0, chunk_key)
			_make_lod(parent, mesh, material, chunk_transforms, lod_far_density, lod_far_distance - 20.0, lod_max_distance, chunk_key)

func _make_lod(parent: Node3D, mesh: Mesh, material: Material, transforms: Array, density: float, near: float, far: float, chunk_key: Vector3i) -> void:
	if not mesh:
		return
	
	var lod_transforms = []
	var step = int(1.0 / density) if density > 0.0 else 1
	for i in range(0, transforms.size(), step):
		if i < transforms.size():
			lod_transforms.append(transforms[i])
	
	if lod_transforms.is_empty():
		return
	
	var multi_mesh = MultiMesh.new()
	multi_mesh.mesh = mesh
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.instance_count = lod_transforms.size()
	
	for i in range(lod_transforms.size()):
		multi_mesh.set_instance_transform(i, lod_transforms[i])
	
	var instance = MultiMeshInstance3D.new()
	instance.multimesh = multi_mesh
	instance.name = "LOD_%s_%.0f_%.0f" % [chunk_key, near, far]
	parent.add_child(instance)
	
	instance.visibility_range_begin = near
	instance.visibility_range_end = far
	instance.visibility_range_end_margin = 10.0
	instance.add_to_group("lod_instance")
	instance.add_to_group("chunk_%s" % chunk_key)
	instance.visible = true
	
	if material:
		instance.material_override = material

func _get_chunk_key(pos: Vector3) -> Vector3i:
	return Vector3i(int(floor(pos.x / chunk_size)), int(floor(pos.y / chunk_size)), int(floor(pos.z / chunk_size)))

func select_weighted_prop(props: Array, total: float) -> Dictionary:
	var val = randf() * total
	var cum = 0.0
	for prop in props:
		cum += prop["proportionality"]
		if val <= cum:
			return prop
	return props[0]

func is_selected_biome(x: float, z: float) -> bool:
	var uv = Vector2((x + terrain_size / 2.0) / terrain_size, (z + terrain_size / 2.0) / terrain_size).clamp(Vector2.ZERO, Vector2.ONE)
	var temp = temp_img.get_pixel(int(uv.x * temp_img.get_width()), int(uv.y * temp_img.get_height())).r
	var hum = hum_img.get_pixel(int(uv.x * hum_img.get_width()), int(uv.y * hum_img.get_height())).r
	var precip = precip_img.get_pixel(int(uv.x * precip_img.get_width()), int(uv.y * precip_img.get_height())).r
	
	var t_min = current_biome_thresholds["t_min"]
	var t_max = current_biome_thresholds["t_max"]
	var h_min = current_biome_thresholds["h_min"]
	var h_max = current_biome_thresholds["h_max"]
	var p_min = current_biome_thresholds["p_min"]
	var p_max = current_biome_thresholds["p_max"]
	
	return (temp >= t_min and temp <= t_max and hum >= h_min and hum <= h_max and precip >= p_min and precip <= p_max)

func sample_terrain_height(x: float, z: float) -> float:
	if not is_inside_tree():
		return 0.0
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 500, z), Vector3(x, -500, z)))
	return result.position.y if result else 0.0

func find_all_mesh_instances(node: Node) -> Array:
	var meshes = []
	if node is MeshInstance3D and node.mesh:
		meshes.append({"mesh": node.mesh, "material": node.material_override if node.material_override else node.get_surface_override_material(0)})
	for child in node.get_children():
		meshes.append_array(find_all_mesh_instances(child))
	return meshes

func verify_biome_spawn():
	print("\n=== BIOME SPAWN VERIFICATION (All Biomes) ===\n")
	
	var biome_names = ["ocean", "desert", "grassland", "savanna", "tundra", "boreal_forest", "temperate_forest", "rainforest", "mountain", "woodland"]
	
	if not terrain_mesh or not water_mesh:
		print("ERROR: No terrain or water mesh!")
		return
	
	var shader_material = terrain_mesh.get_surface_override_material(0)
	if not shader_material:
		print("ERROR: No shader material!")
		return
	
	var shader_mat = shader_material as ShaderMaterial
	var temperature_tex = shader_mat.get_shader_parameter("temperature_map") as Texture2D
	var humidity_tex = shader_mat.get_shader_parameter("humidity_map") as Texture2D
	var precipitation_tex = shader_mat.get_shader_parameter("precipitation_map") as Texture2D
	
	var temp_img = temperature_tex.get_image()
	var hum_img = humidity_tex.get_image()
	var precip_img = precipitation_tex.get_image()
	
	var water_top = water_mesh.global_position.y + (water_mesh.mesh.get_aabb().size.y / 2.0)
	
	for biome_name in biome_names:
		var t_min = biome_thresholds[biome_name]["t_min"]
		var t_max = biome_thresholds[biome_name]["t_max"]
		var h_min = biome_thresholds[biome_name]["h_min"]
		var h_max = biome_thresholds[biome_name]["h_max"]
		var p_min = biome_thresholds[biome_name]["p_min"]
		var p_max = biome_thresholds[biome_name]["p_max"]
		
		var biome_points = 0
		var non_biome_points = 0
		
		for i in range(5):
			var x = randf_range(-terrain_size/2.0, terrain_size/2.0)
			var z = randf_range(-terrain_size/2.0, terrain_size/2.0)
			
			var uv = Vector2((x + terrain_size / 2.0) / terrain_size, (z + terrain_size / 2.0) / terrain_size)
			uv = uv.clamp(Vector2.ZERO, Vector2.ONE)
			
			var temp = temp_img.get_pixel(int(uv.x * temp_img.get_width()), int(uv.y * temp_img.get_height())).r
			var hum = hum_img.get_pixel(int(uv.x * hum_img.get_width()), int(uv.y * hum_img.get_height())).r
			var precip = precip_img.get_pixel(int(uv.x * precip_img.get_width()), int(uv.y * precip_img.get_height())).r
			
			var space_state = get_world_3d().direct_space_state
			var ray_result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 500, z), Vector3(x, -500, z)))
			var height = ray_result.position.y if ray_result else 0.0
			
			if height <= water_top:
				continue
			
			var in_biome = (temp >= t_min and temp <= t_max and hum >= h_min and hum <= h_max and precip >= p_min and precip <= p_max)
			
			if in_biome:
				biome_points += 1
			else:
				non_biome_points += 1
		
		var total = biome_points + non_biome_points
		var percentage = (float(biome_points) / total * 100.0) if total > 0 else 0.0
		print("%s: %.1f%% (%d/%d)" % [biome_name, percentage, biome_points, total])
