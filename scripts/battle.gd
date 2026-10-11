extends Node3D
## Battle loop (design-doc slice): each round both sides ante the Blind,
## place cards concealed on lane pads, reveal, strike lane-vs-lane, clean up.
## Economy: Soul Chips (shared HP), Blood (per-round placement cost, refilled
## by sacrificing hand cards).

const GameCard := preload("res://scripts/game_card.gd")
const CardDef := preload("res://scripts/card_def.gd")
const Sfx := preload("res://scripts/sfx.gd")
const CARDS_DIR := "res://assets_external/card-art/kenney/boardgame-pack/PNG/Cards/"
const LANES := 5
const CHIPS_YOU := 40          # §2.2: persistent soul pool, run starts at 40
const CHIPS_DEVIL := 30        # §2.2: standard tier pile (25–40)
const BLOOD_PER_ROUND := 2
const HAND_MAX := 6
const RAISE_MAX := 5           # §2.3: stake 1–5 extra chips once per turn
const TAUNT_AT := 2.5          # psyche axis level that makes Azrail speak

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
var _chips_you := CHIPS_YOU
var _chips_devil := CHIPS_DEVIL
var _pot := 0                  # §2.4: the prize — every chip paid feeds it
var _debt := 0                 # Final Wager marker
var _raise_used := 0
var _placed_this := 0
var _wager_offered := false
var _wager_pending := false
var _bluff_used := false       # Call the Bluff — once per battle
var _call_armed := false
var _mulligan_used := false    # opening redeal — once per battle
# Azrail psychology (§18.2) — five axes the game feeds; his table manners
# and his AI both read these.
var _psyche := {"cruelty": 0.0, "curiosity": 0.0, "anger": 0.0,
	"respect": 0.0, "boredom": 0.0}
var _taunted := {}
var _pot_pile: Array = []
var _selected = null
var _hovered_card = null
var _hovered_pad = null

var _l_phase: Label
var _l_chips: Label
var _l_blood: Label
var _l_pot: Label
var _scale: Node3D       # the Scales prop — tips when souls swing
var _l_hint: Label
var _l_tool: Label
var _l_over: Label
var _font: Font
var _devil = null
var _phand = null
var _sfx: Node

# ---------------------------------------------------------------- setup

func setup(top: float, cam: Camera3D, layer: CanvasLayer, font: Font,
		devil = null, phand = null) -> void:
	_top = top
	_cam = cam
	_layer = layer
	_font = font
	_devil = devil
	_phand = phand
	_sfx = Sfx.new()
	_sfx.setup(self)
	_back_tex = load("res://assets_external/card-art/gwd/card_back.png")
	_autoplay = OS.get_environment("GWD_AUTO") == "1"
	_make_pads()
	_make_hud()
	_deck = CardDef.starter_deck()
	_edeck = CardDef.starter_deck()
	# Azrail palms two counterfeits into his deck — Call the Bluff prey
	_edeck.insert(randi() % _edeck.size(), CardDef.bluff_card())
	_edeck.insert(randi() % _edeck.size(), CardDef.bluff_card())
	_deck.shuffle()
	_edeck.shuffle()
	for i in range(5):
		_draw_hand()
	_start_round()
	if _autoplay:
		_autoplay_run()

