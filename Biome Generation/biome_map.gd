@tool
extends Node2D

var Config: WorldConfigResource = load("res://world_config.tres")
var Climate: ClimateData = load("res://Climate Maps/climate_data.tres")
var Elevation: ElevationData = load("res://Terrain Maps/elevation_data.tres")

var shader: Shader = load("res://Biome Generation/biome_map.gdshader")

@export var update = true:
	set(_val):
		update = _val
		_update_maps()

func _update_maps():
	# Find the sprites by name
	var simplex_cont: MarginContainer = find_child("Simplex", true, false)
	var perlin_cont: MarginContainer = find_child("Perlin", true, false)
	
	if not simplex_cont or not perlin_cont:
		print("Margin Container nodes not found")
		return
	
	var size = Config.size
	
	simplex_cont.custom_minimum_size = Vector2(size, size)
	perlin_cont.custom_minimum_size = Vector2(size, size)
	perlin_cont.position = Vector2(size + 50, 0)
	
	var simplex_rect: ColorRect = $Simplex/ColorRect
	var perlin_rect: ColorRect = $Perlin/ColorRect
	
	if not simplex_rect or not perlin_rect:
		print("Color Rect nodes not found")
		return
	
	var simplex_elevation = _noise_to_texture(size, SimplexTexture.new(), Elevation.base_simplex)
	var simplex_temperature = _noise_to_texture(size, SimplexTexture.new(), Climate.temperature_simplex)
	var simplex_precipitation = _noise_to_texture(size, SimplexTexture.new(), Climate.precipitation_simplex)
	var simplex_humidity = _noise_to_texture(size, SimplexTexture.new(), Climate.humidity_simplex)
	
	var perlin_elevation = _noise_to_texture(size, NoiseTexture2D.new(), Elevation.base_perlin)
	var perlin_temperature = _noise_to_texture(size, NoiseTexture2D.new(), Climate.temperature_perlin)
	var perlin_precipitation = _noise_to_texture(size, NoiseTexture2D.new(), Climate.precipitation_perlin)
	var perlin_humidity = _noise_to_texture(size, NoiseTexture2D.new(), Climate.humidity_perlin)
	
	var simplex_shader := ShaderMaterial.new()
	simplex_shader.shader = shader
	simplex_shader.set_shader_parameter("elevation_map", simplex_elevation)
	simplex_shader.set_shader_parameter("temperature_map", simplex_temperature)
	simplex_shader.set_shader_parameter("precipitation_map", simplex_precipitation)
	simplex_shader.set_shader_parameter("humidity_map", simplex_humidity)
	
	# Set all threshold parameters for simplex shader
	_set_biome_thresholds(simplex_shader, Config)
	
	simplex_rect.material = simplex_shader
	
	var perlin_shader := ShaderMaterial.new()
	perlin_shader.shader = shader
	perlin_shader.set_shader_parameter("elevation_map", perlin_elevation)
	perlin_shader.set_shader_parameter("temperature_map", perlin_temperature)
	perlin_shader.set_shader_parameter("precipitation_map", perlin_precipitation)
	perlin_shader.set_shader_parameter("humidity_map", perlin_humidity)
	
	# Set all threshold parameters for perlin shader
	_set_biome_thresholds(perlin_shader, Config)
	
	perlin_rect.material = perlin_shader

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

func _noise_to_texture(size, texture, noise):
	texture.set_width(size)
	texture.set_height(size)
	texture.set_noise(noise)
	return texture
