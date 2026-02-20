extends Resource
class_name ElevationData

@export_group("Base Height")
@export var base_simplex: Simplex = Simplex.new()
@export var base_perlin: FastNoiseLite = FastNoiseLite.new()
@export_group("Erosion")
@export var erosion_simplex: Simplex = Simplex.new()
@export var erosion_perlin: FastNoiseLite = FastNoiseLite.new()
