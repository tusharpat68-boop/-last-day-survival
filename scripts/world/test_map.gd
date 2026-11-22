extends Node3D
## Small grey-box test map built entirely in code (no external assets).

const PF = preload("res://scripts/world/placeholder_factory.gd")
const PickupScript = preload("res://scripts/world/pickup.gd")

const COLOR_GRASS := Color(0.25, 0.38, 0.2)
const COLOR_STONE := Color(0.5, 0.5, 0.52)
const COLOR_CONCRETE := Color(0.62, 0.6, 0.57)
const COLOR_WOOD := Color(0.45, 0.3, 0.18)
const COLOR_TRUNK := Color(0.3, 0.2, 0.12)
const COLOR_LEAVES := Color(0.12, 0.3, 0.14)

const TREE_COUNT := 45
const HOUSE_CENTERS := [Vector3(24, 0, 6), Vector3(-24, 0, -8)]
const POND_CENTER := Vector3(-14, 0, 18)
const POND_RADIUS := 5.0
const COLOR_WATER := Color(0.2, 0.42, 0.7)

# [item id, quantity, position]
const PICKUPS := [
    ["water_bottle", 1, Vector3(4, 0, 4)],
    ["water_bottle", 2, Vector3(-6, 0, 6)],
    ["canned_food", 1, Vector3(6, 0, 2)],
    ["canned_food", 2, Vector3(-4, 0, 3)],
    ["bandage", 1, Vector3(2, 0, 6)],
    ["wood", 3, Vector3(-8, 0, -1.5)],
    ["stone", 3, Vector3(9, 0, 5)],
    ["canned_food", 3, Vector3(24, 0, 5)],
    ["bandage", 2, Vector3(22, 0, 4)],
    ["water_bottle", 3, Vector3(-24, 0, -9)],
    ["canned_food", 2, Vector3(-22, 0, -7)],
]


func _ready() -> void:
    _build_environment()
    PF.add_box(self, Vector3(0, -0.5, 0), Vector3(200, 1, 200), COLOR_GRASS)
    _build_obstacle_course()
    for center in HOUSE_CENTERS:
        _build_house(center)
    _build_pond()
    _build_pickups()
    _build_trees()


func _build_environment() -> void:
    var sky_material := ProceduralSkyMaterial.new()
    var sky := Sky.new()
    sky.sky_material = sky_material
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.fog_enabled = true
    env.fog_light_color = Color(0.7, 0.75, 0.8)
    env.fog_density = 0.004
    var world_env := WorldEnvironment.new()
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
    sun.shadow_enabled = SettingsManager.shadows_enabled
    sun.directional_shadow_max_distance = 40.0
    add_child(sun)


func _build_obstacle_course() -> void:
    # Steps (jump test)
    PF.add_box(self, Vector3(-3, 0.2, -8), Vector3(3, 0.4, 3), COLOR_STONE)
    PF.add_box(self, Vector3(-3, 0.4, -11), Vector3(3, 0.8, 3), COLOR_STONE)
    PF.add_box(self, Vector3(-3, 0.6, -14), Vector3(3, 1.2, 3), COLOR_STONE)
    # Ramp (low end toward the spawn)
    var ramp := PF.add_box(self, Vector3(4, 0.9, -10), Vector3(4, 0.3, 8), COLOR_WOOD)
    ramp.rotation_degrees.x = 15.0
    # Low wall
    PF.add_box(self, Vector3(-9, 0.5, -4), Vector3(6, 1, 0.5), COLOR_CONCRETE)
    # Crouch-under beam (beam bottom at ~1.25 m: standing is blocked, crouching fits)
    PF.add_box(self, Vector3(6, 0.75, -3), Vector3(0.3, 1.5, 0.5), COLOR_WOOD)
    PF.add_box(self, Vector3(10, 0.75, -3), Vector3(0.3, 1.5, 0.5), COLOR_WOOD)
    PF.add_box(self, Vector3(8, 1.4, -3), Vector3(4, 0.3, 0.5), COLOR_WOOD)


