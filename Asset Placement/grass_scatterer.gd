@tool
extends MultiMeshInstance3D

class_name GrassScatterer

signal scatter_progress(percent: float, stage: String)

var Config: WorldConfigResource = load("res://world_config.tres")
var temp_img: Image
var hum_img: Image
var precip_img: Image

@export_group("Spawn Control")
@export var test_spawn: bool = false:
	set(_val):
		if _val:
			populate_grass()
			test_spawn = false

@export_group("Settings")
@export var terrain_mesh: MeshInstance3D
@export var water_mesh: MeshInstance3D
@export var terrain_size: int = 1000
@export var instance_count: int = 50000  # Total grass instances across entire terrain
@export var spawn_seed: int = 1

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

@export_group("Biome Selection")
@export var spawn_in_ocean: bool = false
@export var spawn_in_desert: bool = false
@export var spawn_in_grassland: bool = true
@export var spawn_in_savanna: bool = true
@export var spawn_in_tundra: bool = false
@export var spawn_in_boreal_forest: bool = true
@export var spawn_in_temperate_forest: bool = true
@export var spawn_in_rainforest: bool = false
@export var spawn_in_mountain: bool = false
@export var spawn_in_woodland: bool = true

@export_group("Debug")
@export var spawn_everywhere: bool = false

var biome_thresholds = {}

func _ready():
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		populate_grass()

func _enter_tree():
	if Engine.is_editor_hint():
		await get_tree().process_frame
		populate_grass()

func safe_get_float(property_name: String, default_value: float) -> float:
	if Config.has_meta(property_name) or property_name in Config:
		var val = Config.get(property_name)
		if val is float or val is int:
			return float(val)
	return default_value

func build_biome_thresholds():
	biome_thresholds.clear()
	
	biome_thresholds["ocean"] = {
		"e_min": safe_get_float("ocean_e_min", 0.0),
		"e_max": safe_get_float("ocean_e_max", 0.25),
	}
	biome_thresholds["desert"] = {
		"e_min": safe_get_float("desert_e_min", 0.1),
		"e_max": safe_get_float("desert_e_max", 0.9),
	}
	biome_thresholds["grassland"] = {
		"e_min": safe_get_float("grassland_e_min", 0.1),
		"e_max": safe_get_float("grassland_e_max", 0.9),
	}
	biome_thresholds["savanna"] = {
		"e_min": safe_get_float("savanna_e_min", 0.1),
		"e_max": safe_get_float("savanna_e_max", 0.9),
	}
	biome_thresholds["tundra"] = {
		"e_min": safe_get_float("tundra_e_min", 0.1),
		"e_max": safe_get_float("tundra_e_max", 0.9),
	}
	biome_thresholds["boreal_forest"] = {
		"e_min": safe_get_float("boreal_forest_e_min", 0.1),
		"e_max": safe_get_float("boreal_forest_e_max", 0.9),
	}
	biome_thresholds["temperate_forest"] = {
		"e_min": safe_get_float("temperate_forest_e_min", 0.1),
		"e_max": safe_get_float("temperate_forest_e_max", 0.9),
	}
	biome_thresholds["rainforest"] = {
		"e_min": safe_get_float("rainforest_e_min", 0.1),
		"e_max": safe_get_float("rainforest_e_max", 0.9),
	}
	biome_thresholds["mountain"] = {
		"e_min": safe_get_float("mountain_e_min", 0.8),
		"e_max": safe_get_float("mountain_e_max", 1.0),
	}
	biome_thresholds["woodland"] = {
		"e_min": safe_get_float("woodland_e_min", 0.1),
		"e_max": safe_get_float("woodland_e_max", 0.9),
	}

