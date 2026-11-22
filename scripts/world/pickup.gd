extends Node3D
## A collectible item lying in the world. Placeholder visual: coloured cube.
## Create with: var p = PickupScript.new(); p.setup("canned_food", 2); parent.add_child(p)

const PF = preload("res://scripts/world/placeholder_factory.gd")

var item_id := ""
var quantity := 1

var _visual: MeshInstance3D


func setup(id: String, qty: int) -> void:
    item_id = id
    quantity = qty


func _ready() -> void:
    add_to_group("pickups")
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.35, 0.35, 0.35)
    _visual = PF.mesh_instance(mesh, ItemDatabase.item_color(item_id))
    _visual.position.y = 0.3
    add_child(_visual)


func _process(delta: float) -> void:
    _visual.rotate_y(delta * 1.5)


func prompt_text() -> String:
    return "Pick up %s x%d" % [ItemDatabase.item_name(item_id), quantity]
