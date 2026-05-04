extends Resource
class_name WorldConfigResource

@export_enum("Simplex", "FastNoiseLite") var noise_type: int = 0
@export var subdivisions: int = 50
@export var size: int = 500
@export var amplitude := 100
@export var blend_radius: float = 0.05
@export var seed: int = 0
@export var round: Variant = null
@export var debug: bool = true

# Biome Thresholds - Updated realistic configuration with ~10% gaps
@export_group("Ocean Thresholds")
@export_range(0.0, 1.0, 0.01) var ocean_e_min: float = 0.0
@export_range(0.0, 1.0, 0.01) var ocean_e_max: float = 0.25
@export_range(0.0, 1.0, 0.01) var ocean_t_min: float = 0.0
@export_range(0.0, 1.0, 0.01) var ocean_t_max: float = 1.0
@export_range(0.0, 1.0, 0.01) var ocean_p_min: float = 0.0
@export_range(0.0, 1.0, 0.01) var ocean_p_max: float = 1.0
@export_range(0.0, 1.0, 0.01) var ocean_h_min: float = 0.0
@export_range(0.0, 1.0, 0.01) var ocean_h_max: float = 1.0

@export_group("Desert Thresholds")
@export_range(0.0, 1.0, 0.01) var desert_e_min: float = 0.1
@export_range(0.0, 1.0, 0.01) var desert_e_max: float = 0.9
@export_range(0.0, 1.0, 0.01) var desert_t_min: float = 0.5
@export_range(0.0, 1.0, 0.01) var desert_t_max: float = 1.0
@export_range(0.0, 1.0, 0.01) var desert_p_min: float = 0.0
@export_range(0.0, 1.0, 0.01) var desert_p_max: float = 0.2  # Reduced from 0.3 - REAL: Extremely low precipitation
@export_range(0.0, 1.0, 0.01) var desert_h_min: float = 0.0
@export_range(0.0, 1.0, 0.01) var desert_h_max: float = 0.3  # Reduced from 1.0 - REAL: Very dry air

@export_group("Grassland Thresholds")
@export_range(0.0, 1.0, 0.01) var grassland_e_min: float = 0.1
@export_range(0.0, 1.0, 0.01) var grassland_e_max: float = 0.9
@export_range(0.0, 1.0, 0.01) var grassland_t_min: float = 0.2
@export_range(0.0, 1.0, 0.01) var grassland_t_max: float = 0.8  # Increased from 0.7 - Slightly expanded
@export_range(0.0, 1.0, 0.01) var grassland_p_min: float = 0.1
@export_range(0.0, 1.0, 0.01) var grassland_p_max: float = 0.5  # REAL: Moderate precipitation
@export_range(0.0, 1.0, 0.01) var grassland_h_min: float = 0.2
@export_range(0.0, 1.0, 0.01) var grassland_h_max: float = 0.7  # REAL: Moderate humidity

@export_group("Savanna Thresholds")
@export_range(0.0, 1.0, 0.01) var savanna_e_min: float = 0.1
@export_range(0.0, 1.0, 0.01) var savanna_e_max: float = 0.9
@export_range(0.0, 1.0, 0.01) var savanna_t_min: float = 0.6  # Increased from 0.5 - Hot
@export_range(0.0, 1.0, 0.01) var savanna_t_max: float = 1.0
@export_range(0.0, 1.0, 0.01) var savanna_p_min: float = 0.3
@export_range(0.0, 1.0, 0.01) var savanna_p_max: float = 0.7  # REAL: Wet/dry seasons
@export_range(0.0, 1.0, 0.01) var savanna_h_min: float = 0.2
@export_range(0.0, 1.0, 0.01) var savanna_h_max: float = 0.7  # REAL: Seasonal humidity

@export_group("Tundra Thresholds")
@export_range(0.0, 1.0, 0.01) var tundra_e_min: float = 0.1
@export_range(0.0, 1.0, 0.01) var tundra_e_max: float = 0.9
@export_range(0.0, 1.0, 0.01) var tundra_t_min: float = 0.0
@export_range(0.0, 1.0, 0.01) var tundra_t_max: float = 0.4  # Increased from 0.3 - Covers more cold range
@export_range(0.0, 1.0, 0.01) var tundra_p_min: float = 0.0  # Reduced from 0.1 - Polar deserts exist
@export_range(0.0, 1.0, 0.01) var tundra_p_max: float = 1.0  # Increased from 0.5 - Full range
@export_range(0.0, 1.0, 0.01) var tundra_h_min: float = 0.0  # Reduced from 0.2 - Cold deserts exist
@export_range(0.0, 1.0, 0.01) var tundra_h_max: float = 1.0  # Increased from 0.7 - Full range