func populate_grass():
	if not terrain_mesh or not water_mesh or not self.multimesh or not self.multimesh.mesh:
		print("ERROR: Missing terrain_mesh, water_mesh, or MultiMesh!")
		return
	
	var start_time = Time.get_ticks_msec()
	build_biome_thresholds()
	
	seed(spawn_seed)
	print("\n========================================")
	print("=== Populating Grass with populate_surface ===")
	print("========================================\n")
	scatter_progress.emit(1, "Initializing")
	
	# Clear old
	var old_containers = get_tree().get_nodes_in_group("grass_scatter_container")
	for container in old_containers:
		container.queue_free()
	await get_tree().process_frame
	
	# Load climate data
	var shader_material = terrain_mesh.get_surface_override_material(0)
	if not shader_material:
		print("ERROR: No shader material on terrain!")
		return
	
	var shader_mat = shader_material as ShaderMaterial
	var temperature_tex = shader_mat.get_shader_parameter("temperature_map") as Texture2D
	var humidity_tex = shader_mat.get_shader_parameter("humidity_map") as Texture2D
	var precipitation_tex = shader_mat.get_shader_parameter("precipitation_map") as Texture2D
	
	temp_img = temperature_tex.get_image()
	hum_img = humidity_tex.get_image()
	precip_img = precipitation_tex.get_image()
	
	if not temp_img or not hum_img or not precip_img:
		print("ERROR: Invalid climate textures!")
		return
	
	var water_top = water_mesh.global_position.y - 2
	print("Water top: %.2f" % water_top)
	print("Instance count: %d" % instance_count)
	print("Biomes enabled: ocean=%s desert=%s grassland=%s savanna=%s tundra=%s boreal=%s temperate=%s rainforest=%s mountain=%s woodland=%s" % [spawn_in_ocean, spawn_in_desert, spawn_in_grassland, spawn_in_savanna, spawn_in_tundra, spawn_in_boreal_forest, spawn_in_temperate_forest, spawn_in_rainforest, spawn_in_mountain, spawn_in_woodland])
	
	# Get terrain mesh
	var terrain_mesh_obj = terrain_mesh.mesh
	if not terrain_mesh_obj:
		print("ERROR: Terrain has no mesh!")
		return
	
	scatter_progress.emit(20, "Populating surface")
	await get_tree().process_frame
	
	# Custom populate_surface implementation
	print("  Generating transforms on terrain surface...")
	var all_transforms = _custom_populate_surface(terrain_mesh_obj, instance_count)
	print("  Generated %d transforms from mesh surface" % all_transforms.size())
	
	# Now filter by biome - keep only instances in valid biomes
	var valid_transforms = []
	var water_count = 0
	
	scatter_progress.emit(40, "Filtering by biome")
	await get_tree().process_frame
	
	for transform in all_transforms:
		var pos = transform.origin
		var x = pos.x
		var z = pos.z
		var height = pos.y
		
		# Check if above water
		if height <= water_top:
			water_count += 1
			continue
		
		# Normalize elevation
		var normalized_height = inverse_lerp(water_top, water_top + 200.0, height)
		normalized_height = clamp(normalized_height, 0.0, 1.0)
		
		# Check biome
		if is_selected_biome(x, z, normalized_height):
			valid_transforms.append(transform)
	
	print("  Valid transforms: %d / %d" % [valid_transforms.size(), instance_count])
	print("  Underwater instances removed: %d" % water_count)
	
	scatter_progress.emit(60, "Creating LOD chunks")
	await get_tree().process_frame
	
	# Create chunked LODs from valid transforms
	var grass_container = Node3D.new()
	grass_container.name = "GrassScatter"
	grass_container.add_to_group("grass_scatter_container")
	add_child(grass_container)
	
	_create_chunked_lods(grass_container, valid_transforms)
	
	scatter_progress.emit(100, "Complete")
	
	print("\n=== GRASS SPAWN COMPLETE ===")
	print("✓ Total valid instances: %d" % valid_transforms.size())
	print("✓ Total time: %d ms" % (Time.get_ticks_msec() - start_time))

func _custom_populate_surface(mesh: Mesh, target_count: int) -> Array:
	"""Custom implementation of populate_surface - distributes instances evenly across mesh surface"""
	
	if not mesh or mesh.get_surface_count() == 0:
		return []
	
	var transforms = []
	
	# Get mesh data
	var arrays = mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var indices = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
	
	if vertices.is_empty() or indices.is_empty():
		print("ERROR: Mesh has no vertices or indices!")
		return []
	
	# Calculate total triangle area
	var triangle_areas = []
	var total_area = 0.0
	var triangle_count = indices.size() / 3
	
	for tri_idx in range(triangle_count):
		var i0 = indices[tri_idx * 3]
		var i1 = indices[tri_idx * 3 + 1]
		var i2 = indices[tri_idx * 3 + 2]
		
		var v0 = vertices[i0]
		var v1 = vertices[i1]
		var v2 = vertices[i2]
		
		# Calculate triangle area using cross product
		var area = ((v1 - v0).cross(v2 - v0)).length() * 0.5
		triangle_areas.append(area)
		total_area += area
	
	print("  Mesh triangles: %d, total area: %.2f" % [triangle_count, total_area])
	
	# Distribute instances based on triangle area
	var instances_per_triangle = float(target_count) / float(triangle_count)
	
	for tri_idx in range(triangle_count):
		var area_ratio = triangle_areas[tri_idx] / total_area if total_area > 0 else 1.0 / triangle_count
		var instances_for_triangle = int(target_count * area_ratio)
		
		var i0 = indices[tri_idx * 3]
		var i1 = indices[tri_idx * 3 + 1]
		var i2 = indices[tri_idx * 3 + 2]
		
		var v0 = vertices[i0]
		var v1 = vertices[i1]
		var v2 = vertices[i2]
		
		# Spawn instances on this triangle
		for i in range(instances_for_triangle):
			# Random barycentric coordinates
			var r1 = randf()
			var r2 = randf()
			if r1 + r2 > 1.0:
				r1 = 1.0 - r1
				r2 = 1.0 - r2
			
			# Interpolate position on triangle
			var pos = v0 + (v1 - v0) * r1 + (v2 - v0) * r2
			
			# Random rotation
			var rotation = Vector3(0.0, randf() * TAU, 0.0)
			
			# Create transform
			var transform = Transform3D()
			transform.origin = pos
			transform.basis = Basis.from_euler(rotation)
			
			transforms.append(transform)
	
	print("  Created %d instances" % transforms.size())
	return transforms

