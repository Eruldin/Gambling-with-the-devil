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
const EMBER_CLEANSE := 15      # embers to burn one of his counterfeits
# §7.1 Ev Kuralları — house rules hung over each table
const HOUSE_RULES := ["candle_watch", "open_table", "passage_toll",
	"sabbath", "high_stakes", "blood_price"]

enum Phase { PLACE, BUSY, OVER, EVENT }

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
var _board_p := {}         # front rank: lane -> GameCard (strikes)
var _board_e := {}         # front rank: lane -> GameCard
var _board_pb := {}        # back rank: protected support, never strikes
var _board_eb := {}        # his support rank

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
var _mulligan_used := false
var _repos_armed = null       # board card selected for reposition (§2.3)
var _trick_armed = null       # razor awaiting a pawn target
var _dead_p: Array = []       # player defs that died this battle (Tithe fodder)
var _dead_e: Array = []       # his own casualties — the Gravekeeper feeds them back
var _trump_pool: Array = ["sleeve_ace", "cold_deck", "marked_cards",
	"loaded_dice", "mirrored_coin"]
var _trumps: Array = []
var _luck := 0              # §4.7 hidden meta-stat: −3…+3 tilts every roll
var _loaded_next := false   # Loaded Dice spent — next roll wins
var _mirrored := false      # Mirrored Coin spent — one reroll banked
var _marked_active := false   # Marked Cards: your tells are unreadable
var _l_trumps: Label
var _effigies: Array = []     # mantel objects — passive per-round effects
var _l_effigies: Label    # opening redeal — once per battle
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
var _event_cards: Array = []
# §18 Descent — run state survives the scene reload between tables:
# debt follows you, luck keeps its tilt, carried souls ride in extra.
static var _run := {"depth": 0, "debt": 0, "luck": 0.0, "purse": 0,
	"won": 0, "embers": 0, "wager_used": false, "cleanse": 0,
	"psyche": {}, "taunted": [], "spoils": [], "sin_next": false,
	"sin_idx": 0, "sin_name": "", "broken": [], "grafts": {},
	"pact": false, "confessed": false, "toll": false, "pit_next": false}
var _sin_table := false   # this table is a sin-boss fight (§18 arcs)
var _sin_offered := false # a sin door was dealt at the last event
var _anger_lies := false  # §18.2: carried anger packs his sleeve
var _respect_fair := false # carried respect keeps his sleeve honest
var _cruel_seats := false  # carried cruelty seats an extra ambush
var _bored_ante := false   # carried boredom hurries the blinds
var _pact := false         # the Pact: debt bought louder tells
var _toll := false         # the Tollgate: paid up front, taxes waived
var _rule := ""            # §7.1 the house rule hanging over this table
var _pit_table := false    # §8 the Pit — his last table, rules dropped
var _pit_cheated := false  # his one visible cheat already spent
var _his_loaded := false   # Pit mirror: his next roll wins outright
var _his_mirrored := false # Pit mirror: one lost roll rerolled
var _his_marked := false   # Pit mirror: his tells go unreadable too
var _sin_name := ""       # which of the seven is on the throne
var _sin_idx := -1        # its seat in SIN_NAMES (-1 = no sin table)
var _sin_ante := 0        # Greed's extra tithe per hand
var _hand_cap := HAND_MAX # Lust trims how much you may hold
var _glut_drain := false  # Gluttony feeds on the pot each round
var _sloth_table := false # Sloth slows his plays to one

# ------------------------------------------------- row helpers (§2.2)
## Front rank strikes and answers; the back rank is protected support —
## it never strikes and only takes damage when its lane's front slot is
## empty or the attacker carries the Reach seal.
func _prow(row: int) -> Dictionary:
	return _board_p if row == 0 else _board_pb

func _erow(row: int) -> Dictionary:
	return _board_e if row == 0 else _board_eb

func _all_p() -> Array:
	return _board_p.values() + _board_pb.values()

func _all_e() -> Array:
	return _board_e.values() + _board_eb.values()

func _pad_key(letter: String, lane: int, row: int) -> String:
	return letter + str(lane) + ("b" if row == 1 else "")

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
	_spawn_effigies()
	_deck = CardDef.starter_deck()
	# Envy's table chokes stitched seals — the graft keeps riding in
	# _run but lies dormant while it sits the throne (§18.3)
	var envy := bool(_run["sin_next"]) and int(_run["sin_idx"]) == 3
	# §18 spoils: every table you owned leaves a card in your deck —
	# the pile you carry grows as the Descent does (cap 24)
	for sid in _run["spoils"]:
		if _deck.size() < 24:
			var sd: CardDef = CardDef.spoil(sid)
			if sd != null:
				# §3.5 taxidermy: a grafted seal rides the spoil it was
				# stitched onto — survives the reload like everything else
				var graft: String = str(_run["grafts"].get(sid, ""))
				if graft != "" and not envy and not sd.sigils.has(graft):
					sd.sigils.append(graft)
				_deck.append(sd)
	_edeck = CardDef.devil_deck(_run["depth"])
	# §18 the Confessional: kneeling forgave debt but let him read
	# you deeper — his memory of you carries at 90% this table
	var carry: float = 0.9 if bool(_run["confessed"]) else 0.7
	_run["confessed"] = false
	# Azrail palms counterfeits into his deck — Call the Bluff prey;
	# he palms more of them the deeper the Descent takes you, a
	# drowning debtor makes him greedy, and a carried-over temper
	# makes him cheat: anger crossing the run also packs one more
	# lie into his sleeve (§18: he changes the rules when angry)
	_anger_lies = float(_run["psyche"].get("anger", 0.0)) * carry \
		>= TAUNT_AT
	_respect_fair = float(_run["psyche"].get("respect", 0.0)) * carry \
		>= TAUNT_AT
	for i in range(maxi(2 + mini(_run["depth"], 3)
			+ int(_run["debt"] / 10) + (1 if _anger_lies else 0)
			- (1 if _respect_fair else 0), 0)):
		_edeck.insert(randi() % _edeck.size(), CardDef.bluff_card())
	_deck.shuffle()
	_edeck.shuffle()
	if OS.get_environment("GWD_WIN") == "1":   # probe: instant event phase
		_chips_devil = 1
	_trump_pool.shuffle()
	_trumps = _trump_pool.slice(0, 3)   # §4.6: max 3 held
	_update_trumps()
	# §18: the run carries across tables — debt follows, luck tilts stay,
	# souls won at the last door ride in on top of the fresh pile.
	_debt = _run["debt"]
	_luck = _run["luck"]
	# he remembers — the five axes carry across tables at 70% strength,
	# and a taunt he already said stays said for the whole run
	for axis in _psyche:
		_psyche[axis] = float(_run["psyche"].get(axis, 0.0)) * carry
	for t in _run["taunted"]:
		_taunted[t] = true
	_chips_you += _run["purse"]
	_run["purse"] = 0
	# his soul pile fattens a few chips per door passed — deeper tables,
	# deeper pockets (§18 stakes)
	_chips_devil += mini(_run["depth"] * 3, 15)
	# §18 sin-boss: every third door the table sits a sin on the throne —
	# his pile fattens again and his line sharpens one step deeper
	_sin_table = _run["sin_next"]
	_run["sin_next"] = false
	if _sin_table:
		_chips_devil += 5
		for d in _edeck:
			d.attack += 1
		_sin_name = str(_run["sin_name"])
		_sin_idx = int(_run["sin_idx"])
		# §18.3 the sin on the throne plays by its own rules —
		# the seven are bosses, not just bigger stacks
		match _sin_idx:
			0:   # PRIDE seats a fortune it refuses to guard
				_chips_devil += 10
			1:   # GREED weighs the tithe heavier every hand
				_sin_ante = 3
			2:   # LUST courts your cards away — a smaller grip
				_hand_cap = HAND_MAX - 2
			4:   # GLUTTONY feeds on the pot itself
				_glut_drain = true
			5:   # WRATH sharpens his whole line a second step
				for d in _edeck:
					d.attack += 1
				_chips_devil += 5
			6:   # SLOTH barely stirs — one play, fat pockets
				_sloth_table = true
				_chips_devil += 10
			_:   # ENVY already choked the grafts above
				pass
	_wager_offered = _run["wager_used"]
	# embers spent at the last door burn his counterfeits out of the deck
	for i in range(_run["cleanse"]):
		for j in range(_edeck.size()):
			if _edeck[j].is_bluff:
				_edeck.remove_at(j)
				break
	# §18.2 psyche bends the rules: cruelty carried across tables seats
	# him one extra ambush pawn; boredom walks the ante one step higher
	_cruel_seats = float(_run["psyche"].get("cruelty", 0.0)) * carry \
		>= TAUNT_AT
	_bored_ante = float(_run["psyche"].get("boredom", 0.0)) * carry \
		>= TAUNT_AT
	# §18 Pact: debt bought at the last door makes his tells shout
	# for this whole table — the information you paid for
	_pact = bool(_run["pact"])
	_run["pact"] = false
	# §18 the Tollgate: souls paid up front waive the Descent's
	# depth-tax on every hand of this table
	_toll = bool(_run["toll"])
	_run["toll"] = false
	# §8 the Pit answers a deep door — his pile swells, the rules
	# of the house stop mattering, and he will cheat where you
	# can see it
	_pit_table = bool(_run["pit_next"])
	_run["pit_next"] = false
	if _pit_table:
		_chips_devil += 25
	# §7.1 Ev Kuralları — a house rule hangs over every table and
	# bends its rules for the whole fight; the Descent picks the
	# poison (rotates by depth and tables won)
	_rule = HOUSE_RULES[(_run["depth"] * 2 + _run["won"]) % HOUSE_RULES.size()]
	if _rule == "blood_price":
		# wounds carry between tables — the deck enters battered
		for d in _deck:
			if d.kind == "pawn":
				d.health = maxi(1, int(d.health * 0.75))
	# §18 ambush: from the third door down he's already seated pawns
	# face-down — deeper tables start rigged against you
	var ambush := mini(maxi(_run["depth"] - 2, 0)
		+ (1 if _cruel_seats else 0) + (1 if _sin_idx == 5 else 0),
		4 if _sin_idx == 5 else 3)
	for i in range(ambush):
		var free_l: Array = []
		for l in range(LANES):
			if not _board_e.has(l) or not _board_eb.has(l):
				free_l.append(l)
		if free_l.is_empty() or _edeck.is_empty():
			break
		var lane: int = free_l[randi() % free_l.size()]
		var d: CardDef = _edeck.pop_back()
		var ac := GameCard.new()
		ac.def = d
		add_child(ac)
		ac.setup(load(d.face_file), _back_tex)
		ac.lane = lane
		ac.hp = d.health
		var arow := 0 if not _board_e.has(lane) else 1
		ac.row = arow
		_erow(arow)[lane] = ac
		_area_to_card[ac.get_area()] = ac
		ac.place_on_pad(_pads[_pad_key("e", lane, arow)].position, true)
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
			for row in 2:
				var key := ("e" if side == 0 else "p") + str(lane) \
					+ ("b" if row == 1 else "")
				var pad := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(0.155, 0.003, 0.2 if row == 0 else 0.16)
				pad.mesh = bm
				pad.material_override = (mat_e if side == 0 else mat_p).duplicate()
				# front rank mid-felt; support rank behind it (§2.2)
				var pz: float = -0.115 + side * 0.23 if row == 0 \
					else -0.29 + side * 0.58
				pad.position = Vector3(-0.33 + lane * 0.165, _top + 0.014, pz)
				add_child(pad)
				_pads[key] = pad
				var area := Area3D.new()
				area.collision_layer = 2    # pads own a layer so clicks prefer them
				area.collision_mask = 0
				var col := CollisionShape3D.new()
				var sb := BoxShape3D.new()
				sb.size = Vector3(0.175, 0.02, 0.22 if row == 0 else 0.18)
				col.shape = sb
				area.add_child(col)
				pad.add_child(area)
				_pad_areas[area] = {"enemy": side == 0, "lane": lane,
					"row": row}
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
	_l_trumps = _mk_label(Vector2(16, 112), 13, Color(0.58, 0.46, 0.26))
	_update_trumps()
	_l_effigies = _mk_label(Vector2(16, 134), 13, Color(0.5, 0.32, 0.24))
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

