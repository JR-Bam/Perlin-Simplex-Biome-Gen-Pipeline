@tool
extends Node3D

var Config: WorldConfigResource = load("res://world_config.tres")

@export var terrain_mesh: MeshInstance3D
@export var terrain_size: int = Config.size
@export var grid_spacing: float = 10.0
@export var spawn_density: float = 0.2
@export var test_spawn: bool = false:
	set(_val):
		if _val:
			test_pine_trees()
			
# Boreal forest thresholds
var boreal_forest_t_min = Config.boreal_forest_t_min
var boreal_forest_t_max = Config.boreal_forest_t_max
var boreal_forest_e_min = Config.boreal_forest_e_min
var boreal_forest_e_max = Config.boreal_forest_e_max
var boreal_forest_p_min = Config.boreal_forest_p_min
var boreal_forest_p_max = Config.boreal_forest_p_max
var boreal_forest_h_min = Config.boreal_forest_h_min
var boreal_forest_h_max = Config.boreal_forest_h_max

func test_pine_trees():
	if not terrain_mesh:
		print("ERROR: No terrain mesh assigned!")
		return

	print("=== Testing Pine Tree Spawning with Raycasting ===")

	var tree_scene = load("res://addons/proton_scatter/demos/assets/pine_tree.tscn")
	if not tree_scene:
		print("ERROR: Could not load pine_tree.tscn")
		return

	print("✓ Pine tree scene loaded successfully")

	var tree_container = Node3D.new()
	tree_container.name = "TestPineTrees"
	add_child(tree_container)

	var shader_material = terrain_mesh.get_surface_override_material(0)
	if not shader_material:
		print("ERROR: No shader material!")
		return

	var spawned_count = 0
	var boreal_count = 0

	# Generate grid across terrain
	var x = -terrain_size / 2.0
	while x < terrain_size / 2.0:
		var z = -terrain_size / 2.0
		while z < terrain_size / 2.0:
			# Check if boreal forest at this position
			if is_boreal_forest(x, z, shader_material):
				boreal_count += 1

				# Random spawn chance
				if randf() < spawn_density:
					var height = sample_terrain_height(x, z)

					var tree = tree_scene.instantiate()
					tree.position = Vector3(x, height, z)
					tree.rotation.y = randf() * TAU
					tree_container.add_child(tree)
					spawned_count += 1

			z += grid_spacing
		x += grid_spacing

	print("Found ", boreal_count, " boreal forest grid points")
	print("✓ Spawned ", spawned_count, " pine trees in boreal forest!")
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

	if not temperature_tex or not elevation_tex:
		return false

	var temp_img = temperature_tex.get_image()
	var elev_img = elevation_tex.get_image()

	var temp_pixel_x = int(uv.x * temp_img.get_width())
	var temp_pixel_y = int(uv.y * temp_img.get_height())
	var temperature = temp_img.get_pixel(temp_pixel_x, temp_pixel_y).r

	var elev_pixel_x = int(uv.x * elev_img.get_width())
	var elev_pixel_y = int(uv.y * elev_img.get_height())
	var elevation = elev_img.get_pixel(elev_pixel_x, elev_pixel_y).r

	var in_temp = temperature >= boreal_forest_t_min and temperature <= boreal_forest_t_max
	var in_elev = elevation >= boreal_forest_e_min and elevation <= boreal_forest_e_max

	return in_temp and in_elev
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

	print("WARNING: Raycast failed at (", x, ", ", z, ")")
	return 0.0
