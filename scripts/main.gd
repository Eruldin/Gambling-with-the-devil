extends Node3D
## Gambling with the Devil — prototype: candlelit 3D table scene.
## Assembles the felt board, candles, props, cards and pawns from scanned assets.

const PH := "res://assets_external/env-table/polyhaven/"
const PAWN := "res://assets_external/pawn-models/polyhaven/"
const PART := "res://assets_external/anim-vfx/kenney/particle-pack/PNG (Transparent)/"
const FONT_CINZEL := "res://assets_external/ui-fonts/Cinzel/Cinzel_0.ttf"

const CandleFlame := preload("res://scripts/candle_flame.gd")
const ScaleProp := preload("res://scripts/scale_prop.gd")
const Sway := preload("res://scripts/sway.gd")
const Battle := preload("res://scripts/battle.gd")
const Sfx := preload("res://scripts/sfx.gd")
const Devil := preload("res://scripts/devil.gd")
const HandRig := preload("res://scripts/hand_rig.gd")
const GloveHand := preload("res://scripts/glove_hand.gd")
const CatWalker := preload("res://scripts/cat_walker.gd")
const Ambience := preload("res://scripts/ambience_fx.gd")

var _cam: Camera3D
var _t := 0.0
var _shot_frames := -1
var _battle: Node3D
var _hud_layer: CanvasLayer
var _hud_font: Font
var _devil: Node3D
var _hand: Node3D
var _scale: Node3D
var _sfx: Node
var _crackle_in := 0.5
var _flames: Array = []
var _hero: OmniLight3D

# ---------------------------------------------------------------- assembly

func _ready() -> void:
	_environment()
	_room()
	var table := _place(PH + "WoodenTable_02/WoodenTable_02_1k.gltf", "table", Vector3.ZERO, 0.56)
	var top := _world_aabb(table).end.y
	# keep the model's real wood diffuse/normal/ARM — darken via the
	# albedo multiplier only, so the grain reads in candlelight
	for mi: MeshInstance3D in table.find_children("*", "MeshInstance3D", true, false):
		var mesh := mi.mesh
		if mesh == null:
			continue
		for si in range(mesh.get_surface_count()):
			var om := mi.get_active_material(si)
			if om is StandardMaterial3D:
				var dm: StandardMaterial3D = om.duplicate()
				dm.albedo_color = om.albedo_color * Color(0.34, 0.24, 0.16)
				dm.roughness = 0.82
				mi.set_surface_override_material(si, dm)
	_felt(top)
	_floor_props()
	_table_props(top)
	_candles(top)
	_chandelier(top)
	_chip_stacks(top)
	_camera(top)
	_devil = Devil.new()
	add_child(_devil)
	_devil.build(top)
	_devil._cam = _cam
	_hand = GloveHand.new()
	add_child(_hand)
	_hand.setup(Color(0.085, 0.055, 0.04), false)
	_hand.rotation = Vector3(-0.3, -0.4, 0.15)
	_hand.home_pos(Vector3(0.42, top - 0.13, 0.62))
	_hud()
	_vignette()
	_battle = Battle.new()
	add_child(_battle)
	_battle.setup(top, _cam, _hud_layer, _hud_font, _devil, _hand)
	_battle._scale = _scale
	_sfx = Sfx.new()
	_sfx.setup(self)
	# living room layer: the cat prowls the edges, moth/storm/gust/fog live here
	var cat := CatWalker.new()
	add_child(cat)
	cat.build()
	var amb := Ambience.new()
	add_child(amb)
	amb.setup(_flames, _hero, top)
	if OS.get_environment("GWD_SHOT") == "1":
		_shot_frames = 800 if OS.get_environment("GWD_AUTO") == "1" else 150

