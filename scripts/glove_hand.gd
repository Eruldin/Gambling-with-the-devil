extends Node3D
## The player's glove — real Quaternius "Glove" mesh (CC0, poly.pizza)
## driven through the same animation API as hand_rig.gd so battle.gd can
## swap between the two without knowing which is wired.

const GLOVE := "res://assets_external/props-occult/glove.glb"

var _busy := false
var _home := Vector3.ZERO
var _model: Node3D
var _fingers: Array = []   # API parity with hand_rig (never populated)

func setup(_skin: Color, _claw: bool) -> void:
	_model = load(GLOVE).instantiate()
	add_child(_model)
	# Quaternius glove: origin at wrist, fingers along -Z, ~0.3m source
	# → scale to a forearm-length silhouette on the felt edge
	_model.scale = Vector3.ONE * 0.8
	_model.rotation = Vector3(0.15, PI, 0.0)   # fingers point onto the table
	# stained black leather — silhouette against the felt
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.045, 0.03, 0.024)
	dm.roughness = 0.8
	for mi: MeshInstance3D in _model.find_children(
			"*", "MeshInstance3D", true, false):
		mi.material_override = dm

## curl parity: the glove has no finger joints — clench reads as a wrist dip.
func set_curl(f: float) -> void:
	_model.rotation.x = 0.15 - 0.35 * clampf(f, 0.0, 1.0)

func home_pos(p: Vector3) -> void:
	_home = p
	position = p

## Fly to `carry`, grip it, carry to `dest`, release, retreat.
func pick_and_place(carry: Node3D, dest: Vector3, dest_rot: Vector3,
		dur := 1.0) -> void:
	if _busy:
		return
	_busy = true
	var grab_pos: Vector3 = carry.global_position + Vector3(0, 0.03, 0.02)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", grab_pos, 0.16 * dur)
	tw.tween_callback(set_curl.bind(0.85))
	tw.tween_property(self, "global_position", dest + Vector3(0, 0.045, 0.01),
		0.34 * dur)
	tw.parallel().tween_property(carry, "global_position", dest, 0.34 * dur)
	tw.parallel().tween_property(carry, "rotation", dest_rot, 0.34 * dur)
	tw.tween_callback(set_curl.bind(0.0))
	tw.tween_property(self, "global_position", _home, 0.28 * dur)
	tw.tween_callback(_release)
	await tw.finished

## Fly to `target`, grab it, drag it down into the darkness (sacrifice).
func grab_and_pull(target: Node3D, away: Vector3, on_done: Callable,
		dur := 1.0) -> void:
	if _busy:
		on_done.call()
		return
	_busy = true
	var grab_pos: Vector3 = target.global_position + Vector3(0, 0.03, 0.02)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "global_position", grab_pos, 0.14 * dur)
	tw.tween_callback(set_curl.bind(0.9))
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(self, "global_position", away, 0.4 * dur)
	tw.parallel().tween_property(target, "global_position",
		away - Vector3(0, 0.05, 0.03), 0.4 * dur)
	tw.tween_callback(on_done)
	tw.tween_property(self, "global_position", _home, 0.3 * dur)
	tw.tween_callback(set_curl.bind(0.0))
	tw.tween_callback(_release)
	await tw.finished

func _release() -> void:
	_busy = false
