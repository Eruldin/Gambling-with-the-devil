extends Node3D
## The Devil: a mostly-silhouette figure hunched across the table —
## horned skull, glowing eyes, clawed hands resting on the felt edge.
## Inscryption-style: you see shape and eyes, not detail.

const HandRig := preload("res://scripts/hand_rig.gd")

var _mat: StandardMaterial3D
var _eye_mat: StandardMaterial3D
var _torso: Node3D
var _head: Node3D
var _eyes: Array[MeshInstance3D] = []
var _rest_head := Vector3.ZERO
var _rest_lean := 0.0
var _hand_r: Node3D
var _hand_l: Node3D
var _t := 0.0
var _flare := 0.0
var _twitch_in := 5.0 + randf() * 6.0
var _twitch := 0.0
var _drum_in := 8.0 + randf() * 8.0

## seat_z: z of the far chair; top: table surface height.
func build(top: float, seat_z := -1.18) -> void:
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.016, 0.011, 0.010)
	_mat.roughness = 0.98
	_mat.metallic = 0.0
	# silhouette torso: hunched capsule + shoulder mass, looming over the felt
	_torso = Node3D.new()
	_torso.position = Vector3(0, 0, seat_z + 0.08)
	_torso.rotation.x = 0.22
	add_child(_torso)
	var chest := _mi(_capsule(0.13, 0.4), Vector3(0, 0.52, 0),
		Vector3(1.0, 0.9, 0.62), Vector3(0.24, 0, 0))
	_torso.add_child(chest)
	var shoulders := _mi(_sphere(0.1),
		Vector3(0, 0.68, 0.03), Vector3(1.7, 0.45, 0.6))
	_torso.add_child(shoulders)
	# thin neck so the head reads as its own silhouette
	_torso.add_child(_mi(_capsule(0.035, 0.14),
		Vector3(0, 0.82, 0.10), Vector3(1, 1, 1), Vector3(0.35, 0, 0)))
	# head: elongated skull + jaw + back-swept horns + brow ridge
	_head = Node3D.new()
	_head.position = Vector3(0, 0.98, 0.17)
	_rest_head = _head.position
	_torso.add_child(_head)
	_head.add_child(_mi(_sphere(0.085),
		Vector3(0, 0.02, 0.02), Vector3(0.92, 1.12, 1.0)))
	_head.add_child(_mi(_box(0.085, 0.045, 0.09),
		Vector3(0, -0.035, 0.055), Vector3(1, 1, 1)))
	_head.add_child(_mi(_box(0.15, 0.025, 0.03),
		Vector3(0, 0.045, 0.075), Vector3(1, 1, 1)))
	for side in [-1.0, 1.0]:
		var horn := _mi(_cone(0.020, 0.17),
			Vector3(0.055 * side, 0.10, 0.0), Vector3(1, 1, 1),
			Vector3(-0.62, 0, 0.42 * side))
		_head.add_child(horn)
		var horn2 := _mi(_cone(0.013, 0.10),
			Vector3(0.085 * side, 0.13, -0.03), Vector3(1, 1, 1),
			Vector3(-1.05, 0, 0.55 * side))
		_head.add_child(horn2)
		# ears: thin spikes, kept close to the skull
		_head.add_child(_mi(_cone(0.008, 0.05),
			Vector3(0.088 * side, 0.005, 0.0), Vector3(1, 1, 1),
			Vector3(0, 0, 1.5 * side)))
	# glowing eyes
	_eye_mat = StandardMaterial3D.new()
	_eye_mat.albedo_color = Color(1.0, 0.3, 0.06)
	_eye_mat.emission_enabled = true
	_eye_mat.emission = Color(1.0, 0.28, 0.05)
	_eye_mat.emission_energy_multiplier = 8.0
	_eye_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	for side in [-1.0, 1.0]:
		var e := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.019
		es.height = 0.038
		es.radial_segments = 12
		e.mesh = es
		e.material_override = _eye_mat
		e.position = Vector3(0.036 * side, 0.030, 0.11)
		_head.add_child(e)
		_eyes.append(e)
	# faint red uplight so the face is *just* readable
	var face := SpotLight3D.new()
	face.position = Vector3(0, 0.52, seat_z + 0.55)
	add_child(face)
	face.look_at(Vector3(0, 1.12, seat_z + 0.2), Vector3.UP)
	face.light_color = Color(0.9, 0.2, 0.08)
	face.light_energy = 0.4
	face.spot_angle = 26.0
	face.spot_attenuation = 1.2
	# clawed hands resting on the felt edge, fingers reaching mid-table,
	# with forearm stubs trailing back into the dark
	for side in [-1.0, 1.0]:
		var arm := _mi(_capsule(0.035, 0.55),
			Vector3(0.26 * side, top + 0.05, seat_z + 0.52),
			Vector3(1, 1, 1), Vector3(PI / 2.0 - 0.3, 0.1 * side, 0.06 * side))
		add_child(arm)
	_hand_r = HandRig.new()
	add_child(_hand_r)
	_hand_r.setup(Color(0.02, 0.013, 0.011), true)
	_hand_r.home_pos(Vector3(-0.25, top + 0.028, seat_z + 0.74))
	_hand_r.rotation = Vector3(-0.12, PI - 0.45, -0.08)
	_hand_l = HandRig.new()
	add_child(_hand_l)
	_hand_l.setup(Color(0.02, 0.013, 0.011), true)
	_hand_l.home_pos(Vector3(0.27, top + 0.028, seat_z + 0.72))
	_hand_l.rotation = Vector3(-0.12, PI + 0.45, 0.08)
	_hand_l.scale = Vector3(-1, 1, 1)  # mirrored

