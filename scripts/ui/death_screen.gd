extends CanvasLayer
## "YOU DIED" overlay with a Respawn button. Shown/paused by hud.gd.

signal respawn_requested


func _ready() -> void:
    layer = 40
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false

    var dim := ColorRect.new()
    dim.color = Color(0.3, 0.0, 0.0, 0.75)
    add_child(dim)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var center := CenterContainer.new()
    add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 24)
    center.add_child(box)

    var title := Label.new()
    title.text = "YOU DIED"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 72)
    title.add_theme_color_override("font_color", Color(0.9, 0.2, 0.15))
    box.add_child(title)

    var button := Button.new()
    button.text = "RESPAWN"
    button.custom_minimum_size = Vector2(420, 80)
    button.add_theme_font_size_override("font_size", 30)
    button.pressed.connect(func() -> void: respawn_requested.emit())
    box.add_child(button)
