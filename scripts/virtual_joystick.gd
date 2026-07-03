class_name VirtualJoystick
extends Control
## Floating on-screen joystick for touch (and mouse, via emulate_touch_from_mouse).
##
## Fills its parent rect. On press the base appears under the finger; dragging
## moves the knob; the direction is the knob offset normalized to [0,1]. The duck
## reads this each frame via the "virtual_joystick" group — no hard coupling.

## Max distance (px) the knob travels from the base; also the full-tilt radius.
@export var max_radius := 120.0
## Fraction of max_radius below which input reads as zero (finger jitter).
@export var deadzone := 0.12

var _active := false
var _finger := -1
var _center := Vector2.ZERO
var _knob := Vector2.ZERO


func _ready() -> void:
	add_to_group("virtual_joystick")
	set_anchors_preset(Control.PRESET_FULL_RECT)


func is_active() -> bool:
	return _active


## Movement direction, magnitude 0..1 (0 inside the deadzone or when idle).
func get_direction() -> Vector2:
	if not _active:
		return Vector2.ZERO
	var off := _knob - _center
	var mag := clampf(off.length() / max_radius, 0.0, 1.0)
	if mag < deadzone:
		return Vector2.ZERO
	return off.normalized() * mag


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _active:
			_active = true
			_finger = event.index
			_center = event.position
			_knob = event.position
			queue_redraw()
			accept_event()
		elif not event.pressed and event.index == _finger:
			_reset()
			accept_event()
	elif event is InputEventScreenDrag and _active and event.index == _finger:
		var off := event.position - _center
		if off.length() > max_radius:
			off = off.normalized() * max_radius
		_knob = _center + off
		queue_redraw()
		accept_event()


func _reset() -> void:
	_active = false
	_finger = -1
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	draw_circle(_center, max_radius, Color(1, 1, 1, 0.10))
	draw_arc(_center, max_radius, 0.0, TAU, 48, Color(1, 1, 1, 0.30), 2.0, true)
	draw_circle(_knob, 36.0, Color(1, 1, 1, 0.35))
