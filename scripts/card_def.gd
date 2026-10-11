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
		make("cutpurse", "blades", 0, 1, 1, 1, "res://assets_external/card-art/gwd/face_cutpurse.png", ["tithe"]),
		make("duelist", "blades", 1, 2, 2, 1, "res://assets_external/card-art/gwd/face_duelist.png", ["executioner"]),
		make("reaper", "blades", 1, 3, 1, 1, "res://assets_external/card-art/gwd/face_reaper.png", ["pierce"]),
		make("warden", "chalices", 0, 1, 3, 1, "res://assets_external/card-art/gwd/face_warden.png", ["revival"]),
		make("votary", "chalices", 0, 0, 4, 2, "res://assets_external/card-art/gwd/face_votary.png", ["brood"]),
		make("martyr", "chalices", 0, 1, 2, 2, "res://assets_external/card-art/gwd/face_martyr.png", ["haunt"]),
		make("acolyte", "pentacles", 0, 1, 1, 1, "res://assets_external/card-art/gwd/face_acolyte.png", ["venom"]),
		make("usurer", "pentacles", 1, 2, 1, 2, "res://assets_external/card-art/gwd/face_usurer.png", ["loan_shark"]),
		make("spy", "eyes", 0, 1, 1, 1, "res://assets_external/card-art/gwd/face_imp.png", ["swap"]),
		make("seer", "eyes", 1, 1, 2, 1, "res://assets_external/card-art/gwd/face_seer.png", ["mimic"]),
		make("priestess", "eyes", 1, 3, 4, 1, "res://assets_external/card-art/gwd/face_seer.png"),
		# §4.6-adjacent tricks (design §2.3/§5): instant one-shots, no slot
		make_trick("usurer_t", "pentacles", 0, "res://assets_external/card-art/gwd/face_usurer.png"),
		make_trick("tithe", "chalices", 1, "res://assets_external/card-art/gwd/face_martyr.png"),
		make_trick("razor", "blades", 1, "res://assets_external/card-art/gwd/face_duelist.png"),
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
			"res://assets_external/card-art/gwd/face_duelist.png"))
	if depth >= 2:
		d.append(make("reaper", "blades", 1, 3, 1, 1,
			"res://assets_external/card-art/gwd/face_reaper.png",
			["pierce"]))
	if depth >= 3:
		d.append(make("priestess", "eyes", 1, 3, 4, 1,
			"res://assets_external/card-art/gwd/face_seer.png"))
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
				g + "face_duelist.png", ["executioner"])
		"hell_warden":
			return make("warden", "chalices", 1, 1, 5, 1,
				g + "face_warden.png", ["revival", "haunt"])
		"choir_seer":
			return make("seer", "eyes", 1, 2, 3, 1,
				g + "face_seer.png", ["mimic"])
		"debt_reaper":
			return make("reaper", "blades", 2, 4, 2, 1,
				g + "face_reaper.png", ["pierce"])
		"plague_votary":
			return make("votary", "chalices", 1, 0, 5, 2,
				g + "face_votary.png", ["brood", "venom"])
		"fused_abomination":
			# §3.4 Furnace product — never dealt as a spoil, only melted
			return make("fused_abomination", "blades", 3, 5, 6, 2,
				g + "face_martyr.png", ["executioner", "haunt"])
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
