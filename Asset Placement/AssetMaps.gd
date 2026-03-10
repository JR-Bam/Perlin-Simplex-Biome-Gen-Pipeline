extends Resource
class_name AssetMaps

@export_group("Water Refraction")
@export var water_refraction_simplex: Simplex = Simplex.new()
@export var water_refraction_perlin: FastNoiseLite = FastNoiseLite.new()
@export_group("Water Normal")
@export var water_normal_simplex: Simplex = Simplex.new()
@export var water_normal_perlin: FastNoiseLite = FastNoiseLite.new()
