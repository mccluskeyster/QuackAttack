extends Node
## Global signal bus.
##
## Decouples systems: emitters call `Events.emit_signal(...)` (or the typed
## `emit_*` helpers) and listeners connect without holding direct references.
## Registered as the `Events` autoload (see project.godot).

## A piece of food was collected by the duck. `points` is its score value.
signal food_collected(points: int)

## A play session started (fresh round).
signal session_started

## A play session ended (e.g. timer ran out). `final_score` is the round total.
signal session_ended(final_score: int)

## The running score changed. `score` is the new total.
signal score_changed(score: int)


func emit_food_collected(points: int) -> void:
	food_collected.emit(points)


func emit_session_started() -> void:
	session_started.emit()


func emit_session_ended(final_score: int) -> void:
	session_ended.emit(final_score)


func emit_score_changed(score: int) -> void:
	score_changed.emit(score)
