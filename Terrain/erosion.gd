@tool
extends Node2D
class_name Erosion

var wc := WorldConfiguration.new()

@export var SimplexNoise := Simplex.new()
@export var PerlinNoise := FastNoiseLite.new()

@export var update := true:
	set(value):
		print("Update set to: ", value)
		update = value
		if update:
			_update_maps()
			
@export var auto_update := false:
	set(value):
		auto_update = value
		if auto_update and PerlinNoise:
			if not PerlinNoise.changed.is_connected(_update_maps):
				PerlinNoise.changed.connect(_update_maps)
		elif PerlinNoise:
			if PerlinNoise.changed.is_connected(_update_maps):
				PerlinNoise.changed.disconnect(_update_maps)
		
		if auto_update and SimplexNoise:
			if not SimplexNoise.changed.is_connected(_update_maps):
				SimplexNoise.changed.connect(_update_maps)
		elif SimplexNoise:
			if SimplexNoise.changed.is_connected(_update_maps):
				SimplexNoise.changed.disconnect(_update_maps)

func get_noise():
	if wc.noise_type == 0: # Simplex
		return SimplexNoise
	else:
		return PerlinNoise

func _update_maps():
	print("_update_maps() started")
	
	# Find the sprites by name
	var simplex_sprite: Sprite2D = find_child("Simplex", true, false)
	var perlin_sprite: Sprite2D = find_child("Perlin", true, false)
	
	if not simplex_sprite or not perlin_sprite:
		print("Sprite nodes not found - looking for 'Simplex' and 'Perlin'")
		return
	
	var size = wc.size
	print("Size: ", size)
	
	simplex_sprite.position = Vector2(size / 2, size / 2)
	perlin_sprite.position = Vector2(size * 3 / 2 + 50, size / 2)
	
	var simplex_texture := SimplexTexture.new()
	simplex_texture.set_width(size)
	simplex_texture.set_height(size)
	simplex_texture.set_noise(SimplexNoise)
	simplex_sprite.texture = simplex_texture
	
	var perlin_texture = NoiseTexture2D.new()
	perlin_texture.set_width(size)
	perlin_texture.set_height(size)
	perlin_texture.set_noise(PerlinNoise)
	perlin_sprite.texture = perlin_texture
	
	print("Set Textures successfully")

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
