@tool
extends Node3D

class_name PropScatterer

# Add this signal
signal scatter_progress(percent: float, stage: String, biome: String)

var Config: WorldConfigResource = load("res://world_config.tres")
var temp_img: Image
var hum_img: Image
var precip_img: Image

# Add execution times dictionary
var execution_times: Dictionary = {}

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

var biome_thresholds = {}

#func _ready():
	#if not Engine.is_editor_hint():
		#await get_tree().process_frame
		#test_biome_scatter()

func _enter_tree():
	if Engine.is_editor_hint():
		await get_tree().process_frame
		test_biome_scatter()

func safe_get_float(property_name: String, default_value: float) -> float:
	"""Safely get a float property from Config"""
	if Config.has_meta(property_name) or property_name in Config:
		var val = Config.get(property_name)
		if val is float or val is int:
			return float(val)
	return default_value

func build_biome_thresholds():
	"""Build biome thresholds from Config with safe defaults"""
	biome_thresholds.clear()
	
	biome_thresholds["ocean"] = {
		"e_min": safe_get_float("ocean_e_min", 0.0),
		"e_max": safe_get_float("ocean_e_max", 0.25),
		"t_min": safe_get_float("ocean_t_min", 0.0),
		"t_max": safe_get_float("ocean_t_max", 1.0),
		"h_min": safe_get_float("ocean_h_min", 0.0),
		"h_max": safe_get_float("ocean_h_max", 1.0),
		"p_min": safe_get_float("ocean_p_min", 0.0),
		"p_max": safe_get_float("ocean_p_max", 1.0),
	}
	
	biome_thresholds["desert"] = {
		"e_min": safe_get_float("desert_e_min", 0.1),
		"e_max": safe_get_float("desert_e_max", 0.9),
		"t_min": safe_get_float("desert_t_min", 0.5),
		"t_max": safe_get_float("desert_t_max", 1.0),
		"h_min": safe_get_float("desert_h_min", 0.0),
		"h_max": safe_get_float("desert_h_max", 0.3),
		"p_min": safe_get_float("desert_p_min", 0.0),
		"p_max": safe_get_float("desert_p_max", 0.2),
	}
	
	biome_thresholds["grassland"] = {
		"e_min": safe_get_float("grassland_e_min", 0.1),
		"e_max": safe_get_float("grassland_e_max", 0.9),
		"t_min": safe_get_float("grassland_t_min", 0.2),
		"t_max": safe_get_float("grassland_t_max", 0.8),
		"h_min": safe_get_float("grassland_h_min", 0.2),
		"h_max": safe_get_float("grassland_h_max", 0.7),
		"p_min": safe_get_float("grassland_p_min", 0.1),
		"p_max": safe_get_float("grassland_p_max", 0.5),
	}
	
	biome_thresholds["savanna"] = {
		"e_min": safe_get_float("savanna_e_min", 0.1),
		"e_max": safe_get_float("savanna_e_max", 0.9),
		"t_min": safe_get_float("savanna_t_min", 0.6),
		"t_max": safe_get_float("savanna_t_max", 1.0),
		"h_min": safe_get_float("savanna_h_min", 0.2),
		"h_max": safe_get_float("savanna_h_max", 0.7),
		"p_min": safe_get_float("savanna_p_min", 0.3),
		"p_max": safe_get_float("savanna_p_max", 0.7),
	}
	
	biome_thresholds["tundra"] = {
		"e_min": safe_get_float("tundra_e_min", 0.1),
		"e_max": safe_get_float("tundra_e_max", 0.9),
		"t_min": safe_get_float("tundra_t_min", 0.0),
		"t_max": safe_get_float("tundra_t_max", 0.4),
		"h_min": safe_get_float("tundra_h_min", 0.0),
		"h_max": safe_get_float("tundra_h_max", 1.0),
		"p_min": safe_get_float("tundra_p_min", 0.0),
		"p_max": safe_get_float("tundra_p_max", 1.0),
	}
	
	biome_thresholds["boreal_forest"] = {
		"e_min": safe_get_float("boreal_forest_e_min", 0.1),
		"e_max": safe_get_float("boreal_forest_e_max", 0.9),
		"t_min": safe_get_float("boreal_forest_t_min", 0.2),
		"t_max": safe_get_float("boreal_forest_t_max", 0.5),
		"h_min": safe_get_float("boreal_forest_h_min", 0.3),
		"h_max": safe_get_float("boreal_forest_h_max", 0.9),
		"p_min": safe_get_float("boreal_forest_p_min", 0.3),
		"p_max": safe_get_float("boreal_forest_p_max", 0.8),
	}
	
	biome_thresholds["temperate_forest"] = {
		"e_min": safe_get_float("temperate_forest_e_min", 0.1),
		"e_max": safe_get_float("temperate_forest_e_max", 0.9),
		"t_min": safe_get_float("temperate_forest_t_min", 0.3),
		"t_max": safe_get_float("temperate_forest_t_max", 0.7),
		"h_min": safe_get_float("temperate_forest_h_min", 0.4),
		"h_max": safe_get_float("temperate_forest_h_max", 0.9),
		"p_min": safe_get_float("temperate_forest_p_min", 0.5),
		"p_max": safe_get_float("temperate_forest_p_max", 1.0),
	}
	
	biome_thresholds["rainforest"] = {
		"e_min": safe_get_float("rainforest_e_min", 0.1),
		"e_max": safe_get_float("rainforest_e_max", 0.9),
		"t_min": safe_get_float("rainforest_t_min", 0.6),
		"t_max": safe_get_float("rainforest_t_max", 1.0),
		"h_min": safe_get_float("rainforest_h_min", 0.6),
		"h_max": safe_get_float("rainforest_h_max", 1.0),
		"p_min": safe_get_float("rainforest_p_min", 0.8),
		"p_max": safe_get_float("rainforest_p_max", 1.0),
	}
	
	biome_thresholds["mountain"] = {
		"e_min": safe_get_float("mountain_e_min", 0.8),
		"e_max": safe_get_float("mountain_e_max", 1.0),
		"t_min": safe_get_float("mountain_t_min", 0.0),
		"t_max": safe_get_float("mountain_t_max", 1.0),
		"h_min": safe_get_float("mountain_h_min", 0.0),
		"h_max": safe_get_float("mountain_h_max", 1.0),
		"p_min": safe_get_float("mountain_p_min", 0.0),
		"p_max": safe_get_float("mountain_p_max", 1.0),
	}
	
	biome_thresholds["woodland"] = {
		"e_min": safe_get_float("woodland_e_min", 0.1),
		"e_max": safe_get_float("woodland_e_max", 0.9),
		"t_min": safe_get_float("woodland_t_min", 0.4),
		"t_max": safe_get_float("woodland_t_max", 0.8),
		"h_min": safe_get_float("woodland_h_min", 0.2),
		"h_max": safe_get_float("woodland_h_max", 0.7),
		"p_min": safe_get_float("woodland_p_min", 0.2),
		"p_max": safe_get_float("woodland_p_max", 0.6),
	}

