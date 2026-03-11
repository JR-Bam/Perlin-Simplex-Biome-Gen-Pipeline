@tool
@icon("res://addons/SunshineVolumetricClouds/SunshineIcon.svg")
extends Node
class_name CloudsController;

signal initialization_progress(progress: int)

var execution_times = {
	"add_shader_variables": {
		"base_noise_texture": 0.0,
		"base_noise_detail_texture": 0.0,
		"base_noise_large_scale_texture": 0.0,
		"total": 0.0
	},
	"update_global_variable_textures": 0.0,
	"update_global_variables": 0.0,
	"TOTAL": 0.0
}

@export var updateConstantly = false;
@export var sunLight : DirectionalLight3D;
@export var worldEnvironment : WorldEnvironment;

@export_group("Textures")
@export var gradientControlTexture : GradientTexture1D;
@export var baseNoiseTexture : Texture3D;
@export var detailNoiseTexture : Texture3D;
@export var largeScaleNoiseTexture : Texture3D;

@export_group("Weather Controls")
@export var windDirection : Vector2 = Vector2(1, 0);
@export var windSpeed : float = 0.003;

@export_range(0,2) var cloudsCutoff : float = 0.213;
@export var cloudsFloor : float = 80.0;
@export var cloudsCeiling : float = 2000.0;

@export var globalCloudScale : float = 10000;
@export var baseNoiseScale : float = 1.761;
@export var detailNoiseScale : float = 5.921;
@export var detailNoisePower : float = 1.048;
@export var largeScaleNoiseScale : float = 0.216;
@export var largeScaleNoisePower : float = 3.435;

@export_subgroup("Enviroment and Light Driven Controls")
@export var sunColorDefault : Color = Color(1, 1, 1);
@export var overrideAmbientLight : bool = false;
@export var ambientColorDefault : Color = Color(0, 0, 0);
@export var useFogDefault : bool = true;
@export var fogColorDefault : Color = Color(1, 1, 1);

@onready var Config: WorldConfigResource = preload("res://world_config.tres")

func _ready():
	if (!Engine.is_editor_hint()):
		var total_start = Time.get_ticks_msec()
		
		# Emit initial progress
		initialization_progress.emit(0)
		await get_tree().process_frame  # Wait one frame
		
		# Time AddShaderVariables (which includes individual noise texture creation)
		AddShaderVariables()
		initialization_progress.emit(33)
		await get_tree().process_frame  # Wait one frame
		
		# Time UpdateGlobalVariableTextures
		var textures_start = Time.get_ticks_msec()
		UpdateGlobalVariableTextures()
		execution_times.update_global_variable_textures = (Time.get_ticks_msec() - textures_start)
		initialization_progress.emit(66)
		await get_tree().process_frame  # Wait one frame
		
		# Time UpdateGlobalVariables
		var variables_start = Time.get_ticks_msec()
		UpdateGlobalVariables()
		execution_times.update_global_variables = (Time.get_ticks_msec() - variables_start)
		initialization_progress.emit(100)
		
		execution_times.TOTAL = (Time.get_ticks_msec() - total_start)
		print("Execution Times: ", JSON.stringify(execution_times, "\t"))

func create_base_noise_texture():
	var start_time = Time.get_ticks_msec()
	
	var noise_texture = SimplexTexture3D.new() if Config.noise_type == 0 else NoiseTexture3D.new()
	
	var noise = Simplex.new() if Config.noise_type == 0 else FastNoiseLite.new()
	if Config.noise_type == 1:
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
	else:
		noise.fractal_type = Simplex.FRACTAL_FBM
	noise.frequency = 0.0904
	noise.fractal_lacunarity = 3.06
	noise.fractal_gain = 0.15
	
	noise_texture.set_seamless(true)
	noise_texture.set_seamless_blend_skirt(0.4)
	#noise_texture.set_normalize(false)
	noise_texture.set_noise(noise)
	
	execution_times.add_shader_variables.base_noise_texture = (Time.get_ticks_msec() - start_time)
	return noise_texture

