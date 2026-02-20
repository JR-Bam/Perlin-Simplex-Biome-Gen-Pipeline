extends Resource
class_name ClimateData

@export_group("Temperature")
@export var temperature_simplex: Simplex = Simplex.new()
@export var temperature_perlin: FastNoiseLite = FastNoiseLite.new()
@export_group("Precipitation")
@export var precipitation_simplex: Simplex = Simplex.new()
@export var precipitation_perlin: FastNoiseLite = FastNoiseLite.new()
@export_group("Humidity")
@export var humidity_simplex: Simplex = Simplex.new()
@export var humidity_perlin: FastNoiseLite = FastNoiseLite.new()
