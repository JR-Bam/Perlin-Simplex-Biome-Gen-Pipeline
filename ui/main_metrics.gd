extends Control

@onready var main_scene_progress_bar: SceneLoader = $MainSceneTracker/ProgressBar
@onready var main_scene_timing_label: Label = $MainSceneTracker/ProgressTiming

@onready var terrain_progress_bar: ProgressBar = $TerrainTracker/ProgressBar
@onready var terrain_timing_label: Label = $TerrainTracker/ProgressTiming
@onready var terrain_status: Label = $TerrainTracker/ProgressStatus

var load_start_time: float
var main_scene_loaded_time: float
var main_scene_instance: Node
var terrain_node: Node

const MAIN_SCENE_NAME = "res://main.tscn"

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
	
	# Find the Terrain node
	terrain_node = main_scene_instance.get_node_or_null("Terrain")
	if terrain_node and terrain_node.has_signal("terrain_progress"):
		terrain_status.text = "Status: Generating terrain..."
		terrain_node.terrain_progress.connect(_on_terrain_progress)
	else:
		# No terrain found, just mark as complete
		terrain_status.text = "Status: No terrain found"
		terrain_progress_bar.value = 100

func _on_terrain_progress(percent: float, stage: String):
	terrain_progress_bar.value = percent
	terrain_status.text = "Stage: %s" % stage  # Stage goes to status label
	
	if percent >= 100:
		var total_time = Time.get_ticks_msec() - load_start_time
		
		# Get detailed execution times from terrain
		var times = terrain_node.execution_times
		var timing_text := Helpers.format_dict(times, 0)
		
		# Update the timing label with detailed info
		terrain_timing_label.text = timing_text
		# Status already shows "Complete" from the stage parameter
