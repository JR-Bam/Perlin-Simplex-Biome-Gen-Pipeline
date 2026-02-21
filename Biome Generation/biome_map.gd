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
	simplex_rect.material = simplex_shader
	
	var perlin_shader := ShaderMaterial.new()
	perlin_shader.shader = shader
	perlin_shader.set_shader_parameter("elevation_map", perlin_elevation)
	perlin_shader.set_shader_parameter("temperature_map", perlin_temperature)
	perlin_shader.set_shader_parameter("precipitation_map", perlin_precipitation)
	perlin_shader.set_shader_parameter("humidity_map", perlin_humidity)
	perlin_rect.material = perlin_shader

func _noise_to_texture(size, texture, noise):
	texture.set_width(size)
	texture.set_height(size)
	texture.set_noise(noise)
	return texture
