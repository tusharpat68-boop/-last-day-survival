extends RefCounted
## Backpack: fixed slots, stacking, use, drop. Slots are null or {"id": String, "qty": int}.

signal inventory_changed

const SLOT_COUNT := 20

var slots: Array = []


func _init() -> void:
    slots.resize(SLOT_COUNT)
    slots.fill(null)


## Returns how many items did NOT fit (0 = everything was added).
func add_item(item_id: String, quantity: int) -> int:
    if not ItemDatabase.has_item(item_id) or quantity <= 0:
        return quantity
    var max_stack := ItemDatabase.stack_size(item_id)
    var remaining := quantity

    for i in SLOT_COUNT:
        if remaining <= 0:
            break
        var slot = slots[i]
        if slot != null and slot["id"] == item_id and int(slot["qty"]) < max_stack:
            var room := mini(max_stack - int(slot["qty"]), remaining)
            slot["qty"] = int(slot["qty"]) + room
            remaining -= room

    for i in SLOT_COUNT:
        if remaining <= 0:
            break
        if slots[i] == null:
            var amount := mini(max_stack, remaining)
            slots[i] = {"id": item_id, "qty": amount}
            remaining -= amount

    if remaining != quantity:
        inventory_changed.emit()
    return remaining


## Removes and returns the whole stack in a slot ({} if empty).
func take_slot(index: int) -> Dictionary:
    var item = slots[index]
    if item == null:
        return {}
    slots[index] = null
    inventory_changed.emit()
    return item


## Consumes one item from a slot and applies its effects. Returns true on success.
func use_slot(index: int, stats) -> bool:
    var slot = slots[index]
    if slot == null:
        return false
    var effects: Dictionary = ItemDatabase.use_effects(slot["id"])
    if effects.is_empty():
        return false
    stats.apply_effects(effects)
    slot["qty"] = int(slot["qty"]) - 1
    if int(slot["qty"]) <= 0:
        slots[index] = null
    inventory_changed.emit()
    return true
