extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.004

@onready var head = $Head
@onready var camera = $Head/Camera3D

# LOD culling
@export var cull_distance_near: float = 200.0
@export var cull_distance_far: float = 500.0
@export var cull_density_far: float = 0.5

var multimesh_instances: Array[MultiMeshInstance3D] = []

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Wait for props to spawn
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get all LOD instances
	var lod_nodes = get_tree().get_nodes_in_group("lod_instance")
	print("Nodes in lod_instance group: ", lod_nodes.size())
	for node in lod_nodes:
		print("Found LOD node: ", node.name)
		if node is MultiMeshInstance3D:
			multimesh_instances.append(node as MultiMeshInstance3D)
	
	print("Found ", multimesh_instances.size(), " LOD instances to cull")

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	
	# Update LOD culling
	update_lod_culling()

func update_lod_culling():
	var camera_pos = camera.global_position
	
	for mmi in multimesh_instances:
		if not mmi.multimesh:
			continue
		
		var multimesh = mmi.multimesh as MultiMesh
		var closest_distance = INF
		
		# Find closest instance in this MultiMesh
		for i in range(min(100, multimesh.instance_count)):  # Check first 100 for performance
			var instance_transform = multimesh.get_instance_transform(i)
			var instance_pos = instance_transform.origin
			var distance = camera_pos.distance_to(instance_pos)
			
			if distance < closest_distance:
				closest_distance = distance
		
		# Show/hide based on closest prop
		if closest_distance < cull_distance_near:
			mmi.visible = true
		elif closest_distance < cull_distance_far:
			mmi.visible = true
		else:
			mmi.visible = false