func _make_pads() -> void:
	var mat_p := StandardMaterial3D.new()
	mat_p.albedo_color = Color(0.016, 0.028, 0.02)
	mat_p.roughness = 0.95
	mat_p.emission_enabled = true
	mat_p.emission = Color(0.35, 0.6, 0.3)
	mat_p.emission_energy_multiplier = 0.0
	var mat_e := StandardMaterial3D.new()
	mat_e.albedo_color = Color(0.012, 0.02, 0.016)
	mat_e.roughness = 0.95
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
			area.collision_layer = 2        # pads own a layer so clicks prefer them
			area.collision_mask = 0
			var col := CollisionShape3D.new()
			var sb := BoxShape3D.new()
			sb.size = Vector3(0.175, 0.02, 0.22)
			col.shape = sb
			area.add_child(col)
			pad.add_child(area)
			_pad_areas[area] = {"enemy": side == 0, "lane": lane}
	# the pot — a physical chip pile on the felt's right edge; every chip
	# the blinds, raises or wounds pay stacks up here
	for i in range(16):
		var c := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.026
		cyl.bottom_radius = 0.026
		cyl.height = 0.004
		c.mesh = cyl
		var cm := StandardMaterial3D.new()
		cm.albedo_color = Color(0.55, 0.38, 0.12).darkened(0.12 * (i % 3))
		cm.roughness = 0.45
		cm.metallic = 0.65
		c.material_override = cm
		c.position = Vector3(0.44, _top + 0.017 + i * 0.0045, -0.02)
		c.visible = false
		add_child(c)
		_pot_pile.append(c)

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
	_l_pot = _mk_label(Vector2(16, 90), 15, Color(0.78, 0.58, 0.2))
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
	_l_over.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	var ante := _blind_for(_round)
	_chips_you -= ante
	_chips_devil -= ante
	_pot += ante * 2
	_blood = BLOOD_PER_ROUND
	_raise_used = 0
	_placed_this = 0
	_phase = Phase.PLACE
	if _devil != null:
		_devil.set_mood(_round)
		if _sfx != null:
			_devil._sfx_ref = _sfx
	_draw_hand()
	_l_phase.text = "%s %d  ·  %s %d" % [tr("ROUND"), _round, tr("BLIND"), ante]
	_hint(tr("HINT_PLACE_R1") if _round == 1 else tr("HINT_PLACE"))
	_update_chips()
	_sfx.play(Sfx.SHUFFLE, -8.0)
	_check_over()

func _draw_hand() -> void:
	if _hand.size() >= HAND_MAX:
		return
	if _deck.is_empty():
		# Soul Draw (§2.3): thin decks bleed — 2 chips a card, into the pot.
		_chips_you -= 2
		_pot += 2
		_pulse(_l_pot)
		_update_chips()
		return
	var d: CardDef = _deck.pop_back()
	var card := GameCard.new()
	card.def = d
	add_child(card)
	card.setup(load(d.face_file), _back_tex)
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
	if _call_armed:
		if card != null and card.placed and card.face_down \
			and _board_e.values().has(card):
			_call_bluff(card)
		else:
			_hint(tr("HINT_CALL"))
		return
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
		_sfx.play(Sfx.DENIED, -10.0)
		return
	_blood -= card.def.blood_cost
	_placed_this += 1
	_select(null)
	if _hovered_pad != null:
		_pad_glow(_hovered_pad, 0.0)
		_hovered_pad = null
	_hand.erase(card)
	card.lane = lane
	card.hp = card.def.health
	_board_p[lane] = card
	var dest: Vector3 = _pads["p" + str(lane)].position + Vector3(0, 0.002, 0)
	var rot := Vector3(PI, 0, PI * randf() * 0.06)
	card.placed = true
	card.set_face_down(true)
	if _phand != null and not _autoplay:
		card.set_base(dest, rot)
		await _phand.pick_and_place(card, dest, rot)
		card.scale = Vector3.ONE * 0.72
	else:
		card.place_on_pad(_pads["p" + str(lane)].position, false)
	_reflow_hand()
	_update_chips()
	_hint(tr("HINT_PLACE_MORE"))
	_sfx.play(Sfx.PLACE_P, -6.0)

func _sacrifice_card(card) -> void:
	_hand.erase(card)
	_area_to_card.erase(card.get_area())
	if card == _selected:
		_select(null)
	_blood += card.def.sacrifice_value
	_bump("respect", 0.3)         # bold commitment — he notices
	if _devil != null:
		_devil.feed(card.position)   # he feeds on the offering
	if _phand != null and not _autoplay:
		var away := Vector3(0.55, _top - 0.35, 0.75)
		await _phand.grab_and_pull(card, away, card.burn)
	else:
		card.burn()
	_reflow_hand()
	_update_chips()
	_hint("%s +%d %s" % [tr("SACRIFICED"), card.def.sacrifice_value, tr("BLOOD")])
	_burst(card.position + Vector3(0, 0.02, 0), Color(0.45, 0.02, 0.02),
		26, 0.012, 0.55)
	_sfx.play(Sfx.SHOVE, -6.0)
	_sfx.play(Sfx.CHIP_HANDLE, -10.0)