func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.003, 0.005, 0.004)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.022, 0.034, 0.03)
	env.ambient_light_energy = 0.2
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.adjustment_enabled = true
	env.adjustment_brightness = 0.9
	env.adjustment_contrast = 1.25
	env.adjustment_saturation = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.03, 0.024)
	env.fog_density = 0.34
	env.fog_height = 0.4
	env.fog_height_density = 0.12
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _room() -> void:
	var planks: Texture2D = load("res://assets_external/gwd-textures/wood_planks.png")
	var floor_mi := MeshInstance3D.new()
	var fp := PlaneMesh.new()
	fp.size = Vector2(9, 9)
	floor_mi.mesh = fp
	var fm := StandardMaterial3D.new()
	fm.albedo_texture = planks
	fm.albedo_color = Color(0.09, 0.06, 0.045)
	fm.uv1_scale = Vector3(3, 3, 3)
	fm.roughness = 1.0
	floor_mi.material_override = fm
	add_child(floor_mi)

	var wall := MeshInstance3D.new()
	var wp := PlaneMesh.new()
	wp.size = Vector2(9, 4)
	wall.mesh = wp
	wall.position = Vector3(0, 2, -1.9)
	var wm := StandardMaterial3D.new()
	wm.albedo_texture = planks
	wm.albedo_color = Color(0.11, 0.07, 0.05)
	wm.uv1_scale = Vector3(4, 2, 4)
	wm.roughness = 1.0
	wall.material_override = wm
	add_child(wall)

func _felt(top: float) -> void:
	var felt := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.95, 0.012, 0.5)
	felt.mesh = bm
	var m := StandardMaterial3D.new()
	# woven cloth texture (generated) — worn, stained, cold; the candle
	# pool warms it. texture makes the felt read as fabric, not paint
	m.albedo_texture = load("res://assets_external/gwd-textures/felt.png")
	m.albedo_color = Color(0.55, 0.62, 0.5)
	m.uv1_scale = Vector3(2, 2, 2)
	m.roughness = 0.98
	felt.material_override = m
	felt.position = Vector3(0, top + 0.006, 0)
	add_child(felt)

func _floor_props() -> void:
	_place(PH + "ArmChair_01/ArmChair_01_1k.gltf", "chair_player", Vector3(0, 0, 1.05), 0.85, PI)
	_place(PH + "ArmChair_01/ArmChair_01_1k.gltf", "chair_devil", Vector3(0, 0, -1.38), 0.85)
	_place(PH + "wooden_bookshelf_worn/wooden_bookshelf_worn_1k.gltf", "shelf", Vector3(-1.05, 0, -0.85), 1.55, 0.35)
	_place(PH + "GothicCabinet_01/GothicCabinet_01_1k.gltf", "cabinet", Vector3(0.95, 0, -0.9), 1.35, -0.3)
	_place(PH + "gothic_statue/gothic_statue_1k.gltf", "statue", Vector3(-1.25, 0, -1.0), 1.0, 0.45)
	_place(PH + "vintage_grandfather_clock_01/vintage_grandfather_clock_01_1k.gltf", "clock", Vector3(0.72, 0, -1.25), 1.55)
	# old clutter removed (chest/crate/lantern) — Inscryption keeps frame edges sparse
	_place(PH + "ornate_mirror_01/ornate_mirror_01_1k.gltf", "mirror", Vector3(1.3, 0.9, -0.6), 0.95, -0.5)
	# lived-in details at the edges: wine on the cabinet, jug + bowl by the shelf
	_place(PH + "wine_bottles_01/wine_bottles_01_1k.gltf", "wine", Vector3(1.12, 0.62, -0.52), 0.3, -0.4)
	_place(PH + "jug_01/jug_01_1k.gltf", "jug", Vector3(-1.32, 0.0, -0.55), 0.32, 0.6)
	_place(PH + "wooden_bowl_01/wooden_bowl_01_1k.gltf", "bowl", Vector3(-1.05, 0.78, -0.7), 0.14, 0.2)

