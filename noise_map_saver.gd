class_name NoiseMapSaver extends Node

signal saving_progress(progress: int)
signal saving_completed(save_path: String)
signal saving_failed(error_message: String)

var elevation_data: ElevationData = preload("res://Terrain Maps/elevation_data.tres")
var climate_data: ClimateData = preload("res://Climate Maps/climate_data.tres")
var asset_maps: AssetMaps = preload("res://Asset Placement/asset_maps.tres")

var size = null
var is_saving = false
var save_dir = ""

func start():
	if size == null:
		var error_msg = "NoiseMapSaver: Cannot start - size is null"
		print(error_msg)
		saving_failed.emit(error_msg)
		return
	
	if is_saving:
		print("NoiseMapSaver: Already saving, please wait...")
		return
	
	var Config: WorldConfigResource = load("res://world_config.tres")
	
	is_saving = true
	print("NoiseMapSaver: Starting to save noise maps...")
	
	# Create base directory structure: noise_maps/Size/Round/Algorithm
	var base_dir = "user://noise_maps"
	
	# Create base directory if it doesn't exist
	var error = DirAccess.make_dir_recursive_absolute(base_dir)
	if error != OK:
		var error_msg = "NoiseMapSaver: Failed to create base directory: " + base_dir
		print(error_msg)
		saving_failed.emit(error_msg)
		is_saving = false
		return
	
	# Determine size name
	var size_name
	if Config.size == 1000:
		size_name = "Small"
	elif Config.size == 3000:
		size_name = "Medium"
	elif Config.size == 5000:
		size_name = "Large"
	else:
		size_name = str(Config.size)
	
	# Create size directory (Small/Medium/Large)
	var size_dir = base_dir + "/" + size_name
	error = DirAccess.make_dir_recursive_absolute(size_dir)
	if error != OK:
		var error_msg = "NoiseMapSaver: Failed to create size directory: " + size_dir
		print(error_msg)
		saving_failed.emit(error_msg)
		is_saving = false
		return
	
	# Create round directory (1, 2, 3, etc.)
	var round_dir = size_dir + "/" + str(Config.round)
	error = DirAccess.make_dir_recursive_absolute(round_dir)
	if error != OK:
		var error_msg = "NoiseMapSaver: Failed to create round directory: " + round_dir
		print(error_msg)
		saving_failed.emit(error_msg)
		is_saving = false
		return
	
	# Create Perlin and Simplex subdirectories inside the round directory
	var perlin_dir = round_dir + "/Perlin"
	error = DirAccess.make_dir_recursive_absolute(perlin_dir)
	if error != OK:
		var error_msg = "NoiseMapSaver: Failed to create Perlin directory: " + perlin_dir
		print(error_msg)
		saving_failed.emit(error_msg)
		is_saving = false
		return
	
	var simplex_dir = round_dir + "/Simplex"
	error = DirAccess.make_dir_recursive_absolute(simplex_dir)
	if error != OK:
		var error_msg = "NoiseMapSaver: Failed to create Simplex directory: " + simplex_dir
		print(error_msg)
		saving_failed.emit(error_msg)
		is_saving = false
		return
	
	save_dir = round_dir  # Store the round directory as base for reference
	print("NoiseMapSaver: Created directory structure: ", save_dir)
	print("NoiseMapSaver: Perlin maps will be saved to: ", perlin_dir)
	print("NoiseMapSaver: Simplex maps will be saved to: ", simplex_dir)
	
	# Start the saving process
	_save_all_maps(perlin_dir, simplex_dir)

func _save_all_maps(perlin_dir: String, simplex_dir: String):
	var total_maps = 14  # 7 Perlin + 7 Simplex (5 terrain/climate + 4 asset maps)
	var current_progress = 0
	
	# Save Perlin maps (Terrain, Climate, and Asset)
	current_progress = await _save_perlin_maps(current_progress, total_maps, perlin_dir)
	if not is_saving:  # Check if saving was cancelled
		return
	
	# Save Simplex maps (Terrain, Climate, and Asset)
	current_progress = await _save_simplex_maps(current_progress, total_maps, simplex_dir)
	if not is_saving:
		return
	
	if is_saving:
		print("NoiseMapSaver: All maps saved successfully!")
		saving_completed.emit(save_dir)
		is_saving = false