func _build_house(center: Vector3) -> void:
    var wall_h := 3.0
    var y := wall_h * 0.5
    # Back, left, right walls
    PF.add_box(self, center + Vector3(0, y, -4), Vector3(8, wall_h, 0.3), COLOR_CONCRETE)
    PF.add_box(self, center + Vector3(-4, y, 0), Vector3(0.3, wall_h, 8), COLOR_CONCRETE)
    PF.add_box(self, center + Vector3(4, y, 0), Vector3(0.3, wall_h, 8), COLOR_CONCRETE)
    # Front wall with a 2 m door gap
    PF.add_box(self, center + Vector3(-2.5, y, 4), Vector3(3, wall_h, 0.3), COLOR_CONCRETE)
    PF.add_box(self, center + Vector3(2.5, y, 4), Vector3(3, wall_h, 0.3), COLOR_CONCRETE)
    PF.add_box(self, center + Vector3(0, 2.5, 4), Vector3(2, 1.0, 0.3), COLOR_CONCRETE)
    # Roof
    PF.add_box(self, center + Vector3(0, wall_h + 0.15, 0), Vector3(8.6, 0.3, 8.6), COLOR_WOOD)


func _build_pond() -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = POND_RADIUS
    mesh.bottom_radius = POND_RADIUS
    mesh.height = 0.05
    mesh.radial_segments = 32
    mesh.rings = 1
    var pond := PF.mesh_instance(mesh, COLOR_WATER)
    pond.position = POND_CENTER + Vector3(0.0, 0.03, 0.0)
    pond.add_to_group("water")
    pond.set_meta("radius", POND_RADIUS)
    add_child(pond)


func _build_pickups() -> void:
    for entry in PICKUPS:
        var pickup = PickupScript.new()
        pickup.setup(entry[0], entry[1])
        add_child(pickup)
        pickup.position = entry[2]


func _build_trees() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20240611
    var placed := 0
    var attempts := 0
    while placed < TREE_COUNT and attempts < 500:
        attempts += 1
        var pos := Vector3(rng.randf_range(-70.0, 70.0), 0.0, rng.randf_range(-70.0, 70.0))
        if _is_reserved(pos):
            continue
        _add_tree(pos, rng.randf_range(0.8, 1.4))
        placed += 1


func _is_reserved(pos: Vector3) -> bool:
    if absf(pos.x) < 16.0 and pos.z > -20.0 and pos.z < 10.0:
        return true
    for center in HOUSE_CENTERS:
        if Vector2(pos.x - center.x, pos.z - center.z).length() < 10.0:
            return true
    if Vector2(pos.x - POND_CENTER.x, pos.z - POND_CENTER.z).length() < POND_RADIUS + 3.0:
        return true
    return false


func _add_tree(pos: Vector3, tree_scale: float) -> void:
    var trunk_height := 4.0 * tree_scale
    var trunk := StaticBody3D.new()
    trunk.collision_layer = 1
    trunk.collision_mask = 0

    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.22 * tree_scale
    trunk_mesh.bottom_radius = 0.3 * tree_scale
    trunk_mesh.height = trunk_height
    trunk_mesh.radial_segments = 8
    trunk_mesh.rings = 1
    trunk.add_child(PF.mesh_instance(trunk_mesh, COLOR_TRUNK))

    var shape := CylinderShape3D.new()
    shape.radius = 0.3 * tree_scale
    shape.height = trunk_height
    var col := CollisionShape3D.new()
    col.shape = shape
    trunk.add_child(col)

    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 1.8 * tree_scale
    crown_mesh.height = 3.6 * tree_scale
    crown_mesh.radial_segments = 12
    crown_mesh.rings = 6
    var crown := PF.mesh_instance(crown_mesh, COLOR_LEAVES)
    crown.position.y = trunk_height * 0.5 + 1.2 * tree_scale
    trunk.add_child(crown)

    add_child(trunk)
    trunk.position = pos + Vector3(0.0, trunk_height * 0.5, 0.0)
