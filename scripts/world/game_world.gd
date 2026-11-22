extends Node3D
## Gameplay root: map + player + HUD.

const MAP_SCENE: PackedScene = preload("res://scenes/world/test_map.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/hud.tscn")
const SPAWN_POSITION := Vector3(0.0, 0.1, 0.0)


func _ready() -> void:
    GameState.game_mode = GameState.GameMode.OFFLINE
    add_child(MAP_SCENE.instantiate())
    var player := PLAYER_SCENE.instantiate() as Node3D
    player.position = SPAWN_POSITION
    add_child(player)
    add_child(HUD_SCENE.instantiate())
