extends Node3D
## The Scales — Inscryption's signature brass balance on the felt edge.
## Procedural dark brass; the beam sways gently and tips hard when souls
## swing (call tip() from battle on chip changes).

var _beam: Node3D
var _t := 0.0
var _tip := 0.0        # -1 player-heavier … +1 devil-heavier
var _tip_v := 0.0

const BRASS := Color(0.2, 0.15, 0.07)
const BRASS_HI := Color(0.38, 0.28, 0.12)

func build(height := 0.17) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = BRASS
	mat.metallic = 0.85
	mat.roughness = 0.32
	mat.emission_enabled = true
	mat.emission = Color(0.32, 0.2, 0.06)
	mat.emission_energy_multiplier = 0.25
	var dark := StandardMaterial3D.new()
	dark.albedo_color = BRASS * 0.55
	dark.metallic = 0.8
	dark.roughness = 0.5

	# foot: three curled toes = tiny angled boxes on a disc
	var base := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = height * 0.22
	bc.bottom_radius = height * 0.26
	bc.height = height * 0.035
	base.mesh = bc
	base.material_override = dark
	add_child(base)
	for i in range(3):
		var toe := MeshInstance3D.new()
		var tb := BoxMesh.new()
		tb.size = Vector3(height * 0.05, height * 0.02, height * 0.16)
		toe.mesh = tb
		toe.material_override = dark
		var a := i * TAU / 3.0
		toe.position = Vector3(sin(a) * height * 0.16, height * 0.015,
			cos(a) * height * 0.16)
		toe.rotation.y = a
		add_child(toe)
	# turned post
	var post := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = height * 0.018
	pc.bottom_radius = height * 0.03
	pc.height = height * 0.86
	post.mesh = pc
	post.material_override = mat
	post.position.y = height * 0.45
	add_child(post)
	# finial sphere on top
	var fin := MeshInstance3D.new()
	var fs := SphereMesh.new()
	fs.radius = height * 0.028
	fs.height = height * 0.056
	fin.mesh = fs
	fin.material_override = mat
	fin.position.y = height * 0.9
	add_child(fin)

	# swinging beam assembly (pivot at post top)
	_beam = Node3D.new()
	_beam.position.y = height * 0.86
	add_child(_beam)
	var bar := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(height * 1.05, height * 0.022, height * 0.022)
	bar.mesh = bb
	bar.material_override = mat
	_beam.add_child(bar)
	# arrow pointer above pivot (scale needle reading)
	var needle := MeshInstance3D.new()
	var nb := BoxMesh.new()
	nb.size = Vector3(height * 0.012, height * 0.1, height * 0.01)
	needle.mesh = nb
	needle.material_override = dark
	needle.position.y = height * 0.05
	_beam.add_child(needle)

	for side in [-1.0, 1.0]:
		# chain: 3 thin links
		for l in range(3):
			var link := MeshInstance3D.new()
			var lc := CylinderMesh.new()
			lc.top_radius = height * 0.004
			lc.bottom_radius = height * 0.004
			lc.height = height * 0.055
			link.mesh = lc
			link.material_override = dark
			link.position = Vector3(side * height * 0.5,
				-height * 0.055 * (l + 0.5), 0)
			link.rotation.z = 0.0
			_beam.add_child(link)
		# pan: shallow bowl
		var pan := MeshInstance3D.new()
		var pn := CylinderMesh.new()
		pn.top_radius = height * 0.12
		pn.bottom_radius = height * 0.075
		pn.height = height * 0.03
		pan.mesh = pn
		pan.material_override = mat
		pan.position = Vector3(side * height * 0.5, -height * 0.19, 0)
		_beam.add_child(pan)
		# pan rim
		var rim := MeshInstance3D.new()
		var rt := TorusMesh.new()
		rt.inner_radius = height * 0.115
		rt.outer_radius = height * 0.125
		rim.mesh = rt
		rim.material_override = dark
		rim.position = pan.position + Vector3(0, height * 0.012, 0)
		_beam.add_child(rim)

func _process(delta: float) -> void:
	_t += delta
	# spring the beam toward _tip; ambient micro-sway on top
	var target := _tip * 0.09
	_tip_v += (target - _beam.rotation.z) * delta * 6.0
	_tip_v *= 1.0 - delta * 2.4
	_beam.rotation.z += _tip_v * delta * 60.0
	_beam.rotation.z = clampf(_beam.rotation.z, -0.14, 0.14)
	_beam.rotation.z += 0.006 * sin(_t * 0.9) * delta * 60.0
	_tip = lerpf(_tip, 0.0, delta * 0.25)

## knock the scales — sign >0 = devil's side dips (he's winning)
func tip(dir: float, strength := 1.0) -> void:
	_tip = clampf(_tip + dir * strength, -2.5, 2.5)
	_tip_v += dir * strength * 0.09
