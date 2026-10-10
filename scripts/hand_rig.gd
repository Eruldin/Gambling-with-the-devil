extends Node3D
## A creepy articulated hand: palm + thumb + 4 two-segment fingers.
## Used for the player's glove AND the Devil's claws on the table.

var _palm: MeshInstance3D
var _fingers: Array = []   # [{root, j1, j2}]
var _thumb: Dictionary = {}
var _mat: StandardMaterial3D

## Reach animation state.
var _home := Vector3.ZERO
var _busy := false

func setup(skin: Color, claw: bool) -> void:
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = skin
	_mat.roughness = 0.9
	_mat.metallic = 0.0
	_palm = MeshInstance3D.new()
	var pm := SphereMesh.new()
	pm.radius = 0.030
	pm.height = 0.060
	pm.radial_segments = 20
	pm.rings = 12
	_palm.mesh = pm
	_palm.scale = Vector3(0.9, 0.55, 1.5)
	_palm.material_override = _mat
	add_child(_palm)
	# four fingers along the front edge of the palm
	var xs := [-0.020, -0.007, 0.006, 0.019]
	for i in range(4):
		var f := _make_finger(Vector3(xs[i], 0.002, -0.036),
			0.026 - abs(i - 1) * 0.002, 0.021, claw)
		_fingers.append(f)
	# thumb on the left side, angled outward
	_thumb = _make_finger(Vector3(-0.026, -0.002, -0.008),
		0.020, 0.016, claw)
	_thumb.root.rotation.y = 0.7

func _make_finger(pos: Vector3, l1: float, l2: float, claw: bool) -> Dictionary:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var j1 := MeshInstance3D.new()
	var c1 := CapsuleMesh.new()
	c1.radius = 0.0065
	c1.height = l1
	c1.radial_segments = 10
	j1.mesh = c1
	j1.rotation.x = PI / 2.0          # lie flat, pointing -z (forward)
	j1.position = Vector3(0, 0, -l1 * 0.5)
	j1.material_override = _mat
	root.add_child(j1)
	var j2root := Node3D.new()
	j2root.position = Vector3(0, 0, -l1)
	root.add_child(j2root)
	var j2 := MeshInstance3D.new()
	var c2 := CapsuleMesh.new()
	c2.radius = 0.0055
	c2.height = l2
	c2.radial_segments = 10
	j2.mesh = c2
	j2.rotation.x = PI / 2.0
	j2.position = Vector3(0, 0, -l2 * 0.5)
	j2.material_override = _mat
	j2root.add_child(j2)
	if claw:
		var tip := MeshInstance3D.new()
		var cn := CylinderMesh.new()
		cn.top_radius = 0.001
		cn.bottom_radius = 0.0045
		cn.height = 0.016
		tip.mesh = cn
		tip.rotation.x = -PI / 2.0
		tip.position = Vector3(0, -0.001, -l2 - 0.007)
		tip.material_override = _mat
		j2root.add_child(tip)
	return {"root": root, "joint": j2root}

## curl: 0 = flat / open, 1 = full grip.
func set_curl(f: float) -> void:
	f = clampf(f, 0.0, 1.0)
	for d in _fingers:
		d.root.rotation.x = -0.35 * f
		d.joint.rotation.x = -0.85 * f
	_thumb.root.rotation.x = -0.55 * f
	_thumb.joint.rotation.x = -0.6 * f

func home_pos(p: Vector3) -> void:
	_home = p
	position = p

## Fly to `from`, grip, carry `carry` (Node3D) to `dest`, release, retreat.
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

## Fly to `target`, grab it, and drag it down into the darkness below the
## table edge (sacrifice). `on_done` frees the card afterwards.
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

## Devil variant: slide a concealed card onto a lane pad from the darkness.
func hand_play(card: Node3D, dest: Vector3, dest_rot: Vector3) -> void:
	if _busy:
		card.global_position = dest
		card.rotation = dest_rot
		return
	_busy = true
	set_curl(0.7)
	card.global_position = global_position + Vector3(0, -0.01, -0.06)
	card.rotation = Vector3(0, 0, 0)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position",
		dest + Vector3(0, 0.05, 0.03), 0.5)
	tw.parallel().tween_property(card, "global_position", dest, 0.5)
	tw.parallel().tween_property(card, "rotation", dest_rot, 0.5)
	tw.tween_callback(set_curl.bind(0.0))
	tw.tween_property(self, "global_position", _home, 0.45)
	tw.tween_callback(_release)
	await tw.finished

func _release() -> void:
	_busy = false