func _update_trumps() -> void:
	var parts: Array[String] = []
	for i in range(_trumps.size()):
		parts.append("[%d] %s" % [i + 1, tr("TRUMP_" + _trumps[i].to_upper())])
	_l_trumps.text = tr("TRUMPS_LBL") + " " + ("  ".join(parts) 		if parts.size() > 0 else "—")

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
	if not _toll:
		ante += _run["depth"]      # the Descent taxes every hand deeper
	if _sin_table:
		ante += 2                  # a sin at the table raises the tithe
	if _bored_ante:
		ante += 1                  # boredom hurries the blinds (§18.2)
	ante += _sin_ante            # Greed's tithe (§18.3)
	if _pit_table:
		ante += 4                  # the Pit bleeds four a hand
	if _rule != "sabbath":
		for e in _effigies:
			if e["id"] == "debtor_bell":
				ante += 1              # the bell tolls — both antes rise
	if _rule == "high_stakes":
		ante *= 2              # Yüksek Bahis — the blinds double
	# High Priestess of Chance: each round she flips — heads +3, tails −1
	# she flips from either rank — sheltered behind a wall she keeps
	# turning the coin (§2.2 back rank is where she belongs)
	for c in _all_p():
		if not c.face_down and c.def != null and c.def.id == "priestess":
			var won := _roll_chance()
			_chips_you += 3 if won else -1
			_burst(c.position + Vector3(0, 0.03, 0),
				Color(1.0, 0.8, 0.2) if won else Color(0.5, 0.1, 0.4),
				14, 0.01, 0.45)
			_hint((tr("PRIESTESS_WON") if won else tr("PRIESTESS_LOST")))
			_sfx.play(Sfx.DICE, -10.0)
	for e in _all_e():
		if not e.face_down and e.def != null and e.def.id == "priestess":
			var devil_won := true if _his_loaded else _roll_chance()
			_his_loaded = false
			if not devil_won and _his_mirrored:
				_his_mirrored = false
				devil_won = _roll_chance()   # the Pit banked his reroll
			_chips_devil += 3 if devil_won else -1
			_burst(e.position + Vector3(0, 0.03, 0),
				Color(1.0, 0.8, 0.2) if devil_won else Color(0.5, 0.1, 0.4),
				14, 0.01, 0.45)
			_hint(tr("PRIESTESS_DEVIL"))
			_sfx.play(Sfx.DICE, -10.0)
	_chips_you -= ante
	_chips_devil -= ante
	_pot += ante * 2
	if _glut_drain and _pot > 0:
		var bite := mini(2, _pot)  # Gluttony eats from the pot (§18.3)
		_pot -= bite
		_chips_devil += bite
	if _rule != "sabbath":
		for e in _effigies:
			if e["id"] == "croupier":
				_chips_you += 1        # the House's hand pays your ante back
	# venom stacks tick — wounded cards rot a little each round
	for side in [_board_p, _board_pb, _board_e, _board_eb]:
		for lane in range(LANES):
			var c = side.get(lane)
			if c != null:
				c.wax_used = false    # waxhide reforms each round
			if c != null and c.venom > 0 and not c.face_down:
				c.hp -= c.venom
				c.flash()
				_burst(c.position + Vector3(0, 0.03, 0),
					Color(0.35, 0.6, 0.15), 10, 0.01, 0.4)
	# §2.2 support: the Deacon blesses its lane's striker once a round —
	# sheltered in the back rank it keeps preaching as long as it lives
	for c in _all_p():
		if not c.face_down and c.def != null and c.def.id == "deacon":
			var f = _board_p.get(c.lane)
			if f != null and f.def != null:
				f.def.attack += 1
				_burst(f.position + Vector3(0, 0.03, 0),
					Color(0.9, 0.75, 0.3), 10, 0.01, 0.4)
	for c in _all_e():
		if not c.face_down and c.def != null and c.def.id == "deacon":
			var f = _board_e.get(c.lane)
			if f != null and f.def != null:
				f.def.attack += 1
				_burst(f.position + Vector3(0, 0.03, 0),
					Color(0.9, 0.75, 0.3), 10, 0.01, 0.4)
	_blood = BLOOD_PER_ROUND
	_raise_used = 0
	_placed_this = 0
	_phase = Phase.PLACE
	if _devil != null:
		_devil.set_mood(_round)
		if _sfx != null:
			_devil._sfx_ref = _sfx
	_draw_hand()
	_l_phase.text = "%s %d  ·  %s %d  ·  %s %d  ·  %s" % [tr("DEPTH"),
		_run["depth"] + 1, tr("ROUND"), _round, tr("BLIND"), ante,
		tr("RULE_" + _rule.to_upper())]
	# §8 the Pit: from the fourth hand he stops pretending — every
	# concealed card you hold turns face-up under his stare, once
	if _pit_table and _round >= 4 and not _pit_cheated:
		_pit_cheated = true
		for c in _all_p():
			if c.face_down:
				c.reveal()
		_hint(tr("PIT_CHEAT"))
		if _devil != null:
			_devil.eyes_flare(1.0)
			_devil.lean_in(0.5)
	# a sin at the table announces itself on the first hand only —
	# the throne name rides the phase line until the fight is done
	if _sin_table and _round == 1:
		_l_phase.text = tr("SIN_GATE") + ": " + _sin_name
		_hint(tr("EV_SIN") + " " + _sin_name
			+ " — " + tr("SIN_RULE_" + str(_sin_idx)))
	elif _pit_table and _round == 1:
		_hint(tr("EV_PIT_TABLE"))
	else:
		_hint(tr("HINT_PLACE_R1") if _round == 1 else tr("HINT_PLACE"))
	_update_chips()
	_sfx.play(Sfx.SHUFFLE, -8.0)
	_check_over()
	# debug: GWD_DOORS=1 jumps straight to the door pick for visual checks
	if _round == 1 and OS.get_environment("GWD_DOORS") == "1":
		_phase = Phase.EVENT
		_spawn_event_cards()

