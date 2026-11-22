extends Control
## Main menu. Offline works; online modes are placeholders until Phases 6-7.

const GAME_SCENE := "res://scenes/main/game_world.tscn"

var _menu_center: CenterContainer
var _settings_center: CenterContainer


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var bg := ColorRect.new()
    bg.color = Color(0.06, 0.07, 0.06)
    add_child(bg)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _build_main_menu()
    _build_settings_panel()


func _build_main_menu() -> void:
    _menu_center = CenterContainer.new()
    add_child(_menu_center)
    _menu_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 12)
    _menu_center.add_child(box)

    box.add_child(_make_label("LAST DAY: SURVIVAL", 52, Color(0.85, 0.2, 0.15)))
    box.add_child(_make_label("Phase 1 prototype", 20, Color(0.7, 0.7, 0.7)))

    box.add_child(_make_button("NEW GAME - OFFLINE", _on_offline_pressed))
    box.add_child(_make_button("ONLINE SOLO (coming soon)", Callable(), true))
    box.add_child(_make_button("MULTIPLAYER (coming soon)", Callable(), true))
    box.add_child(_make_button("SETTINGS", _on_settings_pressed))
    box.add_child(_make_button("QUIT", _on_quit_pressed))


func _build_settings_panel() -> void:
    _settings_center = CenterContainer.new()
    _settings_center.visible = false
    add_child(_settings_center)
    _settings_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var panel := PanelContainer.new()
    _settings_center.add_child(panel)

    var margin := MarginContainer.new()
    for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(side, 28)
    panel.add_child(margin)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 12)
    margin.add_child(box)

    box.add_child(_make_label("SETTINGS", 36, Color.WHITE))
    box.add_child(_make_label("Look sensitivity", 22, Color.WHITE))
    box.add_child(_make_slider(0.3, 3.0, 0.05, SettingsManager.look_sensitivity,
        func(v: float) -> void: SettingsManager.look_sensitivity = v))
    box.add_child(_make_label("Third-person camera distance", 22, Color.WHITE))
    box.add_child(_make_slider(2.0, 6.0, 0.1, SettingsManager.third_person_distance,
        func(v: float) -> void: SettingsManager.third_person_distance = v))
    box.add_child(_make_button("BACK", _on_settings_back))


func _make_label(text: String, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    return label


func _make_button(text: String, callback: Callable, disabled_button: bool = false) -> Button:
    var button := Button.new()
    button.text = text
    button.disabled = disabled_button
    button.custom_minimum_size = Vector2(520, 64)
    button.add_theme_font_size_override("font_size", 26)
    if not disabled_button:
        button.pressed.connect(callback)
    return button


func _make_slider(min_v: float, max_v: float, step_v: float, current: float, on_change: Callable) -> HSlider:
    var slider := HSlider.new()
    slider.min_value = min_v
    slider.max_value = max_v
    slider.step = step_v
    slider.value = current
    slider.custom_minimum_size = Vector2(520, 44)
    slider.value_changed.connect(on_change)
    return slider


func _on_offline_pressed() -> void:
    GameState.game_mode = GameState.GameMode.OFFLINE
    get_tree().change_scene_to_file(GAME_SCENE)


func _on_settings_pressed() -> void:
    _menu_center.visible = false
    _settings_center.visible = true


func _on_settings_back() -> void:
    SettingsManager.save_settings()
    _settings_center.visible = false
    _menu_center.visible = true


func _on_quit_pressed() -> void:
    get_tree().quit()
