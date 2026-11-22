extends Control
## Splash screen. Tap to skip.

const NEXT_SCENE := "res://scenes/main/main_menu.tscn"
const SPLASH_SECONDS := 2.0

var _done := false


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var bg := ColorRect.new()
    bg.color = Color(0.04, 0.04, 0.05)
    add_child(bg)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var title := Label.new()
    title.text = "LAST DAY: SURVIVAL"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 64)
    title.add_theme_color_override("font_color", Color(0.85, 0.2, 0.15))
    add_child(title)
    title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    await get_tree().create_timer(SPLASH_SECONDS).timeout
    _go_next()


func _input(event: InputEvent) -> void:
    var touch := event as InputEventScreenTouch
    if touch != null and touch.pressed:
        _go_next()


func _go_next() -> void:
    if _done:
        return
    _done = true
    get_tree().change_scene_to_file(NEXT_SCENE)
