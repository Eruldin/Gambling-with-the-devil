extends Node
## One-shot sound effects — Kenney casino + interface packs (CC0).
## `sfx.play(path)` fires and frees; player pool via temporary players.

const AUDIO := "res://assets_external/audio/kenney/"

static var SHUFFLE: String = AUDIO + "casino-audio/Audio/card-shuffle.ogg"
static var FAN: Array[String] = [
	AUDIO + "casino-audio/Audio/card-fan-1.ogg",
	AUDIO + "casino-audio/Audio/card-fan-2.ogg",
]
static var PLACE_P: Array[String] = [
	AUDIO + "casino-audio/Audio/card-place-1.ogg",
	AUDIO + "casino-audio/Audio/card-place-2.ogg",
	AUDIO + "casino-audio/Audio/card-place-3.ogg",
]
static var PLACE_E: Array[String] = [
	AUDIO + "casino-audio/Audio/card-place-4.ogg",
]
static var SLIDE: Array[String] = [
	AUDIO + "casino-audio/Audio/card-slide-1.ogg",
	AUDIO + "casino-audio/Audio/card-slide-2.ogg",
	AUDIO + "casino-audio/Audio/card-slide-5.ogg",
	AUDIO + "casino-audio/Audio/card-slide-7.ogg",
]
static var SHOVE: Array[String] = [
	AUDIO + "casino-audio/Audio/card-shove-1.ogg",
	AUDIO + "casino-audio/Audio/card-shove-3.ogg",
]
static var CHIP_HIT: Array[String] = [
	AUDIO + "casino-audio/Audio/chips-collide-1.ogg",
	AUDIO + "casino-audio/Audio/chips-collide-2.ogg",
	AUDIO + "casino-audio/Audio/chips-collide-3.ogg",
	AUDIO + "casino-audio/Audio/chips-collide-4.ogg",
]
static var CHIP_HANDLE: Array[String] = [
	AUDIO + "casino-audio/Audio/chips-handle-2.ogg",
	AUDIO + "casino-audio/Audio/chips-handle-4.ogg",
	AUDIO + "casino-audio/Audio/chips-handle-6.ogg",
]
static var CHIP_LAY: Array[String] = [
	AUDIO + "casino-audio/Audio/chip-lay-1.ogg",
	AUDIO + "casino-audio/Audio/chip-lay-2.ogg",
	AUDIO + "casino-audio/Audio/chip-lay-3.ogg",
]
static var CHIP_STACK: Array[String] = [
	AUDIO + "casino-audio/Audio/chips-stack-1.ogg",
	AUDIO + "casino-audio/Audio/chips-stack-3.ogg",
	AUDIO + "casino-audio/Audio/chips-stack-5.ogg",
]
static var DICE: Array[String] = [
	AUDIO + "casino-audio/Audio/die-throw-1.ogg",
	AUDIO + "casino-audio/Audio/die-throw-2.ogg",
	AUDIO + "casino-audio/Audio/die-throw-3.ogg",
	AUDIO + "casino-audio/Audio/die-throw-4.ogg",
]
static var PACK_OPEN: String = AUDIO + "casino-audio/Audio/cards-pack-open-1.ogg"
static var TAKE_OUT: Array[String] = [
	AUDIO + "casino-audio/Audio/cards-pack-take-out-1.ogg",
	AUDIO + "casino-audio/Audio/cards-pack-take-out-2.ogg",
]
static var BACK: String = AUDIO + "interface-sounds/Audio/back_001.ogg"
static var GLASS: Array[String] = [
	AUDIO + "interface-sounds/Audio/glass_001.ogg",
	AUDIO + "interface-sounds/Audio/glass_003.ogg",
]
static var DENIED: String = AUDIO + "interface-sounds/Audio/error_002.ogg"
static var CONFIRM: String = AUDIO + "interface-sounds/Audio/confirmation_001.ogg"
static var TURN: String = AUDIO + "interface-sounds/Audio/click_002.ogg"
static var WIN: String = AUDIO + "interface-sounds/Audio/confirmation_003.ogg"
static var LOSE: String = AUDIO + "interface-sounds/Audio/bong_001.ogg"
static var DROP: String = AUDIO + "interface-sounds/Audio/drop_002.ogg"
static var CRACKLE: Array[String] = [
	AUDIO + "interface-sounds/Audio/click_001.ogg",
	AUDIO + "interface-sounds/Audio/click_003.ogg",
	AUDIO + "interface-sounds/Audio/click_005.ogg",
]

var _root: Node

func setup(root: Node) -> void:
	_root = root

## Fire a stream (or a random pick of streams); volume db tuned per call.
func play(streams, volume := -4.0, pitch := 1.0) -> void:
	if _root == null:
		return
	var path: String
	if streams is Array:
		path = streams[randi() % streams.size()]
	else:
		path = streams
	var st: AudioStream = load(path)
	if st == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = st
	p.volume_db = volume
	p.pitch_scale = pitch * randf_range(0.94, 1.06)
	p.finished.connect(p.queue_free)
	_root.add_child(p)
	p.play()
