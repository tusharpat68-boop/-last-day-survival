extends CanvasLayer
## Touch-friendly backpack: tap a slot, then Use or Drop. Game is paused while open.

signal closed

const InventoryScript = preload("res://scripts/inventory/inventory.gd")
const COLUMNS := 5

var _player
var _inventory
var _selected := -1
var _slot_buttons: Array = []
var _stats_label: Label
var _desc_label: Label
var _use_button: Button
var _drop_button: Button


func _ready() -> void:
    layer = 30
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false
    _build_ui()


func open(player) -> void:
    _player = player
    _inventory = player.inventory
    if not _inventory.inventory_changed.is_connected(_refresh):
        _inventory.inventory_changed.connect(_refresh)
    _selected = -1
    _refresh()
    visible = true


func close() -> void:
    visible = false
    closed.emit()


func _build_ui() -> void:
    var dim := ColorRect.new()
    dim.color = Color(0, 0, 0, 0.7)
    add_child(dim)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var center := CenterContainer.new()
    add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var panel := PanelContainer.new()
    center.add_child(panel)

    var margin := MarginContainer.new()
    for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(side, 24)
    panel.add_child(margin)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 10)
    margin.add_child(root)

    var title := Label.new()
    title.text = "BACKPACK"
    title.add_theme_font_size_override("font_size", 34)
    root.add_child(title)

    _stats_label = Label.new()
    _stats_label.add_theme_font_size_override("font_size", 20)
    root.add_child(_stats_label)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 20)
    root.add_child(row)

    var grid := GridContainer.new()
    grid.columns = COLUMNS
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    row.add_child(grid)

    for i in InventoryScript.SLOT_COUNT:
        var button := Button.new()
        button.custom_minimum_size = Vector2(120, 90)
        button.add_theme_font_size_override("font_size", 17)
        button.clip_text = true
        button.pressed.connect(_on_slot_pressed.bind(i))
        grid.add_child(button)
        _slot_buttons.append(button)

    var side := VBoxContainer.new()
    side.add_theme_constant_override("separation", 10)
    row.add_child(side)

    _desc_label = Label.new()
    _desc_label.custom_minimum_size = Vector2(300, 200)
    _desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _desc_label.add_theme_font_size_override("font_size", 20)
    side.add_child(_desc_label)

    _use_button = _make_side_button("USE", _on_use_pressed)
    side.add_child(_use_button)
    _drop_button = _make_side_button("DROP", _on_drop_pressed)
    side.add_child(_drop_button)
    side.add_child(_make_side_button("CLOSE", close))


func _make_side_button(text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(300, 64)
    button.add_theme_font_size_override("font_size", 24)
    button.pressed.connect(callback)
    return button


func _on_slot_pressed(index: int) -> void:
    _selected = index if _inventory.slots[index] != null else -1
    _refresh()


func _on_use_pressed() -> void:
    if _selected < 0:
        return
    _inventory.use_slot(_selected, _player.stats)
    if _inventory.slots[_selected] == null:
        _selected = -1
    _refresh()


func _on_drop_pressed() -> void:
    if _selected < 0:
        return
    _player.drop_slot(_selected)
    _selected = -1
    _refresh()


func _refresh() -> void:
    if _inventory == null:
        return
    for i in _slot_buttons.size():
        var button: Button = _slot_buttons[i]
        var slot = _inventory.slots[i]
        if slot == null:
            button.text = "-"
        else:
            button.text = "%s\nx%d" % [ItemDatabase.item_name(slot["id"]), int(slot["qty"])]
        button.modulate = Color(1.0, 0.95, 0.5) if i == _selected else Color.WHITE

    var stats = _player.stats
    _stats_label.text = "HP %d   FOOD %d   WATER %d   STAMINA %d" % [
        int(stats.health), int(stats.hunger), int(stats.thirst), int(stats.stamina)]

    var selected_slot = null
    if _selected >= 0:
        selected_slot = _inventory.slots[_selected]
    if selected_slot == null:
        _desc_label.text = "Tap an item to select it."
        _use_button.disabled = true
        _drop_button.disabled = true
    else:
        var id: String = selected_slot["id"]
        _desc_label.text = "%s\n\n%s\n\nQuantity: %d" % [
            ItemDatabase.item_name(id), ItemDatabase.item_description(id), int(selected_slot["qty"])]
        _use_button.disabled = not ItemDatabase.is_usable(id)
        _drop_button.disabled = false