func _mi(mesh: Mesh, pos: Vector3, scale: Vector3,
		rot := Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = pos
	m.scale = scale
	m.rotation = rot
	m.material_override = _mat
	return m

func _capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 20
	return c

func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 20
	return s

func _box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b

func _cone(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = 0.001
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 12
	return c

func _process(delta: float) -> void:
	_t += delta
	# breathing
	if _torso:
		_torso.scale.y = 1.0 + 0.012 * sin(_t * 1.1)
	# slow head drift + rare creepy twitch
	if _head:
		_twitch_in -= delta
		if _twitch_in <= 0.0:
			_twitch = 0.5
			_twitch_in = 6.0 + randf() * 9.0
		_twitch = maxf(0.0, _twitch - delta)
		var snap := 0.0
		if _twitch > 0.35:
			snap = 0.22 * (1.0 if randi() % 2 == 0 else -1.0)
		_head.rotation.y = lerpf(_head.rotation.y,
			0.06 * sin(_t * 0.23) + snap, delta * 6.0)
		_head.rotation.z = lerpf(_head.rotation.z,
			0.05 * sin(_t * 0.31), delta * 3.0)
	# eye flicker + flare
	_flare = maxf(0.0, _flare - delta * 1.6)
	_eye_mat.emission_energy_multiplier = 4.2 + _flare * 9.0 \
		+ 0.9 * sin(_t * 9.3) + 0.5 * sin(_t * 17.7)
	# occasional finger drum on the felt
	_drum_in -= delta
	if _drum_in <= 0.0:
		_drum_in = 9.0 + randf() * 10.0
		_drum()

func _drum() -> void:
	var f: Array = _hand_r._fingers
	for i in range(f.size()):
		var root: Node3D = f[i].root
		var tw := create_tween()
		tw.tween_interval(i * 0.07)
		tw.tween_property(root, "rotation:x", -0.3, 0.07)
		tw.tween_property(root, "rotation:x", 0.0, 0.1)

## Eyes flare — call on reveal, player damage, devil victory.
func eyes_flare(strength := 1.0) -> void:
	_flare = clampf(_flare + strength, 0.0, 2.0)

## Lean toward the player (threat / triumph).
func lean_in(amount := 0.4, dur := 0.6) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_torso, "rotation:x", amount, dur)
	tw.tween_property(_torso, "rotation:x", _rest_lean, dur * 1.4)

## Devil's right claw slides a concealed card onto a lane.
func play_card(card: Node3D, dest: Vector3, dest_rot: Vector3) -> void:
	eyes_flare(0.5)
	await _hand_r.hand_play(card, dest, dest_rot)
