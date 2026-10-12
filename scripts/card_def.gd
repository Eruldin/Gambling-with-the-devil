extends RefCounted
## Card definition (design-doc anatomy, trimmed for the battle slice):
## name (i18n key), suit, blood cost, attack, health, sigils, sacrifice value.

var id := ""
var name_key := ""
var suit := ""              # blades | chalices | pentacles | eyes
var blood_cost := 0
var attack := 0
var health := 1
var sigils: Array[String] = []
var sacrifice_value := 1
var face_file := ""         # res:// path to the card face art
var is_bluff := false       # §2.3: a counterfeit — destroyed when Called
var kind := "pawn"          # pawn | trick — tricks resolve instantly, no slot

static func make(p_id: String, p_suit: String, p_cost: int, p_atk: int,
		p_hp: int, p_sac: int, p_face: String,
		p_sigils: Array[String] = []) -> RefCounted:
	var c = (load("res://scripts/card_def.gd") as GDScript).new()
	c.id = p_id
	c.name_key = "CARD_" + p_id.to_upper()
	c.suit = p_suit
	c.blood_cost = p_cost
	c.attack = p_atk
	c.health = p_hp
	c.sacrifice_value = p_sac
	c.face_file = p_face
	c.sigils = p_sigils
	return c

static func make_trick(p_id: String, p_suit: String, p_cost: int,
		p_face: String) -> RefCounted:
	var c := make(p_id, p_suit, p_cost, 0, 1, 1, p_face)
	c.kind = "trick"
	return c

static func make_effigy(p_id: String, p_face: String) -> RefCounted:
	var c := make(p_id, "pentacles", 0, 0, 1, 0, p_face)
	c.kind = "effigy"
	return c

## A counterfeit card the Devil palms into his deck (§2.3): looks like
## a real stake face-down, but it's a lie — Call the Bluff burns it and
## costs him 2 chips.
static func bluff_card() -> RefCounted:
	var c := make("bluff", "eyes", 0, 0, 1, 0,
		"res://assets_external/card-art/gwd/face_imp.png")
	c.is_bluff = true
	return c

