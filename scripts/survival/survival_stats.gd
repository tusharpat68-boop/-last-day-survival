extends Node
## Health / hunger / thirst / stamina. All rates are configurable in
## res://data/survival/config.json (missing keys fall back to DEFAULTS).

signal stats_changed
signal died

const CONFIG_PATH := "res://data/survival/config.json"
const STAT_NAMES := ["health", "hunger", "thirst", "stamina"]
const EMIT_INTERVAL := 0.1
const DEFAULTS := {
    "max_health": 100.0,
    "max_hunger": 100.0,
    "max_thirst": 100.0,
    "max_stamina": 100.0,
    "hunger_drain_per_sec": 0.15,
    "thirst_drain_per_sec": 0.22,
    "starvation_damage_per_sec": 0.4,
    "dehydration_damage_per_sec": 0.7,
    "health_regen_per_sec": 0.6,
    "regen_min_stat": 50.0,
    "stamina_sprint_drain_per_sec": 15.0,
    "stamina_regen_per_sec": 18.0,
    "stamina_regen_delay": 1.0,
    "stamina_jump_cost": 10.0,
    "stamina_exhausted_recover": 25.0,
}

var config: Dictionary = DEFAULTS.duplicate()
var health := 100.0
var hunger := 100.0
var thirst := 100.0
var stamina := 100.0
var is_dead := false

var _sprinting := false
var _exhausted := false
var _stamina_idle := 0.0
var _emit_timer := 0.0


func _ready() -> void:
    _load_config()
    reset()


func _load_config() -> void:
    if not FileAccess.file_exists(CONFIG_PATH):
        return
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
    if parsed is Dictionary:
        for key in parsed:
            config[key] = parsed[key]


func _c(key: String) -> float:
    return float(config.get(key, DEFAULTS[key]))


func max_of(stat: String) -> float:
    return _c("max_" + stat)


func reset() -> void:
    health = _c("max_health")
    hunger = _c("max_hunger")
    thirst = _c("max_thirst")
    stamina = _c("max_stamina")
    is_dead = false
    _exhausted = false
    _sprinting = false
    _stamina_idle = 0.0
    stats_changed.emit()


func set_sprinting(value: bool) -> void:
    _sprinting = value


func can_sprint() -> bool:
    return not _exhausted and stamina > 0.0


func try_spend_jump() -> bool:
    var cost := _c("stamina_jump_cost")
    if stamina < cost:
        return false
    stamina -= cost
    _stamina_idle = 0.0
    stats_changed.emit()
    return true


func apply_effects(effects: Dictionary) -> void:
    for stat in STAT_NAMES:
        if effects.has(stat):
            var new_value := float(get(stat)) + float(effects[stat])
            set(stat, clampf(new_value, 0.0, max_of(stat)))
    stats_changed.emit()


func take_damage(amount: float) -> void:
    if is_dead:
        return
    health -= amount
    _check_death()
    stats_changed.emit()


func _process(delta: float) -> void:
    if is_dead:
        return

    hunger = maxf(0.0, hunger - _c("hunger_drain_per_sec") * delta)
    thirst = maxf(0.0, thirst - _c("thirst_drain_per_sec") * delta)

    var damage := 0.0
    if hunger <= 0.0:
        damage += _c("starvation_damage_per_sec")
    if thirst <= 0.0:
        damage += _c("dehydration_damage_per_sec")
    if damage > 0.0:
        health -= damage * delta
    elif hunger >= _c("regen_min_stat") and thirst >= _c("regen_min_stat"):
        health = minf(_c("max_health"), health + _c("health_regen_per_sec") * delta)

    _update_stamina(delta)

    if _check_death():
        stats_changed.emit()
        return

    _emit_timer += delta
    if _emit_timer >= EMIT_INTERVAL:
        _emit_timer = 0.0
        stats_changed.emit()


func _update_stamina(delta: float) -> void:
    if _sprinting:
        stamina = maxf(0.0, stamina - _c("stamina_sprint_drain_per_sec") * delta)
        _stamina_idle = 0.0
        if stamina <= 0.0:
            _exhausted = true
    else:
        _stamina_idle += delta
        if _stamina_idle >= _c("stamina_regen_delay"):
            stamina = minf(_c("max_stamina"), stamina + _c("stamina_regen_per_sec") * delta)
    if _exhausted and stamina >= _c("stamina_exhausted_recover"):
        _exhausted = false


func _check_death() -> bool:
    if health > 0.0 or is_dead:
        return false
    health = 0.0
    is_dead = true
    died.emit()
    return true