func create_large_scale_noise_texture():
	var start_time = Time.get_ticks_msec()
	
	var noise_texture = SimplexTexture3D.new() if Config.noise_type == 0 else NoiseTexture3D.new()
	
	var noise = Simplex.new() if Config.noise_type == 0 else FastNoiseLite.new()
	if Config.noise_type == 1:
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
	else:
		noise.fractal_type = Simplex.FRACTAL_FBM
	noise.frequency = 0.2175
	noise.fractal_lacunarity = 3.26
	
	# Load the gradient resource
	var gradient = load("res://Asset Placement/large_scale_noise_color_ramp.tres")
	
	# Configure NoiseTexture3D
	noise_texture.set_invert(true)
	noise_texture.set_seamless(true)
	noise_texture.set_seamless_blend_skirt(0.4)
	noise_texture.set_color_ramp(gradient)
	noise_texture.set_noise(noise)
	
	execution_times.add_shader_variables.base_noise_large_scale_texture = (Time.get_ticks_msec() - start_time)
	return noise_texture

func create_detail_noise_texture():
	var start_time = Time.get_ticks_msec()
	
	var noise_texture = SimplexTexture3D.new() if Config.noise_type == 0 else NoiseTexture3D.new()
	
	var noise = Simplex.new() if Config.noise_type == 0 else FastNoiseLite.new()
	if Config.noise_type == 1:
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.161
	noise.fractal_type = Simplex.FRACTAL_RIDGED if Config.noise_type == 0 else FastNoiseLite.FRACTAL_RIDGED
	noise.fractal_lacunarity = 3.26
	
	# Configure NoiseTexture3D
	noise_texture.set_invert(true)
	noise_texture.set_seamless(true)
	noise_texture.set_seamless_blend_skirt(0.4)
	noise_texture.set_noise(noise)
	
	execution_times.add_shader_variables.base_noise_detail_texture = (Time.get_ticks_msec() - start_time)
	return noise_texture

func AddShaderVariables():
	var add_shader_start = Time.get_ticks_msec()
	
	var HeightWeightGradient = ResourceLoader.load("res://addons/SunshineVolumetricClouds/HeightWeightGradient.tres")
	RenderingServer.global_shader_parameter_add("SunshineClouds_HeightWeightGradient", RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D, HeightWeightGradient)

	# Create and add Base Noise Texture
	var BaseNoiseTexture = create_base_noise_texture()
	RenderingServer.global_shader_parameter_add("SunshineClouds_BaseNoiseTexture", RenderingServer.GLOBAL_VAR_TYPE_SAMPLER3D, BaseNoiseTexture)

	# Create and add Detail Noise Texture
	var DetailNoiseTexture = create_detail_noise_texture()
	RenderingServer.global_shader_parameter_add("SunshineClouds_DetailNoiseTexture", RenderingServer.GLOBAL_VAR_TYPE_SAMPLER3D, DetailNoiseTexture)

	# Create and add Large Scale Noise Texture
	var LargeScaleNoiseTexture = create_large_scale_noise_texture()
	RenderingServer.global_shader_parameter_add("SunshineClouds_LargeScaleNoiseTexture", RenderingServer.GLOBAL_VAR_TYPE_SAMPLER3D, LargeScaleNoiseTexture)

	RenderingServer.global_shader_parameter_add("SunshineClouds_SunDirection", RenderingServer.GLOBAL_VAR_TYPE_VEC3, Vector3.UP)
	RenderingServer.global_shader_parameter_add("SunshineClouds_SunColor", RenderingServer.GLOBAL_VAR_TYPE_COLOR, Color(1, 1, 1))
	RenderingServer.global_shader_parameter_add("SunshineClouds_FogColor", RenderingServer.GLOBAL_VAR_TYPE_COLOR, Color(1, 1, 1))
	RenderingServer.global_shader_parameter_add("SunshineClouds_AmbientColor", RenderingServer.GLOBAL_VAR_TYPE_COLOR, Color(0, 0, 0))

	RenderingServer.global_shader_parameter_add("SunshineClouds_UseFog", RenderingServer.GLOBAL_VAR_TYPE_BOOL, true)

	RenderingServer.global_shader_parameter_add("SunshineClouds_WindDirection", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2.ZERO)
	RenderingServer.global_shader_parameter_add("SunshineClouds_WindSpeed", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.003)
	RenderingServer.global_shader_parameter_add("SunshineClouds_CloudsGlobalScale", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 10000.0)
	RenderingServer.global_shader_parameter_add("SunshineClouds_CloudsDetailNoiseScale", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 5.921)
	RenderingServer.global_shader_parameter_add("SunshineClouds_CloudsDetailNoisePower", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 1.048)
	RenderingServer.global_shader_parameter_add("SunshineClouds_CloudsLargeScaleNoiseScale", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.216)
	RenderingServer.global_shader_parameter_add("SunshineClouds_CloudsLargeScaleNoisePower", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 3.435)
	RenderingServer.global_shader_parameter_add("SunshineClouds_CloudsBaseNoiseScale", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 1.761)
	RenderingServer.global_shader_parameter_add("SunshineClouds_CloudsCutoff", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.213)

	RenderingServer.global_shader_parameter_add("SunshineClouds_CloudsFloor", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 80.0)
	RenderingServer.global_shader_parameter_add("SunshineClouds_CloudsCeiling", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 2000.0)
	
	execution_times.add_shader_variables.total = (Time.get_ticks_msec() - add_shader_start)

