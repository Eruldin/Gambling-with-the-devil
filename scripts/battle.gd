extends Node3D
## Battle loop (design-doc slice): each round both sides ante the Blind,
## place cards concealed on lane pads, reveal, strike lane-vs-lane, clean up.
## Economy: Soul Chips (shared HP), Blood (per-round placement cost, refilled
## by sacrificing hand cards).

const GameCard := preload("res://scripts/game_card.gd")
const CardDef := preload("res://scripts/card_def.gd")
const CARDS_DIR := "res://assets_external/card-art/kenney/boardgame-pack/PNG/Cards/"
const BLINDS := [1, 2, 3, 5, 8, 13]
const LANES := 5
const START_CHIPS := 12
const BLOOD_PER_ROUND := 2
const HAND_MAX := 6

enum Phase { PLACE, BUSY, OVER }

var _top := 0.0
var _cam: Camera3D
var _layer: CanvasLayer
var _back_tex: Texture2D
var _autoplay := false

var _pads := {}            # "p0".."p4" / "e0".."e4" -> MeshInstance3D
var _pad_areas := {}       # Area3D -> {"enemy": bool, "lane": int}
var _area_to_card := {}    # Area3D -> GameCard (hand + board)
var _hand: Array = []
var _deck: Array = []
var _edeck: Array = []
var _board_p := {}         # lane -> GameCard
var _board_e := {}         # lane -> GameCard

var _phase := Phase.PLACE
var _round := 1
var _blood := BLOOD_PER_ROUND
var _chips_you := START_CHIPS
var _chips_devil := START_CHIPS
var _selected = null
var _hovered_card = null
var _hovered_pad = null

var _l_phase: Label
var _l_chips: Label
var _l_blood: Label
var _l_hint: Label
var _l_tool: Label
var _l_over: Label
var _font: Font

# ---------------------------------------------------------------- setup

func setup(top: float, cam: Camera3D, layer: CanvasLayer, font: Font) -> void:
	_top = top
	_cam = cam
	_layer = layer
	_font = font
	_back_tex = load(CARDS_DIR + "cardBack_red4.png")
	_autoplay = OS.get_environment("GWD_AUTO") == "1"
	_make_pads()
	_make_hud()
	_deck = CardDef.starter_deck()
	_edeck = CardDef.starter_deck()
	_deck.shuffle()
	_edeck.shuffle()
	for i in range(5):
		_draw_hand()
	_start_round()
	if _autoplay:
		_autoplay_run()

func _make_pads() -> void:
	var mat_p := StandardMaterial3D.new()
	mat_p.albedo_color = Color(0.075, 0.12, 0.08)
	mat_p.roughness = 0.9
	mat_p.emission_enabled = true
	mat_p.emission = Color(0.35, 0.6, 0.3)
	mat_p.emission_energy_multiplier = 0.0
	var mat_e := StandardMaterial3D.new()
	mat_e.albedo_color = Color(0.09, 0.1, 0.09)
	mat_e.roughness = 0.9
	for side in 2:
		for lane in range(LANES):
			var key := ("e" if side == 0 else "p") + str(lane)
			var pad := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.155, 0.003, 0.2)
			pad.mesh = bm
			pad.material_override = (mat_e if side == 0 else mat_p).duplicate()
			pad.position = Vector3(-0.33 + lane * 0.165, _top + 0.014,
				-0.115 + side * 0.23)
			add_child(pad)
			_pads[key] = pad
			var area := Area3D.new()
			var col := CollisionShape3D.new()
			var sb := BoxShape3D.new()
			sb.size = Vector3(0.155, 0.02, 0.2)
			col.shape = sb
			area.add_child(col)
			pad.add_child(area)
			_pad_areas[area] = {"enemy": side == 0, "lane": lane}

func _make_hud() -> void:
	_l_phase = _mk_label(Vector2(16, 46), 15, Color(0.62, 0.45, 0.3))
	_l_chips = _mk_label(Vector2(0, 0), 16, Color(0.78, 0.5, 0.28))
	_l_chips.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_l_chips.offset_left = -320
	_l_chips.offset_right = -16
	_l_chips.offset_top = 46
	_l_chips.offset_bottom = 72
	_l_chips.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_l_blood = _mk_label(Vector2(16, 68), 14, Color(0.65, 0.2, 0.15))
	_l_tool = _mk_label(Vector2(0, 0), 14, Color(0.7, 0.6, 0.45))
	_l_tool.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_l_tool.offset_left = 16
	_l_tool.offset_top = -60
	_l_tool.offset_bottom = -36
	_l_hint = _mk_label(Vector2(0, 0), 15, Color(0.5, 0.4, 0.3))
	_l_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_l_hint.offset_top = -34
	_l_hint.offset_bottom = -10
	_l_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_l_over = _mk_label(Vector2(0, 0), 42, Color(0.85, 0.3, 0.15))
	_l_over.set_anchors_preset(Control.PRESET_CENTER)
	_l_over.offset_left = -400
	_l_over.offset_right = 400
	_l_over.offset_top = -60
	_l_over.offset_bottom = 60
	_l_over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var btn := Button.new()
	btn.text = tr("BTN_REVEAL")
	btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", Color(0.85, 0.6, 0.3))
	btn.position = Vector2(-170, -74)
	btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn.pressed.connect(end_turn)
	_layer.add_child(btn)

