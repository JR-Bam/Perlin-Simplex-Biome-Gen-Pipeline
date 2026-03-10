extends Control

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var noise_option: OptionButton = $CenterContainer/VBoxContainer/MarginContainer3/HBoxContainer/NoiseOption
@onready var world_size_option: OptionButton = $CenterContainer/VBoxContainer/MarginContainer3/HBoxContainer/WorldSizeOption

@onready var export_button: Button = $CenterContainer/VBoxContainer/MarginContainer4/ExportButton
@onready var export_progress: ProgressBar = $CenterContainer/VBoxContainer/ExportProgress

@onready var seed_input: LineEdit = $CenterContainer/VBoxContainer/MarginContainer3/HBoxContainer/SeedInput

const CONFIG_PATH = "res://world_config.tres"
var Config: WorldConfigResource = load(CONFIG_PATH)


func _ready():
	start_button.pressed.connect(_on_start_pressed)
	export_button.pressed.connect(_on_export_pressed)

func _on_start_pressed():
	update_configs()
	ResourceSaver.save(Config, CONFIG_PATH)
	
	print("Noise type: ", Config.noise_type)
	get_tree().change_scene_to_file("res://ui/main_metrics.tscn")


func _on_export_pressed():
	update_configs()
	
	start_button.disabled = true
	start_button.visible = false
	export_progress.visible = true
	export_button.disabled = true
	export_button.visible = false
	var saver := NoiseMapSaver.new()
	saver.saving_progress.connect(_on_save_progress)
	saver.size = Config.size
	saver.start()

func update_configs():
	Config.noise_type = noise_option.selected
	match world_size_option.selected:
		0: Config.size = 1000
		1: Config.size = 3000
		2: Config.size = 5000
	Config.seed = int(seed_input.text) if not seed_input.text.is_empty() else 0

func _on_save_progress(progress: int):
	export_progress.value = progress
	
	if progress == 100:
		export_button.disabled = false
		export_button.visible = true
		start_button.disabled = false
		start_button.visible = true
		export_progress.visible = false
