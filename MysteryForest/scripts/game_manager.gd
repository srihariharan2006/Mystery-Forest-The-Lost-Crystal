# =============================================================
# game_manager.gd  -  Central game state controller
# =============================================================
# Attached to the root node of main_world.tscn.
# Responsibilities:
#   - Tracks crystal collection count (0 to 3)
#   - Updates the HUD counter in real time (0/3, 1/3, 2/3, 3/3)
#   - Triggers the celebratory victory screen upon collecting 3 crystals
#   - Handles pausing (Escape key) and manages mouse capture/release
#   - Manages UI button events (Resume, Restart, Main Menu, Quit)
#   - Prevents duplicate collection via registry array
# Signal API: crystal.gd emits crystal_collected(crystal_name: String)
# =============================================================

extends Node

const TOTAL_CRYSTALS: int = 3
const DEBUG_LOG: bool = true   # set false after verifying collection works

var crystals_collected: int = 0
var collected_crystal_names: Array[String] = []
var is_paused: bool = false
var game_won: bool = false

@onready var hud: CanvasLayer = get_node_or_null("HUD") as CanvasLayer
@onready var pause_menu: CanvasLayer = get_node_or_null("PauseMenu") as CanvasLayer
@onready var victory_screen: CanvasLayer = get_node_or_null("VictoryScreen") as CanvasLayer

func _ready() -> void:
	# Critical for pause menus: allow this node and UI to process while tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	if pause_menu:
		pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		pause_menu.visible = false
	if victory_screen:
		victory_screen.process_mode = Node.PROCESS_MODE_ALWAYS
		victory_screen.visible = false

	# Connect crystal signals — crystals are instantiated as children of the same
	# scene, so get_nodes_in_group works after all _ready() calls in this frame.
	# Use call_deferred to ensure all child nodes have finished their own _ready().
	call_deferred("_connect_crystal_signals")

	# Connect Pause Menu buttons
	var resume_btn = get_node_or_null("PauseMenu/Panel/VBox/ResumeButton") as Button
	var pause_menu_btn = get_node_or_null("PauseMenu/Panel/VBox/MenuButton") as Button
	var pause_quit_btn = get_node_or_null("PauseMenu/Panel/VBox/QuitButton") as Button

	if resume_btn and not resume_btn.pressed.is_connected(resume_game):
		resume_btn.pressed.connect(resume_game)
	if pause_menu_btn and not pause_menu_btn.pressed.is_connected(go_to_main_menu):
		pause_menu_btn.pressed.connect(go_to_main_menu)
	if pause_quit_btn and not pause_quit_btn.pressed.is_connected(quit_game):
		pause_quit_btn.pressed.connect(quit_game)

	# Connect Victory Screen buttons
	var restart_btn = get_node_or_null("VictoryScreen/Panel/VBox/RestartButton") as Button
	var victory_menu_btn = get_node_or_null("VictoryScreen/Panel/VBox/MenuButton") as Button

	if restart_btn and not restart_btn.pressed.is_connected(restart_game):
		restart_btn.pressed.connect(restart_game)
	if victory_menu_btn and not victory_menu_btn.pressed.is_connected(go_to_main_menu):
		victory_menu_btn.pressed.connect(go_to_main_menu)

	# Initial HUD counter display (0 / 3)
	_update_hud()
	if DEBUG_LOG:
		print("[GM] _ready() complete — HUD init: %d / %d" % [crystals_collected, TOTAL_CRYSTALS])

func _connect_crystal_signals() -> void:
	# Called via call_deferred so all nodes have finished their _ready()
	var crystals = get_tree().get_nodes_in_group("crystals")
	if DEBUG_LOG:
		print("[GM] _connect_crystal_signals() — found %d crystal(s) in group 'crystals'" % crystals.size())

	for crystal in crystals:
		if crystal.has_signal("crystal_collected"):
			# Use a simple direct connection — no .bind() needed because the
			# signal itself now carries the crystal_name as a String argument.
			if not crystal.crystal_collected.is_connected(_on_crystal_collected):
				crystal.crystal_collected.connect(_on_crystal_collected)
				if DEBUG_LOG:
					print("[GM] Connected 'crystal_collected' signal for: %s" % crystal.name)
			else:
				if DEBUG_LOG:
					print("[GM] Signal already connected for: %s (skipped)" % crystal.name)
		else:
			push_warning("[GM] Crystal '%s' has no 'crystal_collected' signal!" % crystal.name)

func _unhandled_input(event: InputEvent) -> void:
	if game_won:
		if event.is_action_pressed("ui_accept") and not event.is_echo():
			restart_game()
		return

	# Press ESC to toggle pause (only if not already won)
	if event.is_action_pressed("pause") and not event.is_echo() and not game_won:
		_toggle_pause()

func _toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused

	if pause_menu:
		pause_menu.visible = is_paused

	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func resume_game() -> void:
	if is_paused:
		_toggle_pause()

func quit_game() -> void:
	get_tree().quit()

# Signal handler — crystal_name is the String emitted by crystal_collected(name)
func _on_crystal_collected(crystal_name: String) -> void:
	if DEBUG_LOG:
		print("[GM] _on_crystal_collected() -> '%s'  (current count: %d)" % [crystal_name, crystals_collected])

	# Guard against any duplicate emissions
	if crystal_name in collected_crystal_names:
		if DEBUG_LOG:
			print("[GM] Duplicate ignored for: %s" % crystal_name)
		return

	collected_crystal_names.append(crystal_name)
	crystals_collected += 1
	_update_hud()

	if DEBUG_LOG:
		print("[GM] Counter updated: %d / %d" % [crystals_collected, TOTAL_CRYSTALS])

	if crystals_collected >= TOTAL_CRYSTALS:
		if DEBUG_LOG:
			print("[GM] All crystals collected! Showing victory screen.")
		_show_victory()

func _update_hud() -> void:
	var label = get_node_or_null("HUD/CrystalPanel/CrystalLabel") as Label
	if label:
		label.text = "Crystals: %d / %d" % [crystals_collected, TOTAL_CRYSTALS]
	elif DEBUG_LOG:
		print("[GM] WARNING: HUD/CrystalPanel/CrystalLabel not found!")

func _show_victory() -> void:
	game_won = true
	get_tree().paused = true

	if victory_screen:
		victory_screen.visible = true
	elif DEBUG_LOG:
		print("[GM] WARNING: VictoryScreen node not found!")

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func restart_game() -> void:
	get_tree().paused = false
	if get_tree().current_scene:
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/main_world.tscn")

func go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