## one-shot particle burst — blood splashes, spark hits, reveal wisps
func _burst(pos: Vector3, color: Color, amount: int,
		size: float, lifetime: float) -> void:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.015
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 65.0
	pm.initial_velocity_min = 0.12
	pm.initial_velocity_max = 0.4
	pm.gravity = Vector3(0, -0.5, 0)
	pm.damping_min = 0.3
	pm.damping_max = 0.6
	pm.scale_min = size * 0.5
	pm.scale_max = size
	pm.color = color
	var gp := GPUParticles3D.new()
	gp.amount = amount
	gp.lifetime = lifetime
	gp.one_shot = true
	gp.explosiveness = 0.85
	gp.process_material = pm
	gp.position = pos
	var q := QuadMesh.new()
	q.size = Vector2(0.006, 0.006)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	dm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	dm.albedo_color = color
	q.material = dm
	gp.draw_pass_1 = q
	add_child(gp)
	gp.emitting = true
	get_tree().create_timer(lifetime + 0.4).timeout.connect(gp.queue_free)

# ---------------------------------------------------------------- reveal/strike

func end_turn() -> void:
	if _phase != Phase.PLACE or _autoplay:
		return
	_phase = Phase.BUSY
	_select(null)
	if _placed_this <= 0:
		_bump("boredom", 0.6)     # stalling bores him
		_bump("cruelty", 0.3)      # ...and smells like fear
	await _enemy_place()
	_l_phase.text = tr("PHASE_RESOLVING")
	_hint("")
	_run_resolution()

func _enemy_place() -> void:
	# he reads your row first — a thinking beat, not a random drop
	if _devil != null and not _autoplay:
		await _devil.think(Vector3(0, _top + 0.05, 0.12))
	# lane scoring: the devil *studies* the felt — every placement is
	# a decision, not a coin toss. It's his table; he reads even the
	# face-down cards (he's the devil — thematically a cheat, and it
	# makes his placements feel predatory, not random).
	var free_lanes: Array = []
	for lane in range(LANES):
		if not _board_e.has(lane):
			free_lanes.append(lane)
	var peek: CardDef = _edeck.back() if not _edeck.is_empty() else null

	free_lanes.sort_custom(func(a: int, b: int) -> bool:
		return _lane_score(a, peek) > _lane_score(b, peek))
	# a bored devil presses the attack — more bodies on the felt
	var want := randi_range(1, 2 if _psyche["boredom"] < TAUNT_AT else 3)
	for i in range(mini(want, free_lanes.size())):
		if _edeck.is_empty():
			break
		var lane: int = free_lanes[i]

		var d: CardDef = _edeck.pop_back()
		var card := GameCard.new()
		card.def = d
		add_child(card)
		card.setup(load(d.face_file), _back_tex)
		card.position = Vector3(-0.44, _top + 0.15, -0.14)
		card.rotation = Vector3(PI, 0, 0)
		card.lane = lane
		card.hp = d.health
		_board_e[lane] = card
		_area_to_card[card.get_area()] = card
		var dest: Vector3 = _pads["e" + str(lane)].position + Vector3(0, 0.002, 0)
		var rot := Vector3(PI, 0, PI * randf() * 0.06)
		if _devil != null and not _autoplay:
			card.placed = true
			card.set_face_down(true)
			card.scale = Vector3.ONE * 0.72
			card.set_base(dest, rot)
			await _devil.play_card(card, dest, rot)
		else:
			card.place_on_pad(_pads["e" + str(lane)].position, true)
		_sfx.play(Sfx.PLACE_E, -10.0)
		_sfx.play(Sfx.SLIDE, -14.0, 1.2)   # the arc whoosh

