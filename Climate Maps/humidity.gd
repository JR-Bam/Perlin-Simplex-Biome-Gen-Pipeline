@tool
extends Node2D
class_name Humidity

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
		if auto_update and Data.humidity_perlin:
			Data.humidity_perlin.changed.connect(_update_maps)
		elif Data.humidity_perlin:
			Data.humidity_perlin.changed.disconnect(_update_maps)
		
		if auto_update and Data.humidity_simplex:
			Data.humidity_simplex.changed.connect(_update_maps)
		elif Data.humidity_simplex:
			Data.humidity_simplex.changed.disconnect(_update_maps)


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
	simplex_texture.set_noise(Data.humidity_simplex)
	
	simplex_sprite.texture = simplex_texture
	
	var perlin_texture = NoiseTexture2D.new()
	perlin_texture.set_width(size)
	perlin_texture.set_height(size)
	perlin_texture.set_noise(Data.humidity_perlin)
	
	perlin_sprite.texture = perlin_texture
	print("Set Textures")

func _ready() -> void:
	var simplex_texture: Sprite2D = $Simplex
	var perlin_texture: Sprite2D = $Perlin
	
	save_noise(simplex_texture.texture, perlin_texture.texture)

func save_noise(simplex_texture: SimplexTexture, perlin_texture: NoiseTexture2D):
	var path = "res://Images/"
	
	# Ensure the directory exists
	DirAccess.make_dir_recursive_absolute(path)
	
	# Wait for textures to be ready if needed
	await get_tree().process_frame
	
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
