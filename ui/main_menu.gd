extends Control

@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var noise_option: OptionButton = $CenterContainer/VBoxContainer/MarginContainer2/NoiseOption

const CONFIG_PATH = "res://world_config.tres"
var Config: WorldConfigResource = load(CONFIG_PATH)


func _ready():
	start_button.pressed.connect(_on_start_pressed)
	

func _on_start_pressed():
	Config.noise_type = noise_option.selected
	ResourceSaver.save(Config, CONFIG_PATH)
	
	print("Noise type: ", Config.noise_type)
	get_tree().change_scene_to_file("res://ui/main_metrics.tscn")