## How good is lane `lane` for the next enemy card `d`?
## Empty player lane = free chip damage (best). Weak blocker = wall it.
## Strong blocker = feed it a cheap card to stall (waste nothing strong).
func _lane_score(lane: int, d: CardDef) -> float:
	var p = _board_p.get(lane)
	if d == null:
		return 0.0
	if p == null:
		# a clean line into the player's chips — cruelty makes him crave it
		return 10.0 + d.attack * 2.0 + \
			(3.0 if _psyche["cruelty"] >= TAUNT_AT else 0.0)
	if p.def == null:
		return 0.0
	# block: prefer lanes where our card outlives theirs. Once respect is
	# high he plays fair — a concealed card is priced as an average pawn,
	# not read through the felt.
	var guessed: bool = _psyche["respect"] >= TAUNT_AT and p.face_down
	var p_atk := 1.5 if guessed else float(p.def.attack)
	var p_hp := 1.5 if guessed else float(
		p.hp if p.hp > 0 else p.def.health)
	var survives: bool = d.health > p_atk
	var kills: bool = float(d.attack) >= p_hp
	var s := 2.0
	if kills:
		s += 5.0                      # remove a threat
	if survives:
		s += 3.0                      # and keep a wall standing
	if d.attack > 0 and not survives:
		s -= 4.0                      # don't throw attackers under a wall
	s += randf() * (3.0 if guessed else 1.5)   # he's good, not a machine
	return s

func _run_resolution() -> void:
	await get_tree().create_timer(0.5).timeout
	# reveal all concealed cards, staggered
	_sfx.play(Sfx.FAN, -7.0)
	for lane in range(LANES):
		var p = _board_p.get(lane)
		var e = _board_e.get(lane)
		if p != null and p.face_down:
			p.reveal()
			_burst(p.position + Vector3(0, 0.03, 0),
				Color(0.16, 0.14, 0.11), 14, 0.02, 0.8)
		if e != null and e.face_down:
			e.reveal_enemy()
			if _devil != null:
				_devil.watch(e.position, 1.4)
			_burst(e.position + Vector3(0, 0.03, 0),
				Color(0.16, 0.14, 0.11), 14, 0.02, 0.8)
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
				if e.hp <= 0:
					_bump("respect", 0.4)   # a clean kill earns a nod
				e.flash()
				_burst(e.position + Vector3(0, 0.03, 0),
					Color(1.0, 0.5, 0.12), 18, 0.01, 0.4)
			else:
				# §2.4: chip damage bleeds 1:1 — and antes the same into the pot
				_chips_devil -= p.def.attack
				_pot += p.def.attack
				_bump("anger", 0.3)       # losing chips angers him
				_bump("respect", 0.2)      # ...and impresses him
				_pulse(_l_chips)
				_shake(0.022)
				_punch(0.4 + 0.12 * p.def.attack)
				if _scale != null:
					_scale.tip(0.25 * p.def.attack)
				_burst(_pads["e" + str(lane)].position + Vector3(0, 0.05, 0),
					Color(1.0, 0.55, 0.15), 22, 0.014, 0.5)
				_sfx.play(Sfx.CHIP_HIT, -5.0)
				if _devil != null:
					_devil.eyes_flare(0.7)
					_devil.strike_pose(_pads["e" + str(lane)].position.x, true)
			await get_tree().create_timer(0.42).timeout
		if e != null and not e.face_down and e.def != null and e.hp > 0 \
			and e.def.attack > 0:
			e.lunge(_pads["p" + str(lane)].position)
			if p != null and not p.face_down:
				p.hp -= e.def.attack
				p.flash()
				_burst(p.position + Vector3(0, 0.03, 0),
					Color(1.0, 0.5, 0.12), 18, 0.01, 0.4)
			else:
				_chips_you -= e.def.attack
				_pot += e.def.attack
				_bump("cruelty", 0.4)     # he tastes your blood
				_pulse(_l_chips)
				_shake(0.028)
				_punch(0.6 + 0.15 * e.def.attack)
				if _scale != null:
					_scale.tip(-0.25 * e.def.attack)
				_burst(_pads["p" + str(lane)].position + Vector3(0, 0.05, 0),
					Color(1.0, 0.55, 0.15), 22, 0.014, 0.5)
				_sfx.play(Sfx.CHIP_HIT, -5.0, 0.85)
				if _devil != null:
					_devil.lean_in(0.3)
					_devil.watch(_pads["p" + str(lane)].position, 1.5)
			await get_tree().create_timer(0.42).timeout
	_update_chips()
	await get_tree().create_timer(0.4).timeout
	_cleanup_dead()
	if _check_over():
		return
	_round += 1
	_start_round()

