extends CharacterBody3D
class_name Player

# Add this signal
signal biome_entered(biome_name: String, position: Vector3)

@export var speed = 5.0
@export var jump_force = 4.5
@export var sensitivity = 0.003

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera: Camera3D

# References to PropScatterer
var prop_scatterer: PropScatterer
@onready var Config: WorldConfigResource = preload("res://world_config.tres")

# Track current biome for change detection
var current_biome: String = ""

func _ready():
	camera = $Head/Camera3D
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Wait for PropScatterer to finish creating LOD instances
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	global_position = Vector3(0, Config.amplitude * 3, 0)
	# Find the PropScatterer in the scene
	prop_scatterer = get_tree().root.find_child("PropScatterer", true, false) as PropScatterer
	
	if not prop_scatterer:
		print("ERROR: Could not find PropScatterer node!")
		return
	
	# Initialize current biome
	current_biome = prop_scatterer.get_biome_at_position(global_position)
	
	print("=== PLAYER INITIALIZED ===")
	print("Starting biome: ", current_biome)
	print("All chunks are always loaded.")
	print("LOD visibility_range_end handles distance culling:")
	print("  - 0 to %.0f: Full detail" % prop_scatterer.lod_mid_distance)
	print("  - %.0f to %.0f: Medium detail" % [prop_scatterer.lod_mid_distance, prop_scatterer.lod_far_distance])
	print("  - %.0f to %.0f: Low detail" % [prop_scatterer.lod_far_distance, prop_scatterer.lod_max_distance])
	print("  - Beyond %.0f: Culled" % prop_scatterer.lod_max_distance)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if event.keycode == KEY_P:
			print_performance_stats()
		# Add debug key to print current biome
		if event.keycode == KEY_B:
			print_current_biome()

func _process(_delta):
	# Check biome every frame (you could also do this less frequently for performance)
	check_biome_change()

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force
	
	# Movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()

# Add this function to check for biome changes
func check_biome_change():
	if not prop_scatterer:
		return
	
	var new_biome = prop_scatterer.get_biome_at_position(global_position)
	
	# If biome changed, emit signal
	if new_biome != current_biome:
		biome_entered.emit(new_biome, global_position)
		print("Biome changed: ", current_biome, " -> ", new_biome, " at ", global_position)
		current_biome = new_biome

# Add debug function to print current biome
func print_current_biome():
	if prop_scatterer:
		var biome = prop_scatterer.get_biome_at_position(global_position)
		print("Current biome at ", global_position, ": ", biome)

func print_performance_stats():
	var lod_instances = get_tree().get_nodes_in_group("lod_instance")
	var visible_count = 0
	var total_instances = 0
	var camera_pos = camera.global_position
	
	for lod in lod_instances:
		if lod.visible:
			visible_count += 1
			if lod.multimesh:
				total_instances += lod.multimesh.instance_count
	
	print("\n=== PERFORMANCE STATS ===")
	print("Camera position: ", camera_pos)
	print("Current biome: ", current_biome)
	print("Visible LOD instances: ", visible_count, " / ", lod_instances.size())
	print("Total visible prop instances: ", total_instances)