@export_group("Boreal Forest Thresholds")
@export_range(0.0, 1.0, 0.01) var boreal_forest_e_min: float = 0.1
@export_range(0.0, 1.0, 0.01) var boreal_forest_e_max: float = 0.9
@export_range(0.0, 1.0, 0.01) var boreal_forest_t_min: float = 0.2  # Increased from 0.15
@export_range(0.0, 1.0, 0.01) var boreal_forest_t_max: float = 0.5
@export_range(0.0, 1.0, 0.01) var boreal_forest_p_min: float = 0.3  # Increased from 0.2
@export_range(0.0, 1.0, 0.01) var boreal_forest_p_max: float = 0.8  # Reduced from 1.0
@export_range(0.0, 1.0, 0.01) var boreal_forest_h_min: float = 0.3
@export_range(0.0, 1.0, 0.01) var boreal_forest_h_max: float = 0.9  # REAL: Moist

@export_group("Temperate Forest Thresholds")
@export_range(0.0, 1.0, 0.01) var temperate_forest_e_min: float = 0.1
@export_range(0.0, 1.0, 0.01) var temperate_forest_e_max: float = 0.9
@export_range(0.0, 1.0, 0.01) var temperate_forest_t_min: float = 0.3
@export_range(0.0, 1.0, 0.01) var temperate_forest_t_max: float = 0.7  # Increased from 0.65
@export_range(0.0, 1.0, 0.01) var temperate_forest_p_min: float = 0.5
@export_range(0.0, 1.0, 0.01) var temperate_forest_p_max: float = 1.0
@export_range(0.0, 1.0, 0.01) var temperate_forest_h_min: float = 0.4
@export_range(0.0, 1.0, 0.01) var temperate_forest_h_max: float = 0.9  # REAL: Humid

@export_group("Woodland Thresholds")
@export_range(0.0, 1.0, 0.01) var woodland_e_min: float = 0.1
@export_range(0.0, 1.0, 0.01) var woodland_e_max: float = 0.9
@export_range(0.0, 1.0, 0.01) var woodland_t_min: float = 0.4
@export_range(0.0, 1.0, 0.01) var woodland_t_max: float = 0.8  # Increased from 0.75
@export_range(0.0, 1.0, 0.01) var woodland_p_min: float = 0.2  # Increased from 0.1
@export_range(0.0, 1.0, 0.01) var woodland_p_max: float = 0.6
@export_range(0.0, 1.0, 0.01) var woodland_h_min: float = 0.2
@export_range(0.0, 1.0, 0.01) var woodland_h_max: float = 0.7  # REAL: Moderate

@export_group("Rainforest Thresholds")
@export_range(0.0, 1.0, 0.01) var rainforest_e_min: float = 0.1
@export_range(0.0, 1.0, 0.01) var rainforest_e_max: float = 0.9
@export_range(0.0, 1.0, 0.01) var rainforest_t_min: float = 0.6
@export_range(0.0, 1.0, 0.01) var rainforest_t_max: float = 1.0
@export_range(0.0, 1.0, 0.01) var rainforest_p_min: float = 0.8  # Increased from 0.7 - REAL: Extremely high precipitation
@export_range(0.0, 1.0, 0.01) var rainforest_p_max: float = 1.0
@export_range(0.0, 1.0, 0.01) var rainforest_h_min: float = 0.6
@export_range(0.0, 1.0, 0.01) var rainforest_h_max: float = 1.0  # REAL: Extremely humid

@export_group("Mountain Thresholds")
@export_range(0.0, 1.0, 0.01) var mountain_e_min: float = 0.8  # Reduced from 0.85 - Catches more high elevations
@export_range(0.0, 1.0, 0.01) var mountain_e_max: float = 1.0
@export_range(0.0, 1.0, 0.01) var mountain_t_min: float = 0.0
@export_range(0.0, 1.0, 0.01) var mountain_t_max: float = 1.0
@export_range(0.0, 1.0, 0.01) var mountain_p_min: float = 0.0
@export_range(0.0, 1.0, 0.01) var mountain_p_max: float = 1.0
@export_range(0.0, 1.0, 0.01) var mountain_h_min: float = 0.0
@export_range(0.0, 1.0, 0.01) var mountain_h_max: float = 1.0
