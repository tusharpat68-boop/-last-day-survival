extends Control
## Circular touch button. Routing is done by hud.gd (multi-touch aware);
## this node only draws itself and reports press/release to MobileInput.

var action: StringName = &""
var label_text := ""
var radius := 50.0
var pressed := false


func setup(p_action: StringName, p_label: String, p_radius: float) -> void:
    action = p_action
    label_text = p_label
    radius = p_radius
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    size = Vector2.ONE * radius * 2.0
    queue_redraw()


func contains_point(point: Vector2) -> bool:
    return point.distance_to(global_position + size * 0.5) <= radius


func press() -> void:
    if pressed:
        return
    pressed = true
    queue_redraw()
    MobileInput.press(action)


func release() -> void:
    if not pressed:
        return
    pressed = false
    queue_redraw()
    MobileInput.release(action)


func _draw() -> void:
    var center := size * 0.5
    var fill := Color(1, 1, 1, 0.35) if pressed else Color(0, 0, 0, 0.35)
    draw_circle(center, radius, fill)
    draw_arc(center, radius - 1.5, 0.0, TAU, 48, Color(1, 1, 1, 0.75), 3.0, true)
    var font := ThemeDB.fallback_font
    var font_size := int(maxf(14.0, radius * 0.3))
    draw_string(font, Vector2(0.0, center.y + font_size * 0.35), label_text,
        HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color.WHITE)