func _draw_hand() -> void:
	if _hand.size() >= _hand_cap:
		return
	if _deck.is_empty():
		# Soul Draw (§2.3): thin decks bleed — 2 chips a card, into the pot.
		_chips_you -= 2
		_pot += 2
		_pulse(_l_pot)
		_update_chips()
		# the first bleed gets his voice — thin decks are his favourite
		_remark("souldraw", "HINT_SOULDRAW")
		return
	if _rule == "passage_toll":
		# §7.1 Geçiş Resmi — every draw pays a chip into the pot
		_chips_you -= 1
		_pot += 1
		_pulse(_l_pot)
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
		pad = null
		if _phase != Phase.EVENT:
			card = null
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
	if pad != null and _selected != null \
		and not _prow(int(pad["row"])).has(pad["lane"]):
		_pad_glow(pad, 0.8)

func click(collider) -> void:
	if _phase == Phase.EVENT:
		var door = _area_to_card.get(collider)
		if door != null and _event_cards.has(door):
			_resolve_event(door)
		return
	if _phase != Phase.PLACE or _autoplay:
		return
	var card = _area_to_card.get(collider)
	if _call_armed:
		if card != null and card.placed and card.face_down \
			and _all_e().has(card):
			if card.def != null and "veil" in card.def.sigils:
				# §3.3 Veil: a veiled card can't be Called
				_hint(tr("HINT_VEIL"))
				_sfx.play(Sfx.DENIED, -10.0)
			else:
				_call_bluff(card)
		else:
			_hint(tr("HINT_CALL"))
		return
	var pad = _pad_areas.get(collider)
	# armed-trick target mode — one revealed pawn of yours takes it
	if _trick_armed != null:
		if card != null and _board_p.values().has(card) \
			and not card.face_down:
			match _trick_armed.def.id:
				"salt_circle":
					_resolve_salt(card)
				"grave_candle":
					_resolve_candle(card)
				_:
					_resolve_razor(card)
		else:
			_trick_cancel()
		return
	# reposition armed — an empty lane takes the card, another card swaps
	if _repos_armed != null:
		if pad != null and not pad["enemy"] \
			and not _prow(int(pad["row"])).has(pad["lane"]):
			_do_repos(pad["lane"], int(pad["row"]))
		elif card != null and _board_p.values().has(card) 			and card != _repos_armed and not card.face_down:
			_swap_lanes(_repos_armed, card)
		else:
			_repos_cancel()
		return
	if card != null and _hand.has(card):
		if card.def.kind == "trick":
			_play_trick(card)
		else:
			_select(card if card != _selected else null)
		return
	# a revealed pawn on the board can be picked up for reposition
	if card != null and card.placed and _all_p().has(card):
		if card.face_down:
			_hint(tr("HINT_REPOS_DOWN"))
		elif card.moved_once:
			_hint(tr("HINT_NOREPOS"))
		elif "anchor" in card.def.sigils:
			# §3.3 Anchor: rooted — no reposition, no swap
			_hint(tr("HINT_ANCHOR"))
			_sfx.play(Sfx.DENIED, -10.0)
		else:
			_repos_arm(card)
		return
	if pad != null and not pad["enemy"] and _selected != null:
		_try_place(pad["lane"], int(pad["row"]))

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

func _try_place(lane: int, row := 0) -> void:
	var card = _selected
	if _prow(row).has(lane):
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
	card.row = row
	card.hp = card.def.health
	_prow(row)[lane] = card
	var dest: Vector3 = _pads[_pad_key("p", lane, row)].position \
		+ Vector3(0, 0.002, 0)
	var rot := Vector3(PI, 0, PI * randf() * 0.06)
	card.placed = true
	card.set_face_down(_rule != "open_table")
	if _phand != null and not _autoplay:
		card.set_base(dest, rot)
		await _phand.pick_and_place(card, dest, rot)
		card.scale = Vector3.ONE * 0.72
	else:
		card.place_on_pad(_pads[_pad_key("p", lane, row)].position, false)
	if _rule == "open_table":
		# Açık Masa — everything lands face-up; on-reveal seals fire now
		_on_reveal(card, _board_e.get(lane))
	if "tithe" in card.def.sigils:
		_chips_you += 2
		_pulse(_l_chips)
		_burst(card.position + Vector3(0, 0.03, 0),
			Color(1.0, 0.7, 0.25), 12, 0.01, 0.4)
	if card.def.id == "owed_pig":
		# doc §6 Ahdili Domuz — the wall binds you deeper the moment
		# it hits the felt, whichever side played it
		_debt += 3
		_remark("owed_pig", "HINT_OWED_PIG")
	_reflow_hand()
	_update_chips()
	_hint(tr("HINT_PLACE_MORE"))
	# §18.2 he recognizes faces at his own table — one remark per
	# soul, remembered for the run; a spent key leaves the hint alone
	match card.def.id:
		"reaper":
			_remark("c_reaper")
		"priestess":
			_remark("c_priestess")
		"usurer":
			_remark("c_usurer")
		"martyr":
			_remark("c_martyr")
		"mirror_hound":
			_remark("c_hound")
		"bluffer":
			_remark("c_bluffer")
	_sfx.play(Sfx.PLACE_P, -6.0)

