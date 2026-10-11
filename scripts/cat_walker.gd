extends Node3D
## The house cat: crosses the lit edge of the room every so often.
## CC0 Grab3D tabby — real fur textures, tinted down into the dark.

const CAT := "res://assets_external/props-occult/cat_real.glb"

var _model: Node3D
var _next := 12.0 + randf() * 18.0 if \
	OS.get_environment("GWD_CATNOW") != "1" else 0.5
var _walking := false
var _t := 0.0
var _ap: AnimationPlayer
var _walk_clip := ""
var _idle_clip := ""
var _top := 0.85

func build(top: float = 0.85) -> void:
	_top = top
	_model = load(CAT).instantiate()
	# Grab3D tabby is authored at real-world size — slight shrink keeps
	# it a house cat, not a lynx, against the table's scale
	_model.scale = Vector3.ONE * 0.55
	add_child(_model)
	# keep the model's own fur textures — tint the albedo multiplier only,
	# so it settles into the room's dark without flattening
	for mi: MeshInstance3D in _model.find_children(
			"*", "MeshInstance3D", true, false):
		for si in range(mi.get_surface_override_material_count()):
			var src := mi.get_surface_override_material(si)
			if src is StandardMaterial3D:
				var dup: StandardMaterial3D = src.duplicate()
				dup.albedo_color *= Color(0.5, 0.42, 0.36)
				dup.roughness = minf(dup.roughness + 0.15, 1.0)
				mi.set_surface_override_material(si, dup)
	# real clips if the rigged model has any; the static tabby just sways
	var aps := _model.find_children("*", "AnimationPlayer", true, false)
	if not aps.is_empty():
		_ap = aps[0]
		print("CAT anims:", _ap.get_animation_list())
		for a in _ap.get_animation_list():
			var n := String(a).to_lower()
			if "walk" in n or "run" in n:
				_walk_clip = a
			elif "idle" in n or "sit" in n:
				_idle_clip = a
		if _idle_clip.is_empty() and _walk_clip.is_empty():
			var ls := _ap.get_animation_list()
			if not ls.is_empty():
				_idle_clip = ls[0]
	visible = false

func _process(delta: float) -> void:
	_t += delta
	if not _segs.is_empty():
		var seg: Dictionary = _segs[0]
		if seg["type"] == "pause":
			_model.rotation.z = 0.0
			seg["dur"] = float(seg["dur"]) - delta
			if seg["dur"] <= 0.0:
				_segs.pop_front()
				if not _segs.is_empty() and _segs[0]["type"] == "move":
					_face(_segs[0]["to"])
		else:
			# no rig — sell the stride with a tiny body roll instead of gliding
			_model.rotation.z = 0.035 * sin(_t * 7.0)
			var to: Vector3 = seg["to"]
			var d := to - _model.position
			var step := float(seg["speed"]) * delta
			if d.length() <= step:
				_model.position = to
				_segs.pop_front()
				if _segs.is_empty():
					_gone()
				elif _segs[0]["type"] == "pause":
					_face(Vector3(0, 0, 0.1))
					if _ap != null and not _idle_clip.is_empty():
						_ap.play(_idle_clip)
			else:
				_model.position += d.normalized() * step
		return
	_model.rotation.z = 0.0
	_next -= delta
	if _next <= 0.0:
		_next = 45.0 + randf() * 50.0
		_cross()

var _segs: Array[Dictionary] = []

func _cross() -> void:
	_walking = true
	visible = true
	if _ap != null and not _walk_clip.is_empty():
		_ap.play(_walk_clip)
	# the floor is invisible from this camera — so the cat does the thing
	# a real cat does: it stalks the table's far lip in the candlelight,
	# between you and Azrail, then drops back into the dark. Rarely it
	# takes the long way behind his chair and is swallowed whole.
	var behind := randf() < 0.3 and OS.get_environment("GWD_CATNOW") != "1"
	var from: Vector3
	var to: Vector3
	if behind:
		from = Vector3(-1.7, 0.0, -0.75)
		to = Vector3(1.7, 0.0, -0.6)
		if randf() < 0.5:
			var tmp := from; from = to; to = tmp
	else:
		from = Vector3(-0.62, _top, -0.22)
		to = Vector3(0.62, _top, -0.22)
		if randf() < 0.5:
			var tmp := from; from = to; to = tmp
	_model.position = from
	_face(to)
	var speed := 0.65   # a real cat's crossing pace — a slow prowl
	var midp := from.lerp(to, randf_range(0.35, 0.6))
	_segs = [{"type": "move", "to": midp, "speed": speed}]
	if randf() < 0.4:
		_segs.append({"type": "pause", "dur": 1.4 + randf() * 1.4})
	_segs.append({"type": "move", "to": to, "speed": speed})

func _face(to: Vector3) -> void:
	var d := to - _model.global_position
	if d.length() > 0.01:
		_model.rotation.y = atan2(d.x, d.z)

func _look_table() -> void:
	_face(Vector3(0, 0, 0.1))
	if _ap != null and not _idle_clip.is_empty():
		_ap.play(_idle_clip)

func _gone() -> void:
	visible = false
	_walking = false
	if _ap != null and not _idle_clip.is_empty():
		_ap.play(_idle_clip)
