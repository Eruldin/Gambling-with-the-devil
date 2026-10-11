extends Node3D
## A single 3D card: thin edge box + front/back face quads.
## Handles deal-in tween, hover (lift + tilt), selection, concealed/standing
## placement, attack lunge, damage flash and death animations.

const CARD_W := 0.063
const CARD_H := 0.088
const CARD_T := 0.0016

var def = null                 # CardDef
var placed := false            # on the board (not in hand)
var face_down := false         # concealed on a pad
var lane := -1                 # board lane index when placed
var hp := 1                    # remaining health on board

var _front: MeshInstance3D
var _back: MeshInstance3D
var _edge: MeshInstance3D
var _area: Area3D
var _fmat: StandardMaterial3D
var _bmat: StandardMaterial3D
var _emat: StandardMaterial3D
var _hover := false
var _selected := false
var _lift := 0.0
var _base_pos := Vector3.ZERO
var _base_rot := Vector3.ZERO
var _t := 0.0
var _idle_phase := 0.0
var _dead := false

func setup(front_tex: Texture2D, back_tex: Texture2D) -> void:
	_emat = StandardMaterial3D.new()
	_emat.albedo_color = Color(0.07, 0.05, 0.04)
	_emat.roughness = 0.7
	_emat.emission_enabled = true
	_emat.emission = Color(0.5, 0.16, 0.05)
	_emat.emission_energy_multiplier = 0.0
	_edge = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(CARD_W, CARD_T, CARD_H)
	_edge.mesh = bm
	_edge.material_override = _emat
	add_child(_edge)

	_front = _face_quad(front_tex)
	_front.position = Vector3(0, CARD_T * 0.51 + 0.0002, 0)
	_front.rotation.x = -PI / 2.0
	add_child(_front)

	_back = _face_quad(back_tex, 0.95)
	_back.position = Vector3(0, -CARD_T * 0.51 - 0.0002, 0)
	_back.rotation.x = PI / 2.0
	add_child(_back)

	_area = Area3D.new()
	var col := CollisionShape3D.new()
	var sb := BoxShape3D.new()
	sb.size = Vector3(CARD_W, 0.02, CARD_H)
	col.shape = sb
	_area.add_child(col)
	add_child(_area)

func _face_quad(tex: Texture2D, glow := 0.0) -> MeshInstance3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.albedo_texture = tex
	m.roughness = 0.55
	m.metallic = 0.0
	if glow > 0.0:
		m.emission_enabled = true
		m.emission_texture = tex
		m.emission_energy_multiplier = glow
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
	_hover = v and not placed

func set_selected(v: bool) -> void:
	_selected = v
	var target := 2.2 if v else 0.0
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_emat, "emission_energy_multiplier", target, 0.15)

func set_face_down(v: bool) -> void:
	face_down = v
	_front.visible = not v

# --- board / combat animations -------------------------------------------

## Move the card from hand onto a lane pad, concealed (face-down flat).
func place_on_pad(pos: Vector3, enemy: bool) -> void:
	placed = true
	face_down = true
	_front.visible = false
	# flat, back up — concealed for both sides
	var rot := Vector3(PI, 0, PI * randf() * 0.06)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", pos + Vector3(0, 0.002, 0), 0.4)
	tw.parallel().tween_property(self, "rotation", rot, 0.4)
	tw.parallel().tween_property(self, "scale", Vector3.ONE * 0.72, 0.4)
	set_base(pos + Vector3(0, 0.002, 0), rot)

## Reveal: flip to standing, facing its owner's side.
func reveal() -> void:
	face_down = false
	_front.visible = true
	var rot := Vector3(PI / 2.0 - 0.12, 0, 0)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "rotation", rot, 0.35)
	tw.parallel().tween_property(self, "position:y", _base_pos.y + 0.045, 0.35)
	set_base(_base_pos + Vector3(0, 0.045, 0), rot)

## Enemy reveal: stands facing the Devil's side — player sees the back.
func reveal_enemy() -> void:
	face_down = false
	_front.visible = true
	var rot := Vector3(-PI / 2.0 + 0.12, 0, 0)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "rotation", rot, 0.35)
	tw.parallel().tween_property(self, "position:y", _base_pos.y + 0.045, 0.35)
	set_base(_base_pos + Vector3(0, 0.045, 0), rot)

## Attack lunge toward a target point, then snap back.
func lunge(to_pos: Vector3) -> Tween:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "position",
		_base_pos + (to_pos - _base_pos) * 0.55, 0.16)
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", _base_pos, 0.28)
	return tw

## Damage flash: emissive pulse on face + edge.
func flash(col := Color(1.0, 0.25, 0.1)) -> void:
	_emat.emission = col
	var tw := create_tween()
	tw.tween_property(_emat, "emission_energy_multiplier", 2.6, 0.06)
	tw.tween_property(_emat, "emission_energy_multiplier", 0.0, 0.3)
	tw.tween_callback(func(): _emat.emission = Color(0.5, 0.16, 0.05))

## Death: tip over, sink and free.
func die() -> void:
	_dead = true
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "rotation:x", _base_rot.x + 1.4, 0.4)
	tw.tween_property(self, "position:y", _base_pos.y - 0.12, 0.45)
	tw.parallel().tween_property(self, "scale", Vector3.ONE * 0.001, 0.45)
	tw.tween_callback(queue_free)

## Sacrifice burn: brief flame-flash then dissolve upward.
func burn() -> void:
	_dead = true
	var tw := create_tween()
	tw.tween_callback(flash.bind(Color(1.0, 0.5, 0.1)))
	tw.tween_interval(0.12)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "position:y", _base_pos.y + 0.1, 0.35)
	tw.parallel().tween_property(self, "scale", Vector3.ONE * 0.001, 0.35)
	tw.tween_callback(queue_free)

func tool_text() -> String:
	if def == null:
		return ""
	return "%s  ·  %s %d  ·  atk %d  hp %d  ·  sac %d" % [
		tr(def.name_key), tr("BLOOD"), def.blood_cost,
		def.attack, def.health, def.sacrifice_value]

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	var hover_amt := 1.0 if _hover else 0.0
	var sel_amt := 0.6 if _selected else 0.0
	var target: float = maxf(hover_amt, sel_amt) if not placed else 0.0
	_lift = lerpf(_lift, target, delta * 10.0)
	if not placed:
		var idle := 0.0012 * sin(_t * 2.1 + _idle_phase)
		position.y = _base_pos.y + idle + _lift * 0.045
		rotation.x = _base_rot.x + _lift * -0.22
		rotation.z = _base_rot.z
	var s: float = (1.0 + _lift * 0.08) * (0.72 if placed else 1.0)
	scale = Vector3(s, s, s)

func set_idle_phase(p: float) -> void:
	_idle_phase = p
