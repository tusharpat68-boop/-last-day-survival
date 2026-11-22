extends CharacterBody3D
## Reusable player controller: walk / run / sprint / jump / crouch,
## first- and third-person cameras with a persistent camera switch.
## The whole body yaws with the camera (shooter-style), so switching
## cameras never changes position, rotation or velocity.

const PF = preload("res://scripts/world/placeholder_factory.gd")

const WALK_SPEED := 2.5
const RUN_SPEED := 5.0
const SPRINT_SPEED := 7.5
const CROUCH_SPEED := 1.8
const RUN_THRESHOLD := 0.55      # joystick magnitude where walk becomes run
const SPRINT_THRESHOLD := 0.92   # joystick pushed to the edge = sprint
const JUMP_VELOCITY := 4.8
const ACCEL := 14.0
const AIR_ACCEL := 3.0

const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.1
const RADIUS := 0.35
const EYE_OFFSET := 0.2          # eye is this far below the top of the capsule

const LOOK_RADIANS_PER_PIXEL := 0.0035
const MAX_PITCH := 1.309         # 75 degrees
const KILL_Y := -30.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _pitch := 0.0
var _crouching := false
var _jump_requested := false
var _spawn_position := Vector3.ZERO

var _capsule: CapsuleShape3D
var _collision: CollisionShape3D
var _model: Node3D
var _pitch_pivot: Node3D
var _fp_camera: Camera3D
var _tp_camera: Camera3D
var _spring_arm: SpringArm3D
var _weapon_fp: MeshInstance3D


func _ready() -> void:
    _spawn_position = global_position
    collision_layer = 2
    collision_mask = 1
    _build_body()
    _build_camera_rig()
    EventBus.camera_mode_changed.connect(_on_camera_mode_changed)
    MobileInput.action_pressed.connect(_on_action_pressed)
    SettingsManager.settings_changed.connect(_apply_settings)
    _apply_settings()
    _on_camera_mode_changed(GameState.camera_mode)


func _build_body() -> void:
    _capsule = CapsuleShape3D.new()
    _capsule.radius = RADIUS
    _capsule.height = STAND_HEIGHT
    _collision = CollisionShape3D.new()
    _collision.shape = _capsule
    _collision.position.y = STAND_HEIGHT * 0.5
    add_child(_collision)

    # Placeholder visual model (visible only in third person)
    _model = Node3D.new()
    add_child(_model)

    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = RADIUS
    body_mesh.height = 1.4
    var body := PF.mesh_instance(body_mesh, Color(0.2, 0.35, 0.55))
    body.position.y = 0.7
    _model.add_child(body)

    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.2
    head_mesh.height = 0.4
    var head := PF.mesh_instance(head_mesh, Color(0.85, 0.7, 0.6))
    head.position.y = 1.55
    _model.add_child(head)

    # Small "nose" so the facing direction is obvious
    var nose_mesh := BoxMesh.new()
    nose_mesh.size = Vector3(0.1, 0.1, 0.18)
    var nose := PF.mesh_instance(nose_mesh, Color(0.9, 0.2, 0.2))
    nose.position = Vector3(0.0, 1.55, -0.22)
    _model.add_child(nose)

    # Placeholder weapon in the hand (third person)
    var gun_mesh := BoxMesh.new()
    gun_mesh.size = Vector3(0.08, 0.12, 0.5)
    var gun := PF.mesh_instance(gun_mesh, Color(0.1, 0.1, 0.1))
    gun.position = Vector3(0.3, 1.0, -0.4)
    _model.add_child(gun)