func _process(delta):
	if (Engine.is_editor_hint() || updateConstantly):
		UpdateGlobalVariableTextures();
		UpdateGlobalVariables();

func UpdateGlobalVariableTextures():
	if (gradientControlTexture == null):
		gradientControlTexture = ResourceLoader.load("res://addons/SunshineVolumetricClouds/HeightWeightGradient.tres");
	
	if (baseNoiseTexture == null):
		baseNoiseTexture = create_base_noise_texture()
	
	if (detailNoiseTexture == null):
		detailNoiseTexture = create_detail_noise_texture()
	
	if (largeScaleNoiseTexture == null):
		largeScaleNoiseTexture = create_large_scale_noise_texture()
	

func UpdateGlobalVariables():
	RenderingServer.global_shader_parameter_set("SunshineClouds_CloudsCutoff", cloudsCutoff);
	
	RenderingServer.global_shader_parameter_set("SunshineClouds_WindDirection", windDirection);
	RenderingServer.global_shader_parameter_set("SunshineClouds_WindSpeed", windSpeed);
	RenderingServer.global_shader_parameter_set("SunshineClouds_CloudsFloor", cloudsFloor);
	RenderingServer.global_shader_parameter_set("SunshineClouds_CloudsCeiling", cloudsCeiling);
	
	RenderingServer.global_shader_parameter_set("SunshineClouds_CloudsGlobalScale", globalCloudScale);
	RenderingServer.global_shader_parameter_set("SunshineClouds_CloudsBaseNoiseScale", baseNoiseScale);
	RenderingServer.global_shader_parameter_set("SunshineClouds_CloudsDetailNoiseScale", detailNoiseScale);
	RenderingServer.global_shader_parameter_set("SunshineClouds_CloudsDetailNoisePower", detailNoisePower);
	RenderingServer.global_shader_parameter_set("SunshineClouds_CloudsLargeScaleNoiseScale", largeScaleNoiseScale);
	RenderingServer.global_shader_parameter_set("SunshineClouds_CloudsLargeScaleNoisePower", largeScaleNoisePower);
	
	if (sunLight != null):
		RenderingServer.global_shader_parameter_set("SunshineClouds_SunDirection", sunLight.global_transform.basis.z);
		sunColorDefault = sunLight.light_color * sunLight.light_energy;
	
	if (worldEnvironment != null && worldEnvironment.environment != null):
		useFogDefault = worldEnvironment.environment.fog_enabled;
		fogColorDefault = worldEnvironment.environment.fog_light_color * worldEnvironment.environment.fog_light_energy;
		
		if (!overrideAmbientLight && worldEnvironment.environment.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR):
			ambientColorDefault = worldEnvironment.environment.ambient_light_color * worldEnvironment.environment.ambient_light_energy;
	
	RenderingServer.global_shader_parameter_set("SunshineClouds_SunColor", sunColorDefault);
	RenderingServer.global_shader_parameter_set("SunshineClouds_UseFog", useFogDefault);
	RenderingServer.global_shader_parameter_set("SunshineClouds_FogColor", fogColorDefault);
	RenderingServer.global_shader_parameter_set("SunshineClouds_AmbientColor", ambientColorDefault);
