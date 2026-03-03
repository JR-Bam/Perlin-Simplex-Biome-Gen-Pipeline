@tool
extends Node2D
class_name Temperature

var Config: WorldConfigResource = load("res://world_config.tres")
@export var Data: ClimateData = load("res://Climate Maps/climate_data.tres")

@export var update := true:
	set(value):
		update = value
		if update:
			_update_maps()
			
@export var auto_update := false:
	set(value):
		auto_update = value
		if auto_update and Data.temperature_perlin:
			Data.temperature_perlin.changed.connect(_update_maps)
		elif Data.temperature_perlin:
			Data.temperature_perlin.changed.disconnect(_update_maps)
		
		if auto_update and Data.temperature_simplex:
			Data.temperature_simplex.changed.connect(_update_maps)
		elif Data.temperature_simplex:
			Data.temperature_simplex.changed.disconnect(_update_maps)


func _update_maps():
	# Find the sprites by name
	var simplex_sprite: Sprite2D = find_child("Simplex", true, false)
	var perlin_sprite: Sprite2D = find_child("Perlin", true, false)
	
	var size = Config.size
	
	simplex_sprite.position = Vector2(size / 2, size / 2)
	perlin_sprite.position = Vector2(size * 3 / 2 + 50, size / 2)
	
	if not simplex_sprite or not perlin_sprite:
		print("Sprite nodes not found")
		return
	
	var simplex_texture := SimplexTexture.new()
	simplex_texture.set_width(size)
	simplex_texture.set_height(size)
	simplex_texture.set_noise(Data.temperature_simplex)
	
	simplex_sprite.texture = simplex_texture
	
	var perlin_texture = NoiseTexture2D.new()
	perlin_texture.set_width(size)
	perlin_texture.set_height(size)
	perlin_texture.set_noise(Data.temperature_perlin)
	
	perlin_sprite.texture = perlin_texture
	print("Set Textures")

func _ready() -> void:
	var simplex_texture: Sprite2D = $Simplex
	var perlin_texture: Sprite2D = $Perlin
	
	# Wait for textures to be ready if needed
	await get_tree().process_frame
	Helpers.save_noise(simplex_texture.texture, perlin_texture.texture, name)
