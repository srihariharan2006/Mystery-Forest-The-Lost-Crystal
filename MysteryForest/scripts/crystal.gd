# =============================================================
# crystal.gd  -  Collectible Magical Shard Cluster & Sky Beacon
# =============================================================
# Signal now carries crystal_name so game_manager needs no .bind()
# DEBUG_LOG = true for verification — set false once working
# =============================================================

extends Node3D

# Signal carries the crystal's node name so game_manager needs no .bind()
signal crystal_collected(crystal_name: String)

const DEBUG_LOG: bool = true   # set false after verifying collection works

@export var crystal_color: Color = Color(0.75, 0.25, 1.0)
@export var rotation_speed: float = 2.0
@export var bob_amplitude: float = 0.25
@export var bob_frequency: float = 2.2

var base_y: float = 0.0
var elapsed: float = 0.0
var is_collected: bool = false

@onready var visual_gem: Node3D = get_node_or_null("VisualGem") as Node3D
@onready var beacon_beam: MeshInstance3D = get_node_or_null("BeaconBeam") as MeshInstance3D
@onready var glow_light: OmniLight3D = get_node_or_null("OmniLight3D") as OmniLight3D
@onready var audio_player: AudioStreamPlayer3D = get_node_or_null("AudioStreamPlayer3D") as AudioStreamPlayer3D
@onready var area: Area3D = get_node_or_null("Area3D") as Area3D
@onready var particles: CPUParticles3D = get_node_or_null("SparkleParticles") as CPUParticles3D
@onready var pedestal_ring: MeshInstance3D = get_node_or_null("PedestalRing") as MeshInstance3D

var crystal_material: StandardMaterial3D
var beacon_material: StandardMaterial3D
var ring_material: StandardMaterial3D

func _ready() -> void:
	base_y = position.y

	if DEBUG_LOG:
		print("[CRYSTAL] _ready() -> name='%s'  global_pos=%s" % [name, global_position])

	# 1. Custom crystal gem material
	var upper_mesh = get_node_or_null("VisualGem/UpperSpire") as MeshInstance3D
	if upper_mesh and upper_mesh.material_override:
		crystal_material = upper_mesh.material_override.duplicate() as StandardMaterial3D
	else:
		crystal_material = StandardMaterial3D.new()
		crystal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		crystal_material.roughness = 0.05

	crystal_material.albedo_color = Color(crystal_color.r, crystal_color.g, crystal_color.b, 0.95)
	crystal_material.emission_enabled = true
	crystal_material.emission = crystal_color
	crystal_material.emission_energy_multiplier = 3.0

	if upper_mesh:
		upper_mesh.material_override = crystal_material

	if visual_gem:
		for shard_name in ["LowerSpire", "Shard1", "Shard2", "Shard3", "Shard4"]:
			var shard = visual_gem.get_node_or_null(shard_name) as MeshInstance3D
			if shard:
				shard.material_override = crystal_material

	# 2. Custom beacon beam material (unshaded high-visibility light column)
	if beacon_beam:
		if beacon_beam.material_override:
			beacon_material = beacon_beam.material_override.duplicate() as StandardMaterial3D
		else:
			beacon_material = StandardMaterial3D.new()
		beacon_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		beacon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		beacon_material.albedo_color = Color(crystal_color.r, crystal_color.g, crystal_color.b, 0.65)
		beacon_beam.material_override = beacon_material

	# 3. Ground Pedestal Ring
	if pedestal_ring:
		ring_material = StandardMaterial3D.new()
		ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring_material.albedo_color = Color(crystal_color.r, crystal_color.g, crystal_color.b, 0.45)
		pedestal_ring.material_override = ring_material

	# 4. Light and particles color matching
	if glow_light:
		glow_light.light_color = crystal_color
	if particles:
		particles.color = crystal_color

	# 5. Configure trigger area collision
	if area:
		area.collision_layer = 0   # Area3D does not occupy any physics layer
		area.collision_mask = 1    # Detects physics bodies on layer 1 (player is layer 1)
		area.monitoring = true
		area.monitorable = false
		# Connect body_entered signal
		if not area.body_entered.is_connected(_on_body_entered):
			area.body_entered.connect(_on_body_entered)
		if DEBUG_LOG:
			var col_shape = area.get_node_or_null("CollisionShape3D")
			print("[CRYSTAL] Area3D ready — monitoring=%s  mask=%d  has_shape=%s" % [
				area.monitoring, area.collision_mask, col_shape != null
			])
	else:
		push_error("[CRYSTAL] '%s' has NO Area3D child — collection impossible!" % name)

func _process(delta: float) -> void:
	if is_collected:
		return

	elapsed += delta

	# Continuous rotation of the faceted crystal cluster
	if visual_gem:
		visual_gem.rotation.y += rotation_speed * delta

	# Gentle sinusoidal vertical hovering
	position.y = base_y + sin(elapsed * bob_frequency) * bob_amplitude

	# Dynamic emission energy pulse
	if crystal_material:
		var pulse: float = 2.6 + sin(elapsed * 4.5) * 1.0
		crystal_material.emission_energy_multiplier = pulse

	# Subtle beacon shimmer
	if beacon_material:
		beacon_material.albedo_color.a = 0.60 + sin(elapsed * 3.0) * 0.12

	if pedestal_ring:
		pedestal_ring.rotation.y -= 0.6 * delta

func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return

	if DEBUG_LOG:
		print("[CRYSTAL] body_entered -> crystal='%s'  body='%s'  in_group_player=%s  is_CB3D=%s" % [
			name, body.name,
			body.is_in_group("player"),
			body is CharacterBody3D
		])

	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody3D:
		if DEBUG_LOG:
			print("[CRYSTAL] *** COLLECTING '%s' from body '%s' ***" % [name, body.name])

		# State lock first — prevents any race on duplicate signals
		is_collected = true

		# Disconnect immediately to guarantee no re-entry
		if area and area.body_entered.is_connected(_on_body_entered):
			area.body_entered.disconnect(_on_body_entered)

		# Emit signal carrying this crystal's name (game_manager receives it directly)
		crystal_collected.emit(name)

		if DEBUG_LOG:
			print("[CRYSTAL] Signal 'crystal_collected' emitted with name='%s'" % name)

		_collect()

func _collect() -> void:
	if area:
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)

	if audio_player and audio_player.stream:
		audio_player.play()

	# Immediately hide the sky beam so player immediately sees it is collected
	if beacon_beam:
		beacon_beam.visible = false

	# Magical flash and collection dissolve
	var tween: Tween = create_tween().set_parallel(true)
	if visual_gem:
		tween.tween_property(visual_gem, "scale", Vector3(2.5, 2.5, 2.5), 0.35)
		tween.tween_property(visual_gem, "position:y", visual_gem.position.y + 0.5, 0.35)
	if pedestal_ring:
		tween.tween_property(pedestal_ring, "scale", Vector3(0.01, 1.0, 0.01), 0.3)
	if glow_light:
		tween.tween_property(glow_light, "light_energy", 10.0, 0.18)
		tween.chain().tween_property(glow_light, "light_energy", 0.0, 0.18)

	# process_always=true keeps the timer running even if scene tree is paused
	await get_tree().create_timer(0.4, true).timeout
	hide()
	queue_free()