func _save_perlin_maps(current_progress: int, total_maps: int, perlin_dir: String) -> int:
	print("NoiseMapSaver: Saving Perlin maps to: ", perlin_dir)
	
	# Add small delay between operations to keep UI responsive
	await _yield_to_main_loop()
	
	# Base height Perlin
	print("NoiseMapSaver: Generating Base Height Perlin...")
	var perlin_base_height = Helpers._noise_to_texture(size, NoiseTexture2D.new(), elevation_data.base_perlin)
	var success = await _wait_for_texture(perlin_base_height, "Base Height Perlin")
	if not success or not is_saving:
		return current_progress
	
	var image = perlin_base_height.get_image()
	if image:
		image.save_png(perlin_dir + "/BaseHeight_Perlin.png")
		current_progress += 1
		saving_progress.emit(int(float(current_progress) / total_maps * 100))
		print("NoiseMapSaver: Saved Base Height Perlin (Progress: ", current_progress, "/", total_maps, ")")
	
	await _yield_to_main_loop()
	
	# Erosion Perlin
	print("NoiseMapSaver: Generating Erosion Perlin...")
	var perlin_erosion = Helpers._noise_to_texture(size, NoiseTexture2D.new(), elevation_data.erosion_perlin)
	success = await _wait_for_texture(perlin_erosion, "Erosion Perlin")
	if not success or not is_saving:
		return current_progress
	
	image = perlin_erosion.get_image()
	if image:
		image.save_png(perlin_dir + "/Erosion_Perlin.png")
		current_progress += 1
		saving_progress.emit(int(float(current_progress) / total_maps * 100))
		print("NoiseMapSaver: Saved Erosion Perlin (Progress: ", current_progress, "/", total_maps, ")")
	
	await _yield_to_main_loop()
	
	# Temperature Perlin
	print("NoiseMapSaver: Generating Temperature Perlin...")
	var perlin_temperature = Helpers._noise_to_texture(size, NoiseTexture2D.new(), climate_data.temperature_perlin)
	success = await _wait_for_texture(perlin_temperature, "Temperature Perlin")
	if not success or not is_saving:
		return current_progress
	
	image = perlin_temperature.get_image()
	if image:
		image.save_png(perlin_dir + "/Temperature_Perlin.png")
		current_progress += 1
		saving_progress.emit(int(float(current_progress) / total_maps * 100))
		print("NoiseMapSaver: Saved Temperature Perlin (Progress: ", current_progress, "/", total_maps, ")")
	
	await _yield_to_main_loop()
	
	# Precipitation Perlin
	print("NoiseMapSaver: Generating Precipitation Perlin...")
	var perlin_precipitation = Helpers._noise_to_texture(size, NoiseTexture2D.new(), climate_data.precipitation_perlin)
	success = await _wait_for_texture(perlin_precipitation, "Precipitation Perlin")
	if not success or not is_saving:
		return current_progress
	
	image = perlin_precipitation.get_image()
	if image:
		image.save_png(perlin_dir + "/Precipitation_Perlin.png")
		current_progress += 1
		saving_progress.emit(int(float(current_progress) / total_maps * 100))
		print("NoiseMapSaver: Saved Precipitation Perlin (Progress: ", current_progress, "/", total_maps, ")")
	
	await _yield_to_main_loop()
	
	# Humidity Perlin
	print("NoiseMapSaver: Generating Humidity Perlin...")
	var perlin_humidity = Helpers._noise_to_texture(size, NoiseTexture2D.new(), climate_data.humidity_perlin)
	success = await _wait_for_texture(perlin_humidity, "Humidity Perlin")
	if not success or not is_saving:
		return current_progress
	
	image = perlin_humidity.get_image()
	if image:
		image.save_png(perlin_dir + "/Humidity_Perlin.png")
		current_progress += 1
		saving_progress.emit(int(float(current_progress) / total_maps * 100))
		print("NoiseMapSaver: Saved Humidity Perlin (Progress: ", current_progress, "/", total_maps, ")")
	
	await _yield_to_main_loop()
	
	# Water Refraction Perlin (from AssetMaps)
	print("NoiseMapSaver: Generating Water Refraction Perlin...")
	var perlin_water_refraction = Helpers._noise_to_texture(size, NoiseTexture2D.new(), asset_maps.water_refraction_perlin)
	success = await _wait_for_texture(perlin_water_refraction, "Water Refraction Perlin")
	if not success or not is_saving:
		return current_progress
	
	image = perlin_water_refraction.get_image()
	if image:
		image.save_png(perlin_dir + "/WaterRefraction_Perlin.png")
		current_progress += 1
		saving_progress.emit(int(float(current_progress) / total_maps * 100))
		print("NoiseMapSaver: Saved Water Refraction Perlin (Progress: ", current_progress, "/", total_maps, ")")
	
	await _yield_to_main_loop()
	
	# Water Normal Perlin (from AssetMaps)
	print("NoiseMapSaver: Generating Water Normal Perlin...")
	var perlin_water_normal = Helpers._noise_to_texture(size, NoiseTexture2D.new(), asset_maps.water_normal_perlin)
	success = await _wait_for_texture(perlin_water_normal, "Water Normal Perlin")
	if not success or not is_saving:
		return current_progress
	
	image = perlin_water_normal.get_image()
	if image:
		image.save_png(perlin_dir + "/WaterNormal_Perlin.png")
		current_progress += 1
		saving_progress.emit(int(float(current_progress) / total_maps * 100))
		print("NoiseMapSaver: Saved Water Normal Perlin (Progress: ", current_progress, "/", total_maps, ")")
	
	print("NoiseMapSaver: Finished saving Perlin maps")
	return current_progress