func test_biome_scatter():
	var start_time = Time.get_ticks_msec()
	execution_times.clear()
	
	build_biome_thresholds()
	
	var biome_names = ["ocean", "desert", "grassland", "savanna", "tundra", "boreal_forest", "temperate_forest", "rainforest", "mountain", "woodland"]
	var biome_props_list = [ocean_props, desert_props, grassland_props, savanna_props, tundra_props, boreal_forest_props, temperate_forest_props, rainforest_props, mountain_props, woodland_props]
	var biome_counts_list = [ocean_counts, desert_counts, grassland_counts, savanna_counts, tundra_counts, boreal_forest_counts, temperate_forest_counts, rainforest_counts, mountain_counts, woodland_counts]

	seed(spawn_seed)
	print("=== Scattering ALL Biomes (Seed: %d) ===" % spawn_seed)
	scatter_progress.emit(1, "Initializing", "all")

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
	
	var water_top = water_mesh.global_position.y - 2
	
	print("LOD: near=%.0f mid=%.0f far=%.0f max=%.0f" % [lod_near_distance, lod_mid_distance, lod_far_distance, lod_max_distance])
	print("")
	
	var total_spawned = 0
	var biome_times = {}
	
	for i in range(biome_names.size()):
		var biome_start = Time.get_ticks_msec()
		var progress_base = 10.0 + (float(i) / biome_names.size()) * 80.0
		scatter_progress.emit(progress_base, "Processing", biome_names[i])
		
		var biome_name = biome_names[i]
		var selected_props = biome_props_list[i]
		var selected_counts = biome_counts_list[i]
		var biome_threshold = biome_thresholds[biome_name]
		
		print("DEBUG [%s]: Checking biome (Elev: %.2f-%.2f)..." % [biome_name, biome_threshold["e_min"], biome_threshold["e_max"]])
		print("  Props array size: %d" % selected_props.size())
		
		if selected_props.is_empty():
			print("⊘ Skipped %s (no props assigned)" % biome_name)
			biome_times[biome_name] = {"total": Time.get_ticks_msec() - biome_start, "skipped": true}
			continue
		
		# Track prop loading time
		var prop_load_start = Time.get_ticks_msec()
		var loaded_props = []
		for j in range(selected_props.size()):
			var prop_data = selected_props[j]
			var count = selected_counts[j] if j < selected_counts.size() else 1
			
			if prop_data and prop_data.scene and count > 0:
				# Get the original scale and rotation from the scene
				var scene_instance_temp = prop_data.scene.instantiate()
				var original_scale = scene_instance_temp.scale
				var original_rotation = scene_instance_temp.rotation
				scene_instance_temp.queue_free()
				
				# Get per-prop density if available, otherwise use base spawn density
				var prop_density = base_spawn_density
				if prop_data.has_meta("spawn_density"):
					var meta_density = prop_data.get_meta("spawn_density")
					if meta_density > 0.0:
						prop_density = meta_density
				elif "spawn_density" in prop_data:
					if prop_data.spawn_density > 0.0:
						prop_density = prop_data.spawn_density
				
				for _k in range(count):
					loaded_props.append({
						"scene": prop_data.scene,
						"proportionality": prop_data.proportionality,
						"original_scale": original_scale,
						"original_rotation": original_rotation,
						"spawn_density": prop_density
					})
				print("  Loaded prop: %s (x%d, scale: %.2f, density: %.2f)" % [prop_data.scene.resource_path.get_file(), count, original_scale.x, prop_density])
		
		if loaded_props.is_empty():
			print("⊘ Skipped %s (no valid props)" % biome_name)
			biome_times[biome_name] = {"total": Time.get_ticks_msec() - biome_start, "skipped": true}
			continue
		
		var prop_load_time = Time.get_ticks_msec() - prop_load_start
		
		print("  Total loaded props for %s: %d instances" % [biome_name, loaded_props.size()])
		
		var total_proportionality = 0.0
		for prop in loaded_props:
			total_proportionality += prop["proportionality"]
		
		var scatter_container = Node3D.new()
		scatter_container.name = "%sScatter" % biome_name
		scatter_container.add_to_group("scatter_container")
		add_child(scatter_container)
		
		var spawned_count = 0
		var biome_match_count = 0
		
		var prop_instances: Dictionary = {}
		var max_offset = terrain_size / 2.0 - (grid_spacing * boundary_margin)
		
		# Track scanning time
		var scan_start = Time.get_ticks_msec()
		var x = -max_offset
		var grid_cells = 0
		var total_cells = int((max_offset * 2) / grid_spacing) ** 2
		
		while x < max_offset:
			var z = -max_offset
			while z < max_offset:
				grid_cells += 1
				if grid_cells % 1000 == 0:
					await get_tree().process_frame
					var grid_progress = progress_base + (float(grid_cells) / total_cells) * 10.0
					scatter_progress.emit(min(grid_progress, progress_base + 10.0), "Scanning", biome_name)
				
				var height = sample_terrain_height(x, z)
				var normalized_height = inverse_lerp(water_top, water_top + 200.0, height)
				normalized_height = clamp(normalized_height, 0.0, 1.0)
				
				if is_selected_biome(x, z, normalized_height, biome_threshold):
					biome_match_count += 1
					# Use per-prop density instead of base spawn density
					var selected_prop = select_weighted_prop(loaded_props, total_proportionality)
					if randf() < selected_prop.get("spawn_density", base_spawn_density):
						var varied_x = clamp(x + randf_range(-position_variance, position_variance), -max_offset, max_offset)
						var varied_z = clamp(z + randf_range(-position_variance, position_variance), -max_offset, max_offset)
						
						var varied_height = sample_terrain_height(varied_x, varied_z)
						var varied_normalized = inverse_lerp(water_top, water_top + 200.0, varied_height)
						varied_normalized = clamp(varied_normalized, 0.0, 1.0)
						
						if not is_selected_biome(varied_x, varied_z, varied_normalized, biome_threshold):
							z += grid_spacing
							continue
						
						if varied_height > water_top:
							var final_pos = Vector3(varied_x, varied_height + randf_range(-height_variance * 0.2, height_variance * 0.2), varied_z)
							
							# Preserve original X rotation, randomize Y and Z
							var original_rotation = selected_prop.get("original_rotation", Vector3.ZERO)
							var final_rotation = Vector3(
								original_rotation.x,  # Keep original X rotation
								randf() * TAU,  # Fully randomize Y rotation
								randf_range(-rotation_variance, rotation_variance)  # Slight randomize Z
							)
							
							# Use the stored original scale and multiply by variance
							var original_scale = selected_prop.get("original_scale", Vector3.ONE)
							var variance_scale = 1.0 + randf_range(-scale_variance, scale_variance)
							var final_scale = original_scale * variance_scale
							
							var transform = Transform3D()
							transform.origin = final_pos
							transform.basis = Basis.from_euler(final_rotation).scaled(final_scale)
							
							var scene_key = selected_prop["scene"].resource_path
							if not prop_instances.has(scene_key):
								prop_instances[scene_key] = []
							prop_instances[scene_key].append(transform)
							spawned_count += 1
				z += grid_spacing
			x += grid_spacing
		
		var scan_time = Time.get_ticks_msec() - scan_start
		
		print("  Biome matches found: %d" % biome_match_count)
		
		# Track LOD creation time for this biome
		var lod_start = Time.get_ticks_msec()
		var lod_count = 0
		
		for scene_path in prop_instances:
			var scene = load(scene_path)
			if not scene:
				continue
			
			var scene_instance = scene.instantiate()
			var all_meshes = find_all_mesh_instances(scene_instance)
			
			if all_meshes.size() > 0:
				_create_chunked_lods(scatter_container, all_meshes, prop_instances[scene_path])
				lod_count += prop_instances[scene_path].size()
			
			scene_instance.queue_free()
		
		var lod_time = Time.get_ticks_msec() - lod_start
		
		print("✓ %s: %d assets (from %d matches)" % [biome_name, spawned_count, biome_match_count])
		total_spawned += spawned_count
		
		# Store detailed times for this biome
		biome_times[biome_name] = {
			"total": Time.get_ticks_msec() - biome_start,
			"prop_loading": prop_load_time,
			"scanning": scan_time,
			"lod_creation": lod_time,
			"misc": {
				"grid_cells": grid_cells,
				"spawned": spawned_count,
				"matches": biome_match_count,
			}
		}
		print("")
	
	print("\n=== SPAWN COMPLETE ===")
	print("✓ Total spawned: %d assets" % total_spawned)
	scatter_progress.emit(95, "Creating global LODs", "all")
	var global_lod_start = Time.get_ticks_msec()
	await get_tree().process_frame
	var lod_instances = get_tree().get_nodes_in_group("lod_instance")
	var global_lod_time = Time.get_ticks_msec() - global_lod_start
	
	execution_times["TOTAL"] = Time.get_ticks_msec() - start_time
	execution_times["global_lod_count"] = lod_instances.size()
	execution_times["global_lod_creation"] = global_lod_time
	execution_times["biome_details"] = biome_times
	
	scatter_progress.emit(100, "Complete", "all")
	
	print("\n=== SPAWN COMPLETE ===")
	print("✓ Total spawned: %d assets" % total_spawned)
	print("✓ Total LOD instances: %d" % lod_instances.size())
	print("=== Detailed Execution Times ===")
	
	var total_biome_time = 0
	for biome in biome_times:
		var data = biome_times[biome]
		if data is Dictionary and data.has("skipped") and data["skipped"]:
			print("  %s: SKIPPED" % biome)
		else:
			print("  %s:" % biome)
			print("    Total: %d ms" % data["total"])
			print("    Prop Loading: %d ms" % data["prop_loading"])
			print("    Scanning: %d ms" % data["scanning"])
			print("    LOD Creation: %d ms" % data["lod_creation"])
			print("    Spawned: %d" % data["misc"]["spawned"])
			print("    Matches: %d" % data["misc"]["matches"])
			print("    Grid Cells: %d" % data["misc"]["grid_cells"])
			total_biome_time += data["total"]
	
	print("  Global LOD creation: %d ms" % global_lod_time)
	print("  TOTAL: %d ms" % execution_times["TOTAL"])
	print("  (Biome sum: %d ms)" % total_biome_time)

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

