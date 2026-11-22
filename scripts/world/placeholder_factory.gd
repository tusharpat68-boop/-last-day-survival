extends RefCounted
## Procedural placeholder geometry so the prototype needs no external assets.
## Load with: const PF = preload("res://scripts/world/placeholder_factory.gd")

static var _materials: Dictionary = {}


static func material(color: Color) -> StandardMaterial3D:
    var key := color.to_html()
    if _materials.has(key):
        return _materials[key]
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.9
    _materials[key] = mat
    return mat


static func mesh_instance(mesh: Mesh, color: Color) -> MeshInstance3D:
    var inst := MeshInstance3D.new()
    inst.mesh = mesh
    inst.material_override = material(color)
    return inst


static func add_box(parent: Node, center: Vector3, box_size: Vector3, color: Color) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.collision_layer = 1
    body.collision_mask = 0
    var mesh := BoxMesh.new()
    mesh.size = box_size
    body.add_child(mesh_instance(mesh, color))
    var shape := BoxShape3D.new()
    shape.size = box_size
    var col := CollisionShape3D.new()
    col.shape = shape
    body.add_child(col)
    parent.add_child(body)
    body.position = center
    return body
