extends Node
## Central input state (autoload "MobileInput").
## The touch HUD writes into it; the player reads from it.
## Keyboard fallback exists only for desktop testing:
## WASD move, Shift sprint, Space jump, C crouch, V camera, Esc pause.

signal action_pressed(action: StringName)
signal action_released(action: StringName)

var _joystick_vector := Vector2.ZERO
var _keyboard_vector := Vector2.ZERO
var _look_accum := Vector2.ZERO
var _held: Dictionary = {}


func set_joystick(value: Vector2) -> void:
    _joystick_vector = value


func get_move() -> Vector2:
    if _joystick_vector.length() > 0.01:
        return _joystick_vector
    return _keyboard_vector


func add_look(delta: Vector2) -> void:
    _look_accum += delta


func consume_look() -> Vector2:
    var d := _look_accum
    _look_accum = Vector2.ZERO
    return d


func press(action: StringName) -> void:
    if _held.get(action, false):
        return
    _held[action] = true
    action_pressed.emit(action)


func release(action: StringName) -> void:
    if not _held.get(action, false):
        return
    _held[action] = false
    action_released.emit(action)


func is_held(action: StringName) -> bool:
    return _held.get(action, false)


func reset() -> void:
    for action in _held.keys():
        release(action)
    _joystick_vector = Vector2.ZERO
    _look_accum = Vector2.ZERO


func _process(_delta: float) -> void:
    var kb := Vector2.ZERO
    if Input.is_physical_key_pressed(KEY_A):
        kb.x -= 1.0
    if Input.is_physical_key_pressed(KEY_D):
        kb.x += 1.0
    if Input.is_physical_key_pressed(KEY_W):
        kb.y -= 1.0
    if Input.is_physical_key_pressed(KEY_S):
        kb.y += 1.0
    if kb != Vector2.ZERO:
        var strength := 1.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 0.7
        kb = kb.normalized() * strength
    _keyboard_vector = kb


func _unhandled_key_input(event: InputEvent) -> void:
    var key := event as InputEventKey
    if key == null or key.echo:
        return
    var action: StringName = &""
    match key.physical_keycode:
        KEY_SPACE:
            action = &"jump"
        KEY_C:
            action = &"crouch"
        KEY_V:
            action = &"camera_switch"
        KEY_ESCAPE:
            action = &"pause"
    if action == &"":
        return
    if key.pressed:
        press(action)
    else:
        release(action)