func _build_camera_rig() -> void:
    _pitch_pivot = Node3D.new()
    _pitch_pivot.position.y = STAND_HEIGHT - EYE_OFFSET
    add_child(_pitch_pivot)

    # First-person camera at eye level
    _fp_camera = Camera3D.new()
    _fp_camera.fov = 75.0
    _fp_camera.near = 0.05
    _pitch_pivot.add_child(_fp_camera)

    # Placeholder weapon visible in first person
    var fp_gun_mesh := BoxMesh.new()
    fp_gun_mesh.size = Vector3(0.08, 0.12, 0.5)
    _weapon_fp = PF.mesh_instance(fp_gun_mesh, Color(0.1, 0.1, 0.1))
    _weapon_fp.position = Vector3(0.25, -0.22, -0.5)
    _fp_camera.add_child(_weapon_fp)

    # Third-person camera: over-the-shoulder spring arm (handles wall collision)
    var shoulder := Node3D.new()
    shoulder.position.x = 0.35
    _pitch_pivot.add_child(shoulder)

    _spring_arm = SpringArm3D.new()
    _spring_arm.spring_length = SettingsManager.third_person_distance
    _spring_arm.margin = 0.3
    _spring_arm.collision_mask = 1
    var arm_shape := SphereShape3D.new()
    arm_shape.radius = 0.25
    _spring_arm.shape = arm_shape
    shoulder.add_child(_spring_arm)
    _spring_arm.add_excluded_object(get_rid())

    _tp_camera = Camera3D.new()
    _tp_camera.fov = 70.0
    _spring_arm.add_child(_tp_camera)


func _apply_settings() -> void:
    if _spring_arm != null:
        _spring_arm.spring_length = SettingsManager.third_person_distance


func _on_camera_mode_changed(mode: int) -> void:
    var first_person := mode == GameState.CameraMode.FIRST_PERSON
    _model.visible = not first_person
    _weapon_fp.visible = first_person
    if first_person:
        _fp_camera.make_current()
    else:
        _tp_camera.make_current()


func _on_action_pressed(action: StringName) -> void:
    match action:
        &"jump":
            _jump_requested = true
            _crouching = false
        &"crouch":
            _crouching = not _crouching
        &"camera_switch":
            GameState.toggle_camera_mode()


func _physics_process(delta: float) -> void:
    _handle_look()
    _handle_crouch(delta)

    var move := MobileInput.get_move()
    var wish := global_transform.basis * Vector3(move.x, 0.0, move.y)
    wish.y = 0.0
    var target := wish.normalized() * _speed_for(move.length())
    var accel := ACCEL if is_on_floor() else AIR_ACCEL
    var blend := clampf(accel * delta, 0.0, 1.0)
    velocity.x = lerpf(velocity.x, target.x, blend)
    velocity.z = lerpf(velocity.z, target.z, blend)

    if not is_on_floor():
        velocity.y -= _gravity * delta
    elif _jump_requested:
        velocity.y = JUMP_VELOCITY
    _jump_requested = false

    move_and_slide()

    if global_position.y < KILL_Y:
        _respawn()


func _speed_for(magnitude: float) -> float:
    if magnitude < 0.01:
        return 0.0
    if _crouching:
        return CROUCH_SPEED
    if magnitude >= SPRINT_THRESHOLD:
        return SPRINT_SPEED
    if magnitude >= RUN_THRESHOLD:
        return RUN_SPEED
    return WALK_SPEED


func _handle_look() -> void:
    var d := MobileInput.consume_look()
    if d == Vector2.ZERO:
        return
    var k := LOOK_RADIANS_PER_PIXEL * SettingsManager.look_sensitivity
    rotate_y(-d.x * k)
    _pitch = clampf(_pitch - d.y * k, -MAX_PITCH, MAX_PITCH)
    _pitch_pivot.rotation.x = _pitch


func _handle_crouch(delta: float) -> void:
    var target_height := CROUCH_HEIGHT if _crouching else STAND_HEIGHT
    _capsule.height = lerpf(_capsule.height, target_height, clampf(12.0 * delta, 0.0, 1.0))
    _collision.position.y = _capsule.height * 0.5
    _pitch_pivot.position.y = _capsule.height - EYE_OFFSET
    _model.scale.y = _capsule.height / STAND_HEIGHT


func _respawn() -> void:
    global_position = _spawn_position
    velocity = Vector3.ZERO
