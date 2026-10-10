extends Node3D
## A single 3D card: thin edge box + front/back face quads.
## Handles deal-in tween and hover (lift + tilt toward camera) animation.

const CARD_W := 0.063
const CARD_H := 0.088
const CARD_T := 0.0016

var _front: MeshInstance3D
var _back: MeshInstance3D
var _edge: MeshInstance3D
var _area: Area3D
var _hover := false
var _lift := 0.0
var _base_pos := Vector3.ZERO
var _base_rot := Vector3.ZERO
var _t := 0.0
var _idle_phase := 0.0

func setup(front_tex: Texture2D, back_tex: Texture2D) -> void:
	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_color = Color(0.07, 0.05, 0.04)
	edge_mat.roughness = 0.7
	_edge = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(CARD_W, CARD_T, CARD_H)
	_edge.mesh = bm
	_edge.material_override = edge_mat
	add_child(_edge)

	_front = _face_quad(front_tex)
	_front.position = Vector3(0, CARD_T * 0.51 + 0.0002, 0)
	_front.rotation.x = -PI / 2.0
	add_child(_front)

	_back = _face_quad(back_tex)
	_back.position = Vector3(0, -CARD_T * 0.51 - 0.0002, 0)
	_back.rotation.x = PI / 2.0
	add_child(_back)

	_area = Area3D.new()
	var col := CollisionShape3D.new()
	var sb := BoxShape3D.new()
	sb.size = Vector3(CARD_W, 0.01, CARD_H)
	col.shape = sb
	_area.add_child(col)
	add_child(_area)

func _face_quad(tex: Texture2D) -> MeshInstance3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.albedo_texture = tex
	m.roughness = 0.55
	m.metallic = 0.0
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(CARD_W, CARD_H)
	mi.mesh = q
	mi.material_override = m
	return mi

func get_area() -> Area3D:
	return _area

func set_base(pos: Vector3, rot: Vector3) -> void:
	_base_pos = pos
	_base_rot = rot

func set_hovered(v: bool) -> void:
	_hover = v

func _process(delta: float) -> void:
	_t += delta
	var target := 1.0 if _hover else 0.0
	_lift = lerpf(_lift, target, delta * 10.0)
	var idle := 0.0012 * sin(_t * 2.1 + _idle_phase)
	# hover: rise, scale, tilt more upright toward viewer
	position.y = _base_pos.y + idle + _lift * 0.045
	var s := 1.0 + _lift * 0.08
	scale = Vector3(s, s, s)
	rotation.x = _base_rot.x + _lift * -0.22
	rotation.z = _base_rot.z

func set_idle_phase(p: float) -> void:
	_idle_phase = p