func _table_props(top: float) -> void:
	# spare, occult only — Inscryption keeps the felt clean
	_place(PH + "ornate_medieval_dagger/ornate_medieval_dagger_1k.gltf", "dagger", Vector3(-0.18, top, -0.33), 0.05, 0.9)
	# a face-down deck waits at the right edge (the encyclopedia block read cheap)
	var back: Texture2D = load("res://assets_external/card-art/gwd/card_back.png")
	for i in range(5):
		var dq := MeshInstance3D.new()
		var dm := QuadMesh.new()
		dm.size = Vector2(0.045, 0.063)
		dq.mesh = dm
		var dmat := StandardMaterial3D.new()
		dmat.albedo_texture = back
		dmat.albedo_color = Color(0.45, 0.36, 0.3)
		dmat.roughness = 0.95
		dq.material_override = dmat
		dq.rotation.x = -PI / 2
		dq.rotation.z = 0.12 + i * 0.008
		dq.position = Vector3(0.66, top + 0.006 + i * 0.0012, -0.24)
		add_child(dq)
	# the Scales of the gamble — Inscryption's signature prop, center-left edge
	_scale = ScaleProp.new()
	_scale.position = Vector3(-0.45, top, 0.14)
	_scale.rotation.y = 0.35
	add_child(_scale)
	_scale.build(0.17)
	# a skull watches from behind the candles — stained bone, not bleach
	var skull := _place("res://assets_external/props-occult/skull.glb",
		"skull", Vector3(0.44, top, 0.12), 0.075, -2.2)
	var bone := StandardMaterial3D.new()
	bone.albedo_color = Color(0.16, 0.12, 0.085)
	bone.roughness = 0.95
	for mi: MeshInstance3D in skull.find_children(
			"*", "MeshInstance3D", true, false):
		mi.material_override = bone
	# loose aged cards face-down on the felt edges
	for i in range(3):
		var lc := MeshInstance3D.new()
		var lq := QuadMesh.new()
		lq.size = Vector2(0.045, 0.063)
		lc.mesh = lq
		var lm := StandardMaterial3D.new()
		lm.albedo_color = Color(0.16, 0.11, 0.07)
		lm.roughness = 0.95
		lc.material_override = lm
		lc.rotation.x = -PI / 2
		lc.rotation.z = randf() * 0.9 - 0.45
		lc.position = Vector3(-0.3 - i * 0.05, top + 0.008 + i * 0.001,
			0.3 + 0.02 * sin(i * 2.1))
		add_child(lc)
	# wall talismans at the frame edges — gas mask + rat idol, like Inscryption's
	# hanging pelts and charms around the table
	_place("res://assets_external/pawn-models/polyhaven/old_gas_mask/old_gas_mask_1k.gltf",
		"gasmask", Vector3(-1.45, 0.72, -1.35), 0.45, 0.5)
	_place("res://assets_external/pawn-models/polyhaven/street_rat/street_rat_1k.gltf",
		"rat_idol", Vector3(1.42, 0.55, -1.3), 0.4, -0.6)

func _flame_frames() -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for i in range(1, 7):
		out.append(load(PART + "flame_0%d.png" % i))
	return out

func _candles(top: float) -> void:
	var frames := _flame_frames()
	var smoke: Texture2D = load(PART + "smoke_03.png")
	var spots := [
		Vector3(-0.42, top, -0.2), Vector3(0.42, top, -0.2), Vector3(-0.3, top, 0.32),
		Vector3(0.28, top, 0.3),
	]
	var i := 0
	for pos in spots:
		var model := "wooden_candlestick/wooden_candlestick_1k.gltf" if i == 3 \
			else "brass_candleholders/brass_candleholders_1k.gltf"
		var holder := _place(PH + model,
			"candle%d" % i, pos, 0.13)
		var htop := _world_aabb(holder).end.y
		var flame := CandleFlame.new()
		flame.position = Vector3(pos.x, htop + 0.002, pos.z)
		add_child(flame)
		flame.setup(frames, smoke, i * 3.7)
		_flames.append(flame)
		i += 1
	# one shadow-casting hero light: tight warm pool over the felt
	var hero := OmniLight3D.new()
	hero.position = Vector3(0, top + 0.38, -0.02)
	hero.light_color = Color(1.0, 0.58, 0.26)
	hero.light_energy = 0.8
	hero.omni_range = 1.35
	hero.omni_attenuation = 2.6
	hero.shadow_enabled = true
	add_child(hero)
	_hero = hero
	_dust(top)
	_embers(top)
	_contact_shadow(top)

## tiny sparks climbing off the candle flames — sells live fire
func _embers(top: float) -> void:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.5, 0.02, 0.35)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.16
	pm.gravity = Vector3(0, 0.04, 0)
	pm.damping_min = 0.0
	pm.damping_max = 0.02
	pm.scale_min = 0.3
	pm.scale_max = 0.9
	var gp := GPUParticles3D.new()
	gp.amount = 40
	gp.lifetime = 2.2
	gp.preprocess = 2.2
	gp.process_material = pm
	gp.position = Vector3(0, top + 0.06, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.0028, 0.0028)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	dm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	dm.albedo_color = Color(1.0, 0.42, 0.1, 0.5)
	q.material = dm
	gp.draw_pass_1 = q
	add_child(gp)

