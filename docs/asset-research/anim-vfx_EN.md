# Asset Research — anim-vfx: animation & visual effects (EN)

Category: everything that moves or glows — card motion (draw/play/hover/attack/destroy), board effects (sacrifice, seal triggers, chip transfers, pot growth), ambient scene effects (candle flames, smoke, embers, dust, vignettes), feedback (bluff-call flashes, win/lose sequences). User requirement: nothing static — "animasyonsuz iş yapmayacaksın". Target: Godot 4.x, 3D scene + Control overlays.

## Requirements
| Effect class | Technique | Assets needed |
|---|---|---|
| Card play/summon | Tween + GPU particles | flipbook sprites, glow/magic-circle decals |
| Sacrifice | particle burst + dissolve shader | smoke/ember sprites, dissolve noise texture |
| Chip/pot movement | Tween chains | none (mesh animation) |
| Candle flames & smoke | shader + flipbook sprites | flame/smoke particle sprites |
| Ambient | GPUParticles3D | dust/ember sprites, fog |
| Attack/damage feedback | Tween + flash shader | hit sparks, screenshake (code) |
| Bluff/Call/Tell reveals | UI anim + light pulse | magic-circle rune sprites |
| Win/lose, level transitions | scene anim + particles | confetti-vs-ash sprites |

## Sources compared
| Source | License | Format | Verdict |
|---|---|---|---|
| **Kenney Particle Pack** | CC0 | 98 transparent PNGs | ✅ downloaded — flames, smoke, sparks, magic circles, symbols |
| **Effekseer** | MIT | runtime + .efk effects | ✅ candidate engine-level particle tool w/ Godot plugin — evaluate vs native GPUParticles3D |
| **Godot VFX demos/libs** (e.g. godot-shaders repos) | MIT mostly | shader code | ✅ code refs for dissolve/foil/holo card shaders — adapt, don't copy wholesale |
| itch.io VFX packs | mixed (often CC0 or paid) | sprites/flipbooks | ⚠ per-item license check; good for flipbook fire/blood later |
| OpenGameArt | GPL/CC-SA risk | mixed | ❌ avoid for production |
| Unity/Unreal VFX | store license | engine-locked | ❌ |

## Downloaded
`assets_external/anim-vfx/kenney/particle-pack/` — 98 transparent PNG sprites + black-background variants + License.txt (CC0). Covers flame, smoke, spark, star, circle, magic-rune, trace, twirl families — usable as GPUParticles3D sprite textures and card-effect decals.

## Custom work required (no pack substitutes)
- **Card material shaders**: foil/holo, dissolve-on-sacrifice, emissive seal glow — write custom canvas_item/spatial shaders (references: godot-shaders.com tutorials, MIT snippets).
- **Candle flame**: procedural shader (vertex sway + emissive gradient) over Kenney flame sprite as fallback.
- **Physical chip/card motion**: Tween + AnimationPlayer — pure code, no assets.
- **Screenshake/hitstop**: Camera3D code.
- **The "deal" sequence**: multi-stage animation (deck slide → place → reveal flip) — code-driven.

## Integration plan (Godot 4.x)
1. GPUParticles3D emitters as children of card/pawn scene roots; sprite textures from particle-pack (transparent set; use black-bg set only for additive `blend_add` materials).
2. One `VFXManager` autoload: spawn(name, position, params) → pooled emitters; never instance particles ad hoc.
3. Shader library: `res://shaders/` — dissolve (noise tex + edge emissive), foil (view-dependent rainbow tint), flame flicker (vertex sway + scroll), card-hover highlight.
4. Animation priority: gameplay-readable beats (draw 300ms, play 400ms, attack 250ms, destroy 500ms) — ambient loops run in parallel, never blocking input.
5. Perf: particle budgets (max ~6 concurrent emitters, ≤200 particles each), additive blend for glows, disable off-screen emitters via visibility_notifiers.
6. Testing: frame-by-frame review of sacrifice + attack sequences vs the 60fps target; verify no particle leak after 50 effects.

## Risks
- Kenney sprites are generic — style-matching the occult palette needs tint/shader passes (planned).
- Effekseer adds a plugin dependency — decide after a GPUParticles3D prototype.
- Over-animation risk vs pacing: keep animation times capped and skippable (design doc §pace).
