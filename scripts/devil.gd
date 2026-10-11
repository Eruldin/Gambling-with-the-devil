extends Node3D
## The Devil: a real textured demon model (CC0 demon sorcerer — ram horns,
## skull face, claws, tattered robe) looming across the table.
## Inscryption-style: warm uplight on the face, glowing eyes, clawed hands
## resting on the felt edge.

const HandRig := preload("res://scripts/hand_rig.gd")
const DEMON := "res://assets_external/devil-model/hooded_inquisitor.glb"

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
# game-driven attention: when set, the head locks onto this world point
# (played lanes, struck chips, the scale) instead of idly tracking the cursor
var _gaze := Vector3.ZERO
var _gaze_t := 0.0
var _mood := 0            # 0 calm · 1 tense (mid blinds) · 2 furious (deep blinds)
var _sfx_ref = null       # set by battle — growls/breath live on his thread
const BREATH := "res://assets_external/audio/gwd/breath.wav"

func _model_aabb(root: Node3D) -> AABB:
	var inv := root.global_transform.affine_inverse()
	var out := AABB()
	var first := true
	var stack: Array = [root]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		if c is MeshInstance3D:
			var a: AABB = (inv * c.global_transform) * c.get_aabb()
			out = a if first else out.merge(a)
			first = false
		for ch in c.get_children():
			stack.push_back(ch)
	return out

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
	_torso.add_child(_model)
	# NOTE: skinned-mesh aabb reports bind-space (tiny) — size is hand-tuned
	# for this asset: ~2m source → 0.45 ≈ looming seated silhouette
	var s := 0.45
	_model.scale = Vector3.ONE * s
	_model.position.y = -0.36
	_model.rotation.x = -0.07   # chin up — face catches the hood light       # waist at pivot → lean bends torso
	# the inquisitor's white cape lining pops in candlelight — darken any
	# bright surface materials while keeping their textures
	for mi: MeshInstance3D in _model.find_children(
			"*", "MeshInstance3D", true, false):
		var mesh := mi.mesh
		if mesh == null:
			continue
		for si in range(mesh.get_surface_count()):
			var om := mesh.surface_get_material(si)
			if om is StandardMaterial3D and \
					om.albedo_color.get_luminance() > 0.62:
				var dm := StandardMaterial3D.new()
				dm.albedo_texture = om.albedo_texture
				dm.albedo_color = om.albedo_color * Color(0.3, 0.24, 0.24)
				dm.roughness = 0.92
				mi.set_surface_override_material(si, dm)
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
	# eye anchor — hood brow ~0.62 torso-local on the 0.32-scale model
	_head = Node3D.new()
	_head.position = Vector3(0, 0.31, 0.1)
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
		h.position = Vector3(0.027 * side, 0.0, 0.07)
		_head.add_child(h)
		_halos.append(h)
		var e := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.014
		es.height = 0.028
		es.radial_segments = 12
		e.mesh = es
		e.material_override = _eye_mat
		e.position = Vector3(0.027 * side, 0.0, 0.075)
		_head.add_child(e)
		_eyes.append(e)
	# faint red uplight so the textured face is *just* readable
	var face := SpotLight3D.new()
	face.position = Vector3(0, 0.42, seat_z + 0.5)
	add_child(face)
	face.look_at(Vector3(0, 0.66, seat_z + 0.15), Vector3.UP)
	face.light_color = Color(0.9, 0.2, 0.08)
	face.light_energy = 0.85
	face.spot_angle = 36.0
	face.spot_attenuation = 1.2
	# tiny warm orb inside the hood — the pale face glows out of the dark
	var hood := OmniLight3D.new()
	hood.position = Vector3(0, 0.7, seat_z + 0.34)
	add_child(hood)
	hood.light_color = Color(1.0, 0.55, 0.3)
	hood.light_energy = 0.8
	hood.omni_range = 0.55
	hood.omni_attenuation = 1.8
	# faint cold rim light so the robed silhouette reads against the dark
	var chest := OmniLight3D.new()
	chest.position = Vector3(0, 0.85, seat_z - 0.15)
	add_child(chest)
	chest.light_color = Color(0.3, 0.42, 0.5)
	chest.light_energy = 0.16
	chest.omni_range = 1.4
	chest.omni_attenuation = 2.0
	# old primitive claws hidden — the inquisitor's presence carries the scene;
	# the nodes stay (invisible) because their tweens still carry played cards
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
	_hand_r.visible = false
	_hand_l.visible = false