static func starter_deck() -> Array:
	# 10-card opening deck, mirrored for the Devil. Suits per design doc:
	# blades=Kılıç, chalices=Kupa, pentacles=Tılsım, eyes=Göz.
	return [
		make("cutpurse", "blades", 0, 1, 1, 1, "res://assets_external/card-art/gwd/face_cutpurse.png", ["tithe", "pot_cut"]),
		make("duelist", "blades", 1, 2, 2, 1, "res://assets_external/card-art/gwd/face_duelist.png", ["executioner"]),
		make("reaper", "blades", 1, 3, 1, 1, "res://assets_external/card-art/gwd/face_reaper.png", ["pierce", "frenzied"]),
		make("hangman", "blades", 2, 2, 4, 1, "res://assets_external/card-art/gwd/face_hangman.png", ["executioner", "anchor"]),
		# §2.2/§3.3 Reach: the pikeman strikes over his own wall —
		# a back-rank guard can't hide from the point
		make("halberd", "blades", 1, 1, 2, 1, "res://assets_external/card-art/gwd/face_halberd.png", ["reach"]),
		# the blades' first-strike pawn — cuts before the answer comes
		make("dissector", "blades", 2, 2, 2, 1, "res://assets_external/card-art/gwd/face_dissector.png", ["sharp", "venom"]),
		# a writhing cheap striker — venom on the tooth, frenzy in the coil
		make("graveworm", "blades", 1, 2, 1, 1, "res://assets_external/card-art/gwd/face_graveworm.png", ["venom", "frenzied"]),
		# a headsman's heavier brother — slow, certain, and the blade
		# remembers: what it kills stays killed (executioner + anchor)
		make("pallbearer", "blades", 2, 1, 5, 1, "res://assets_external/card-art/gwd/face_pallbearer.png", ["executioner", "bulwark"]),
		make("warden", "chalices", 0, 1, 3, 1, "res://assets_external/card-art/gwd/face_warden.png", ["revival", "bulwark"]),
		# §2.2 support pair: the Deacon blesses its lane's striker from
		# the sheltered rank; the Gravedigger feeds on friendly deaths
		make("deacon", "chalices", 1, 0, 3, 1, "res://assets_external/card-art/gwd/face_deacon.png"),
		make("votary", "chalices", 0, 0, 4, 2, "res://assets_external/card-art/gwd/face_votary.png", ["brood", "shell"]),
		make("martyr", "chalices", 0, 1, 2, 2, "res://assets_external/card-art/gwd/face_martyr.png", ["haunt"]),
		make("acolyte", "pentacles", 0, 1, 1, 1, "res://assets_external/card-art/gwd/face_acolyte.png", ["venom"]),
		make("usurer", "pentacles", 1, 2, 1, 2, "res://assets_external/card-art/gwd/face_usurer.png", ["loan_shark"]),
		make("penitent", "pentacles", 1, 0, 4, 1, "res://assets_external/card-art/gwd/face_penitent.png", ["loan_shark", "waxhide", "protection"]),
		make("gravedigger", "pentacles", 1, 1, 2, 1, "res://assets_external/card-art/gwd/face_gravedigger.png"),
		# a mid-table usurer — every chip it earns is written as debt
		make("bargainer", "pentacles", 1, 1, 3, 1, "res://assets_external/card-art/gwd/face_bargainer.png", ["loan_shark"]),
		# a chained debtor — rooted where he kneels and skims the pot
		make("bondsman", "pentacles", 0, 0, 3, 1, "res://assets_external/card-art/gwd/face_bondsman.png", ["pot_cut", "anchor"]),
		# he comes for what is owed at night — plated, patient,
		# and every chip he touches is written down as debt
		make("night_collector", "pentacles", 2, 1, 3, 1, "res://assets_external/card-art/gwd/face_night_collector.png", ["loan_shark", "shell"]),
		# a safe that walks — everything it touches skims into the pot,
		# and wax seals keep the first wound from opening it
		make("strongbox", "pentacles", 2, 0, 4, 1, "res://assets_external/card-art/gwd/face_strongbox.png", ["pot_cut", "waxhide"]),
		make("spy", "eyes", 0, 1, 1, 1, "res://assets_external/card-art/gwd/face_spy.png", ["swap", "veil"]),
		make("seer", "eyes", 1, 1, 2, 1, "res://assets_external/card-art/gwd/face_seer.png", ["mimic", "eyecorner"]),
		make("priestess", "eyes", 1, 3, 4, 1, "res://assets_external/card-art/gwd/face_priestess.png"),
		# doc §6 roster — trickier bodies the starter line lacked:
		# the Owed Pig is a wall you pay for in debt, the Choir Leech
		# sips a chip per clash, the Eyes' Servant carries the Eyecorner
		# seal proper, and the Mirror Hound wears the foe it meets.
		make("owed_pig", "pentacles", 1, 4, 4, 1, "res://assets_external/card-art/gwd/face_owed_pig.png"),
		make("choir_leech", "chalices", 1, 1, 3, 1, "res://assets_external/card-art/gwd/face_choir_leech.png"),
		# a smoke wall that curses whatever kills it
		make("thurifer", "chalices", 1, 0, 4, 1, "res://assets_external/card-art/gwd/face_thurifer.png", ["haunt", "bulwark"]),
		# her bowl pays two chips when seated, and she offers thick
		make("alms_sister", "chalices", 1, 0, 3, 1, "res://assets_external/card-art/gwd/face_alms_sister.png", ["tithe", "shell"]),
		# a stone saint that weeps real alms — a wall that pays
		make("weeping_idol", "chalices", 2, 0, 5, 1, "res://assets_external/card-art/gwd/face_weeping_idol.png", ["bulwark", "tithe"]),
		# a drowned bell-ringer — comes back wet, rings once for the pot
		make("drowned_bellman", "chalices", 1, 1, 2, 1, "res://assets_external/card-art/gwd/face_drowned_bellman.png", ["revival", "tithe"]),
		make("eyes_servant", "eyes", 2, 1, 3, 1, "res://assets_external/card-art/gwd/face_eyes_servant.png", ["eyecorner"]),
		make("mirror_hound", "eyes", 2, 1, 1, 1, "res://assets_external/card-art/gwd/face_mirror_hound.png", ["mimic"]),
		# doc §6 Blöfcü: a concealed trap — it is nothing on the felt,
		# but the instant an enemy read *sees* it, it bursts and the
		# reader pays two chips for the look
		make("bluffer", "eyes", 0, 0, 1, 1, "res://assets_external/card-art/gwd/face_bluffer.png"),
		# a fog courier — cheap body that slides its lane free
		make("mist_page", "eyes", 0, 0, 2, 1, "res://assets_external/card-art/gwd/face_mist_page.png", ["swap"]),
		# it writes the dead's debts in the margin — sees around
		# its own wall and reaches the sheltered rank behind
		make("dust_scribe", "eyes", 1, 1, 2, 1, "res://assets_external/card-art/gwd/face_dust_scribe.png", ["eyecorner", "reach"]),
		# a moth-winged oracle — flits lanes, and whatever reads it
		# pays for the look (veil + swap)
		make("moth_oracle", "eyes", 1, 0, 2, 1, "res://assets_external/card-art/gwd/face_moth_oracle.png", ["veil", "swap"]),
		# §4.6-adjacent tricks (design §2.3/§5): instant one-shots, no slot
		make_trick("usurer_t", "pentacles", 0, "res://assets_external/card-art/gwd/face_pale_usurer.png"),
		make_trick("tithe", "chalices", 1, "res://assets_external/card-art/gwd/face_tithe.png"),
		make_trick("razor", "blades", 1, "res://assets_external/card-art/gwd/face_razor.png"),
		# warding pair: the Circle grafts Protection, the Candle
		# knits wounds and burns the venom out of the blood
		make_trick("salt_circle", "eyes", 1, "res://assets_external/card-art/gwd/face_salt_circle.png"),
		make_trick("grave_candle", "chalices", 1, "res://assets_external/card-art/gwd/face_grave_candle.png"),
		# the iron finger and the stake — one reads his felt for lies,
		# the other buys chips and blood with your own pawn's pyre
		make_trick("cold_iron", "eyes", 1, "res://assets_external/card-art/gwd/face_cold_iron.png"),
		make_trick("ash_offering", "chalices", 0, "res://assets_external/card-art/gwd/face_ash_offering.png"),
	]