func _sacrifice_card(card) -> void:
	if _rule == "candle_watch":
		# §7.1 Mum Nöbeti — no blood may be drawn at this table
		_hint(tr("HINT_RULE_CANDLE"))
		return
	_hand.erase(card)
	_area_to_card.erase(card.get_area())
	if card == _selected:
		_select(null)
	_blood += card.def.sacrifice_value \
		+ (1 if "shell" in card.def.sigils else 0)  # §3.3 Shell: thicker offering
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
	_hint("%s +%d %s" % [tr("SACRIFICED"), card.def.sacrifice_value \
		+ (1 if "shell" in card.def.sigils else 0), tr("BLOOD")])
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
	# §2.2: a lane counts as free while either of its ranks is open —
	# he can tuck a support pawn behind a wall of his own
	var free_lanes: Array = []
	for lane in range(LANES):
		if not _board_e.has(lane) or not _board_eb.has(lane):
			free_lanes.append(lane)
	var peek: CardDef = _edeck.back() if not _edeck.is_empty() else null

	free_lanes.sort_custom(func(a: int, b: int) -> bool:
		return _lane_score(a, peek) > _lane_score(b, peek))
	# a bored devil presses the attack — more bodies on the felt
	var want := randi_range(1, 1 if _sloth_table
		else (2 if _psyche["boredom"] < TAUNT_AT else 3))
	for i in range(mini(want, free_lanes.size())):
		if _edeck.is_empty():
			break
		var lane: int = free_lanes[i]

		var d: CardDef = _edeck.pop_back()
		if d.kind == "trick":
			_resolve_his_trick(d)
			continue
		var card := GameCard.new()
		card.def = d
		add_child(card)
		card.setup(load(d.face_file), _back_tex)
		card.position = Vector3(-0.44, _top + 0.15, -0.14)
		card.rotation = Vector3(PI, 0, 0)
		card.lane = lane
		card.hp = d.health
		# §2.2: 0-attack supports shelter in the back rank; everything
		# else takes the front. Fall back to whichever rank is open.
		var row := 1 if (d.attack == 0 and not _board_eb.has(lane)) else 0
		if _erow(row).has(lane):
			row = 1 - row
		if _erow(row).has(lane):
			continue
		card.row = row
		_erow(row)[lane] = card
		_area_to_card[card.get_area()] = card
		var dest: Vector3 = _pads[_pad_key("e", lane, row)].position \
			+ Vector3(0, 0.002, 0)
		var rot := Vector3(PI, 0, PI * randf() * 0.06)
		if _devil != null and not _autoplay:
			card.placed = true
			card.set_face_down(_rule != "open_table")
			card.scale = Vector3.ONE * 0.72
			card.set_base(dest, rot)
			await _devil.play_card(card, dest, rot)
		else:
			card.place_on_pad(_pads[_pad_key("e", lane, row)].position, true)
		if _rule == "open_table":
			_on_reveal_his(card, _board_p.get(lane))
		if card.def.id == "owed_pig":
			_debt += 3    # his pig feeds the same ledger
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
	var guessed: bool = (_psyche["respect"] >= TAUNT_AT 		or _marked_active) and p.face_down
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
		# reveal both ranks, staggered — support cards flip with the rest
		for p in [_board_p.get(lane), _board_pb.get(lane)]:
			if p != null and p.face_down:
				p.reveal()
				_on_reveal(p, _board_e.get(lane))
				_burst(p.position + Vector3(0, 0.03, 0),
					Color(0.16, 0.14, 0.11), 14, 0.02, 0.8)
		for e in [_board_e.get(lane), _board_eb.get(lane)]:
			if e != null and e.face_down:
				e.reveal_enemy()
				_on_reveal_his(e, _board_p.get(lane))
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
		# §3.3: clashes are simultaneous — a defender answers even in
		# death, unless the attacker's Sharp seal slew it first
		var e_answer: bool = e != null and not e.face_down \
			and e.def != null and e.hp > 0 and e.def.attack > 0 \
			and not "bulwark" in e.def.sigils \
			and not (p != null and p.def != null \
				and "bulwark" in p.def.sigils)
		var sharp_kill := false
		if p != null and not p.face_down and p.def.attack > 0 \
			and p.hp > 0:
			# §2.2/§3.3: the back rank is shielded by its own front card;
			# only Reach lets a strike bypass the wall
			var tgt = _board_eb.get(lane) if (
				"reach" in p.def.sigils and _board_eb.get(lane) != null) \
				else e
			if tgt == null:
				tgt = _board_eb.get(lane)
			p.lunge(_pads[_pad_key("e", lane,
				1 if tgt == _board_eb.get(lane) else 0)].position)
			if tgt != null and not tgt.face_down:
				var e2 = tgt
				var atk: float = float(p.def.attack) + (3.0 \
					if "executioner" in p.def.sigils \
						and e2.hp < float(e2.def.health) else 0.0)
				# §3.3 Waxhide: shrugs off the first wound each round
				if "waxhide" in e2.def.sigils and not e2.wax_used \
					and atk > 0:
					e2.wax_used = true
					atk = 0.0
				var hp_before: float = e2.hp
				e2.hp -= atk
				if "pierce" in p.def.sigils and e2.hp <= 0:
					var over: float = atk - hp_before
					if over > 0.0:
						_chips_devil -= int(over)
						_pot += int(over)
						_pulse(_l_pot)
				if "venom" in p.def.sigils and e2.hp > 0:
					e2.venom = mini(e2.venom + 1, 3)
				if e2.hp <= 0:
					_bump("respect", 0.4)   # a clean kill earns a nod
					# Sharp only silences the front rank — a back-rank
					# target never earned an answer anyway
					sharp_kill = "sharp" in p.def.sigils and tgt == e
					if p.def.id == "choir_leech":
						# doc §6 Koro Sülüğü — every clash it joins sips
						# one chip back into your pile
						_chips_you += 1
						_pulse(_l_chips)
				e2.flash()
				_burst(e2.position + Vector3(0, 0.03, 0),
					Color(1.0, 0.5, 0.12), 18, 0.01, 0.4)
				# §3.3 Frenzied: a kill buys a second blow at −2 attack —
				# the dying card is gone, so the follow-through takes the
				# rank behind it, or the pot if the lane stands empty
				if e2.hp <= 0 and "frenzied" in p.def.sigils:
					var fatk: float = maxf(float(p.def.attack) - 2.0, 0.0)
					var tgt2 = _board_eb.get(lane) if e2 == e else e
					if fatk > 0.0:
						if tgt2 != null and not tgt2.face_down:
							p.lunge(_pads[_pad_key("e", lane,
								1 if tgt2 == _board_eb.get(lane) else 0)].position)
							if "waxhide" in tgt2.def.sigils \
								and not tgt2.wax_used:
								tgt2.wax_used = true
								fatk = 0.0
							tgt2.hp -= fatk
							if "venom" in p.def.sigils and tgt2.hp > 0:
								tgt2.venom = mini(tgt2.venom + 1, 3)
							tgt2.flash()
							_burst(tgt2.position + Vector3(0, 0.03, 0),
								Color(1.0, 0.5, 0.12), 14, 0.01, 0.35)
							if tgt2.hp <= 0:
								_bump("respect", 0.3)
						else:
							p.lunge(_pads["e" + str(lane)].position)
							_chips_devil -= int(fatk)
							_pot += int(fatk)
							_pulse(_l_chips)
							_shake(0.018)
							_sfx.play(Sfx.CHIP_HIT, -6.0)
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
		if e != null and not e.face_down and e.def != null and e_answer \
			and not sharp_kill:
			# §2.2 symmetric: his Reach slips past your wall; an empty
			# front leaves your back rank exposed
			var pb = _board_pb.get(lane)
			var ptgt = pb if ("reach" in e.def.sigils and pb != null) \
				else (p if p != null else pb)
			e.lunge(_pads[_pad_key("p", lane,
				1 if ptgt == pb else 0)].position)
			if ptgt != null and not ptgt.face_down:
				var eatk: float = float(e.def.attack) + (3.0 \
					if "executioner" in e.def.sigils \
						and ptgt.hp < float(ptgt.def.health) else 0.0)
				if "waxhide" in ptgt.def.sigils and not ptgt.wax_used \
					and eatk > 0:
					ptgt.wax_used = true
					eatk = 0.0
				var php_before: float = ptgt.hp
				ptgt.hp -= eatk
				if "pierce" in e.def.sigils and ptgt.hp <= 0:
					var eover: float = eatk - php_before
					if eover > 0.0:
						_chips_you -= int(eover)
						_pot += int(eover)
						_pulse(_l_pot)
				if "venom" in e.def.sigils and ptgt.hp > 0:
					ptgt.venom = mini(ptgt.venom + 1, 3)
				ptgt.flash()
				_burst(ptgt.position + Vector3(0, 0.03, 0),
					Color(1.0, 0.5, 0.12), 18, 0.01, 0.4)
				if e.def.id == "choir_leech":
					_chips_devil += 1   # his leech drinks for his pile
					_pulse(_l_chips)
				# §3.3 Frenzied — his killers press on too
				if ptgt.hp <= 0 and "frenzied" in e.def.sigils:
					var fatk2: float = maxf(float(e.def.attack) - 2.0, 0.0)
					var ptgt2 = _board_pb.get(lane) if ptgt == p else p
					if fatk2 > 0.0:
						if ptgt2 != null and not ptgt2.face_down:
							e.lunge(_pads[_pad_key("p", lane,
								1 if ptgt2 == _board_pb.get(lane) else 0)].position)
							if "waxhide" in ptgt2.def.sigils \
								and not ptgt2.wax_used:
								ptgt2.wax_used = true
								fatk2 = 0.0
							ptgt2.hp -= fatk2
							if "venom" in e.def.sigils and ptgt2.hp > 0:
								ptgt2.venom = mini(ptgt2.venom + 1, 3)
							ptgt2.flash()
							_burst(ptgt2.position + Vector3(0, 0.03, 0),
								Color(1.0, 0.5, 0.12), 14, 0.01, 0.35)
						else:
							e.lunge(_pads["p" + str(lane)].position)
							_chips_you -= int(fatk2)
							_pot += int(fatk2)
							_pulse(_l_chips)
							_shake(0.018)
							_sfx.play(Sfx.CHIP_HIT, -6.0, 0.85)
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
		for row in 2:   # front rank, then the support rank behind it
			var p = _prow(row).get(lane)
			if p != null and p.hp <= 0:
				_prow(row).erase(lane)
				_area_to_card.erase(p.get_area())
				var e_killer = _board_e.get(lane)
				if "haunt" in p.def.sigils and e_killer != null:
					e_killer.def.attack = maxi(0, e_killer.def.attack - 1)
					_burst(e_killer.position + Vector3(0, 0.03, 0),
						Color(0.4, 0.1, 0.5), 12, 0.01, 0.5)
				if "revival" in p.def.sigils and not p.revived:
					p.revived = true
					_dead_to_hand(p.def)
				elif "brood" in p.def.sigils:
					_dead_p.append(p.def)
					_spawn_grub(lane, true, row)
				else:
					_dead_p.append(p.def)
				p.die()
				# the Gravedigger feeds — every friendly corpse in its
				# lane sharpens its shovel
				for c in _all_p():
					if c.lane == lane and c.def != null \
						and c.def.id == "gravedigger" and c.hp > 0:
						c.def.attack += 1
						c.flash()
			var e = _erow(row).get(lane)
			if e != null and e.hp <= 0:
				_erow(row).erase(lane)
				_area_to_card.erase(e.get_area())
				var p_killer = _board_p.get(lane)
				if "haunt" in e.def.sigils and p_killer != null:
					p_killer.def.attack = maxi(0, p_killer.def.attack - 1)
					_burst(p_killer.position + Vector3(0, 0.03, 0),
						Color(0.4, 0.1, 0.5), 12, 0.01, 0.5)
				elif "brood" in e.def.sigils:
					_spawn_grub(lane, false, row)
				else:
					_dead_e.append(e.def)
				e.die()
				for c in _all_e():
					if c.lane == lane and c.def != null \
						and c.def.id == "gravedigger" and c.hp > 0:
						c.def.attack += 1
						c.flash()

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
	_wager_pending = false
	if _devil != null:
		if won:
			_devil.defeat()
		else:
			_devil.victory()
	if won:
		# §18: a won table opens the Descent — three doors drop on
		# the felt and the run continues a chamber deeper.
		_phase = Phase.EVENT
		_run["won"] += 1
		var emb: int = _pot * (2 if _rule == "high_stakes" else 1)
		_run["embers"] += emb
		# §2.4: the pot converts to embers (doubled at High Stakes)
		if _sin_table:
			# beating a sin pays its own tithe on top of the pot
			_run["embers"] += 10
			_l_over.text = tr("YOU_WIN") + " " + tr("SIN_BEATEN") + "\n" \
				+ str(emb + 10) + " " + tr("EMBERS_WON")
		else:
			_l_over.text = tr("YOU_WIN") + "\n" + str(emb) + " " \
				+ tr("EMBERS_WON")
		_run["debt"] = _debt
		_run["luck"] = _luck
		_run["psyche"] = _psyche.duplicate()
		_run["taunted"] = _taunted.keys()
		var spoil_ids: Array = CardDef.spoil_ids()
		_run["spoils"].append(spoil_ids[randi() % spoil_ids.size()])
		_l_phase.text = tr("GAME_OVER")
		_sfx.play(Sfx.CHIP_STACK, -6.0)   # the pot counts itself out
		_sfx.play(Sfx.WIN, -4.0)
		_hint(tr("HINT_EVENT") + (" " + tr("HINT_EMBER")
			if _run["embers"] >= EMBER_CLEANSE else ""))
		_spawn_event_cards()
		if _autoplay:
			await get_tree().create_timer(1.6).timeout
			_resolve_event(_event_cards[randi() % _event_cards.size()])
		return
	_phase = Phase.OVER
	# the run's epitaph — what the Descent gave you before it took you
	var epitaph := "%s %d · %s %d" % [tr("EP_TABLES"), _run["won"],
		tr("EP_DEPTH"), _run["depth"] + 1]
	if _run["embers"] > 0:
		epitaph += " · %d %s" % [_run["embers"], tr("EMBERS_LBL")]
	_reset_run()
	_l_over.text = tr("DEVIL_WINS")
	_l_over.text += "\n" + epitaph
	if _debt > 0:
		_l_over.text += "\n" + tr("DEBT_LBL") + " " + str(_debt)
	_l_over.text += "\n" + tr("RESTART")
	_l_phase.text = tr("GAME_OVER")
	_sfx.play(Sfx.LOSE, -4.0)

