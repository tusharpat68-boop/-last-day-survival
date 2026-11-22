extends CanvasLayer
## Android touch HUD. All touch routing happens here so that the joystick,
## buttons and look-drag work simultaneously (true multi-touch).
## Phase 2 adds: survival bars, interact prompt, toast messages,
## backpack panel and death screen.

const JoystickScript = preload("res://scripts/ui/virtual_joystick.gd")
const TouchButtonScript = preload("res://scripts/ui/touch_button.gd")
const StatBarsScript = preload("res://scripts/ui/stat_bars.gd")
const InventoryPanelScript = preload("res://scripts/ui/inventory_panel.gd")
const DeathScreenScript = preload("res://scripts/ui/death_screen.gd")
const MAIN_MENU_SCENE := "res://scenes/main/main_menu.tscn"

const JOYSTICK_RADIUS := 110.0
const JOYSTICK_MARGIN := 100.0
const LOOK_MIN_X_FRACTION := 0.35
const LOOK_OWNER := "look"

# dx/dy = distance of the button centre from the right edge and from the
# bottom (or top, when "top" is true) edge of the screen. r = radius.
const BUTTON_DEFS := [
    {"action": &"fire", "label": "FIRE", "dx": 170.0, "dy": 180.0, "r": 85.0, "top": false},
    {"action": &"aim", "label": "AIM", "dx": 360.0, "dy": 110.0, "r": 55.0, "top": false},
    {"action": &"jump", "label": "JUMP", "dx": 110.0, "dy": 360.0, "r": 58.0, "top": false},
    {"action": &"crouch", "label": "CROUCH", "dx": 300.0, "dy": 260.0, "r": 50.0, "top": false},
    {"action": &"reload", "label": "RELOAD", "dx": 280.0, "dy": 400.0, "r": 48.0, "top": false},
    {"action": &"interact", "label": "USE", "dx": 440.0, "dy": 230.0, "r": 48.0, "top": false},
    {"action": &"camera_switch", "label": "CAM", "dx": 80.0, "dy": 170.0, "r": 45.0, "top": true},
    {"action": &"weapon_switch", "label": "WPN", "dx": 190.0, "dy": 170.0, "r": 45.0, "top": true},
    {"action": &"pause", "label": "II", "dx": 60.0, "dy": 60.0, "r": 34.0, "top": true},
    {"action": &"map", "label": "MAP", "dx": 150.0, "dy": 60.0, "r": 34.0, "top": true},
    {"action": &"backpack", "label": "BAG", "dx": 240.0, "dy": 60.0, "r": 34.0, "top": true},
]

var _root: Control
var _joystick
var _buttons: Array = []
var _owners: Dictionary = {}   # touch index -> joystick | button | LOOK_OWNER
var _viewport_size := Vector2(1280, 720)
var _info_label: Label
var _prompt_label: Label
var _toast_label: Label
var _toast_time := 0.0
var _pause_layer: CanvasLayer
var _stat_bars
var _inventory_panel
var _death_screen
var _player


func _ready() -> void:
    layer = 10
    _root = Control.new()
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_root)
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _joystick = JoystickScript.new()
    _joystick.setup(JOYSTICK_RADIUS)
    _root.add_child(_joystick)

    for entry in BUTTON_DEFS:
        var button = TouchButtonScript.new()
        button.setup(entry["action"], entry["label"], entry["r"])
        _root.add_child(button)
        _buttons.append(button)

    _info_label = Label.new()
    _info_label.position = Vector2(24, 16)
    _info_label.add_theme_font_size_override("font_size", 18)
    _root.add_child(_info_label)

    _stat_bars = StatBarsScript.new()
    _stat_bars.position = Vector2(24, 48)
    _root.add_child(_stat_bars)

    _prompt_label = _make_centered_label(340.0, 22)
    _toast_label = _make_centered_label(700.0, 22)
    _toast_label.modulate.a = 0.0

    _build_pause_menu()

    _inventory_panel = InventoryPanelScript.new()
    add_child(_inventory_panel)
    _inventory_panel.closed.connect(_on_inventory_closed)

    _death_screen = DeathScreenScript.new()
    add_child(_death_screen)
    _death_screen.respawn_requested.connect(_on_respawn_requested)

    _player = get_tree().get_first_node_in_group("player")
    if _player != null:
        _stat_bars.bind(_player.stats)
        _player.stats.died.connect(_on_player_died)
    else:
        push_warning("HUD: no player found in group 'player'")

    _layout()
    get_viewport().size_changed.connect(_layout)
    MobileInput.action_pressed.connect(_on_action_pressed)
    EventBus.interact_prompt_changed.connect(_on_prompt_changed)
    EventBus.message_posted.connect(_on_message_posted)


func _make_centered_label(width: float, font_size: int) -> Label:
    var label := Label.new()
    label.size = Vector2(width, 36)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_outline_color", Color.BLACK)
    label.add_theme_constant_override("outline_size", 6)
    _root.add_child(label)
    return label