## radial soft shadow under the devil so he grounds into the floor
func _contact_shadow(top: float) -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0.55))
	grad.set_color(1, Color(0, 0, 0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.width = 256
	tex.height = 256
	var m := StandardMaterial3D.new()
	m.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.1, 0.8)
	q.mesh = qm
	q.material_override = m
	q.rotation.x = -PI / 2
	q.position = Vector3(0, 0.004, -1.05)
	add_child(q)
	# and a second smaller blob under the player's near edge
	var q2 := MeshInstance3D.new()
	var qm2 := QuadMesh.new()
	qm2.size = Vector2(1.2, 0.7)
	q2.mesh = qm2
	q2.material_override = m
	q2.rotation.x = -PI / 2
	q2.position = Vector3(0, top - 0.02, 0.55)
	add_child(q2)

## faint motes drifting through the candle pool — sells the stillness
func _dust(top: float) -> void:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.55, 0.28, 0.35)
	pm.direction = Vector3(0.15, -0.35, 0.05)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.004
	pm.initial_velocity_max = 0.02
	pm.gravity = Vector3.ZERO
	pm.linear_accel_min = 0.001
	pm.linear_accel_max = 0.006
	pm.scale_min = 0.4
	pm.scale_max = 1.0
	var gp := GPUParticles3D.new()
	gp.amount = 90
	gp.lifetime = 9.0
	gp.preprocess = 9.0
	gp.process_material = pm
	gp.position = Vector3(0, top + 0.25, -0.05)
	var q := QuadMesh.new()
	q.size = Vector2(0.0032, 0.0032)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = Color(0.95, 0.7, 0.4, 0.22)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = dm
	gp.draw_pass_1 = q
	add_child(gp)

func _chandelier(top: float) -> void:
	var ch := _place(PH + "lantern_chandelier_01/lantern_chandelier_01_1k.gltf",
		"chandelier", Vector3(0, top + 0.85, -0.05), 0.4)
	var sw := Sway.new()
	sw.amplitude = 0.03
	sw.speed = 0.06
	ch.add_child(sw)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, top + 1.0, -0.05)
	glow.light_color = Color(1.0, 0.55, 0.24)
	glow.light_energy = 0.28
	glow.omni_range = 1.4
	add_child(glow)

func _chip_stack(pos: Vector3, chips: int, tint: Color) -> void:
	for i in range(chips):
		var c := MeshInstance3D.new()
		var cy := CylinderMesh.new()
		cy.top_radius = 0.024
		cy.bottom_radius = 0.024
		cy.height = 0.0038
		cy.radial_segments = 32
		c.mesh = cy
		var m := StandardMaterial3D.new()
		m.albedo_color = tint
		m.roughness = 0.35
		m.metallic = 0.35
		c.material_override = m
		c.position = pos + Vector3(0, i * 0.004, 0)
		add_child(c)

func _chip_stacks(top: float) -> void:
	_chip_stack(Vector3(-0.38, top + 0.014, 0.22), 7, Color(0.25, 0.05, 0.05))
	_chip_stack(Vector3(0.34, top + 0.014, -0.24), 4, Color(0.08, 0.08, 0.09))

func _camera(top: float) -> void:
	_cam = Camera3D.new()
	_cam.fov = 46.0
	add_child(_cam)
	_cam.position = Vector3(0, top + 0.52, 0.85)
	_cam.look_at(Vector3(0, top + 0.06, -0.5), Vector3.UP)
	# dim warm fill from the player's side so card faces and felt read
	var fill := SpotLight3D.new()
	fill.position = Vector3(0, top + 0.7, 1.2)
	add_child(fill)
	fill.look_at(Vector3(0, top, -0.05), Vector3.UP)
	fill.light_color = Color(1.0, 0.62, 0.36)
	fill.light_energy = 0.38
	fill.spot_angle = 40.0
	fill.spot_attenuation = 1.5
	fill.shadow_enabled = true

func _hud() -> void:
	_hud_layer = CanvasLayer.new()
	add_child(_hud_layer)
	_hud_font = load(FONT_CINZEL)
	var title := Label.new()
	title.text = tr("GAME_TITLE") + "   ·   " + tr("BLINDS_LBL") + " 1 / 2 / 3 / 5 / 8 / 13"
	title.add_theme_font_override("font", _hud_font)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.78, 0.42, 0.22))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 14
	title.offset_bottom = 58
	_hud_layer.add_child(title)