func _process(delta: float) -> void:
	_t += delta
	# breathing + slow whole-body sway so he never reads as a statue
	if _torso:
		_torso.scale.y = 1.0 + 0.014 * sin(_t * 1.1)
		_torso.rotation.z = 0.018 * sin(_t * 0.42)
		_torso.rotation.y = 0.03 * sin(_t * 0.17)
	# head: locks onto game events (_gaze), else stalks the cursor
	if _head:
		var track := 0.0
		_gaze_t = maxf(0.0, _gaze_t - delta)
		var d: Vector3
		var has_d := false
		if _gaze_t > 0.0 and _gaze.is_finite():
			d = _head.global_transform.affine_inverse() * _gaze
			has_d = true
		elif _cam != null:
			var m := get_viewport().get_mouse_position()
			var p: Vector3 = _cam.project_position(m, 2.2)
			d = _head.global_transform.affine_inverse() * p
			has_d = true
		if has_d and d.is_finite():
			track = clampf(atan2(d.x, d.z), -0.55, 0.55) * 0.9
		_twitch_in -= delta * (1.0 + 0.6 * _mood)
		if _twitch_in <= 0.0:
			_twitch = 0.5
			_twitch_in = 6.0 + randf() * 9.0
		_twitch = maxf(0.0, _twitch - delta)
		var snap := 0.0
		if _twitch > 0.35:
			snap = 0.22 * (1.0 if randi() % 2 == 0 else -1.0)
		var target_y := track + 0.05 * sin(_t * 0.23) + snap
		_head.rotation.y = lerpf(_head.rotation.y,
			target_y, minf(delta * 5.0, 1.0))
		_head.rotation.z = lerpf(_head.rotation.z,
			0.05 * sin(_t * 0.31), minf(delta * 3.0, 1.0))
	# blinking — rarer when he's locked in (higher blinds → longer stares)
	_blink_in -= delta
	if _blink_in <= 0.0:
		_blink = 0.22
		_blink_in = (2.5 + randf() * 5.0) * (1.0 + 0.5 * _mood)
	_blink = maxf(0.0, _blink - delta)
	var lid := 1.0
	if _blink > 0.0:
		lid = 0.08
	for e in _eyes:
		# clamp the lerp weight — a delta hitch otherwise overshoots scale
		# negative, then blows up to inf/NaN inside a few frames
		e.scale.y = lerpf(e.scale.y, lid, minf(delta * 40.0, 1.0))
	var lid_dim := _eyes[0].scale.y if not _eyes.is_empty() else 1.0
	# eye flicker + flare (orbs glow, halos breathe)
	_flare = maxf(0.0, _flare - delta * 1.6)
	var glow := (4.2 + _flare * 9.0 + 0.9 * sin(_t * 9.3) + 0.5 * sin(_t * 17.7)) * lid_dim
	_eye_mat.emission_energy_multiplier = glow
	var hs := 0.085 * (0.7 + 0.22 * sin(_t * 2.9) + _flare * 1.6)
	for h in _halos:
		var q: QuadMesh = h.mesh
		q.size = Vector2(hs, hs)
	# occasional finger drum — faster when the stakes climb
	_drum_in -= delta * (1.0 + 0.5 * _mood)
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

## Lock the head onto a world point for `secs` (played lane, chip hit,
## the scale tipping). This is what kills the "random" feel — every
## glance now has a reason.
func watch(pos: Vector3, secs := 2.2) -> void:
	_gaze = pos
	_gaze_t = secs

## Thinking beat before he commits: reads your row, breathes, then plays.
func think(player_felt: Vector3) -> void:
	watch(player_felt, 2.0)
	lean_in(0.24, 0.5)
	_drum()
	if _sfx_ref != null:
		_sfx_ref.play(BREATH, -12.0, randf_range(0.8, 0.95))
	await get_tree().create_timer(0.85).timeout

## He notices every sacrifice — a small feeding reaction.
func feed(pos: Vector3) -> void:
	eyes_flare(0.45)
	watch(pos + Vector3(0, 0.05, 0), 1.6)
	lean_in(0.18, 0.4)

## Snap a glance + shoulder lean toward a lane that just connected.
func strike_pose(lane_x: float, hit_him := true) -> void:
	eyes_flare(0.4 if hit_him else 0.25)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_torso, "rotation:y",
		clampf(lane_x, -0.3, 0.3) * (0.7 if hit_him else -0.7), 0.18)
	tw.tween_property(_torso, "rotation:y", 0.0, 0.6)

## Blinds climb → agitation: twitchier, stares longer, drums faster.
func set_mood(round_no: int) -> void:
	_mood = 0 if round_no < 3 else (1 if round_no < 5 else 2)

func victory() -> void:
	eyes_flare(2.2)
	lean_in(0.6, 1.0)

func defeat() -> void:
	_flare = 0.0
	# slump back into the chair — shoulders drop, light dies
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_torso, "rotation:x", -0.06, 1.1)
	tw.tween_property(_torso, "position:y", _torso.position.y - 0.02, 1.1)

## Devil's reach: the concealed card arcs out of the dark onto the lane.
func play_card(card: Node3D, dest: Vector3, dest_rot: Vector3) -> void:
	eyes_flare(0.5)
	watch(dest, 2.0)
	strike_pose(dest.x, false)
	# lift from his side, arc, slam — reads as a thrown placement
	var from := card.global_position
	var mid := from.lerp(dest, 0.5) + Vector3(0, 0.16, 0)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "global_position", mid, 0.28)
	tw.parallel().tween_property(card, "rotation", dest_rot + Vector3(0.25, 0.5, 0), 0.28)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(card, "global_position", dest + Vector3(0, 0.002, 0), 0.16)
	tw.parallel().tween_property(card, "rotation", dest_rot, 0.16)
	await tw.finished