func _save_simplex_maps(current_progress: int, total_maps: int, simplex_dir: String) -> int:
	print("NoiseMapSaver: Saving Simplex maps to: ", simplex_dir)
	
	await _yield_to_main_loop()
	
	# Base height Simplex
	print("NoiseMapSaver: Generating Base Height Simplex...")
	var simplex_base_height = Helpers._noise_to_texture(size, SimplexTexture.new(), elevation_data.base_simplex)
	var success = await _wait_for_texture(simplex_base_height, "Base Height Simplex")
	if not success or not is_saving:
		return current_progress
	
	var image = simplex_base_height.get_image()
	if image:
		image.save_png(simplex_dir + "/BaseHeight_Simplex.png")
		current_progress += 1
		saving_progress.emit(int(float(current_progress) / total_maps * 100))
		print("NoiseMapSaver: Saved Base Height Simplex (Progress: ", current_progress, "/", total_maps, ")")
	
	await _yield_to_main_loop()
	
	# Erosion Simplex
	print("NoiseMapSaver: Generating Erosion Simplex...")
	var simplex_erosion = Helpers._noise_to_texture(size, SimplexTexture.new(), elevation_data.erosion_simplex)
	success = await _wait_for_texture(simplex_erosion, "Erosion Simplex")
	if not success or not is_saving:
		return current_progress
	
	image = simplex_erosion.get_image()
	if image:
		image.save_png(simplex_dir + "/Erosion_Simplex.png")
		current_progress += 1
		saving_progress.emit(int(float(current_progress) / total_maps * 100))
		print("NoiseMapSaver: Saved Erosion Simplex (Progress: ", current_progress, "/", total_maps, ")")
	
	await _yield_to_main_loop()
	
	# Temperature Simplex
	print("NoiseMapSaver: Generating Temperature Simplex...")
	var simplex_temperature = Helpers._noise_to_texture(size, SimplexTexture.new(), climate_data.temperature_simplex)
	success = await _wait_for_texture(simplex_temperature, "Temperature Simplex")
	if not success or not is_saving:
		return current_progress
	
	image = simplex_temperature.get_image()
	if image:
		image.save_png(simplex_dir + "/Temperature_Simplex.png")
		current_progress += 1
		saving_progress.emit(int(float(current_progress) / total_maps * 100))
		print("NoiseMapSaver: Saved Temperature Simplex (Progress: ", current_progress, "/", total_maps, ")")
	
	await _yield_to_main_loop()
	
	# Precipitation Simplex
	print("NoiseMapSaver: Generating Precipitation Simplex...")
	var simplex_precipitation = Helpers._noise_to_texture(size, SimplexTexture.new(), climate_data.precipitation_simplex)
	success = await _wait_for_texture(simplex_precipitation, "Precipitation Simplex")
	if not success or not is_saving:
		return current_progress
	
	image = simplex_precipitation.get_image()
	if image:
		image.save_png(simplex_dir + "/Precipitation_Simplex.png")
		current_progress += 1
		saving_progress.emit(int(float(current_progress) / total_maps * 100))
		print("NoiseMapSaver: Saved Precipitation Simplex (Progress: ", current_progress, "/", total_maps, ")")
	
	await _yield_to_main_loop()
	
	# Humidity Simplex
	print("NoiseMapSaver: Generating Humidity Simplex...")
	var simplex_humidity = Helpers._noise_to_texture(size, SimplexTexture.new(), climate_data.humidity_simplex)
	success = await _wait_for_texture(simplex_humidity, "Humidity Simplex")
	if not success or not is_saving:
		return current_progress
	
	image = simplex_humidity.get_image()
	if image:
		image.save_png(simplex_dir + "/Humidity_Simplex.png")
		current_progress += 1
		saving_progress.emit(int(float(current_progress) / total_maps * 100))
		print("NoiseMapSaver: Saved Humidity Simplex (Progress: ", current_progress, "/", total_maps, ")")
	
	await _yield_to_main_loop()
	
	# Water Refraction Simplex (from AssetMaps)
	print("NoiseMapSaver: Generating Water Refraction Simplex...")
	var simplex_water_refraction = Helpers._noise_to_texture(size, SimplexTexture.new(), asset_maps.water_refraction_simplex)
	success = await _wait_for_texture(simplex_water_refraction, "Water Refraction Simplex")
	if not success or not is_saving:
		return current_progress
	
	image = simplex_water_refraction.get_image()
	if image:
		image.save_png(simplex_dir + "/WaterRefraction_Simplex.png")
		current_progress += 1
		saving_progress.emit(int(float(current_progress) / total_maps * 100))
		print("NoiseMapSaver: Saved Water Refraction Simplex (Progress: ", current_progress, "/", total_maps, ")")
	
	await _yield_to_main_loop()
	
	# Water Normal Simplex (from AssetMaps)
	print("NoiseMapSaver: Generating Water Normal Simplex...")
	var simplex_water_normal = Helpers._noise_to_texture(size, SimplexTexture.new(), asset_maps.water_normal_simplex)
	success = await _wait_for_texture(simplex_water_normal, "Water Normal Simplex")
	if not success or not is_saving:
		return current_progress
	
	image = simplex_water_normal.get_image()
	if image:
		image.save_png(simplex_dir + "/WaterNormal_Simplex.png")
		current_progress += 1
		saving_progress.emit(int(float(current_progress) / total_maps * 100))
		print("NoiseMapSaver: Saved Water Normal Simplex (Progress: ", current_progress, "/", total_maps, ")")
	
	print("NoiseMapSaver: Finished saving Simplex maps")
	return current_progress

