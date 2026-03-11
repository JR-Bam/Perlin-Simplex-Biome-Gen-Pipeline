extends Control

@onready var main_scene_progress_bar: SceneLoader = $MainSceneTracker/ProgressBar
@onready var main_scene_timing_label: Label = $MainSceneTracker/ProgressTiming

@onready var terrain_progress_bar: ProgressBar = $TerrainTracker/ProgressBar
@onready var terrain_timing_label: Label = $TerrainTracker/ProgressTiming
@onready var terrain_status: Label = $TerrainTracker/ProgressStatus

@onready var scatter_progress_bar: ProgressBar = $ScatterTracker/ProgressBar
@onready var scatter_timing_label: Label = $ScatterTracker/ScrollContainer/ProgressTiming
@onready var scatter_status: Label = $ScatterTracker/ProgressStatus
@onready var scatter_biome: Label = $ScatterTracker/ProgressBiome

@onready var clouds_progress_bar: ProgressBar = $CloudsTracker/ProgressBar
@onready var clouds_timing_label: Label = $CloudsTracker/ProgressTiming

var load_start_time: float
var main_scene_loaded_time: float
var main_scene_instance: Node
var terrain_node: Node
var scatter_node: Node
var clouds_node: CloudsController

const MAIN_SCENE_NAME = "res://main.tscn"

# Track completion status
var terrain_complete: bool = false
var scatter_complete: bool = false
var clouds_complete: bool = false
var export_saved: bool = false

# Dictionary mapping original keys to readable names
var column_name_mapping = {
	# Terrain mappings
	"terrain/TOTAL": "Terrain - Total Time (ms)",
	"terrain/collision_creation": "Terrain - Collision Creation (ms)",
	"terrain/vertex_generation": "Terrain - Vertex Generation (ms)",
	"terrain/triangle_generation": "Terrain - Triangle Generation (ms)",
	"terrain/texturization/total_texturization": "Terrain - Texturization Total (ms)",
	"terrain/texturization/temperature_texture": "Terrain - Temperature Texture (ms)",
	"terrain/texturization/humidity_texture": "Terrain - Humidity Texture (ms)",
	"terrain/texturization/precipitation_texture": "Terrain - Precipitation Texture (ms)",
	"terrain/texturization/shader_creation": "Terrain - Shader Creation (ms)",
	"terrain/texturization/apply_material": "Terrain - Apply Material (ms)",
	"terrain/water_update/total_water_update": "Terrain - Water Update Total (ms)",
	"terrain/water_update/mesh_configuration": "Terrain - Water Mesh Config (ms)",
	"terrain/water_update/normal_texture": "Terrain - Water Normal Texture (ms)",
	"terrain/water_update/refraction_texture": "Terrain - Water Refraction Texture (ms)",
	"terrain/water_update/shader_application": "Terrain - Water Shader Apply (ms)",
	"terrain/water_update/texture_generation_wait": "Terrain - Water Texture Wait (ms)",
	
	# Scatter global mappings
	"scatter/TOTAL": "Scatter - Total Time (ms)",
	"scatter/global_lod_count": "Scatter - Global LOD Count",
	"scatter/global_lod_creation": "Scatter - Global LOD Creation (ms)",
	
	# Clouds mappings
	"clouds/add_shader_variables/total": "Clouds - Add Shader Variables (ms)",
	"clouds/update_global_variable_textures": "Clouds - Update Global Var Textures (ms)",
	"clouds/update_global_variables": "Clouds - Update Global Variables (ms)"
}

# Biome-specific scatter mappings (will be generated dynamically)
func get_biome_column_name(biome: String, metric: String) -> String:
	var biome_display = biome.replace("_", " ").capitalize()
	match metric:
		"total": return "Scatter - %s - Total (ms)" % biome_display
		"lod_creation": return "Scatter - %s - LOD Creation (ms)" % biome_display
		"scanning": return "Scatter - %s - Scanning (ms)" % biome_display
		"prop_loading": return "Scatter - %s - Prop Loading (ms)" % biome_display
		"misc/grid_cells": return "Scatter - %s - Grid Cells" % biome_display
		"misc/matches": return "Scatter - %s - Matches Found" % biome_display
		"misc/spawned": return "Scatter - %s - Props Spawned" % biome_display
		"skipped": return "Scatter - %s - Skipped (ms)" % biome_display
		_ : return "Scatter - %s - %s" % [biome_display, metric.capitalize()]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_start_time = Time.get_ticks_msec()
	main_scene_progress_bar.load(MAIN_SCENE_NAME)


