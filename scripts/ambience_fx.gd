extends Node3D
## Living-room ambience: distant storm flashes + thunder, wind gusts
## that lean every flame, floor fog tendrils.

const SMOKE := "res://assets_external/anim-vfx/kenney/particle-pack/PNG (Transparent)/smoke_03.png"
const GUST := "res://assets_external/audio/gwd/gust.wav"
const THUNDER := "res://assets_external/audio/gwd/thunder.wav"
const DRONE := "res://assets_external/audio/gwd/drone.wav"
const SFX_C := preload("res://scripts/sfx.gd")

var _sfx: Node
var _hero: OmniLight3D
var _flames: Array = []
var _moth_t := 0.0
var _storm_in := 25.0 + randf() * 25.0
var _gust_in := 10.0 + randf() * 12.0
var _flash: OmniLight3D
var _fog: Array = []

## flames: CandleFlame nodes; hero: the main candle-pool light
func setup(flames: Array, hero: OmniLight3D, table_y: float) -> void:
	_flames = flames
	_hero = hero
	_sfx = SFX_C.new()
	_sfx.setup(self)
	# the room's voice — a low cathedral drone under everything; the loop
	# fades breathe into each other so the seam sits in the quiet tail
	var st: AudioStream = load(DRONE)
	if st != null:
		var d := AudioStreamPlayer.new()
		d.stream = st
		d.volume_db = -24.0
		d.finished.connect(d.play)
		add_child(d)
		d.play()
	# storm flash light above the gothic window (cold, far away)
	_flash = OmniLight3D.new()
	_flash.position = Vector3(-0.6, 2.0, -0.9)
	_flash.light_color = Color(0.6, 0.7, 1.0)
	_flash.light_energy = 0.0
	_flash.omni_range = 6.0
	_flash.omni_attenuation = 0.6
	add_child(_flash)
	# three fog tendrils drifting under the table
	var smoke: Texture2D = load(SMOKE)
	for i in range(3):
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1.4, 0.5)
		q.mesh = qm
		var m := StandardMaterial3D.new()
		m.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture = smoke
		m.albedo_color = Color(0.55, 0.55, 0.55, 0.09)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		q.material_override = m
		q.position = Vector3(-1.0 + i * 0.9, 0.16, -0.15 + i * 0.18)
		q.rotation.x = -0.5
		add_child(q)
		_fog.append({"n": q, "ph": i * 2.1})

func _process(delta: float) -> void:
	_moth_t += delta
	# fog drift
	for f in _fog:
		var n: MeshInstance3D = f.n
		n.position.x += delta * 0.05
		n.position.y = 0.14 + 0.04 * sin(_moth_t * 0.4 + f.ph)
		if n.position.x > 1.6:
			n.position.x = -1.6
	# wind gust — flames lean, hero dips, cloth/curtains whisper
	_gust_in -= delta
	if _gust_in <= 0.0:
		_gust_in = 16.0 + randf() * 22.0
		_gust()
	# storm flash — cold light through the window, delayed thunder
	_storm_in -= delta
	if _storm_in <= 0.0:
		_storm_in = 50.0 + randf() * 60.0
		_storm()

func _gust() -> void:
	_sfx.play(GUST, -14.0, randf_range(0.85, 1.1))
	var dir := 0.35 if randf() < 0.5 else -0.35
	for fl in _flames:
		var tw := create_tween()
		tw.tween_property(fl, "rotation:z", dir * randf_range(1.4, 2.2), 0.18)
		tw.tween_property(fl, "rotation:z", 0.0, 0.5).set_delay(0.15)
	if _hero != null:
		var base := _hero.light_energy
		var tw := create_tween()
		tw.tween_property(_hero, "light_energy", base * 0.25, 0.12)
		tw.tween_property(_hero, "light_energy", base, 0.6)

func _storm() -> void:
	# double-strobe flash then rumble rolls in ~0.5s later
	var tw := create_tween()
	tw.tween_property(_flash, "light_energy", 7.0, 0.06)
	tw.tween_property(_flash, "light_energy", 0.0, 0.09)
	tw.tween_property(_flash, "light_energy", 10.0, 0.05).set_delay(0.12)
	tw.tween_property(_flash, "light_energy", 0.0, 0.6)
	get_tree().create_timer(0.45 + randf() * 0.5).timeout.connect(
		func(): _sfx.play(THUNDER, -8.0, randf_range(0.8, 1.0)))