func _reset_run() -> void:
	for k in _run:
		_run[k] = false if ["wager_used", "sin_next"].has(k) else 0
	_run["luck"] = 0.0
	_run["psyche"] = {}
	_run["taunted"] = []
	_run["spoils"] = []
	_run["sin_name"] = ""
	_run["broken"] = []
	_run["grafts"] = {}
	_run["pact"] = false
	_run["confessed"] = false
	_run["toll"] = false

# ------------------------------------------------------------ descent (§18)

## Three door cards drop face-up on the felt — the Whisper (small
## gamble), the Wheel (big gamble), the Covenant (safe passage).
func _spawn_event_cards() -> void:
	_sfx.play(Sfx.PACK_OPEN, -8.0)      # the doors fan open on the felt
	# §18 event-template pool: doors dealt depend on how deep the run
	# has gone — the Ledger and the Mirror only open deeper down.
	var faces := {
		"event_whisper": "face_seer.png", "event_wheel": "face_imp.png",
		"event_covenant": "face_warden.png", "event_ledger": "face_usurer.png",
		"event_mirror": "face_acolyte.png", "event_furnace": "face_furnace.png",
		"event_taxidermist": "face_taxidermist.png", "event_pact": "face_votary.png",
		"event_confessor": "face_confessor.png",
		"event_toll": "face_tollgate.png", "event_reliquary": "face_reliquary.png",
		"event_pit": "face_pit.png"}
	faces["event_sin"] = "face_reaper.png"
	var pool: Array = ["event_whisper", "event_wheel", "event_covenant"]
	if _run["depth"] >= 1:
		pool.append("event_ledger")
		pool.append("event_toll")
	if _run["depth"] >= 2:
		pool.append("event_furnace")
		pool.append("event_confessor")
	if _run["depth"] >= 3:
		pool.append("event_mirror")
		pool.append("event_reliquary")
	if _run["depth"] >= 4:
		pool.append("event_taxidermist")
		pool.append("event_pact")
	if _run["depth"] >= 5:
		pool.append("event_pit")        # §8: the Pit can answer the deep doors
	pool.shuffle()
	# every third descent the sin door is dealt — you may walk around
	# it, but Azrail marks the cowardice (§18: bosses at depths 3,6,9)
	_sin_offered = ((_run["depth"] + 1) % 3) == 0
	var defs: Array = []
	for i in range(3):
		var id: String = pool[i]
		if _sin_offered and i == 0:
			id = "event_sin"
		defs.append(CardDef.make(id, "eyes", 0, 0, 1, 0,
			"res://assets_external/card-art/gwd/" + faces[id]))
	for i in range(3):
		var card := GameCard.new()
		card.def = defs[i]
		add_child(card)
		card.setup(load(defs[i].face_file), _back_tex)
		# §18 the doors rise from the felt standing — tall slabs
		# facing the player, not cards lying flat on the table
		var pos := Vector3(-0.19 + i * 0.19, _top + 0.082, -0.02)
		card.position = pos + Vector3(0, 0.5, 0)
		card.scale = Vector3.ONE * 0.001
		_area_to_card[card.get_area()] = card
		_event_cards.append(card)
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.14 * i)
		tw.tween_property(card, "position", pos, 0.55)
		tw.parallel().tween_property(card, "scale",
			Vector3(1.0, 1.35, 1.0), 0.55)
		card.set_base(pos, Vector3(PI * 0.5, 0, 0))
	if _devil != null:
		_devil.watch(Vector3(0, _top + 0.05, 0.03), 1.4)
	# §18 Azrail event: at the doors he speaks to the strongest thing
	# he has learned about you — once per axis per run, run-wide memory
	var top_axis := ""
	var top_val := TAUNT_AT
	for axis in _psyche:
		if _psyche[axis] > top_val and not _taunted.has("door_" + axis):
			top_axis = axis
			top_val = _psyche[axis]
	if top_axis != "":
		_taunted["door_" + top_axis] = true
		_run["taunted"] = _taunted.keys()
		await get_tree().create_timer(1.0).timeout
		if _phase == Phase.EVENT:   # a fast pick already resolved it
			_hint(tr("DOOR_" + top_axis.to_upper()))
			if _devil != null:
				_devil.eyes_flare(0.7)

