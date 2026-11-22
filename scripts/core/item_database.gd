extends Node
## Data-driven item definitions (autoload "ItemDatabase").
## Items live in res://data/items/items.json - add new items there.

const ITEMS_PATH := "res://data/items/items.json"

var _items: Dictionary = {}


func _ready() -> void:
    _load_items()


func _load_items() -> void:
    if not FileAccess.file_exists(ITEMS_PATH):
        push_error("ItemDatabase: missing %s" % ITEMS_PATH)
        return
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(ITEMS_PATH))
    if parsed is Dictionary:
        _items = parsed
    else:
        push_error("ItemDatabase: could not parse %s" % ITEMS_PATH)


func has_item(item_id: String) -> bool:
    return _items.has(item_id)


func item_name(item_id: String) -> String:
    var def: Dictionary = _items.get(item_id, {})
    return str(def.get("name", item_id))


func item_description(item_id: String) -> String:
    var def: Dictionary = _items.get(item_id, {})
    return str(def.get("description", ""))


func stack_size(item_id: String) -> int:
    var def: Dictionary = _items.get(item_id, {})
    return maxi(1, int(def.get("stack", 1)))


func item_color(item_id: String) -> Color:
    var def: Dictionary = _items.get(item_id, {})
    return Color.html(str(def.get("color", "#ffffff")))


func use_effects(item_id: String) -> Dictionary:
    var def: Dictionary = _items.get(item_id, {})
    return def.get("use", {})


func is_usable(item_id: String) -> bool:
    return not use_effects(item_id).is_empty()