func _layout() -> void:
    _viewport_size = get_viewport().get_visible_rect().size
    var joy_center := Vector2(JOYSTICK_MARGIN + JOYSTICK_RADIUS, _viewport_size.y - JOYSTICK_MARGIN - JOYSTICK_RADIUS)
    _joystick.position = joy_center - Vector2.ONE * JOYSTICK_RADIUS
    for i in _buttons.size():
        var entry: Dictionary = BUTTON_DEFS[i]
        var cx: float = _viewport_size.x - float(entry["dx"])
        var cy: float = float(entry["dy"]) if entry["top"] else _viewport_size.y - float(entry["dy"])
        var r: float = entry["r"]
        _buttons[i].position = Vector2(cx - r, cy - r)
    _prompt_label.position = Vector2(_viewport_size.x * 0.5 - _prompt_label.size.x * 0.5, _viewport_size.y - 170.0)
    _toast_label.position = Vector2(_viewport_size.x * 0.5 - _toast_label.size.x * 0.5, 24.0)


func _process(delta: float) -> void:
    var mode_name := "FIRST PERSON" if GameState.camera_mode == GameState.CameraMode.FIRST_PERSON else "THIRD PERSON"
    _info_label.text = "FPS %d  |  %s" % [Engine.get_frames_per_second(), mode_name]
    if _toast_time > 0.0:
        _toast_time -= delta
        _toast_label.modulate.a = clampf(_toast_time, 0.0, 1.0)


func _on_prompt_changed(text: String) -> void:
    _prompt_label.text = ("USE: " + text) if text != "" else ""


func _on_message_posted(text: String) -> void:
    _toast_label.text = text
    _toast_time = 2.5
    _toast_label.modulate.a = 1.0


# ---------------------------------------------------------------- touch routing

func _input(event: InputEvent) -> void:
    if get_tree().paused:
        return
    var touch := event as InputEventScreenTouch
    if touch != null:
        if touch.pressed:
            _touch_down(touch.index, touch.position)
        else:
            _touch_up(touch.index)
        return
    var drag := event as InputEventScreenDrag
    if drag != null:
        _touch_drag(drag.index, drag.position, drag.relative)


func _touch_down(index: int, pos: Vector2) -> void:
    for button in _buttons:
        if button.contains_point(pos):
            button.press()
            _owners[index] = button
            return
    if _joystick.contains_point(pos):
        _joystick.begin(pos)
        MobileInput.set_joystick(_joystick.value)
        _owners[index] = _joystick
        return
    if pos.x > _viewport_size.x * LOOK_MIN_X_FRACTION:
        _owners[index] = LOOK_OWNER


func _touch_up(index: int) -> void:
    if not _owners.has(index):
        return
    var owner_obj = _owners[index]
    _owners.erase(index)
    if owner_obj is String:
        return
    if owner_obj == _joystick:
        _joystick.end()
        MobileInput.set_joystick(Vector2.ZERO)
    else:
        owner_obj.release()


func _touch_drag(index: int, pos: Vector2, relative: Vector2) -> void:
    if not _owners.has(index):
        return
    var owner_obj = _owners[index]
    if owner_obj is String:
        MobileInput.add_look(relative)
    elif owner_obj == _joystick:
        _joystick.update_drag(pos)
        MobileInput.set_joystick(_joystick.value)


func _release_all_touches() -> void:
    _owners.clear()
    for button in _buttons:
        button.release()
    _joystick.end()
    MobileInput.reset()


# ---------------------------------------------------------------- panels

func _on_action_pressed(action: StringName) -> void:
    match action:
        &"pause":
            _open_pause()
        &"backpack":
            _open_inventory()


func _open_pause() -> void:
    if get_tree().paused:
        return
    _release_all_touches()
    _pause_layer.visible = true
    get_tree().paused = true


func _resume() -> void:
    _pause_layer.visible = false
    get_tree().paused = false


func _open_inventory() -> void:
    if get_tree().paused or _player == null:
        return
    _release_all_touches()
    _inventory_panel.open(_player)
    get_tree().paused = true


func _on_inventory_closed() -> void:
    get_tree().paused = false


func _on_player_died() -> void:
    _release_all_touches()
    _death_screen.visible = true
    get_tree().paused = true


func _on_respawn_requested() -> void:
    _death_screen.visible = false
    get_tree().paused = false
    _player.respawn()


func _quit_to_menu() -> void:
    get_tree().paused = false
    MobileInput.reset()
    get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _build_pause_menu() -> void:
    _pause_layer = CanvasLayer.new()
    _pause_layer.layer = 20
    _pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
    _pause_layer.visible = false
    add_child(_pause_layer)

    var dim := ColorRect.new()
    dim.color = Color(0, 0, 0, 0.6)
    _pause_layer.add_child(dim)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var center := CenterContainer.new()
    _pause_layer.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 16)
    center.add_child(box)

    var title := Label.new()
    title.text = "PAUSED"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 48)
    box.add_child(title)

    box.add_child(_make_menu_button("RESUME", _resume))
    box.add_child(_make_menu_button("MAIN MENU", _quit_to_menu))


func _make_menu_button(text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(420, 70)
    button.add_theme_font_size_override("font_size", 26)
    button.pressed.connect(callback)
    return button