func _resolve_event(card) -> void:
	_phase = Phase.BUSY
	for c in _event_cards:
		if c != card:
			c.burn()
	card.flash(Color(0.9, 0.7, 0.2))
	# walking around a dealt sin door reads as cowardice — he notes it
	if _sin_offered and card.def.id != "event_sin":
		_psyche["cruelty"] = minf(_psyche["cruelty"] + 0.2, 3.0)
	# §18.4: a spoil soul in your deck can snap the door's harm — once
	# per event kind per run. "I kept this card for this."
	var breaker_id := CardDef.breaker_of(card.def.id)
	var broken: bool = breaker_id != "" and _run["spoils"].has(breaker_id) \
		and not _run["broken"].has(card.def.id)
	if broken:
		_run["broken"].append(card.def.id)
	var gamble: bool = ["event_whisper", "event_wheel"].has(card.def.id)
	var won_roll := true
	if gamble:
		won_roll = _roll_chance()
	match card.def.id:
		"event_whisper":
			if won_roll:
				_run["luck"] = minf(_run["luck"] + 0.5, 3.0)
				_hint(tr("EV_WHISPER_WIN"))
			elif broken:
				_hint(tr("EV_BROKEN") + " " + tr("CARD_" + breaker_id.to_upper()))
			else:
				_run["debt"] += 6
				_hint(tr("EV_WHISPER_LOSE"))
		"event_wheel":
			if won_roll:
				_run["purse"] += 12
				_hint(tr("EV_WHEEL_WIN"))
			elif broken:
				_hint(tr("EV_BROKEN") + " " + tr("CARD_" + breaker_id.to_upper()))
			else:
				_run["debt"] += 10
				_hint(tr("EV_WHEEL_LOSE"))
		"event_ledger":
			# the Usurer's ledger — pay souls now to strike the debt;
			# a Reaper in your pile collects it for free instead
			_run["debt"] = maxi(_run["debt"] - 5, 0)
			if broken:
				_hint(tr("EV_BROKEN") + " " + tr("CARD_" + breaker_id.to_upper()))
			else:
				_run["purse"] = maxi(_run["purse"] - 4, 0)
				_hint(tr("EV_LEDGER"))
		"event_mirror":
			# his mirror flips your fortune — lucky becomes cursed,
			# cursed becomes blessed (§4.7 tilts invert)
			if broken:
				_hint(tr("EV_BROKEN") + " " + tr("CARD_" + breaker_id.to_upper()))
			else:
				_run["luck"] = -_run["luck"]
				_hint(tr("EV_MIRROR"))
		"event_furnace":
			# §3.4 the Furnace: it eats two of your spoils and coughs up
			# one fused monstrosity — or, empty-handed, just warms you
			if _run["spoils"].size() >= 2:
				_run["spoils"].pop_back()
				_run["spoils"].pop_back()
				_run["spoils"].append("fused_abomination")
				_hint(tr("EV_FURNACE"))
			else:
				_run["purse"] += 3
				_hint(tr("EV_FURNACE_COLD"))
		"event_taxidermist":
			# §3.5 the Taxidermist: he stitches a spare seal onto your
			# newest spoil — venom, haunt, mimic, pierce, revival,
			# executioner — whatever the back room yields
			if not _run["spoils"].is_empty():
				var tgt: String = str(_run["spoils"][_run["spoils"].size() - 1])
				var tgt_def: CardDef = CardDef.spoil(tgt)
				var graft_pool: Array = ["venom", "haunt", "mimic",
					"pierce", "revival", "executioner", "sharp", "reach",
				"waxhide", "shell", "veil", "anchor", "pot_cut",
				"eyecorner", "frenzied", "bulwark"]
				if tgt_def != null:
					for s in tgt_def.sigils:
						graft_pool.erase(s)
				if graft_pool.is_empty():
					_run["purse"] += 3
					_hint(tr("EV_TAXI_FULL"))
				else:
					var g: String = str(graft_pool[randi() % graft_pool.size()])
					_run["grafts"][tgt] = g
					_hint(tr("EV_TAXI") + " " + tr("SIGIL_" + g.to_upper()))
			else:
				_run["purse"] += 3
				_hint(tr("EV_TAXI_EMPTY"))
		"event_pact":
			# §18 the Pact: souls now for information next table —
			# his concealed cards shout their weight twice as loud
			_run["debt"] += 8
			_run["pact"] = true
			_hint(tr("EV_PACT"))
		"event_confessor":
			# §18 the Confessional: he absolves a little debt — but
			# kneeling lets him read you deeper; next table his
			# memory of you carries at 90% instead of 70%
			_run["debt"] = maxi(int(_run["debt"]) - 3, 0)
			_run["confessed"] = true
			_hint(tr("EV_CONFESS"))
		"event_toll":
			# §18 the Tollgate: owe him four souls now — pass the
			# next table without the Descent's depth-tax on your antes
			_run["debt"] += 4
			_run["toll"] = true
			_hint(tr("EV_TOLL"))
		"event_reliquary":
			# §18 the Reliquary: a forgotten soul waits in its niche —
			# it joins your spoils without a fight
			var sids: Array = CardDef.spoil_ids()
			var gift: String = str(sids[randi() % sids.size()])
			_run["spoils"].append(gift)
			_hint(tr("EV_RELIC") + " "
				+ tr(CardDef.spoil(gift).name_key))
		"event_pit":
			# §8 the Pit: the next table is his — rules dropped, trumps
			# mirrored, one visible cheat guaranteed
			_run["pit_next"] = true
			_hint(tr("EV_PIT"))
		"event_sin":
			# the sin door: the next table seats one of the seven
			_run["sin_next"] = true
			var sins: Array = tr("SIN_NAMES").split(",")
			_run["sin_idx"] = (_run["won"] / 3) % sins.size()
			_run["sin_name"] = sins[int(_run["sin_idx"])].strip_edges()
			_hint(tr("EV_SIN") + " " + str(_run["sin_name"]))
		_:
			_run["purse"] += 5
			_run["luck"] = minf(_run["luck"] + 0.2, 3.0)
			_hint(tr("EV_COVENANT"))
	_sfx.play(Sfx.WIN if won_roll else Sfx.LOSE, -12.0)
	if _devil != null:
		_devil.watch(card.position, 1.2)
	_descend()

## At the door, embers buy a cleaner deck — 15 burns one counterfeit
## he would have palmed into the next hand (§18: the house can be cheated).
func spend_embers() -> void:
	if _phase != Phase.EVENT or _run["embers"] < EMBER_CLEANSE:
		return
	_run["embers"] -= EMBER_CLEANSE
	_run["cleanse"] += 1
	_hint(tr("EMBER_SPENT"))
	_update_chips()

func _descend() -> void:
	_run["depth"] += 1
	await get_tree().create_timer(1.8).timeout
	get_tree().reload_current_scene()

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
	# §18.2: push the same axis twice as far and he remarks again —
	# a second, deeper line that only long tables ever hear
	elif before < TAUNT_AT * 2.0 and _psyche[axis] >= TAUNT_AT * 2.0 \
		and not _taunted.has(axis + "_2"):
		_taunted[axis + "_2"] = true
		_hint(tr("AZRAIL_" + axis.to_upper() + "_2"))
		if _devil != null:
			_devil.eyes_flare(1.0)
		# §18.2: the first time his temper crosses he cheats openly —
		# reaches across and burns a card straight out of your hand
		if axis == "anger" and _phase == Phase.PLACE \
			and not _hand.is_empty() and not _taunted.has("anger_stole"):
			_taunted["anger_stole"] = true
			var stolen = _hand[randi() % _hand.size()]
			_hand.erase(stolen)
			_area_to_card.erase(stolen.get_area())
			stolen.burn()
			_reflow_hand()
			_hint(tr("ANGER_STEAL"))

## §18.2 situational remarks — one spoken line per named moment, kept for
## the whole run so he never repeats himself. A key already spent falls
## back to the generic line instead of silence.
func _remark(key: String, fallback := "") -> void:
	if _taunted.has(key):
		if fallback != "":
			_hint(tr(fallback))
		return
	_taunted[key] = true
	_hint(tr("AZRAIL_" + key.to_upper()))
	if _devil != null:
		_devil.eyes_flare(0.6)

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
	_sfx.play(Sfx.CHIP_LAY, -8.0)
	_pulse(_l_pot)
	_update_chips()
	if _pot >= 30:
		# the first truly fat pot gets a remark — he appreciates the stakes
		_remark("big_pot")

func wager_accept() -> void:
	if not _wager_pending:
		return
	_wager_pending = false
	_wager_offered = true
	_run["wager_used"] = true   # one bargain per run — even across tables
	_chips_you = 10
	_debt += 15
	_l_over.text = ""
	_phase = Phase.BUSY
	_round += 1
	_start_round()
	_remark("wager_yes")

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
		_erow(card.row).erase(card.lane)
		_area_to_card.erase(card.get_area())
		card.burn()
		_remark("bluff_caught", "CALL_BLUFF")
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
	for e in _all_e():
		# the Pit's mirrored Marked Cards silences his tells too
		if e.face_down and e.def != null and not _his_marked:
			var restless: float = 0.0012 * float(e.def.attack) * (
				2.5 if _pact else 1.0)
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
	_sfx.play(Sfx.TAKE_OUT, -8.0)   # he sweeps the hand back first
	_redeal()
	_bump("boredom", 0.15)   # hesitation bores him
	_remark("mulligan", "MULLIGAN")

func _redeal() -> void:
	var n := _hand.size()
	for card in _hand:
		_deck.append(card.def)
		_area_to_card.erase(card.get_area())
		card.queue_free()
	_hand.clear()
	_deck.shuffle()
	for i in range(n):
		_draw_hand()
	_sfx.play(Sfx.SHUFFLE, -4.0)

## §4.6 Trumps — consumable cheats, keys 1..3, max 3 held.
## He always notices a cheat: every trump feeds his Anger.
func use_trump(idx: int) -> void:
	if _phase != Phase.PLACE and _phase != Phase.BUSY:
		return
	if idx < 0 or idx >= _trumps.size():
		_hint(tr("TRUMPS_EMPTY"))
		_sfx.play(Sfx.DENIED, -10.0)
		return
	var id: String = _trumps[idx]
	match id:
		"sleeve_ace":
			var any := false
			for e in _all_e():
				if e.face_down:
					any = true
					e.reveal_enemy()
					_peek_rehide(e)
			if not any:
				_hint(tr("TRUMP_NOPEEK"))
				_sfx.play(Sfx.DENIED, -10.0)
				return
			_hint(tr("TRUMP_PEEKED"))
			_sfx.play(Sfx.FAN, -8.0)
		"cold_deck":
			_redeal()
			_hint(tr("TRUMP_COLD"))
		"marked_cards":
			_marked_active = true
			_hint(tr("TRUMP_MARKED"))
			_sfx.play(Sfx.SLIDE, -10.0)
		"loaded_dice":
			_loaded_next = true
			_hint(tr("TRUMP_LOADED"))
			_sfx.play(Sfx.DICE, -6.0)
		"mirrored_coin":
			_mirrored = true
			_hint(tr("TRUMP_MIRRORED"))
			_sfx.play(Sfx.GLASS, -8.0)
	if _pit_table:
		_mirror_trump(id)
	_trumps.remove_at(idx)
	_update_trumps()
	_bump("anger", 0.35)      # §4.7 — he always notices a cheat
	_sfx.play(Sfx.CHIP_HANDLE, -8.0)