func _create_chunked_lods(parent: Node3D, transforms: Array) -> void:
	if transforms.is_empty():
		return
	
	# Group by chunk
	var chunks: Dictionary = {}
	for t in transforms:
		var key = _get_chunk_key(t.origin)
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(t)
	
	print("  Created %d chunks" % chunks.size())
	
	# Create LODs per chunk
	for chunk_key in chunks:
		var chunk_transforms = chunks[chunk_key]
		
		_make_lod(parent, chunk_transforms, 1.0, lod_near_distance, lod_mid_distance + 20.0, chunk_key)
		_make_lod(parent, chunk_transforms, lod_mid_density, lod_mid_distance - 20.0, lod_far_distance + 20.0, chunk_key)
		_make_lod(parent, chunk_transforms, lod_far_density, lod_far_distance - 20.0, lod_max_distance, chunk_key)

func _make_lod(parent: Node3D, transforms: Array, density: float, near: float, far: float, chunk_key: Vector3i) -> void:
	if not self.multimesh or not self.multimesh.mesh:
		return
	
	var lod_transforms = []
	var step = int(1.0 / density) if density > 0.0 else 1
	for i in range(0, transforms.size(), step):
		if i < transforms.size():
			lod_transforms.append(transforms[i])
	
	if lod_transforms.is_empty():
		return
	
	var multi_mesh = MultiMesh.new()
	multi_mesh.mesh = self.multimesh.mesh
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.instance_count = lod_transforms.size()
	
	for i in range(lod_transforms.size()):
		multi_mesh.set_instance_transform(i, lod_transforms[i])
	
	var instance = MultiMeshInstance3D.new()
	instance.multimesh = multi_mesh
	instance.name = "GrassLOD_%.0f_%.0f" % [near, far]
	parent.add_child(instance)
	
	instance.visibility_range_begin = near
	instance.visibility_range_end = far
	instance.visibility_range_end_margin = 10.0
	instance.add_to_group("grass_lod_instance")
	instance.add_to_group("chunk_%s" % chunk_key)
	instance.visible = true
	
	# Copy material from self
	if self.material_override:
		instance.material_override = self.material_override

func _get_chunk_key(pos: Vector3) -> Vector3i:
	return Vector3i(int(floor(pos.x / chunk_size)), 0, int(floor(pos.z / chunk_size)))

func is_selected_biome(x: float, z: float, normalized_elevation: float) -> bool:
	if spawn_everywhere:
		return true
	
	var any_enabled = (spawn_in_ocean or spawn_in_desert or spawn_in_grassland or 
					   spawn_in_savanna or spawn_in_tundra or spawn_in_boreal_forest or 
					   spawn_in_temperate_forest or spawn_in_rainforest or spawn_in_mountain or 
					   spawn_in_woodland)
	
	if not any_enabled:
		return false
	
	# Get climate values
	var uv = Vector2((x + terrain_size / 2.0) / terrain_size, (z + terrain_size / 2.0) / terrain_size).clamp(Vector2.ZERO, Vector2.ONE)
	var temp = temp_img.get_pixel(int(uv.x * temp_img.get_width()), int(uv.y * temp_img.get_height())).r
	var hum = hum_img.get_pixel(int(uv.x * hum_img.get_width()), int(uv.y * hum_img.get_height())).r
	var precip = precip_img.get_pixel(int(uv.x * precip_img.get_width()), int(uv.y * precip_img.get_height())).r
	
	# Classify biome
	var biome = _classify_biome(temp, hum, precip, normalized_elevation)
	
	# Check if enabled
	return _is_biome_enabled(biome)

func _classify_biome(temp: float, hum: float, precip: float, elevation: float) -> String:
	if elevation < 0.25:
		return "ocean"
	elif temp > 0.6 and hum < 0.3 and precip < 0.2:
		return "desert"
	elif temp > 0.7 and hum > 0.5:
		return "rainforest"
	elif temp < 0.3:
		return "tundra"
	elif temp < 0.5 and hum > 0.3:
		return "boreal_forest"
	elif temp > 0.6 and hum > 0.4 and precip > 0.3:
		return "savanna"
	elif hum > 0.6 and precip > 0.5:
		return "temperate_forest"
	elif elevation > 0.8:
		return "mountain"
	elif hum > 0.4 and precip > 0.2:
		return "woodland"
	else:
		return "grassland"

func _is_biome_enabled(biome: String) -> bool:
	match biome:
		"ocean":
			return spawn_in_ocean
		"desert":
			return spawn_in_desert
		"grassland":
			return spawn_in_grassland
		"savanna":
			return spawn_in_savanna
		"tundra":
			return spawn_in_tundra
		"boreal_forest":
			return spawn_in_boreal_forest
		"temperate_forest":
			return spawn_in_temperate_forest
		"rainforest":
			return spawn_in_rainforest
		"mountain":
			return spawn_in_mountain
		"woodland":
			return spawn_in_woodland
		_:
			return false
