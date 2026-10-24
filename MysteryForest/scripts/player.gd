# =============================================================
# player.gd  -  3D Adventurer Controller with Articulated Procedural Animation
# =============================================================
# - Third-person camera-relative movement
# - Distinct walking vs athletic running (sprinting) animations
# - Forward run lean, dynamic arm pumping, knee drive & stride lift
# - Mid-air jump tuck & reach pose with soft landing compression
# - Subtle breathing and posture when stationary
# =============================================================

extends CharacterBody3D

@export var walk_speed: float = 5.5
@export var sprint_speed: float = 10.5
@export var jump_force: float = 6.5
@export var gravity: float = 18.0

# Node references
@onready var camera_pivot: Node3D = get_node_or_null("CameraPivot") as Node3D
@onready var visual_root: Node3D = get_node_or_null("VisualRoot") as Node3D

# Articulated procedural animation pivots
@onready var torso: Node3D = get_node_or_null("VisualRoot/Torso") as Node3D
@onready var head: Node3D = get_node_or_null("VisualRoot/Torso/Head") as Node3D
@onready var scarf_tail: Node3D = get_node_or_null("VisualRoot/Torso/ScarfTail") as Node3D

@onready var left_arm_pivot: Node3D = get_node_or_null("VisualRoot/Torso/LeftArmPivot") as Node3D
@onready var left_forearm_pivot: Node3D = get_node_or_null("VisualRoot/Torso/LeftArmPivot/LeftForearmPivot") as Node3D
@onready var right_arm_pivot: Node3D = get_node_or_null("VisualRoot/Torso/RightArmPivot") as Node3D
@onready var right_forearm_pivot: Node3D = get_node_or_null("VisualRoot/Torso/RightArmPivot/RightForearmPivot") as Node3D

@onready var left_leg_pivot: Node3D = get_node_or_null("VisualRoot/LeftLegPivot") as Node3D
@onready var left_knee_pivot: Node3D = get_node_or_null("VisualRoot/LeftLegPivot/LeftKneePivot") as Node3D
@onready var right_leg_pivot: Node3D = get_node_or_null("VisualRoot/RightLegPivot") as Node3D
@onready var right_knee_pivot: Node3D = get_node_or_null("VisualRoot/RightLegPivot/RightKneePivot") as Node3D

# Animation state trackers
var walk_cycle: float = 0.0
var idle_time: float = 0.0
var was_on_floor_last: bool = true
var landing_cushion: float = 0.0

func _physics_process(delta: float) -> void:
	# 1. Apply gravity when airborne
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Jump input
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	# 3. Read directional movement inputs
	var input_x: float = 0.0
	var input_z: float = 0.0

	if Input.is_action_pressed("move_forward"):
		input_z -= 1.0
	if Input.is_action_pressed("move_backward"):
		input_z += 1.0
	if Input.is_action_pressed("move_left"):
		input_x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_x += 1.0

	var raw_input := Vector2(input_x, input_z).normalized()
	var is_sprinting: bool = Input.is_action_pressed("sprint")
	var current_speed: float = sprint_speed if is_sprinting else walk_speed

	# 4. Calculate movement relative to third-person camera orientation
	if raw_input != Vector2.ZERO and camera_pivot:
		var cam_basis: Basis = camera_pivot.global_transform.basis
		var cam_forward: Vector3 = -cam_basis.z
		var cam_right: Vector3 = cam_basis.x

		cam_forward.y = 0.0
		cam_right.y = 0.0
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()

		var move_direction: Vector3 = (cam_forward * (-raw_input.y)) + (cam_right * raw_input.x)
		velocity.x = move_direction.x * current_speed
		velocity.z = move_direction.z * current_speed

		# Smoothly rotate visual body to face movement direction
		if visual_root:
			var target_angle: float = atan2(-move_direction.x, -move_direction.z)
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_angle, 0.22)
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed * 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, current_speed * 12.0 * delta)

	# Detect landing impact for squash/cushion effect
	var currently_on_floor: bool = is_on_floor()
	if not was_on_floor_last and currently_on_floor:
		landing_cushion = 0.12
	was_on_floor_last = currently_on_floor

	if landing_cushion > 0.0:
		landing_cushion = move_toward(landing_cushion, 0.0, delta * 0.8)

	move_and_slide()

	# 5. Execute articulated humanoid procedural animation
	_animate_humanoid(delta, is_sprinting)

