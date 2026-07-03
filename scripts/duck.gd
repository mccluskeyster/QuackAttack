class_name Duck
extends CharacterBody2D
## The player duck. Flies top-down; movement speed is scaled by
## GameState.speed_multiplier() (fatter = slower, upgrades = faster).
##
## Input: virtual joystick on touch, arrow/WASD (ui_* actions) as an in-editor
## fallback. Space triggers an offload while playtesting on desktop; the mobile
## HUD offload button (M3) calls GameState.offload() directly.

## Top speed (px/sec) at zero weight and no upgrade. Actual speed is this times
## GameState.speed_multiplier().
@export var base_speed := 340.0
## Higher = snappier acceleration toward the target velocity.
@export var accel_response := 12.0
## Higher = faster turn of the visual toward the heading.
@export var turn_response := 12.0
## Speed (px/sec) below which the duck counts as not flying (metabolism pauses).
@export var flying_threshold := 8.0

@onready var _visual: Node2D = $Visual

var _joystick: VirtualJoystick
var _facing := Vector2.RIGHT


func _ready() -> void:
	_joystick = get_tree().get_first_node_in_group("virtual_joystick") as VirtualJoystick


func _physics_process(delta: float) -> void:
	var dir := _input_dir()
	var target := dir * base_speed * GameState.speed_multiplier()
	velocity = velocity.lerp(target, 1.0 - exp(-accel_response * delta))
	move_and_slide()

	GameState.is_flying = velocity.length() > flying_threshold

	if dir != Vector2.ZERO:
		_facing = dir
	_visual.rotation = lerp_angle(_visual.rotation, _facing.angle(), 1.0 - exp(-turn_response * delta))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		GameState.offload()


## Joystick first (touch), keyboard ui_* as fallback. Magnitude clamped to 1.
## The joystick is looked up lazily so sibling _ready() order can't leave it null.
func _input_dir() -> Vector2:
	if _joystick == null:
		_joystick = get_tree().get_first_node_in_group("virtual_joystick") as VirtualJoystick
	if _joystick and _joystick.is_active():
		return _joystick.get_direction()
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
