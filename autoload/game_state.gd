extends Node
## Global game state: score, session lifecycle, duck weight/speed, persistence.
##
## Registered as the `GameState` autoload (see project.godot). Reacts to the
## `Events` signal bus so gameplay nodes stay decoupled from bookkeeping.

const SAVE_PATH := "user://save.cfg"

## Tuning (all provisional — balanced during M5).
## Speed multiplier lost per unit of accumulated weight.
const WEIGHT_SLOWDOWN := 0.01
## Floor so a very fat duck still crawls rather than freezing.
const MIN_SPEED_MULT := 0.35
## Weight added per point of food eaten (heavier food = fatter, slower).
const MASS_PER_POINT := 0.20

var score := 0
var high_score := 0
var session_active := false

## Accumulated fat. Rises as the duck eats; drives the speed penalty.
var weight := 0.0
## Additive speed bonus from side-quest upgrades (rideables, propulsion, drones).
## Set/cleared by the upgrade system (M-future); offsets the weight penalty.
var upgrade_speed_bonus := 0.0


func _ready() -> void:
	_load()
	Events.food_collected.connect(_on_food_collected)


func start_session() -> void:
	score = 0
	weight = 0.0
	upgrade_speed_bonus = 0.0
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


## Current movement speed multiplier, clamped so the duck never fully stops.
## The duck reads this each frame: effective_speed = base_speed * speed_multiplier().
func speed_multiplier() -> float:
	var m := 1.0 - weight * WEIGHT_SLOWDOWN + upgrade_speed_bonus
	return maxf(MIN_SPEED_MULT, m)


func _on_food_collected(points: int) -> void:
	if not session_active:
		return
	score += points
	weight += points * MASS_PER_POINT
	Events.emit_score_changed(score)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "high_score", high_score)
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	high_score = int(cfg.get_value("progress", "high_score", 0))