func is_selected_biome(x: float, z: float, normalized_elevation: float, thresholds: Dictionary) -> bool:
	# PRIMARY CHECK: Elevation must match
	var e_min = thresholds["e_min"]
	var e_max = thresholds["e_max"]
	
	if normalized_elevation < e_min or normalized_elevation > e_max:
		return false
	
	# SECONDARY CHECK: Climate characteristics
	var uv = Vector2((x + terrain_size / 2.0) / terrain_size, (z + terrain_size / 2.0) / terrain_size).clamp(Vector2.ZERO, Vector2.ONE)
	var temp = temp_img.get_pixel(int(uv.x * temp_img.get_width()), int(uv.y * temp_img.get_height())).r
	var hum = hum_img.get_pixel(int(uv.x * hum_img.get_width()), int(uv.y * hum_img.get_height())).r
	var precip = precip_img.get_pixel(int(uv.x * precip_img.get_width()), int(uv.y * precip_img.get_height())).r
	
	var t_min = thresholds["t_min"]
	var t_max = thresholds["t_max"]
	var h_min = thresholds["h_min"]
	var h_max = thresholds["h_max"]
	var p_min = thresholds["p_min"]
	var p_max = thresholds["p_max"]
	
	return (temp >= t_min and temp <= t_max and 
			hum >= h_min and hum <= h_max and 
			precip >= p_min and precip <= p_max)

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
	build_biome_thresholds()
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
	
	var temp_img_local = temperature_tex.get_image()
	var hum_img_local = humidity_tex.get_image()
	var precip_img_local = precipitation_tex.get_image()
	
	var water_top = water_mesh.global_position.y + (water_mesh.mesh.get_aabb().size.y / 2.0)
	
	for biome_name in biome_names:
		var biome_threshold = biome_thresholds[biome_name]
		
		var biome_points = 0
		var non_biome_points = 0
		
		for i in range(20):
			var x = randf_range(-terrain_size/2.0, terrain_size/2.0)
			var z = randf_range(-terrain_size/2.0, terrain_size/2.0)
			
			var height = sample_terrain_height(x, z)
			var normalized_height = inverse_lerp(water_top, water_top + 200.0, height)
			normalized_height = clamp(normalized_height, 0.0, 1.0)
			
			if height <= water_top:
				continue
			
			var in_biome = is_selected_biome(x, z, normalized_height, biome_threshold)
			
			if in_biome:
				biome_points += 1
			else:
				non_biome_points += 1
		
		var total = biome_points + non_biome_points
		var percentage = (float(biome_points) / total * 100.0) if total > 0 else 0.0
		print("%s: %.1f%% (%d/%d) | Elev: %.2f-%.2f" % [biome_name, percentage, biome_points, total, biome_threshold["e_min"], biome_threshold["e_max"]])
