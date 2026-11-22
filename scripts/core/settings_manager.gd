extends Node
## Local settings (autoload "SettingsManager"). Stored in user://settings.cfg.

signal settings_changed

const SAVE_PATH := "user://settings.cfg"

var look_sensitivity: float = 1.0
var third_person_distance: float = 3.5
var shadows_enabled: bool = false   # off by default: shadows are the heaviest effect on phones
var render_scale: float = 0.75      # 3D resolution scale (0.5 - 1.0)


func _ready() -> void:
    load_settings()
    apply_render_settings()


func load_settings() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    look_sensitivity = clampf(float(cfg.get_value("controls", "look_sensitivity", 1.0)), 0.3, 3.0)
    third_person_distance = clampf(float(cfg.get_value("camera", "third_person_distance", 3.5)), 2.0, 6.0)
    shadows_enabled = bool(cfg.get_value("graphics", "shadows_enabled", false))
    render_scale = clampf(float(cfg.get_value("graphics", "render_scale", 0.75)), 0.5, 1.0)
    settings_changed.emit()


func save_settings() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("controls", "look_sensitivity", look_sensitivity)
    cfg.set_value("camera", "third_person_distance", third_person_distance)
    cfg.set_value("graphics", "shadows_enabled", shadows_enabled)
    cfg.set_value("graphics", "render_scale", render_scale)
    cfg.save(SAVE_PATH)
    apply_render_settings()
    settings_changed.emit()


func apply_render_settings() -> void:
    get_tree().root.scaling_3d_scale = render_scale
