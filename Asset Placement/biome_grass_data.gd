extends Resource
class_name BiomeGrassData

## Grass scene to spawn (should be a simple grass blade mesh)
@export var grass_scene: PackedScene

## Spawn density for this grass in this biome (0.0-1.0)
@export var spawn_density: float = 1.0

## Height range for grass in this biome
@export var height_min: float = 0.3
@export var height_max: float = 0.6

## Small grass color (younger/shorter grass)
@export var color_small: Color = Color(0.3, 0.6, 0.1)

## Large grass color (older/taller grass)
@export var color_large: Color = Color(0.9, 0.9, 0.2)

## Blade bend amount
@export var blade_bend: float = 0.5

## Size variation
@export var size_small: float = 0.2
@export var size_large: float = 0.6

## Patching/clumping scale
@export var patch_scale: float = 5.0

func _init(
	p_grass_scene: PackedScene = null,
	p_spawn_density: float = 1.0,
	p_height_min: float = 0.3,
	p_height_max: float = 0.6,
	p_color_small: Color = Color(0.3, 0.6, 0.1),
	p_color_large: Color = Color(0.9, 0.9, 0.2),
	p_blade_bend: float = 0.5,
	p_size_small: float = 0.2,
	p_size_large: float = 0.6,
	p_patch_scale: float = 5.0
):
	grass_scene = p_grass_scene
	spawn_density = p_spawn_density
	height_min = p_height_min
	height_max = p_height_max
	color_small = p_color_small
	color_large = p_color_large
	blade_bend = p_blade_bend
	size_small = p_size_small
	size_large = p_size_large
	patch_scale = p_patch_scale