func _mk_label(offset: Vector2, size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.position = offset
	_layer.add_child(l)
	return l

# ---------------------------------------------------------------- rounds

func _start_round() -> void:
	var ante: int = BLINDS[mini(_round - 1, BLINDS.size() - 1)]
	_chips_you -= ante
	_chips_devil -= ante
	_blood = BLOOD_PER_ROUND
	_phase = Phase.PLACE
	_draw_hand()
	_l_phase.text = "%s %d  ·  %s %d" % [tr("ROUND"), _round, tr("BLIND"), ante]
	_hint(tr("HINT_PLACE"))
	_update_chips()
	_check_over()

func _draw_hand() -> void:
	if _deck.is_empty() or _hand.size() >= HAND_MAX:
		return
	var d: CardDef = _deck.pop_back()
	var card := GameCard.new()
	card.def = d
	add_child(card)
	card.setup(load(CARDS_DIR + d.face_file), _back_tex)
	card.set_idle_phase(randf() * 3.0)
	_area_to_card[card.get_area()] = card
	_hand.append(card)
	_reflow_hand()

func _reflow_hand() -> void:
	var n := _hand.size()
	for i in range(n):
		var x := (i - (n - 1) * 0.5) * 0.07
		var pos := Vector3(x, _top + 0.136, 0.42)
		var rot := Vector3(1.12, 0, (i - (n - 1) * 0.5) * -0.07)
		var card: Node3D = _hand[i]
		if card.position == Vector3.ZERO:
			card.position = Vector3(0.44, pos.y, -0.14)
			card.rotation = Vector3(PI, 0, 0)
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "position", pos, 0.4)
		tw.parallel().tween_property(card, "rotation", rot, 0.4)
		card.set_base(pos, rot)

# ---------------------------------------------------------------- input

func hover_target(collider) -> void:
	var card = _area_to_card.get(collider)
	var pad = _pad_areas.get(collider)
	if _phase != Phase.PLACE:
		card = null
		pad = null
	if card != _hovered_card:
		if _hovered_card != null:
			_hovered_card.set_hovered(false)
		_hovered_card = card
		if card != null:
			card.set_hovered(true)
	_l_tool.text = card.tool_text() if card != null \
		and (not card.placed or not card.face_down) else ""
	if pad != null and pad["enemy"]:
		pad = null
	var lit = _hovered_pad
	_hovered_pad = pad
	if lit != null and lit != pad:
		_pad_glow(lit, 0.0)
	if pad != null and _selected != null and not _board_p.has(pad["lane"]):
		_pad_glow(pad, 0.8)

func click(collider) -> void:
	if _phase != Phase.PLACE or _autoplay:
		return
	var card = _area_to_card.get(collider)
	var pad = _pad_areas.get(collider)
	if card != null and _hand.has(card):
		_select(card if card != _selected else null)
		return
	if pad != null and not pad["enemy"] and _selected != null:
		_try_place(pad["lane"])

func right_click(collider) -> void:
	if _phase != Phase.PLACE or _autoplay:
		return
	var card = _area_to_card.get(collider)
	if card != null and _hand.has(card):
		_sacrifice_card(card)

func _select(card) -> void:
	if _selected != null and is_instance_valid(_selected):
		_selected.set_selected(false)
	_selected = card
	if card != null:
		card.set_selected(true)
		_hint(tr("HINT_PAD") if card != null else "")
	else:
		_hint(tr("HINT_PLACE"))

func _try_place(lane: int) -> void:
	var card = _selected
	if _board_p.has(lane):
		return
	if card.def.blood_cost > _blood:
		_hint(tr("HINT_NOBLOOD"))
		return
	_blood -= card.def.blood_cost
	_select(null)
	if _hovered_pad != null:
		_pad_glow(_hovered_pad, 0.0)
		_hovered_pad = null
	_hand.erase(card)
	card.lane = lane
	card.hp = card.def.health
	_board_p[lane] = card
	card.place_on_pad(_pads["p" + str(lane)].position, false)
	_reflow_hand()
	_update_chips()
	_hint(tr("HINT_PLACE_MORE"))

func _sacrifice_card(card) -> void:
	_hand.erase(card)
	_area_to_card.erase(card.get_area())
	if card == _selected:
		_select(null)
	_blood += card.def.sacrifice_value
	card.burn()
	_reflow_hand()
	_update_chips()
	_hint("%s +%d %s" % [tr("SACRIFICED"), card.def.sacrifice_value, tr("BLOOD")])

# ---------------------------------------------------------------- reveal/strike

func end_turn() -> void:
	if _phase != Phase.PLACE or _autoplay:
		return
	_phase = Phase.BUSY
	_select(null)
	_enemy_place()
	_l_phase.text = tr("PHASE_RESOLVING")
	_hint("")
	_run_resolution()