## §8 the Pit: at his last table every trump you palm comes back
## mirrored — the same cheat, pointed at you
func _mirror_trump(id: String) -> void:
	match id:
		"sleeve_ace":
			# he gets the peek too — one of your concealed cards, read
			var hidden := []
			for c in _all_p():
				if c.face_down:
					hidden.append(c)
			if not hidden.is_empty():
				hidden[randi() % hidden.size()].peeked = true
		"cold_deck":
			# a redeal pointed at you: your concealed cards swap lanes
			var mine := []
			for c in _all_p():
				if c.face_down:
					mine.append(c)
			if mine.size() >= 2:
				var spots := []
				for c in mine:
					_prow(c.row).erase(c.lane)
					spots.append([c.lane, c.row])
				spots.shuffle()
				for i in range(mine.size()):
					var c = mine[i]
					c.lane = int(spots[i][0])
					c.row = int(spots[i][1])
					_prow(c.row)[c.lane] = c
					c.position = _pads[_pad_key("p", c.lane,
						c.row)].position + Vector3(0, 0.002, 0)
		"marked_cards":
			_his_marked = true    # his tells go quiet too
		"loaded_dice":
			_his_loaded = true    # his next roll wins outright
		"mirrored_coin":
			_his_mirrored = true  # he banks a reroll as well
	_hint(tr("TRUMP_MIRRORED_PIT"))

func _peek_rehide(card) -> void:
	# the peek lasts a breath — then the card lies down again
	await get_tree().create_timer(2.6).timeout
	if is_instance_valid(card) and card.placed \
		and _all_e().has(card) and not card.face_down:
		card.set_face_down(true)

func restart() -> void:
	# one-shot frame signal — a deferred call on the tree gets queued
	# behind the same frame's tail and is swallowed on game-over screens
	get_tree().process_frame.connect(
		func(): get_tree().reload_current_scene(), CONNECT_ONE_SHOT)

# ---------------------------------------------------------------- hud bits

func _update_chips() -> void:
	_l_chips.text = "%s %d   ·   %s %d" % [tr("CHIPS_YOU"),
		maxi(_chips_you, 0), tr("CHIPS_DEVIL"), maxi(_chips_devil, 0)]
	_l_blood.text = "%s %d   ·   %s %d" % [tr("BLOOD"), _blood,
		tr("CARDS_LEFT"), _deck.size()]
	if _debt > 0:
		_l_blood.text += "   ·   %s %d" % [tr("DEBT_LBL"), _debt]
	_l_pot.text = "%s %d" % [tr("POT"), _pot]
	if _run["embers"] > 0:
		_l_pot.text += "  ·  %s %d" % [tr("EMBERS_LBL"), _run["embers"]]
	for i in range(_pot_pile.size()):
		_pot_pile[i].visible = i < mini(_pot, _pot_pile.size())

func _hint(t: String) -> void:
	_l_hint.text = t

func _pad_glow(pad, amt: float) -> void:
	var m: StandardMaterial3D = _pads[_pad_key("p", pad["lane"],
		int(pad["row"]))].material_override
	var tw := create_tween()
	tw.tween_property(m, "emission_energy_multiplier", amt, 0.15)

func _pulse(l: Label) -> void:
	var tw := create_tween()
	tw.tween_property(l, "modulate", Color(2.4, 0.7, 0.5), 0.08)
	tw.tween_property(l, "modulate", Color.WHITE, 0.4)

# ---------------------------------------------------------------- autoplay probe

## §2.3 Reposition: one revealed card moves lanes (or swaps) once per battle.
func _repos_arm(card) -> void:
	_repos_armed = card
	card.set_selected(true)
	_hint(tr("HINT_REPOS"))

func _repos_cancel() -> void:
	if _repos_armed != null and is_instance_valid(_repos_armed):
		_repos_armed.set_selected(false)
	_repos_armed = null
	_hint(tr("HINT_PLACE"))

func _repos_dest(lane: int, row := 0) -> Vector3:
	return _pads[_pad_key("p", lane, row)].position + Vector3(0, 0.002, 0)

func _do_repos(lane: int, row := 0) -> void:
	var card = _repos_armed
	_repos_cancel()
	_prow(card.row).erase(card.lane)
	_prow(row)[lane] = card
	card.lane = lane
	card.row = row
	card.moved_once = true
	var dest := _repos_dest(lane, row)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "position", dest, 0.35)
	card.set_base(dest, card.rotation)
	_hint(tr("REPOS_DONE") % tr(card.def.name_key))
	_bump("curiosity", 0.15)   # he watches how you think
	_sfx.play(Sfx.SLIDE, -7.0)

func _swap_lanes(a, b) -> void:
	_repos_cancel()
	var la: int = a.lane
	var lb: int = b.lane
	var ra: int = a.row
	var rb: int = b.row
	_prow(ra).erase(la)
	_prow(rb).erase(lb)
	_prow(ra)[la] = b
	_prow(rb)[lb] = a
	a.lane = lb
	a.row = rb
	b.lane = la
	b.row = ra
	a.moved_once = true
	var da := _repos_dest(lb, rb)
	var db := _repos_dest(la, ra)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(a, "position", da, 0.35)
	tw.parallel().tween_property(b, "position", db, 0.35)
	a.set_base(da, a.rotation)
	b.set_base(db, b.rotation)
	_hint(tr("REPOS_SWAP"))
	_bump("curiosity", 0.15)
	_sfx.play(Sfx.SLIDE, -7.0)

## §2.3/§5 Tricks: one-shots — they resolve on the spot and burn away.
func _play_trick(card) -> void:
	if card.def.blood_cost > _blood:
		_hint(tr("HINT_NOBLOOD"))
		_sfx.play(Sfx.DENIED, -10.0)
		return
	match card.def.id:
		"tithe":
			if _dead_p.is_empty():
				_hint(tr("TRICK_TITHE_NONE"))
				_sfx.play(Sfx.DENIED, -10.0)
				return
		"razor", "salt_circle", "grave_candle":
			_trick_arm(card)
			return
	_blood -= card.def.blood_cost
	_hand.erase(card)
	_burn_trick(card)
	match card.def.id:
		"usurer_t":
			_chips_you += 4
			_debt += 2
			_hint(tr("TRICK_USURER"))
			_bump("curiosity", 0.25)
		"tithe":
			var d: CardDef = _dead_p.pop_back()
			_dead_to_hand(d)
			_hint(tr("TRICK_TITHE") % tr(d.name_key))
			_bump("respect", 0.2)
	_reflow_hand()
	_update_chips()
	_sfx.play(Sfx.CONFIRM, -8.0)

func _burn_trick(card) -> void:
	_area_to_card.erase(card.get_area())
	_burst(card.position + Vector3(0, 0.02, 0),
		Color(0.5, 0.3, 0.08), 16, 0.01, 0.5)
	card.burn()

func _dead_to_hand(d: CardDef) -> void:
	_sfx.play(Sfx.TAKE_OUT, -10.0)  # the tithe slides it back out
	var card := GameCard.new()
	card.def = d
	add_child(card)
	card.setup(load(d.face_file), _back_tex)
	card.set_idle_phase(randf() * 3.0)
	_area_to_card[card.get_area()] = card
	_hand.append(card)
	_reflow_hand()

## Azrail resolves his own tricks rather than seating them as bodies:
## razor grafts Sharp onto a revealed pawn, the usurer feeds his pile,
## the tithe shuffles his freshest casualty back into the deck.
func _resolve_his_trick(d: CardDef) -> void:
	match d.id:
		"razor":
			var cands: Array = []
			for l in _board_e.keys():
				var c = _board_e[l]
				if c != null and not c.face_down and c.hp > 0 \
					and not c.def.sigils.has("sharp"):
					cands.append(c)
			if cands.is_empty():
				_edeck.insert(randi() % (_edeck.size() + 1), d)
				return
			var t = cands[randi() % cands.size()]
			t.def.sigils.append("sharp")
			t.flash()
		"usurer_t":
			_chips_devil += 4
			_pot += 2          # the usurer's cut lands in the pot
		"tithe":
			if not _dead_e.is_empty():
				_edeck.insert(randi() % (_edeck.size() + 1),
					_dead_e.pop_back())
			else:
				_edeck.insert(randi() % (_edeck.size() + 1), d)
				return
		"hot_iron_t":
			# doc §2.3: the iron sears one of your concealed cards off
			# the felt — Koruma wards it; if every hidden card is warded
			# the trick goes back up his sleeve unspent
			var prey := []
			for c in _all_p():
				if c.face_down and c.def != null \
					and not "protection" in c.def.sigils:
					prey.append(c)
			if prey.is_empty():
				_edeck.insert(randi() % (_edeck.size() + 1), d)
				_hint(tr("HINT_IRON_WARDED"))
				return
			var victim = prey[randi() % prey.size()]
			_prow(victim.row).erase(victim.lane)
			_area_to_card.erase(victim.get_area())
			_dead_p.append(victim.def)
			victim.burn()
	_hint(tr("TRICK_HIS") % tr(d.name_key))
	_sfx.play(Sfx.CONFIRM, -10.0, 0.8)

func _trick_arm(card) -> void:
	_blood -= card.def.blood_cost
	_trick_armed = card
	_hand.erase(card)
	card.set_selected(true)
	_reflow_hand()
	_hint(tr("HINT_TRICK_TARGET"))

func _trick_cancel() -> void:
	var card = _trick_armed
	_trick_armed = null
	if card != null and is_instance_valid(card):
		card.set_selected(false)
		_blood += card.def.blood_cost   # the edge goes back, unpaid
		_hand.append(card)
		_reflow_hand()
	_sfx.play(Sfx.BACK, -10.0)
	_hint(tr("HINT_PLACE"))