func _animate_humanoid(delta: float, is_sprinting: bool) -> void:
	if not visual_root or not torso:
		return

	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()

	if is_on_floor() and horizontal_speed > 0.2:
		idle_time = 0.0
		var running: bool = is_sprinting and horizontal_speed > (walk_speed + 1.0)

		# Animation frequency & stride length
		var anim_freq: float = 14.5 if running else 9.5
		walk_cycle += delta * anim_freq

		var swing: float = sin(walk_cycle)
		var arm_amp: float = 0.85 if running else 0.48
		var leg_amp: float = 0.78 if running else 0.44

		# Leg strides & knee flexion
		if left_leg_pivot and right_leg_pivot:
			left_leg_pivot.rotation.x = swing * leg_amp
			right_leg_pivot.rotation.x = -swing * leg_amp

			# Knees bend when trailing and straightens when stepping
			if left_knee_pivot:
				var knee_bend: float = clamp(-swing * 0.65, 0.0, 0.8) if running else clamp(-swing * 0.4, 0.0, 0.5)
				left_knee_pivot.rotation.x = -knee_bend
			if right_knee_pivot:
				var knee_bend: float = clamp(swing * 0.65, 0.0, 0.8) if running else clamp(swing * 0.4, 0.0, 0.5)
				right_knee_pivot.rotation.x = -knee_bend

		# Arm pumps with elbow flexion
		if left_arm_pivot and right_arm_pivot:
			left_arm_pivot.rotation.x = -swing * arm_amp
			right_arm_pivot.rotation.x = swing * arm_amp

			left_arm_pivot.rotation.z = -0.12
			right_arm_pivot.rotation.z = 0.12

			if left_forearm_pivot:
				left_forearm_pivot.rotation.x = -0.75 if running else -0.30
			if right_forearm_pivot:
				right_forearm_pivot.rotation.x = -0.75 if running else -0.30

		# Torso posture: athletic forward lean when running
		var target_lean: float = -0.22 if running else -0.06
		var hip_sway: float = sin(walk_cycle) * 0.03
		torso.rotation.x = lerp_angle(torso.rotation.x, target_lean, delta * 12.0)
		torso.rotation.y = lerp_angle(torso.rotation.y, -swing * 0.06, delta * 10.0)
		torso.rotation.z = lerp_angle(torso.rotation.z, hip_sway, delta * 10.0)

		if head:
			head.rotation.x = lerp_angle(head.rotation.x, -target_lean * 0.6, delta * 10.0)

		if scarf_tail:
			scarf_tail.rotation.x = 0.35 + sin(walk_cycle * 2.0) * 0.15 if running else 0.1

		# Vertical bounce synced to footsteps
		var bounce_height: float = 0.065 if running else 0.035
		visual_root.position.y = (abs(sin(walk_cycle)) * bounce_height) - landing_cushion

	elif not is_on_floor():
		# Airborne jump/fall pose
		idle_time = 0.0
		var is_jumping_up: bool = velocity.y > 0.0

		if left_arm_pivot and right_arm_pivot:
			left_arm_pivot.rotation.x = lerp_angle(left_arm_pivot.rotation.x, -0.65, delta * 8.0)
			right_arm_pivot.rotation.x = lerp_angle(right_arm_pivot.rotation.x, -0.65, delta * 8.0)
			left_arm_pivot.rotation.z = lerp_angle(left_arm_pivot.rotation.z, -0.25, delta * 8.0)
			right_arm_pivot.rotation.z = lerp_angle(right_arm_pivot.rotation.z, 0.25, delta * 8.0)

		if left_leg_pivot and right_leg_pivot:
			if is_jumping_up:
				# Knee tuck in ascent
				left_leg_pivot.rotation.x = lerp_angle(left_leg_pivot.rotation.x, 0.45, delta * 8.0)
				right_leg_pivot.rotation.x = lerp_angle(right_leg_pivot.rotation.x, -0.25, delta * 8.0)
				if left_knee_pivot:
					left_knee_pivot.rotation.x = lerp_angle(left_knee_pivot.rotation.x, -0.6, delta * 8.0)
				if right_knee_pivot:
					right_knee_pivot.rotation.x = lerp_angle(right_knee_pivot.rotation.x, -0.3, delta * 8.0)
			else:
				# Leg extension preparing for landing
				left_leg_pivot.rotation.x = lerp_angle(left_leg_pivot.rotation.x, 0.1, delta * 8.0)
				right_leg_pivot.rotation.x = lerp_angle(right_leg_pivot.rotation.x, 0.1, delta * 8.0)
				if left_knee_pivot:
					left_knee_pivot.rotation.x = lerp_angle(left_knee_pivot.rotation.x, -0.15, delta * 8.0)
				if right_knee_pivot:
					right_knee_pivot.rotation.x = lerp_angle(right_knee_pivot.rotation.x, -0.15, delta * 8.0)

		torso.rotation.x = lerp_angle(torso.rotation.x, 0.10, delta * 8.0)
		visual_root.position.y = lerp(visual_root.position.y, 0.05, delta * 8.0)

	else:
		# Idle standing pose with gentle breathing
		walk_cycle = 0.0
		idle_time += delta
		var breathing: float = sin(idle_time * 2.2) * 0.015

		if left_arm_pivot and right_arm_pivot:
			left_arm_pivot.rotation.x = lerp_angle(left_arm_pivot.rotation.x, 0.0, delta * 10.0)
			right_arm_pivot.rotation.x = lerp_angle(right_arm_pivot.rotation.x, 0.0, delta * 10.0)
			left_arm_pivot.rotation.z = -0.08 + breathing
			right_arm_pivot.rotation.z = 0.08 - breathing

		if left_forearm_pivot and right_forearm_pivot:
			left_forearm_pivot.rotation.x = lerp_angle(left_forearm_pivot.rotation.x, -0.15, delta * 10.0)
			right_forearm_pivot.rotation.x = lerp_angle(right_forearm_pivot.rotation.x, -0.15, delta * 10.0)

		if left_leg_pivot and right_leg_pivot:
			left_leg_pivot.rotation.x = lerp_angle(left_leg_pivot.rotation.x, 0.0, delta * 10.0)
			right_leg_pivot.rotation.x = lerp_angle(right_leg_pivot.rotation.x, 0.0, delta * 10.0)
			if left_knee_pivot:
				left_knee_pivot.rotation.x = lerp_angle(left_knee_pivot.rotation.x, 0.0, delta * 10.0)
			if right_knee_pivot:
				right_knee_pivot.rotation.x = lerp_angle(right_knee_pivot.rotation.x, 0.0, delta * 10.0)

		torso.rotation.x = lerp_angle(torso.rotation.x, 0.0, delta * 10.0)
		torso.rotation.y = lerp_angle(torso.rotation.y, 0.0, delta * 10.0)
		torso.rotation.z = lerp_angle(torso.rotation.z, 0.0, delta * 10.0)

		if head:
			head.rotation.x = lerp_angle(head.rotation.x, 0.0, delta * 10.0)

		if scarf_tail:
			scarf_tail.rotation.x = lerp_angle(scarf_tail.rotation.x, 0.05, delta * 8.0)

		visual_root.position.y = lerp(visual_root.position.y, breathing - landing_cushion, delta * 8.0)
