extends Node3D
## The house cat: crosses the dark edge of the room every so often.
## CC0 Quaternius cat, stained near-black — a silhouette, not a pet.

const CAT := "res://assets_external/props-occult/cat.glb"

var _model: Node3D
var _next := 12.0 + randf() * 18.0 if \
	OS.get_environment("GWD_CATNOW") != "1" else 0.5
var _walking := false
var _t := 0.0
var _ap: AnimationPlayer
var _walk_clip := ""
var _idle_clip := ""

func build() -> void:
	_model = load(CAT).instantiate()
	add_child(_model)
	# near-black but readable — pure black vanished against the floor
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.12, 0.09, 0.075)
	dm.roughness = 0.85
	for mi: MeshInstance3D in _model.find_children(
			"*", "MeshInstance3D", true, false):
		mi.material_override = dm
	# a pair of faint amber eyes — created ONCE (was stacking per crossing)
	for side in [-1.0, 1.0]:
		var e := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.008
		es.height = 0.016
		e.mesh = es
		var em := StandardMaterial3D.new()
		em.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		em.emission_enabled = true
		em.emission = Color(1.0, 0.75, 0.2)
		em.emission_energy_multiplier = 4.0
		e.material_override = em
		_model.add_child(e)
		e.position = Vector3(0.02 * side, 0.11, 0.09)
	# Quaternius cat ships real clips — walk while crossing, idle at rest
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
	if _walking:
		return
	_next -= delta
	if _next <= 0.0:
		_next = 45.0 + randf() * 50.0
		_cross()

func _cross() -> void:
	_walking = true
	visible = true
	if _ap != null and not _walk_clip.is_empty():
		_ap.play(_walk_clip)
	# the right-edge route reads best (moon-pale floor at the cabinet);
	# the deep route disappears behind the devil's chair — keep it rare
	var behind := randf() < 0.35 and OS.get_environment("GWD_CATNOW") != "1"
	var y := 0.0
	var z := -0.75 if behind else 0.15
	var from := Vector3(-1.7, y, z - (0.2 if behind else 0.0))
	var to := Vector3(1.7, y, z + (0.15 if behind else 0.1))
	if randf() < 0.5:
		var tmp := from; from = to; to = tmp
	_model.position = from
	_face(to)
	var speed := 0.35   # slow, measured prowl
	# tween the MODEL's local position — the wrapper stays at origin
	# (tweening the wrapper dragged the cat a whole route-length off-path
	# and left it crossing behind furniture where nobody could see it)
	var midp := from.lerp(to, randf_range(0.35, 0.6))
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(_model, "position", midp, from.distance_to(midp) / speed)
	if randf() < 0.4:
		tw.tween_callback(_look_table)
		tw.tween_interval(1.4 + randf() * 1.4)
		tw.tween_callback(_face.bind(to))
		tw.tween_interval(0.3)
	tw.tween_property(_model, "position", to, midp.distance_to(to) / speed)
	tw.tween_callback(_gone)

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