func _vignette() -> void:
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;" \
		+ "uniform float inner : hint_range(0.0,1.5) = 0.42;" \
		+ "uniform float outer : hint_range(0.0,2.0) = 1.18;" \
		+ "uniform float strength : hint_range(0.0,1.0) = 0.82;" \
		+ "uniform float grain : hint_range(0.0,0.2) = 0.055;" \
		+ "void fragment(){" \
		+ " float d = distance(UV, vec2(0.5, 0.44)) * 1.7;" \
		+ " float n = fract(sin(dot(UV * (TIME * 6.0 + 1.0)," \
		+ " vec2(12.9898, 78.233))) * 43758.5453);" \
		+ " float a = smoothstep(inner, outer, d) * strength;" \
		+ " COLOR = vec4(0.0, 0.0, 0.0, a + n * grain);" \
		+ "}"
	sm.shader = sh
	r.material = sm
	_hud_layer.add_child(r)

# ---------------------------------------------------------------- runtime

func _process(delta: float) -> void:
	_t += delta
	# camera slow sway
	_cam.position.x = 0.06 * sin(_t * 0.11)
	_cam.position.y += (1.1 + 0.02 * sin(_t * 0.23) - _cam.position.y) * delta
	_cam.look_at(Vector3(0, 0.62, -0.5), Vector3.UP)
	# fire crackle bed: sparse quiet ticks, feels like the room is burning low
	_crackle_in -= delta
	if _crackle_in <= 0.0:
		_crackle_in = randf_range(0.25, 1.6)
		if _sfx != null:
			_sfx.play(Sfx.CRACKLE, randf_range(-30.0, -22.0),
				randf_range(0.5, 0.75))
	_battle.hover_target(_ray_hit().get("collider"))
	if _shot_frames >= 0:
		_shot_frames -= 1
		if _shot_frames == 0:
			_save_shot()

func _ray_hit(mask := 3) -> Dictionary:
	var mp := get_viewport().get_mouse_position()
	var from := _cam.project_ray_origin(mp)
	var to := from + _cam.project_ray_normal(mp) * 6.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collide_with_areas = true
	q.collision_mask = mask
	return get_world_3d().direct_space_state.intersect_ray(q)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_battle.end_turn()
		elif event.keycode == KEY_R:
			_battle.restart()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var col
		if event.button_index == MOUSE_BUTTON_LEFT:
			# pads live on layer 2 and are checked first so card bodies
			# can't swallow clicks aimed at a lane pad
			var pad_hit := _ray_hit(2)
			if not pad_hit.is_empty():
				col = pad_hit.get("collider")
			else:
				col = _ray_hit(1).get("collider")
			_battle.click(col)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			col = _ray_hit(1).get("collider")
			_battle.right_click(col)

func _save_shot() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "C:/Users/Administrator/gwd_shot.png"
	var err := img.save_png(path)
	print("[probe] saved ", path, " err=", err)
	get_tree().quit()

# ---------------------------------------------------------------- helpers

func _world_aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array = [n]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		if c is MeshInstance3D:
			var a: AABB = c.global_transform * c.get_aabb()
			out = a if first else out.merge(a)
			first = false
		for ch in c.get_children():
			stack.push_back(ch)
	return out

func _place(scene_path: String, node_name: String, pos: Vector3,
		target_h: float, rot_y := 0.0) -> Node3D:
	var inst: Node3D = load(scene_path).instantiate()
	return _place_node(inst, node_name, pos, target_h, rot_y)

func _place_node(inst: Node3D, node_name: String, pos: Vector3,
		target_h: float, rot_y: float) -> Node3D:
	var wrap := Node3D.new()
	wrap.name = node_name
	wrap.position = pos
	wrap.rotation.y = rot_y
	add_child(wrap)
	wrap.add_child(inst)
	var ab := _local_aabb(inst)
	var s: float = target_h / maxf(ab.size.y, 0.0001)
	inst.scale = Vector3.ONE * s
	var c := (ab.position + ab.end) * 0.5
	inst.position = Vector3(-c.x * s, -ab.position.y * s, -c.z * s)
	return wrap

func _local_aabb(root: Node3D) -> AABB:
	var inv := root.global_transform.affine_inverse()
	var out := AABB()
	var first := true
	var stack: Array = [root]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		if c is MeshInstance3D:
			var a: AABB = (inv * c.global_transform) * c.get_aabb()
			out = a if first else out.merge(a)
			first = false
		for ch in c.get_children():
			stack.push_back(ch)
	return out

