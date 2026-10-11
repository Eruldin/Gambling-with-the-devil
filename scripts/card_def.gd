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

static func make(p_id: String, p_suit: String, p_cost: int, p_atk: int,
		p_hp: int, p_sac: int, p_face: String) -> RefCounted:
	var c = (load("res://scripts/card_def.gd") as GDScript).new()
	c.id = p_id
	c.name_key = "CARD_" + p_id.to_upper()
	c.suit = p_suit
	c.blood_cost = p_cost
	c.attack = p_atk
	c.health = p_hp
	c.sacrifice_value = p_sac
	c.face_file = p_face
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
		make("cutpurse", "blades", 0, 1, 1, 1, "res://assets_external/card-art/gwd/face_cutpurse.png"),
		make("duelist", "blades", 1, 2, 2, 1, "res://assets_external/card-art/gwd/face_duelist.png"),
		make("reaper", "blades", 1, 3, 1, 1, "res://assets_external/card-art/gwd/face_reaper.png"),
		make("warden", "chalices", 0, 1, 3, 1, "res://assets_external/card-art/gwd/face_warden.png"),
		make("votary", "chalices", 0, 0, 4, 2, "res://assets_external/card-art/gwd/face_votary.png"),
		make("martyr", "chalices", 0, 1, 2, 2, "res://assets_external/card-art/gwd/face_martyr.png"),
		make("acolyte", "pentacles", 0, 1, 1, 1, "res://assets_external/card-art/gwd/face_acolyte.png"),
		make("usurer", "pentacles", 1, 2, 1, 2, "res://assets_external/card-art/gwd/face_usurer.png"),
		make("spy", "eyes", 0, 1, 1, 1, "res://assets_external/card-art/gwd/face_imp.png"),
		make("seer", "eyes", 1, 1, 2, 1, "res://assets_external/card-art/gwd/face_seer.png"),
	]