## impact shake: quick camera offset jitter, settles in ~0.25s
func _punch(strength: float) -> void:
	# dramatic camera kick — the lens dips for a frame then snaps back,
	# like the table itself flinched when chips changed hands
	if _cam == null:
		return
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_cam, "fov", _cam.fov - 4.0 * strength, 0.06)
	tw.tween_property(_cam, "fov", 46.0, 0.38).set_ease(Tween.EASE_OUT)

func _shake(amt: float) -> void:
	if _cam == null:
		return
	var tw := create_tween()
	tw.tween_property(_cam, "h_offset",
		randf_range(-amt, amt), 0.05)
	tw.parallel().tween_property(_cam, "v_offset",
		randf_range(-amt, amt), 0.05)
	tw.tween_property(_cam, "h_offset", 0.0, 0.2)
	tw.parallel().tween_property(_cam, "v_offset", 0.0, 0.2)

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
	if _chips_you <= 0 and not _wager_offered:
		# Final Wager (§2.5): the Devil deals you back in — ten chips,
		# fifteen debt, once per run.
		_phase = Phase.OVER
		_wager_pending = true
		_l_over.text = tr("WAGER_OFFER")
		_l_phase.text = tr("GAME_OVER")
		if _devil != null:
			_devil.lean_in(0.5)
			_devil.eyes_flare(1.0)
		_sfx.play(Sfx.LOSE, -10.0)
		return true
	_finish_over(_chips_devil <= 0 and _chips_you > 0)
	return true

func _finish_over(won: bool) -> void:
	_phase = Phase.OVER
	_wager_pending = false
	if _devil != null:
		if won:
			_devil.defeat()
		else:
			_devil.victory()
	_l_over.text = tr("YOU_WIN") if won else tr("DEVIL_WINS")
	if won:
		# §2.4: the pot converts to embers — the fatter the violence,
		# the fatter the payday.
		_l_over.text += "\n" + str(_pot) + " " + tr("EMBERS_WON")
	if _debt > 0:
		_l_over.text += "\n" + tr("DEBT_LBL") + " " + str(_debt)
	_l_over.text += "\n" + tr("RESTART")
	_l_phase.text = tr("GAME_OVER")
	_sfx.play(Sfx.WIN if won else Sfx.LOSE, -4.0)

# ---------------------------------------------------------------- Azrail

## Blinds escalation (§2.6): 1×3, 2×3, 3×3, 5×3, 8×3, then 13 and
## +5 every round after 15 — the doom clock both sides pay.
func _blind_for(r: int) -> int:
	if r <= 3:
		return 1
	if r <= 6:
		return 2
	if r <= 9:
		return 3
	if r <= 12:
		return 5
	if r <= 15:
		return 8
	return 13 + 5 * (r - 15)

## Azrail psychology feed (§18.2) — every play nudges an axis; the first
## time an axis crosses the taunt threshold he remarks on it.
func _bump(axis: String, amt: float) -> void:
	var before: float = _psyche[axis]
	_psyche[axis] = before + amt
	if before < TAUNT_AT and _psyche[axis] >= TAUNT_AT \
		and not _taunted.has(axis):
		_taunted[axis] = true
		_hint(tr("AZRAIL_" + axis.to_upper()))
		if _devil != null:
			_devil.eyes_flare(0.8)

## Raise (§2.3): stake extra chips into the pot, up to 5 per round.
func raise() -> void:
	if _phase != Phase.PLACE or _raise_used >= RAISE_MAX:
		return
	_raise_used += 1
	_chips_you -= 1
	_pot += 1
	# hint first — a taunt crossing inside _bump must not be clobbered
	_hint(tr("RAISED"))
	_bump("curiosity", 0.5)
	if _devil != null:
		_devil.watch(Vector3(0, _top + 0.04, 0.02), 1.2)
	_sfx.play(Sfx.CHIP_HANDLE, -8.0)
	_pulse(_l_pot)
	_update_chips()

func wager_accept() -> void:
	if not _wager_pending:
		return
	_wager_pending = false
	_wager_offered = true
	_chips_you = 10
	_debt += 15
	_l_over.text = ""
	_phase = Phase.BUSY
	_round += 1
	_start_round()