func _wait_for_texture(texture: Texture2D, texture_name: String) -> bool:
	if texture == null:
		print("NoiseMapSaver: Warning - ", texture_name, " texture is null")
		saving_failed.emit("Failed to generate " + texture_name)
		return false
		
	var attempts = 0
	var max_attempts = 600  # Prevent infinite loops (about 10 seconds at 60fps)
	
	while (texture.get_image() == null or texture.get_image().is_empty()) and attempts < max_attempts and is_saving:
		attempts += 1
		if attempts % 60 == 0:  # Print every second at 60fps
			print("NoiseMapSaver: Waiting for ", texture_name, " to generate... (", attempts/60, " seconds)")
		
		# Use a safe way to yield without requiring a node in tree
		await _yield_to_main_loop()
	
	if attempts >= max_attempts:
		print("NoiseMapSaver: Warning - ", texture_name, " generation timed out")
		saving_failed.emit(texture_name + " generation timed out")
		return false
	
	if not is_saving:
		print("NoiseMapSaver: ", texture_name, " generation cancelled")
		return false
	
	print("NoiseMapSaver: ", texture_name, " generated after ", attempts, " frames")
	return true

func _yield_to_main_loop():
	# Safe way to yield without assuming we're in the scene tree
	await Engine.get_main_loop().process_frame

func cancel_saving():
	if is_saving:
		print("NoiseMapSaver: Cancelling save operation...")
		is_saving = false
		saving_failed.emit("Save operation cancelled by user")
