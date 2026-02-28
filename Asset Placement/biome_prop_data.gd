extends Resource
class_name BiomePropData

@export var scene: PackedScene
@export var proportionality: float = 1.0

func _init(p_scene: PackedScene = null, p_proportionality: float = 1.0):
	scene = p_scene
	proportionality = p_proportionality
