extends Node3D
## Generic gentle sway (chandelier, hanging props). Attach to the node to animate.

@export var amplitude := 0.02
@export var speed := 0.5

var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	rotation.z = amplitude * sin(_t * speed * TAU)
	rotation.x = amplitude * 0.6 * sin(_t * speed * TAU * 0.7 + 0.9)
