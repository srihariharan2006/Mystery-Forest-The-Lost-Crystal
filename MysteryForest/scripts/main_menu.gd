# =============================================================
# main_menu.gd  -  Main Menu & Settings Logic
# =============================================================

extends CanvasLayer

@onready var settings_panel: Panel = get_node_or_null("SettingsPanel") as Panel
@onready var fullscreen_check: CheckBox = get_node_or_null("SettingsPanel/VBox/FullscreenCheck") as CheckBox
@onready var volume_slider: HSlider = get_node_or_null("SettingsPanel/VBox/VolumeSlider") as HSlider
@onready var sens_slider: HSlider = get_node_or_null("SettingsPanel/VBox/SensSlider") as HSlider

func _ready() -> void:
	# Ensure cursor is always visible and free on menus
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if settings_panel:
		settings_panel.visible = false

	# Connect main buttons
	var play_btn = get_node_or_null("Panel/VBoxContainer/PlayButton") as Button
	var settings_btn = get_node_or_null("Panel/VBoxContainer/SettingsButton") as Button
	var quit_btn = get_node_or_null("Panel/VBoxContainer/QuitButton") as Button
	var close_btn = get_node_or_null("SettingsPanel/VBox/CloseButton") as Button

	if play_btn:
		play_btn.pressed.connect(_on_play_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)
	if close_btn:
		close_btn.pressed.connect(_on_close_settings_pressed)

	if fullscreen_check:
		fullscreen_check.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_changed)

	if sens_slider:
		sens_slider.value_changed.connect(_on_sens_changed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_world.tscn")

func _on_settings_pressed() -> void:
	if settings_panel:
		settings_panel.visible = true

func _on_close_settings_pressed() -> void:
	if settings_panel:
		settings_panel.visible = false

func _on_fullscreen_toggled(is_toggled: bool) -> void:
	if is_toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_volume_changed(val: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		if val <= 1.0:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val / 100.0))

func _on_sens_changed(val: float) -> void:
	# Load camera script class or set static variable
	var cam_script = load("res://scripts/camera_controller.gd")
	if cam_script and "sensitivity_scale" in cam_script:
		cam_script.sensitivity_scale = clamp(val / 50.0, 0.2, 3.0)

func _on_quit_pressed() -> void:
	get_tree().quit()
