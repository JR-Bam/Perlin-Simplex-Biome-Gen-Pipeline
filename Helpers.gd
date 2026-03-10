extends Node
class_name Helpers



static func _set_biome_thresholds(shader_material: ShaderMaterial, config: WorldConfigResource):
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
	
	# woodland Thresholds
	shader_material.set_shader_parameter("woodland_e_min", config.woodland_e_min)
	shader_material.set_shader_parameter("woodland_e_max", config.woodland_e_max)
	shader_material.set_shader_parameter("woodland_t_min", config.woodland_t_min)
	shader_material.set_shader_parameter("woodland_t_max", config.woodland_t_max)
	shader_material.set_shader_parameter("woodland_p_min", config.woodland_p_min)
	shader_material.set_shader_parameter("woodland_p_max", config.woodland_p_max)
	shader_material.set_shader_parameter("woodland_h_min", config.woodland_h_min)
	shader_material.set_shader_parameter("woodland_h_max", config.woodland_h_max)
	
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
	
	shader_material.set_shader_parameter("blend_radius", config.blend_radius)

static func save_noise(simplex_texture: SimplexTexture, perlin_texture: NoiseTexture2D, name: StringName):
	var path = "res://Images/"
	
	# Ensure the directory exists
	DirAccess.make_dir_recursive_absolute(path)
	
	# For SimplexTexture
	if simplex_texture and simplex_texture.get_image():
		var simplex_img = simplex_texture.get_image()
		simplex_img.save_png(path + "Simplex_" + name + ".png")
		ResourceSaver.save(simplex_texture, path + "Simplex_" + name + ".tres")
		print("Simplex files saved")
	else:
		print("Simplex texture not ready or null")
	
	# For Perlin NoiseTexture2D
	if perlin_texture and perlin_texture.get_image():
		var perlin_img = perlin_texture.get_image()
		perlin_img.save_png(path + "Perlin_" + name + ".png")
		ResourceSaver.save(perlin_texture, path + "Perlin_" + name + ".tres")
		print("Perlin files saved")
	else:
		print("Perlin texture not ready or null")

static func _get_indent(level: int) -> String:
	var indent = ""
	for i in range(level):
		indent += "  "
	return indent

static func format_dict(data, indent_level: int) -> String:
	var result = ""
	var indent = _get_indent(indent_level)
	
	if data is Dictionary:
		var keys = data.keys()
		keys.sort()
		
		for key in keys:
			if key in ["TOTAL", "misc"]: continue
			
			var value = data[key]
			var formatted_key = key.capitalize().replace("_", " ")
			
			if value is Dictionary:
				result += indent + formatted_key + ":\n"
				result += format_dict(value, indent_level + 1)
			elif value is int:
				result += indent + formatted_key + ": %d ms\n" % value
			else:
				result += indent + formatted_key + ": " + str(value) + "\n"
	else:
		result += indent + str(data) + "\n"
	
	return result

static func _noise_to_texture(size, texture, noise):
	var Config: WorldConfigResource = load("res://world_config.tres")
	noise.set_seed(Config.seed)
	texture.set_width(size)
	texture.set_height(size)
	texture.set_noise(noise)
	return texture