func _resolve_razor(target) -> void:
	var card = _trick_armed
	_trick_armed = null
	card.set_selected(false)
	# §3.3 the Straight Razor grafts the Sharp seal — strikes first
	# in its lane's clash for the rest of this battle
	if not target.def.sigils.has("sharp"):
		target.def.sigils.append("sharp")
	target.flash()
	_burst(target.position + Vector3(0, 0.03, 0),
		Color(0.75, 0.75, 0.8), 18, 0.01, 0.4)
	_hint(tr("TRICK_RAZOR") % tr(target.def.name_key))
	_burn_trick(card)

func _resolve_salt(target) -> void:
	var card = _trick_armed
	_trick_armed = null
	card.set_selected(false)
	# §5 the Salt Circle wards a pawn — grafted Protection turns the
	# Hot Iron and his reads aside for the rest of this battle
	if not target.def.sigils.has("protection"):
		target.def.sigils.append("protection")
	target.flash()
	_burst(target.position + Vector3(0, 0.03, 0),
		Color(0.9, 0.88, 0.8), 18, 0.01, 0.4)
	_hint(tr("TRICK_SALT") % tr(target.def.name_key))
	_burn_trick(card)

func _resolve_candle(target) -> void:
	var card = _trick_armed
	_trick_armed = null
	card.set_selected(false)
	# §5 the Grave Candle tends the wounds — +2 health (never past
	# its birth strength) and the venom in its blood burns out
	target.hp = min(target.hp + 2, float(target.def.health))
	target.venom = 0
	target.flash()
	_burst(target.position + Vector3(0, 0.03, 0),
		Color(0.9, 0.62, 0.2), 18, 0.01, 0.45)
	_hint(tr("TRICK_CANDLE") % tr(target.def.name_key))
	_burn_trick(card)
	_bump("respect", 0.15)
	_sfx.play(Sfx.SLIDE, -8.0)

## seal hooks that fire when a card flips face-up
func _on_reveal(card, opposing) -> void:
	var sig: Array = card.def.sigils
	if "loan_shark" in sig:
		_chips_you += 2
		_debt += 1
		_pulse(_l_chips)
	if "pot_cut" in sig:
		# §3.3 Pot Cut: on reveal, skim a chip per five in the pot
		var cut: int = int(_pot / 5)
		if cut > 0:
			_chips_you += cut
			_pulse(_l_chips)
			_burst(card.position + Vector3(0, 0.03, 0),
				Color(0.9, 0.7, 0.2), 12, 0.01, 0.4)
	if "mimic" in sig and opposing != null and opposing.def != null:
		for sg in opposing.def.sigils:
			if not sig.has(sg):
				sig.append(sg)
		# doc §6 Ayna Tazısı: the Mirror Hound wears the foe it
		# meets — stats as well as seals
		card.def.attack = opposing.def.attack
		card.def.health = opposing.def.health
		card.hp = card.def.health
	if "eyecorner" in sig:
		# §3.3: glimpse one enemy concealed card — only you read it;
		# the card itself stays hidden from the table
		var hidden := []
		for c in _all_e():
			if c.face_down:
				hidden.append(c)
		if not hidden.is_empty():
			var peek = hidden[randi() % hidden.size()]
			_hint(tr("HINT_EYECORNER") + " — " + tr(peek.def.name_key))
	# §3.3 Anchor: an anchored card can't be moved — Swap can't lift it
	if "swap" in sig and not "anchor" in sig:
		var empty: Array = []
		for l in range(LANES):
			for r in 2:
				if not _prow(r).has(l):
					empty.append([l, r])
		if empty.size() > 0:
			_repos_armed = card
			var pick = empty[randi() % empty.size()]
			_do_repos(int(pick[0]), int(pick[1]))

## his side's on-reveal seals — the table is symmetric (§3.3):
## loan shark pays him into debt owed to *you*, pot cut skims his way,
## mimic mirrors your lane's front card.
func _on_reveal_his(card, opposing) -> void:
	var sig: Array = card.def.sigils
	if "loan_shark" in sig:
		_chips_devil += 2
		_debt += 1
	if "pot_cut" in sig:
		var cut: int = int(_pot / 5)
		if cut > 0:
			_chips_devil += cut
			_pulse(_l_chips)
	if "mimic" in sig and opposing != null and opposing.def != null:
		for sg in opposing.def.sigils:
			if not sig.has(sg):
				sig.append(sg)
		card.def.attack = opposing.def.attack
		card.def.health = opposing.def.health
		card.hp = card.def.health
	if "eyecorner" in sig:
		# he glimpses one of your concealed cards — a learned read
		var yours := []
		for c in _all_p():
			if c.face_down:
				yours.append(c)
		if not yours.is_empty():
			var seen = yours[randi() % yours.size()]
			if seen.def.id == "bluffer":
				# doc §6 Blöfcü: the moment it's *seen* it bursts and the
				# reader pays — his own Eyecorner springs the trap
				_prow(seen.row).erase(seen.lane)
				_area_to_card.erase(seen.get_area())
				_chips_devil -= 2
				_bump("anger", 0.5)
				seen.burn()
				_hint(tr("HINT_BLUFFER_CAUGHT"))
			else:
				seen.peeked = true
				_hint(tr("HINT_EYECORNER_HIS"))

func _spawn_grub(lane: int, mine: bool, row := 0) -> void:
	var d: CardDef = CardDef.make("grub", "chalices", 0, 0, 1, 0,
		"res://assets_external/card-art/gwd/face_imp.png")
	var card := GameCard.new()
	card.def = d
	add_child(card)
	card.setup(load(d.face_file), _back_tex)
	card.lane = lane
	card.row = row
	card.hp = d.health
	card.placed = true
	card.scale = Vector3.ONE * 0.72
	_area_to_card[card.get_area()] = card
	# the grub crawls out where its mother died — same lane, same rank
	var dest: Vector3 = _repos_dest(lane, row) if mine \
		else _pads[_pad_key("e", lane, row)].position + Vector3(0, 0.002, 0)
	if mine:
		_prow(row)[lane] = card
	else:
		_erow(row)[lane] = card
	card.position = dest + Vector3(0, 0.05, 0)
	card.set_base(dest, Vector3(PI, 0, 0))
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(card, "position", dest, 0.35)
	_burst(dest + Vector3(0, 0.03, 0), Color(0.3, 0.5, 0.2),
		12, 0.01, 0.4)

## mantel effigies — passive objects lying on the table's back edge;
## they sit behind Azrail's pads and tick every round (§5 effigy slice)
func _spawn_effigies() -> void:
	var defs := [
		{"id": "debtor_bell", "key": "EFFIGY_BELL",
			"face": "res://assets_external/card-art/gwd/face_votary.png"},
		{"id": "croupier", "key": "EFFIGY_CROUPIER",
			"face": "res://assets_external/card-art/gwd/face_acolyte.png"},
	]
	var names: Array[String] = []
	for i in range(defs.size()):
		_effigies.append(defs[i])
		names.append(tr(defs[i]["key"]))
		var card := GameCard.new()
		card.def = CardDef.make_effigy(defs[i]["id"], defs[i]["face"])
		add_child(card)
		card.setup(load(defs[i]["face"]), _back_tex)
		card.placed = true
		card.scale = Vector3.ONE * 0.62
		var dest := Vector3(-0.42 + i * 0.09, _top + 0.02, -0.30)
		card.position = dest + Vector3(0, 0.25, -0.15)
		card.rotation = Vector3(PI, 0, -0.35)
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC) 			.set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.8 + i * 0.4)
		tw.tween_property(card, "position", dest, 0.6)
		tw.parallel().tween_property(card, "rotation",
			Vector3(PI, 0, 0), 0.6)
		card.set_base(dest, Vector3(PI, 0, 0))
	_l_effigies.text = "%s  %s" % [tr("EFFIGY_LBL"), " · ".join(names)]

## §4.7 Luck: every internal roll tilts by the hidden band; Loaded Dice
## forces the next roll, Mirrored Coin refunds one lost roll.
func _roll_chance() -> bool:
	if _loaded_next:
		_loaded_next = false
		return true
	var win := randf() < 0.5 + 0.08 * float(_luck)
	if not win and _mirrored:
		_mirrored = false
		win = randf() < 0.5 + 0.08 * float(_luck)
		_hint(tr("COIN_REROLL"))
	return win

func _autoplay_run() -> void:
	await get_tree().create_timer(1.2).timeout
	if _phase != Phase.PLACE:
		return
	# place hand[0] on lane 1, next free on lane 3, one support behind
	# lane 1 (exercises the back rank), sacrifice hand[0]
	if _hand.size() >= 1:
		_select(_hand[0]); _try_place(1)
	if _hand.size() >= 1:
		_select(_hand[1] if _hand.size() > 1 else _hand[0]); _try_place(3)
	if _hand.size() >= 1:
		_select(_hand[0]); _try_place(1, 1)
	for c in _hand.duplicate():
		if c.def.kind == "trick":
			_play_trick(c)
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
