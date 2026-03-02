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

@export var boreal_forest_props: Array[BiomePropData] = []

@export var test_spawn: bool = false:
	set(_val):
		if _val:
			test_biome_scatter()

var boreal_forest_t_min = Config.boreal_forest_t_min
var boreal_forest_t_max = Config.boreal_forest_t_max
var boreal_forest_h_min = Config.boreal_forest_h_min
var boreal_forest_h_max = Config.boreal_forest_h_max
var boreal_forest_p_min = Config.boreal_forest_p_min
var boreal_forest_p_max = Config.boreal_forest_p_max

func _ready():
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		test_biome_scatter()

func _enter_tree():
	if Engine.is_editor_hint():
		await get_tree().process_frame
		test_biome_scatter()

func test_biome_scatter():
	var old_container = get_node_or_null("BorealForestScatter")
	if old_container:
		old_container.queue_free()
		print("Cleared previous boreal forest scatter")
		await get_tree().process_frame
	
	if not terrain_mesh or not water_mesh or boreal_forest_props.is_empty():
		print("ERROR: Missing terrain, water, or props!")
		return
	
	print("=== Scattering Boreal Forest Assets ===")
	print("LOD: near=%.0f mid=%.0f far=%.0f max=%.0f" % [lod_near_distance, lod_mid_distance, lod_far_distance, lod_max_distance])
	
	var scatter_container = Node3D.new()
	scatter_container.name = "BorealForestScatter"
	add_child(scatter_container)
	
	var shader_material = terrain_mesh.get_surface_override_material(0)
	if not shader_material:
		print("ERROR: No shader material!")
		return
	
	var water_top = water_mesh.global_position.y + (water_mesh.mesh.get_aabb().size.y / 2.0)
	
	var loaded_props = []
	for prop_data in boreal_forest_props:
		if prop_data.scene:
			loaded_props.append({
				"scene": prop_data.scene,
				"proportionality": prop_data.proportionality
			})
	
	if loaded_props.is_empty():
		print("ERROR: No valid props!")
		return
	
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
	
	if not temp_img or not hum_img or not precip_img:
		print("ERROR: Invalid texture images!")
		return
	
	var prop_instances: Dictionary = {}
	var max_offset = terrain_size / 2.0 - (grid_spacing * boundary_margin)
	
	var x = -max_offset
	while x < max_offset:
		var z = -max_offset
		while z < max_offset:
			if is_boreal_forest(x, z):
				boreal_count += 1
				if randf() < base_spawn_density:
					var varied_x = clamp(x + randf_range(-position_variance, position_variance), -max_offset, max_offset)
					var varied_z = clamp(z + randf_range(-position_variance, position_variance), -max_offset, max_offset)
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
					else:
						water_blocked += 1
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
	
	print("✓ Spawned ", spawned_count, " assets!")
	await get_tree().process_frame
	var lod_instances = get_tree().get_nodes_in_group("lod_instance")
	print("LOD instances: ", lod_instances.size())

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
			
			_make_lod(parent, mesh, material, chunk_transforms, 1.0, lod_near_distance, lod_mid_distance, chunk_key)
			_make_lod(parent, mesh, material, chunk_transforms, lod_mid_density, lod_mid_distance, lod_far_distance, chunk_key)
			_make_lod(parent, mesh, material, chunk_transforms, lod_far_density, lod_far_distance, lod_max_distance, chunk_key)

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
	instance.visibility_range_end_margin = 5.0
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

func is_boreal_forest(x: float, z: float) -> bool:
	var uv = Vector2((x + terrain_size / 2.0) / terrain_size, (z + terrain_size / 2.0) / terrain_size).clamp(Vector2.ZERO, Vector2.ONE)
	var temp = temp_img.get_pixel(int(uv.x * temp_img.get_width()), int(uv.y * temp_img.get_height())).r
	var hum = hum_img.get_pixel(int(uv.x * hum_img.get_width()), int(uv.y * hum_img.get_height())).r
	var precip = precip_img.get_pixel(int(uv.x * precip_img.get_width()), int(uv.y * precip_img.get_height())).r
	return (temp >= boreal_forest_t_min and temp <= boreal_forest_t_max and hum >= boreal_forest_h_min and hum <= boreal_forest_h_max and precip >= boreal_forest_p_min and precip <= boreal_forest_p_max)

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
