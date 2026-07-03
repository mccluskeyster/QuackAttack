extends Node
## Global game state: score, weight/speed loop, upgrades, session, persistence.
##
## Registered as the `GameState` autoload (see project.godot). Reacts to the
## `Events` signal bus so gameplay nodes stay decoupled from bookkeeping.
##
## Core loop: eating raises `score` AND `weight`. Weight slows the duck
## (`speed_multiplier`). Weight only comes off via metabolism (passive burn
## while flying), `offload()` (active poop/drop), or a temporary speed
## `upgrade`. Cross `MAX_WEIGHT` and the duck is grounded — the run ends.

const SAVE_PATH := "user://save.cfg"

## --- Tuning (all provisional; balanced in M5) ---
## Weight added per point of food eaten (heavier food = fatter, slower).
const MASS_PER_POINT := 0.20
## Weight at which the duck is too fat to fly → grounded → game over.
const MAX_WEIGHT := 100.0
## Weight burned per second while actively flying (metabolism).
const METABOLISM_RATE := 3.0
## Weight dropped by one active offload (poop / drop food).
const OFFLOAD_AMOUNT := 18.0
## Speed multiplier lost per unit of weight.
const WEIGHT_SLOWDOWN := 0.008
## Floor so a heavy (but not grounded) duck still crawls.
const MIN_SPEED_MULT := 0.30

var score := 0
var high_score := 0
var session_active := false

## Accumulated fat in [0, MAX_WEIGHT]. Drives the speed penalty and fail state.
var weight := 0.0
## Set true by the duck while it is moving, so metabolism only burns in flight.
var is_flying := false

## Additive speed bonus from the active temporary upgrade (0 when none).
var upgrade_speed_bonus := 0.0
var _active_upgrade_id := ""
var _upgrade_time_left := 0.0


func _ready() -> void:
	_load()
	Events.food_collected.connect(_on_food_collected)


func _process(delta: float) -> void:
	if not session_active:
		return
	# Metabolism: passively burn weight while flying.
	if is_flying and weight > 0.0:
		_set_weight(weight - METABOLISM_RATE * delta)
	# Tick down the active temporary upgrade.
	if _upgrade_time_left > 0.0:
		_upgrade_time_left -= delta
		if _upgrade_time_left <= 0.0:
			_clear_upgrade()


func start_session() -> void:
	score = 0
	is_flying = false
	_clear_upgrade()
	_set_weight(0.0)
	session_active = true
	Events.emit_score_changed(score)
	Events.emit_session_started()


func end_session() -> void:
	if not session_active:
		return
	session_active = false
	if score > high_score:
		high_score = score
		_save()
	Events.emit_session_ended(score)


## Current movement speed multiplier, clamped so a still-flying duck never
## fully stops. Duck reads: effective_speed = base_speed * speed_multiplier().
func speed_multiplier() -> float:
	var m := 1.0 - weight * WEIGHT_SLOWDOWN + upgrade_speed_bonus
	return maxf(MIN_SPEED_MULT, m)


## Deliberately shed weight (poop / drop food). Called by the duck on input.
func offload() -> void:
	if not session_active or weight <= 0.0:
		return
	_set_weight(weight - OFFLOAD_AMOUNT)


## Activate a temporary speed upgrade (rideable/propulsion/drone). A new one
## replaces any active one.
func apply_upgrade(id: String, speed_bonus: float, duration: float) -> void:
	_active_upgrade_id = id
	upgrade_speed_bonus = speed_bonus
	_upgrade_time_left = duration
	Events.emit_upgrade_activated(id, duration)


func _on_food_collected(points: int) -> void:
	if not session_active:
		return
	score += points
	Events.emit_score_changed(score)
	_set_weight(weight + points * MASS_PER_POINT)


## Single choke point for weight changes: clamps, notifies, and grounds the
## duck when it hits the fail threshold.
func _set_weight(value: float) -> void:
	weight = clampf(value, 0.0, MAX_WEIGHT)
	Events.emit_weight_changed(weight, MAX_WEIGHT)
	if weight >= MAX_WEIGHT:
		Events.emit_duck_grounded()
		end_session()


func _clear_upgrade() -> void:
	if _active_upgrade_id != "":
		Events.emit_upgrade_expired(_active_upgrade_id)
	_active_upgrade_id = ""
	upgrade_speed_bonus = 0.0
	_upgrade_time_left = 0.0


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "high_score", high_score)
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	high_score = int(cfg.get_value("progress", "high_score", 0))
