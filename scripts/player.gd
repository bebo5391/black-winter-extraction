extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 9.0
@export var jump_velocity: float = 5.2
@export var gravity: float = 14.0
@export var mouse_sensitivity: float = 0.0025
@export var initial_yaw: float = 0.0
@export var initial_pitch: float = -0.32

@onready var yaw_pivot: Node3D = $YawPivot
@onready var pitch_pivot: Node3D = $YawPivot/PitchPivot
@onready var follow_camera: Camera3D = $YawPivot/PitchPivot/SpringArm3D/Camera3D

var _pitch: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	yaw_pivot.rotation.y = initial_yaw
	_pitch = initial_pitch
	pitch_pivot.rotation.x = _pitch
	follow_camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clamp(_pitch - event.relative.y * mouse_sensitivity, -1.1, 0.8)
		pitch_pivot.rotation.x = _pitch
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var basis := yaw_pivot.global_transform.basis
	var move_dir := (basis.x * input_vec.x + -basis.z * input_vec.y)
	move_dir.y = 0.0
	move_dir = move_dir.normalized()

	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	if move_dir != Vector3.ZERO:
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()
