extends Node3D
## Animated candle flame: flipbook sprite + flickering omni light + rising smoke.
## Attach under a holder root positioned at the flame's base.

@export var fps := 11.0
@export var light_energy_base := 0.4

var _flame: MeshInstance3D
var _smoke: MeshInstance3D
var _light: OmniLight3D
var _frames: Array[Texture2D] = []
var _smoke_tex: Texture2D
var _t := 0.0
var _phase := 0.0

func setup(frames: Array[Texture2D], smoke_tex: Texture2D, phase := 0.0) -> void:
	_frames = frames
	_smoke_tex = smoke_tex
	_phase = phase
	_build()

func _build() -> void:
	# flame quad (additive, billboarded, unshaded)
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	fmat.disable_fog = true
	fmat.albedo_texture = _frames[0]
	_flame = MeshInstance3D.new()
	var fq := QuadMesh.new()
	fq.size = Vector2(0.042, 0.075)
	_flame.mesh = fq
	_flame.material_override = fmat
	_flame.position = Vector3(0, 0.028, 0)
	add_child(_flame)

	# smoke quad (normal blend, subtle)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	smat.cull_mode = BaseMaterial3D.CULL_DISABLED
	smat.albedo_texture = _smoke_tex
	smat.albedo_color = Color(0.5, 0.5, 0.5, 0.25)
	_smoke = MeshInstance3D.new()
	var sq := QuadMesh.new()
	sq.size = Vector2(0.05, 0.08)
	_smoke.mesh = sq
	_smoke.material_override = smat
	_smoke.position = Vector3(0, 0.09, 0)
	add_child(_smoke)

	# flickering light
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.55, 0.22)
	_light.light_energy = light_energy_base
	_light.omni_range = 0.9
	_light.omni_attenuation = 1.4
	_light.position = Vector3(0, 0.12, 0)
	add_child(_light)

func _process(delta: float) -> void:
	_t += delta
	var i := _t * fps + _phase
	# flipbook
	var idx := int(i) % _frames.size()
	(_flame.material_override as StandardMaterial3D).albedo_texture = _frames[idx]
	# wobble + pulse
	var n := sin(i * 1.9) * 0.55 + sin(i * 4.7 + 1.3) * 0.45
	_flame.scale = Vector3(1.0 + 0.10 * n, 1.0 + 0.16 * n, 1.0)
	_light.light_energy = light_energy_base * (0.82 + 0.22 * n) + 0.04 * sin(i * 9.1)
	# smoke rise + fade loop
	var cyc := fmod(_t * 0.22 + _phase * 0.1, 1.0)
	_smoke.position.y = 0.09 + cyc * 0.16
	var fade := sin(cyc * PI)
	(_smoke.material_override as StandardMaterial3D).albedo_color.a = 0.22 * fade
	_smoke.scale = Vector3.ONE * (0.7 + cyc * 0.9)