## §18: Azrail's deck hardens down the Descent — his pawns sharpen one
## edge per two depths, and his hand grows meaner tricks and counterfeits.
static func devil_deck(depth: int) -> Array:
	var d := starter_deck()
	var sharpen := depth / 2
	if sharpen > 0:
		for c in d:
			if c.kind == "pawn":
				c.attack += sharpen
	if depth >= 1:
		d.append(make_trick("razor", "blades", 1,
			"res://assets_external/card-art/gwd/face_razor.png"))
	if depth >= 2:
		d.append(make("reaper", "blades", 1, 3, 1, 1,
			"res://assets_external/card-art/gwd/face_reaper.png",
			["pierce"]))
	if depth >= 3:
		d.append(make("priestess", "eyes", 1, 3, 4, 1,
			"res://assets_external/card-art/gwd/face_priestess.png"))
		d.append(make_trick("usurer_t", "pentacles", 0,
			"res://assets_external/card-art/gwd/face_pale_usurer.png"))
		d.append(make_trick("hot_iron_t", "blades", 1,
			"res://assets_external/card-art/gwd/face_hot_iron.png"))
	if depth >= 4:
		d.append(make_trick("tithe", "chalices", 1,
			"res://assets_external/card-art/gwd/face_tithe.png"))
	return d

## §18 spoils: cards a won table pays into your deck — slightly better
## than the starter line, drawn from the same face set.
static func spoil_ids() -> Array:
	return ["grave_duelist", "hell_warden", "choir_seer", "debt_reaper",
		"plague_votary"]

static func spoil(sid: String) -> RefCounted:
	var g := "res://assets_external/card-art/gwd/"
	match sid:
		"grave_duelist":
			return make("duelist", "blades", 1, 3, 2, 1,
				g + "face_grave_duelist.png", ["executioner"])
		"hell_warden":
			return make("warden", "chalices", 1, 1, 5, 1,
				g + "face_hell_warden.png", ["revival", "haunt"])
		"choir_seer":
			return make("seer", "eyes", 1, 2, 3, 1,
				g + "face_choir_seer.png", ["mimic"])
		"debt_reaper":
			return make("reaper", "blades", 2, 4, 2, 1,
				g + "face_debt_reaper.png", ["pierce"])
		"plague_votary":
			return make("votary", "chalices", 1, 0, 5, 2,
				g + "face_plague_votary.png", ["brood", "venom"])
		"fused_abomination":
			# §3.4 Furnace product — never dealt as a spoil, only melted
			return make("fused_abomination", "blades", 3, 5, 6, 2,
				g + "face_abomination.png", ["executioner", "haunt"])
	return null

## §18.4 scenario breakers — a spoil soul whose presence in your deck
## snaps a door's harm once per run. The Duelist duels the Whisper,
## the Warden wards the Wheel, the Reaper collects the Ledger,
## the Seer sees through the Mirror. "I kept this card for this."
static func breaker_of(event_id: String) -> String:
	match event_id:
		"event_whisper": return "grave_duelist"
		"event_wheel": return "hell_warden"
		"event_ledger": return "debt_reaper"
		"event_mirror": return "choir_seer"
	return ""
