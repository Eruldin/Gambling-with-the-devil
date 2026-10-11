extends Node3D
## The Devil: a real textured demon model (CC0 demon sorcerer — ram horns,
## skull face, claws, tattered robe) looming across the table.
## Inscryption-style: warm uplight on the face, glowing eyes, clawed hands
## resting on the felt edge.

const HandRig := preload("res://scripts/hand_rig.gd")
const DEMON := "res://assets_external/devil-model/winged_demon_wraith.glb"

var _eye_mat: StandardMaterial3D
var _halo_mat: StandardMaterial3D
var _torso: Node3D          # pivot at the hips — lean/breath act on it
var _model: Node3D
var _head: Node3D           # eye/halo anchor at skull height
var _eyes: Array[MeshInstance3D] = []
var _halos: Array[MeshInstance3D] = []
var _rest_head := Vector3.ZERO
var _rest_lean := 0.0
var _hand_r: Node3D
var _hand_l: Node3D
var _t := 0.0
var _flare := 0.0
var _twitch_in := 5.0 + randf() * 6.0
var _twitch := 0.0
var _drum_in := 8.0 + randf() * 8.0
var _blink_in := 3.0 + randf() * 4.0
var _blink := 0.0
var _cam: Camera3D

## seat_z: z of the far chair; top: table surface height.
func build(top: float, seat_z := -1.10) -> void:
	# real model: ~2.0m tall, faces +Z (toward the player — correct as-is).
	# seated: waist dropped to chair-seat height, torso pitched forward
	# over the felt edge — Inscryption's hunched opponent silhouette.
	_torso = Node3D.new()
	_torso.position = Vector3(0, 0.34, seat_z)
	_torso.rotation.x = 0.18
	add_child(_torso)
	_model = load(DEMON).instantiate()
	var s := 0.62
	_model.scale = Vector3.ONE * s
	_model.position.y = -0.42       # waist at pivot → lean bends torso
	_torso.add_child(_model)
	# skeletal animation — the body actually moves, not just node sways
	var aps := _model.find_children("*", "AnimationPlayer", true, false)
	var ap: AnimationPlayer = null if aps.is_empty() else aps[0]
	if ap != null:
		var anims := ap.get_animation_list()
		print("DEVIL anims:", anims)
		var pick := anims[0]
		for a in anims:
			var n := String(a).to_lower()
			if "idle" in n or "fly" in n or "float" in n or "hover" in n:
				pick = a
				break
		var anim := ap.get_animation(pick)
		if anim != null:
			anim.loop_mode = Animation.LOOP_LINEAR
		ap.play(pick)
	# eye anchor: skull face height ≈ 1.72m * s above feet → ~0.77 over pivot
	_head = Node3D.new()
	_head.position = Vector3(0, 0.66, 0.16)
	_rest_head = _head.position
	_torso.add_child(_head)
	# glowing eyes — orbs + additive flare halo quads behind them
	_eye_mat = StandardMaterial3D.new()
	_eye_mat.albedo_color = Color(1.0, 0.3, 0.06)
	_eye_mat.emission_enabled = true
	_eye_mat.emission = Color(1.0, 0.28, 0.05)
	_eye_mat.emission_energy_multiplier = 8.0
	_eye_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	_halo_mat = StandardMaterial3D.new()
	_halo_mat.albedo_texture = load(
		"res://assets_external/anim-vfx/kenney/particle-pack/PNG (Transparent)/flare_01.png")
	_halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_halo_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_halo_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	_halo_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	for side in [-1.0, 1.0]:
		var h := MeshInstance3D.new()
		var hq := QuadMesh.new()
		hq.size = Vector2(0.085, 0.085)
		h.mesh = hq
		h.material_override = _halo_mat
		h.position = Vector3(0.031 * side, 0.005, 0.08)
		_head.add_child(h)
		_halos.append(h)
		var e := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.019
		es.height = 0.038
		es.radial_segments = 12
		e.mesh = es
		e.material_override = _eye_mat
		e.position = Vector3(0.031 * side, 0.005, 0.085)
		_head.add_child(e)
		_eyes.append(e)
	# faint red uplight so the textured face is *just* readable
	var face := SpotLight3D.new()
	face.position = Vector3(0, 0.5, seat_z + 0.55)
	add_child(face)
	face.look_at(Vector3(0, 1.05, seat_z + 0.15), Vector3.UP)
	face.light_color = Color(0.9, 0.2, 0.08)
	face.light_energy = 0.34
	face.spot_angle = 30.0
	face.spot_attenuation = 1.2
	# the wraith's glowing chest throws faint magenta light onto the table
	var chest := OmniLight3D.new()
	chest.position = Vector3(0, 0.75, seat_z + 0.35)
	add_child(chest)
	chest.light_color = Color(0.75, 0.12, 0.42)
	chest.light_energy = 0.22
	chest.omni_range = 1.6
	chest.omni_attenuation = 2.0
	# clawed hands resting on the felt edge (kept: they reach mid-table)
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

func _process(delta: float) -> void:
	_t += delta
	# breathing + slow whole-body sway so he never reads as a statue
	if _torso:
		_torso.scale.y = 1.0 + 0.014 * sin(_t * 1.1)
		_torso.rotation.z = 0.018 * sin(_t * 0.42)
		_torso.rotation.y = 0.03 * sin(_t * 0.17)
	# head: watches the cursor (the opponent *sees* you) + creepy twitch
	if _head:
		var track := 0.0
		if _cam != null:
			var m := get_viewport().get_mouse_position()
			var p: Vector3 = _cam.project_position(m, 2.2)
			var d := _head.global_transform.affine_inverse() * p
			track = clampf(atan2(d.x, d.z), -0.45, 0.45) * 0.6
		_twitch_in -= delta
		if _twitch_in <= 0.0:
			_twitch = 0.5
			_twitch_in = 6.0 + randf() * 9.0
		_twitch = maxf(0.0, _twitch - delta)
		var snap := 0.0
		if _twitch > 0.35:
			snap = 0.22 * (1.0 if randi() % 2 == 0 else -1.0)
		_head.rotation.y = lerpf(_head.rotation.y,
			track + 0.05 * sin(_t * 0.23) + snap, delta * 5.0)
		_head.rotation.z = lerpf(_head.rotation.z,
			0.05 * sin(_t * 0.31), delta * 3.0)
	# blinking — eyes shut for a beat every few seconds
	_blink_in -= delta
	if _blink_in <= 0.0:
		_blink = 0.22
		_blink_in = 2.5 + randf() * 5.0
	_blink = maxf(0.0, _blink - delta)
	var lid := 1.0
	if _blink > 0.0:
		lid = 0.08
	for e in _eyes:
		e.scale.y = lerpf(e.scale.y, lid, delta * 40.0)
	var lid_dim := _eyes[0].scale.y if not _eyes.is_empty() else 1.0
	# eye flicker + flare (orbs glow, halos breathe)
	_flare = maxf(0.0, _flare - delta * 1.6)
	var glow := (4.2 + _flare * 9.0 + 0.9 * sin(_t * 9.3) + 0.5 * sin(_t * 17.7)) * lid_dim
	_eye_mat.emission_energy_multiplier = glow
	var hs := 0.085 * (0.7 + 0.22 * sin(_t * 2.9) + _flare * 1.6)
	for h in _halos:
		var q: QuadMesh = h.mesh
		q.size = Vector2(hs, hs)
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