func _on_scene_loaded(path: String):
	main_scene_progress_bar.value = 100
	var total_time = Time.get_ticks_msec() - load_start_time
	main_scene_timing_label.text = "Total Load: %d ms" % total_time
	# Instance the main scene
	var loaded_main_scene = ResourceLoader.load_threaded_get(path) # Should just be MAIN_SCENE_NAME
	main_scene_instance = loaded_main_scene.instantiate()
	add_child(main_scene_instance)
	
	clouds_node = main_scene_instance.get_node_or_null("CloudsController")
	if clouds_node and clouds_node.has_signal("initialization_progress"):
		clouds_node.initialization_progress.connect(_on_clouds_progress)
	else:
		clouds_progress_bar.value = 100
		clouds_timing_label.text = "Status: No CloudsController found"
		clouds_complete = true
	
	# Find the Terrain node
	terrain_node = main_scene_instance.get_node_or_null("Terrain")
	if terrain_node and terrain_node.has_signal("terrain_progress"):
		terrain_status.text = "Status: Generating terrain..."
		terrain_node.terrain_progress.connect(_on_terrain_progress)
	else:
		# No terrain found, just mark as complete
		terrain_status.text = "Status: No terrain found"
		terrain_progress_bar.value = 100
		terrain_complete = true
	
	scatter_node = main_scene_instance.get_node_or_null("Terrain/PropScatterer")
	if scatter_node and scatter_node.has_signal("scatter_progress"):
		scatter_status.text = "Status: Scattering props..."
		scatter_node.scatter_progress.connect(_on_scatter_progress)
	else:
		# No scatter found, just mark as complete
		scatter_status.text = "Status: No prop scatterer found"
		scatter_progress_bar.value = 100
		scatter_complete = true
	
	# Check if all are already complete
	check_all_complete()

func _on_terrain_progress(percent: float, stage: String):
	terrain_progress_bar.value = percent
	terrain_status.text = "Stage: %s" % stage  # Stage goes to status label
	
	if percent >= 100:
		terrain_complete = true
		
		# Get detailed execution times from terrain
		var times = terrain_node.execution_times
		var timing_text := Helpers.format_dict(times, 0)
		
		timing_text += "\nTotal: %d ms" % times["TOTAL"]
		
		# Update the timing label with detailed info
		terrain_timing_label.text = timing_text
		# Status already shows "Complete" from the stage parameter
		
		check_all_complete()

func _on_scatter_progress(percent: float, stage: String, biome: String):
	scatter_progress_bar.value = percent
	scatter_status.text = "Stage: %s" % stage  # Stage goes to status label
	scatter_biome.text = "Biome: %s" % biome
	
	if percent >= 100:
		scatter_complete = true
		
		# Get detailed execution times from prop scatterer
		var times = scatter_node.execution_times
		var timing_text := Helpers.format_dict(times, 0)
		
		timing_text += "\nTotal: %d ms" % times["TOTAL"]
		
		# Update the timing label with detailed info
		scatter_timing_label.text = timing_text
		# Status already shows "Complete" from the stage parameter
		
		check_all_complete()

func _on_clouds_progress(percent: int):
	clouds_progress_bar.value = percent
	
	if percent >= 100:
		clouds_complete = true
		
		var times = clouds_node.execution_times
		var timing_text := Helpers.format_dict(times, 0)
		
		timing_text += "\nTotal: %d ms" % times["TOTAL"]
		clouds_timing_label.text = timing_text
		
		check_all_complete()

func check_all_complete():
	# Check if all components are complete and export hasn't been saved yet
	if terrain_complete and scatter_complete and clouds_complete and not export_saved:
		export_saved = true
		export_execution_times_as_csv()

# Recursive function to flatten nested dictionaries
func flatten_dict(dict_data: Dictionary, parent_key: String = "") -> Dictionary:
	var result = {}
	
	for key in dict_data.keys():
		var value = dict_data[key]
		var new_key = parent_key + "/" + key if parent_key else key
		
		if typeof(value) == TYPE_DICTIONARY:
			# Recursively flatten nested dictionary
			var nested = flatten_dict(value, new_key)
			for nested_key in nested.keys():
				result[nested_key] = nested[nested_key]
		else:
			# Store primitive values directly
			result[new_key] = value
	
	return result

