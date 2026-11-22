extends Control
## Virtual joystick. Routing is done by hud.gd (multi-touch aware).

const DEADZONE := 0.12

var base_radius := 110.0
var knob_radius := 46.0
var value := Vector2.ZERO
var active := false
var _knob_offset := Vector2.ZERO


func setup(p_base_radius: float) -> void:
    base_radius = p_base_radius
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    size = Vector2.ONE * base_radius * 2.0


func _center() -> Vector2:
    return global_position + size * 0.5


func contains_point(point: Vector2) -> bool:
    return point.distance_to(_center()) <= base_radius * 1.6


func begin(point: Vector2) -> void:
    active = true
    update_drag(point)


func update_drag(point: Vector2) -> void:
    var offset := point - _center()
    if offset.length() > base_radius:
        offset = offset.normalized() * base_radius
    _knob_offset = offset
    var v := offset / base_radius
    value = Vector2.ZERO if v.length() < DEADZONE else v
    queue_redraw()


func end() -> void:
    active = false
    value = Vector2.ZERO
    _knob_offset = Vector2.ZERO
    queue_redraw()


func _draw() -> void:
    var center := size * 0.5
    draw_circle(center, base_radius, Color(0, 0, 0, 0.3))
    draw_arc(center, base_radius - 1.5, 0.0, TAU, 64, Color(1, 1, 1, 0.6), 3.0, true)
    var knob_alpha := 0.7 if active else 0.45
    draw_circle(center + _knob_offset, knob_radius, Color(1, 1, 1, knob_alpha))