func _enemy_place() -> void:
	var want := randi_range(1, 2)
	var free_lanes: Array = []
	for lane in range(LANES):
		if not _board_e.has(lane):
			free_lanes.append(lane)
	free_lanes.shuffle()
	for i in range(mini(want, free_lanes.size())):
		if _edeck.is_empty():
			break
		var lane: int = free_lanes[i]
		var d: CardDef = _edeck.pop_back()
		var card := GameCard.new()
		card.def = d
		add_child(card)
		card.setup(load(CARDS_DIR + d.face_file), _back_tex)
		card.position = Vector3(-0.44, _top + 0.15, -0.14)
		card.rotation = Vector3(PI, 0, 0)
		card.lane = lane
		card.hp = d.health
		_board_e[lane] = card
		_area_to_card[card.get_area()] = card
		card.place_on_pad(_pads["e" + str(lane)].position, true)

func _run_resolution() -> void:
	await get_tree().create_timer(0.5).timeout
	# reveal all concealed cards, staggered
	for lane in range(LANES):
		var p = _board_p.get(lane)
		var e = _board_e.get(lane)
		if p != null and p.face_down:
			p.reveal()
		if e != null and e.face_down:
			e.reveal_enemy()
		await get_tree().create_timer(0.18).timeout
	await get_tree().create_timer(0.5).timeout
	# strikes lane by lane: player hits first, then the Devil answers
	for lane in range(LANES):
		var p = _board_p.get(lane)
		var e = _board_e.get(lane)
		if p != null and not p.face_down and p.def.attack > 0:
			p.lunge(_pads["e" + str(lane)].position)
			if e != null and not e.face_down:
				e.hp -= p.def.attack
				e.flash()
			else:
				_chips_devil -= p.def.attack
				_pulse(_l_chips)
			await get_tree().create_timer(0.42).timeout
		if e != null and not e.face_down and e.def != null and e.hp > 0 \
			and e.def.attack > 0:
			e.lunge(_pads["p" + str(lane)].position)
			if p != null and not p.face_down:
				p.hp -= e.def.attack
				p.flash()
			else:
				_chips_you -= e.def.attack
				_pulse(_l_chips)
			await get_tree().create_timer(0.42).timeout
	_update_chips()
	await get_tree().create_timer(0.4).timeout
	_cleanup_dead()
	if _check_over():
		return
	_round += 1
	_start_round()

func _cleanup_dead() -> void:
	for lane in range(LANES):
		var p = _board_p.get(lane)
		if p != null and p.hp <= 0:
			_board_p.erase(lane)
			_area_to_card.erase(p.get_area())
			p.die()
		var e = _board_e.get(lane)
		if e != null and e.hp <= 0:
			_board_e.erase(lane)
			_area_to_card.erase(e.get_area())
			e.die()

func _check_over() -> bool:
	if _chips_you > 0 and _chips_devil > 0:
		return false
	_phase = Phase.OVER
	var won := _chips_devil <= 0 and _chips_you > 0
	_l_over.text = tr("YOU_WIN") if won else tr("DEVIL_WINS")
	_l_over.text += "\n" + tr("RESTART")
	_l_phase.text = tr("GAME_OVER")
	return true

func restart() -> void:
	get_tree().reload_current_scene()

# ---------------------------------------------------------------- hud bits

func _update_chips() -> void:
	_l_chips.text = "%s %d   ·   %s %d" % [tr("CHIPS_YOU"), _chips_you,
		tr("CHIPS_DEVIL"), _chips_devil]
	_l_blood.text = "%s %d   ·   %s %d" % [tr("BLOOD"), _blood,
		tr("CARDS_LEFT"), _deck.size()]

func _hint(t: String) -> void:
	_l_hint.text = t

func _pad_glow(pad, amt: float) -> void:
	var m: StandardMaterial3D = _pads["p" + str(pad["lane"])].material_override
	var tw := create_tween()
	tw.tween_property(m, "emission_energy_multiplier", amt, 0.15)

func _pulse(l: Label) -> void:
	var tw := create_tween()
	tw.tween_property(l, "modulate", Color(2.4, 0.7, 0.5), 0.08)
	tw.tween_property(l, "modulate", Color.WHITE, 0.4)

# ---------------------------------------------------------------- autoplay probe

func _autoplay_run() -> void:
	await get_tree().create_timer(1.2).timeout
	# place hand[0] on lane 1, next free on lane 3, sacrifice hand[0]
	if _hand.size() >= 1:
		_select(_hand[0]); _try_place(1)
	if _hand.size() >= 1:
		_select(_hand[1] if _hand.size() > 1 else _hand[0]); _try_place(3)
	if _hand.size() >= 1:
		_sacrifice_card(_hand[0])
	_phase = Phase.PLACE
	end_turn_autoplay()

func end_turn_autoplay() -> void:
	_phase = Phase.BUSY
	_enemy_place()
	_l_phase.text = tr("PHASE_RESOLVING")
	_run_resolution()
