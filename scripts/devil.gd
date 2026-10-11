extends Node3D
## The Devil: a real textured demon model (CC0 demon sorcerer — ram horns,
## skull face, claws, tattered robe) looming across the table.
## Inscryption-style: warm uplight on the face, glowing eyes, clawed hands
## resting on the felt edge.

const HandRig := preload("res://scripts/hand_rig.gd")
const DEMON := "res://assets_external/devil-model/hooded_inquisitor.glb"

var _torso: Node3D          # pivot at the hips — lean/breath act on it
var _model: Node3D
var _head: Node3D           # gaze anchor at skull height (no eye meshes)
var _face_light: SpotLight3D
var _hood_light: OmniLight3D
var _face_base := 2.3
var _hood_base := 1.6
var _rest_head := Vector3.ZERO
var _rest_lean := 0.0
var _hand_r: Node3D
var _hand_l: Node3D
var _t := 0.0
var _flare := 0.0
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
		ap.speed_scale = 0.55   # slowed for weight — a devil never hurries
	# gaze anchor — inside the cowl; head turns only for game events
	_head = Node3D.new()
	_head.position = Vector3(0, 0.53, 0.13)
	_rest_head = _head.position
	_torso.add_child(_head)
	# NO glowing eye orbs — his real face texture reads in the hood light.
	# "Eye flare" is the face light surging, not dots floating off the face.
	var face := SpotLight3D.new()
	face.position = Vector3(0, 0.42, seat_z + 0.5)
	add_child(face)
	face.look_at(Vector3(0, 0.66, seat_z + 0.15), Vector3.UP)
	# warm candle tone — the pale inquisitor face must actually read
	# out of the cowl dark (a red light on a dark face reads as void)
	face.light_color = Color(1.0, 0.58, 0.3)
	face.light_energy = _face_base
	face.spot_angle = 34.0
	face.spot_attenuation = 1.4
	_face_light = face
	# tiny warm orb inside the hood — the pale face glows out of the dark
	var hood := OmniLight3D.new()
	hood.position = Vector3(0, 0.7, seat_z + 0.34)
	add_child(hood)
	hood.light_color = Color(1.0, 0.6, 0.34)
	hood.light_energy = _hood_base
	hood.omni_range = 0.6
	hood.omni_attenuation = 1.8
	_hood_light = hood
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
	# breathing only — no sway noise, no random twitch. Stillness with weight.
	if _torso:
		_torso.scale.y = 1.0 + 0.014 * sin(_t * 1.1)
	# head: turns ONLY for game events (_gaze). At rest he faces the
	# player dead-on — a stare, not a wandering head.
	if _head:
		_gaze_t = maxf(0.0, _gaze_t - delta)
		var target_y := 0.0
		var speed := 1.6
		if _gaze_t > 0.0 and _gaze.is_finite():
			var d: Vector3 = _head.global_transform.affine_inverse() * _gaze
			if d.is_finite():
				target_y = clampf(atan2(d.x, d.z), -0.5, 0.5)
				speed = 2.4
		_head.rotation.y = lerpf(_head.rotation.y, target_y,
			minf(delta * speed, 1.0))
		# mood still reads: at high blinds his stare hardens a touch
		_head.rotation.x = lerpf(_head.rotation.x,
			0.02 * _mood, minf(delta * 1.2, 1.0))
	# blinking lives in the hood light now — a brief dip of the face
	# glow, like a flicker crossing his eyes (no eye meshes to scale)
	_blink_in -= delta
	if _blink_in <= 0.0:
		_blink = 0.16
		_blink_in = (3.5 + randf() * 6.0) * (1.0 + 0.5 * _mood)
	_blink = maxf(0.0, _blink - delta)
	var lid_dim := 1.0
	if _blink > 0.0:
		lid_dim = 0.55
	# face-light flare — events surge the hood glow, then it settles
	_flare = maxf(0.0, _flare - delta * 1.6)
	var flick := 1.0 + 0.05 * sin(_t * 9.3) + 0.03 * sin(_t * 17.7)
	if _face_light:
		_face_light.light_energy = (_face_base + _flare * 1.6) * flick * lid_dim
	if _hood_light:
		_hood_light.light_energy = (_hood_base + _flare * 1.2) * lid_dim
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
## A dark card flying through the dark reads as nothing — the card
## carries its own ember light for the flight so the arc is visible.
func play_card(card: Node3D, dest: Vector3, dest_rot: Vector3) -> void:
	eyes_flare(0.5)
	watch(dest, 2.0)
	strike_pose(dest.x, false)
	# ember light riding the card — dies when the card lands
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.45, 0.15)
	glow.light_energy = 1.4
	glow.omni_range = 0.35
	glow.omni_attenuation = 1.2
	card.add_child(glow)
	glow.position = Vector3(0, 0.03, 0)
	var from := card.global_position
	var mid := from.lerp(dest, 0.5) + Vector3(0, 0.16, 0)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "global_position", mid, 0.28)
	tw.parallel().tween_property(card, "rotation", dest_rot + Vector3(0.25, 0.5, 0), 0.28)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(card, "global_position", dest + Vector3(0, 0.002, 0), 0.16)
	tw.parallel().tween_property(card, "rotation", dest_rot, 0.16)
	await tw.finished
	# ember dies with a soft fade instead of a pop
	var dt := create_tween()
	dt.tween_property(glow, "light_energy", 0.0, 0.4)
	dt.tween_callback(glow.queue_free)
