extends Resource
class_name BiomePropData

@export var scene: PackedScene
@export var proportionality: float = 1.0
@export var spawn_density: float = 0.0

func _init(p_scene: PackedScene = null, p_proportionality: float = 1.0, p_spawn_density: float = 0.0):
	scene = p_scene
	proportionality = p_proportionality
	spawn_density = p_spawn_density
