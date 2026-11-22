extends Control
## Health / hunger / thirst / stamina bars (drawn, no child nodes).

const BAR_SIZE := Vector2(280, 20)
const SPACING := 26.0
const ENTRIES := [
    ["HP", "health", Color(0.8, 0.15, 0.15)],
    ["FOOD", "hunger", Color(0.9, 0.55, 0.15)],
    ["WATER", "thirst", Color(0.2, 0.5, 0.85)],
    ["STAM", "stamina", Color(0.25, 0.7, 0.3)],
]

var _stats


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    size = Vector2(BAR_SIZE.x, SPACING * ENTRIES.size())


func bind(stats) -> void:
    _stats = stats
    stats.stats_changed.connect(queue_redraw)
    queue_redraw()


func _draw() -> void:
    if _stats == null:
        return
    var font := ThemeDB.fallback_font
    for i in ENTRIES.size():
        var entry: Array = ENTRIES[i]
        var value: float = _stats.get(entry[1])
        var max_value: float = _stats.max_of(entry[1])
        var ratio := clampf(value / max_value, 0.0, 1.0)
        var pos := Vector2(0.0, i * SPACING)
        draw_rect(Rect2(pos, BAR_SIZE), Color(0, 0, 0, 0.5))
        draw_rect(Rect2(pos, Vector2(BAR_SIZE.x * ratio, BAR_SIZE.y)), entry[2])
        draw_string(font, pos + Vector2(8.0, 15.0), "%s %d" % [entry[0], int(value)],
            HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
