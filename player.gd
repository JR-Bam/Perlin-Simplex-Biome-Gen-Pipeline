extends CharacterBody3D

@export var speed = 5.0
@export var jump_force = 4.5
@export var sensitivity = 0.003

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera: Camera3D

# References to PropScatterer for LOD/chunk settings
var prop_scatterer: PropScatterer
var loaded_chunks: Dictionary = {}  # chunk_name -> visible state
var all_chunks: Array = []  # Cache of all chunk names
var time_since_update: float = 0.0
var time_since_reload: float = 10.0  # Start high so update runs immediately

func _ready():
	camera = $Head/Camera3D
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Wait for PropScatterer to finish creating LOD instances
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find the PropScatterer in the scene
	prop_scatterer = get_tree().root.find_child("PropScatterer", true, false) as PropScatterer
	
	if not prop_scatterer:
		print("ERROR: Could not find PropScatterer node!")
		return
	
	print("=== PLAYER INITIALIZED ===")
	print("PropScatterer found with settings:")
	print("  Chunks: load=%.0f unload=%.0f" % [prop_scatterer.chunk_load_distance, prop_scatterer.chunk_unload_distance])
	
	setup_chunks()

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if event.keycode == KEY_P:
			reload_all_chunks()

func _process(_delta):
	pass

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
	
	# Update chunks periodically (but not right after reload)
	time_since_update += delta
	time_since_reload += delta
	
	if time_since_update >= 0.5 and time_since_reload >= 2.0:  # Wait 2 seconds after reload before updating
		time_since_update = 0.0
		_update_chunks()

func setup_chunks():
	# Cache all unique chunks once at startup
	print("\n=== CACHING ALL CHUNKS ===")
	var lod_instances = get_tree().get_nodes_in_group("lod_instance")
	var chunks_set = {}
	
	for lod in lod_instances:
		var groups = lod.get_groups()
		for group in groups:
			if group.begins_with("chunk_"):
				chunks_set[group] = true
	
	all_chunks = chunks_set.keys()
	print("Total unique chunks cached: ", all_chunks.size())
	
	# Start with all chunks visible
	for chunk_name in all_chunks:
		_set_chunk_visibility(chunk_name, true)
		loaded_chunks[chunk_name] = true

func _update_chunks():
	if not prop_scatterer or all_chunks.size() == 0:
		return
	
	var camera_pos = camera.global_position
	var chunks_unloaded = 0
	
	# Check each chunk
	for chunk_name in all_chunks:
		var chunk_nodes = get_tree().get_nodes_in_group(chunk_name)
		
		if chunk_nodes.size() == 0:
			continue
		
		# Get chunk center from visible nodes first
		var chunk_center = Vector3.ZERO
		var found = false
		
		for node in chunk_nodes:
			if node is MultiMeshInstance3D and node.visible:
				chunk_center = node.global_position
				found = true
				break
		
		# If no visible nodes, try any node
		if not found:
			for node in chunk_nodes:
				if node is MultiMeshInstance3D:
					chunk_center = node.global_position
					found = true
					break
		
		if not found:
			continue
		
		var distance = camera_pos.distance_to(chunk_center)
		var is_loaded = loaded_chunks.get(chunk_name, false)
		
		# Only unload if VERY far away
		if is_loaded and distance > prop_scatterer.chunk_unload_distance:
			_set_chunk_visibility(chunk_name, false)
			loaded_chunks[chunk_name] = false
			chunks_unloaded += 1
		# Always keep chunks visible if close
		elif distance <= prop_scatterer.chunk_load_distance:
			if not is_loaded:
				_set_chunk_visibility(chunk_name, true)
				loaded_chunks[chunk_name] = true

func _set_chunk_visibility(chunk_name: String, visible: bool):
	var chunk_nodes = get_tree().get_nodes_in_group(chunk_name)
	
	for node in chunk_nodes:
		if node is MultiMeshInstance3D:
			node.visible = visible

func reload_all_chunks():
	print("Reloading all chunks... (waiting 2 seconds before unloading)")
	for chunk_name in all_chunks:
		_set_chunk_visibility(chunk_name, true)
		loaded_chunks[chunk_name] = true
	
	# Reset cooldown to prevent immediate unloading
	time_since_reload = 0.0
	time_since_update = 0.0
	print("All chunks reloaded!")
