# =============================================================
# camera_controller.gd  -  Smooth orbit third-person camera
# =============================================================
# - Decoupled 360-degree free mouse rotation
# - SpringArm3D obstacle collision avoidance
# - Generous pitch range to look up at tall sky beams and scenic peaks
# - Smooth position follow interpolation without initial snap
# =============================================================

extends Node3D

static var sensitivity_scale: float = 1.0

@export var mouse_sensitivity: float = 0.0025
@export var min_pitch: float = -1.15   # Look up towards sky beams (~66 deg)
@export var max_pitch: float = 0.85    # Look down towards ground (~49 deg)
@export var camera_height_offset: float = 1.6

var pitch: float = 0.0
var player: CharacterBody3D

@onready var spring_arm: SpringArm3D = get_node_or_null("SpringArm3D") as SpringArm3D

func _ready() -> void:
	# Decouple this node transform from parent player rotation
	set_as_top_level(true)
	player = get_parent() as CharacterBody3D

	# Immediately match player position on frame 0 to avoid origin jump
	if player:
		global_position = player.global_position + Vector3(0.0, camera_height_offset, 0.0)

	# Hide and capture mouse cursor for in-game look
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var effective_sens: float = mouse_sensitivity * sensitivity_scale

		# Yaw: rotate pivot horizontally
		rotate_y(-event.relative.x * effective_sens)

		# Pitch: tilt spring arm vertically with clamping
		pitch -= event.relative.y * effective_sens
		pitch = clamp(pitch, min_pitch, max_pitch)
		if spring_arm:
			spring_arm.rotation.x = pitch

func _process(delta: float) -> void:
	if player:
		# Smooth follow position interpolation
		var target_pos: Vector3 = player.global_position + Vector3(0.0, camera_height_offset, 0.0)
		global_position = global_position.lerp(target_pos, clamp(delta * 16.0, 0.0, 1.0))
