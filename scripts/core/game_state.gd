extends Node
## Global game state (autoload "GameState").

enum CameraMode { FIRST_PERSON, THIRD_PERSON }
enum GameMode { OFFLINE, ONLINE_SOLO, ONLINE_MULTIPLAYER }

var camera_mode: CameraMode = CameraMode.THIRD_PERSON
var game_mode: GameMode = GameMode.OFFLINE


func toggle_camera_mode() -> void:
    if camera_mode == CameraMode.THIRD_PERSON:
        camera_mode = CameraMode.FIRST_PERSON
    else:
        camera_mode = CameraMode.THIRD_PERSON
    EventBus.camera_mode_changed.emit(camera_mode)
