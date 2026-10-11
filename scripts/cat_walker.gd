extends Node3D
## The house cat: crosses the dark edge of the room every so often.
## CC0 Quaternius cat, stained near-black — a silhouette, not a pet.

const CAT := "res://assets_external/props-occult/cat.glb"

var _model: Node3D
var _next := 18.0 + randf() * 25.0
var _walking := false
var _t := 0.0

func build() -> void:
	_model = load(CAT).instantiate()
	add_child(_model)
	# near-black but readable — pure black vanished against the floor
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.06, 0.045, 0.038)
	dm.roughness = 0.85
	for mi: MeshInstance3D in _model.find_children(
			"*", "MeshInstance3D", true, false):
		mi.material_override = dm
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
	# two routes: behind the table (under the devil's chair) or along
	# the right edge past the cabinet — always at floor level, in shadow
	var behind := randf() < 0.6
	var y := 0.0
	var z := -0.75 if behind else 0.15
	var from := Vector3(-1.7, y, z - (0.2 if behind else 0.0))
	var to := Vector3(1.7, y, z + (0.15 if behind else 0.1))
	# a pair of faint amber eyes — the black cat's signature in the dark
	for side in [-1.0, 1.0]:
		var e := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.006
		es.height = 0.012
		e.mesh = es
		var em := StandardMaterial3D.new()
		em.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		em.emission_enabled = true
		em.emission = Color(1.0, 0.75, 0.2)
		em.emission_energy_multiplier = 4.0
		e.material_override = em
		_model.add_child(e)
		e.position = Vector3(0.02 * side, 0.11, 0.09)
	if randf() < 0.5:
		var tmp := from; from = to; to = tmp
	_model.global_position = from
	_face(to)
	var speed := 0.35   # slow, measured prowl
	# path split at a midpoint — sometimes it stops and stares at the table
	var midp := from.lerp(to, randf_range(0.35, 0.6))
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "global_position", midp, from.distance_to(midp) / speed)
	if randf() < 0.35:
		tw.tween_callback(_look_table)
		tw.tween_interval(1.4 + randf() * 1.4)
		tw.tween_callback(_face.bind(to))
		tw.tween_interval(0.3)
	tw.tween_property(self, "global_position", to, midp.distance_to(to) / speed)
	tw.tween_callback(_gone)
	# slight prowl bob while crossing
	var dur := from.distance_to(to) / speed
	var bob := create_tween().set_loops(maxi(1, int(dur * 2)))
	bob.tween_property(_model, "position:y", 0.004, 0.12)
	bob.tween_property(_model, "position:y", 0.0, 0.13)

func _face(to: Vector3) -> void:
	var d := to - global_position
	if d.length() > 0.01:
		_model.rotation.y = atan2(d.x, d.z)

func _look_table() -> void:
	_face(Vector3(0, 0, 0.1))

func _gone() -> void:
	visible = false
	_walking = false
