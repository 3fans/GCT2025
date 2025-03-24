extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

const MOUSE_SENSE = 0.005


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSE)
		$Camera3D.rotate_x(-event.relative.y * MOUSE_SENSE)
		$Camera3D.rotation_degrees.x = clampf($Camera3D.rotation_degrees.x, -60, 60)
		
	if event is InputEventMouseButton:
		if event.button_index == 1 && event.pressed:
			$AnimationPlayer.play("rod_cast")

func _physics_process(delta: float) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	move_and_slide()

func cast_rod() -> void:
	$AnimationPlayer.play("rod_cast")