func wager_decline() -> void:
	if not _wager_pending:
		return
	_wager_pending = false
	_wager_offered = true
	_finish_over(false)

## Call the Bluff (§2.3): once per battle, arm with C then click one of
## his concealed cards. Costs 2 chips into the pot. A counterfeit burns
## and he pays 2; a real card just stands revealed — you bought truth.
func arm_call() -> void:
	if _phase != Phase.PLACE or _bluff_used:
		_hint(tr("HINT_NOCALL"))
		return
	_call_armed = not _call_armed
	_hint(tr("HINT_CALL") if _call_armed else tr("HINT_PLACE"))

func _call_bluff(card) -> void:
	_call_armed = false
	_bluff_used = true
	_chips_you -= 2
	_pot += 2
	if card.def.is_bluff:
		_chips_devil -= 2
		_bump("anger", 0.6)          # caught palming a fake — he hates it
		_board_e.erase(card.lane)
		_area_to_card.erase(card.get_area())
		card.burn()
		_hint(tr("CALL_BLUFF"))
		if _devil != null:
			_devil.eyes_flare(1.0)
			_devil.strike_pose(0.0, true)
	else:
		card.reveal_enemy()
		_bump("curiosity", 0.5)
		_hint(tr("CALL_REAL"))
		if _devil != null:
			_devil.watch(card.position, 1.4)
	_sfx.play(Sfx.CHIP_HANDLE, -8.0)
	_pulse(_l_chips)
	_pulse(_l_pot)
	_update_chips()
	_check_over()

var _tell_t := 0.0
func _process(delta: float) -> void:
	_tell_t += delta
	# §2.3 tells: a concealed card betrays its weight — real violence can't
	# stop trembling; a palmed bluff lies unnaturally still.
	for e in _board_e.values():
		if e.face_down and e.def != null:
			var restless: float = 0.0012 * float(e.def.attack)
			var shiver: float = pow(maxf(0.0,
				sin(_tell_t * 1.6 + e.lane * 2.1)), 8.0)
			e.position = e._base_pos + Vector3(
				restless * shiver * sin(_tell_t * 43.0 + e.lane * 7.0), 0,
				restless * shiver * cos(_tell_t * 37.0))

func mulligan() -> void:
	# §2.3 opening redeal: once per battle, only before the first card lands
	if _mulligan_used or _round > 1 or _placed_this > 0 or _phase != Phase.PLACE:
		_hint(tr("HINT_NOMULL"))
		return
	_mulligan_used = true
	var n := _hand.size()
	for card in _hand:
		_deck.append(card.def)
		_area_to_card.erase(card.get_area())
		card.queue_free()
	_hand.clear()
	_deck.shuffle()
	for i in range(n):
		_draw_hand()
	_bump("boredom", 0.15)   # hesitation bores him
	_hint(tr("MULLIGAN"))
	_sfx.play(Sfx.SHUFFLE, -4.0)

func restart() -> void:
	# one-shot frame signal — a deferred call on the tree gets queued
	# behind the same frame's tail and is swallowed on game-over screens
	get_tree().process_frame.connect(
		func(): get_tree().reload_current_scene(), CONNECT_ONE_SHOT)

# ---------------------------------------------------------------- hud bits

func _update_chips() -> void:
	_l_chips.text = "%s %d   ·   %s %d" % [tr("CHIPS_YOU"), _chips_you,
		tr("CHIPS_DEVIL"), _chips_devil]
	_l_blood.text = "%s %d   ·   %s %d" % [tr("BLOOD"), _blood,
		tr("CARDS_LEFT"), _deck.size()]
	if _debt > 0:
		_l_blood.text += "   ·   %s %d" % [tr("DEBT_LBL"), _debt]
	_l_pot.text = "%s %d" % [tr("POT"), _pot]
	for i in range(_pot_pile.size()):
		_pot_pile[i].visible = i < mini(_pot, _pot_pile.size())

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
	raise()
	_phase = Phase.PLACE
	end_turn_autoplay()

func end_turn_autoplay() -> void:
	_phase = Phase.BUSY
	await _enemy_place()
	_l_phase.text = tr("PHASE_RESOLVING")
	_run_resolution()