func get_readable_column_name(original_key: String) -> String:
	# Check if we have a direct mapping
	if column_name_mapping.has(original_key):
		return column_name_mapping[original_key]
	
	# Check if this is a biome-specific scatter key
	if original_key.begins_with("scatter/biome_details/"):
		var parts = original_key.split("/")
		if parts.size() >= 4:
			var biome = parts[2]  # biome name
			var metric_parts = parts.slice(3)  # everything after biome
			var metric = "/".join(metric_parts)
			return get_biome_column_name(biome, metric)
	
	# Return original if no mapping found (with spaces for readability)
	return original_key.replace("_", " ").replace("/", " - ").capitalize()

func get_size_folder(size_value: int) -> String:
	match size_value:
		1000:
			return "Small"
		3000:
			return "Medium"
		5000:
			return "Large"
		_:
			return str(size_value)

func export_execution_times_as_csv():
	# Load configuration
	var Config: WorldConfigResource = load("res://world_config.tres")
	
	# Get size folder name
	var size_folder = get_size_folder(Config.size)
	
	# Create logs directory with size subfolder
	var logs_dir = "user://init-gen-logs/%s/" % size_folder
	DirAccess.make_dir_absolute(logs_dir)
	
	# Generate noise type string
	var noise = "Simplex" if Config.noise_type == 0 else "Perlin"
	
	# Generate filename with timestamp
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var filename = logs_dir + "init_gen_data_%s_%s_Round%d.csv" % [timestamp, noise, Config.round]
	
	# Create the CSV file
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file:
		# Prepare flattened data structures
		var flattened_data = {
			"terrain": flatten_dict(terrain_node.execution_times) if terrain_node else {},
			"scatter": flatten_dict(scatter_node.execution_times) if scatter_node else {},
			"clouds": flatten_dict(clouds_node.execution_times) if clouds_node else {}
		}
		
		# Collect all unique flattened keys from all categories
		var all_keys = []
		
		# Add metadata keys first
		all_keys.append("metadata/noise_type")
		all_keys.append("metadata/round")
		all_keys.append("metadata/seed")
		
		# Add all data keys
		for category in flattened_data:
			for key in flattened_data[category].keys():
				# Add category prefix with proper slash separation
				var full_key = "%s/%s" % [category, key]
				if full_key not in all_keys:
					all_keys.append(full_key)
		
		# Sort keys for consistent output (keeping metadata at the beginning)
		# We'll manually ensure metadata stays first
		var sorted_keys = []
		sorted_keys.append("metadata/noise_type")
		sorted_keys.append("metadata/round")
		sorted_keys.append("metadata/seed")
		
		var remaining_keys = all_keys.slice(2)  # Remove metadata keys
		remaining_keys.sort()
		sorted_keys += remaining_keys
		
		# Generate readable headers
		var readable_headers = []
		for key in sorted_keys:
			if key == "metadata/noise_type":
				readable_headers.append("Algoruth")
			elif key == "metadata/round":
				readable_headers.append("Round")
			elif key == "metadata/seed":
				readable_headers.append("Seed")
			else:
				readable_headers.append(get_readable_column_name(key))
		
		# Write header row with readable names
		file.store_line(",".join(readable_headers))
		
		# Write data row - we need to create one row with values from all categories
		var row_values = []
		for full_key in sorted_keys:
			if full_key == "metadata/noise_type":
				row_values.append(noise)
			elif full_key == "metadata/round":
				row_values.append(str(Config.round))
			elif full_key == "metadata/seed":
				row_values.append(Config.seed)
			else:
				# Split into category and actual key path
				var parts = full_key.split("/")
				var category = parts[0]
				# Rejoin the rest of the path (everything after the first slash)
				var key_path = "/".join(parts.slice(1))
				
				# Get the value if it exists
				if flattened_data.has(category) and flattened_data[category].has(key_path):
					row_values.append(str(flattened_data[category][key_path]))
				else:
					row_values.append("")
		
		# Write the single data row
		file.store_line(",".join(row_values))
		file.close()
		
		print("Execution times exported to: ", filename)
		print("Headers: ", readable_headers)
