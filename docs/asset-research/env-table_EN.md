# Asset Research — env-table: 3D table scene & environment (EN)

Category: the 3D battle table and its environment for **Gambling with the Devil** — heavy carved table, candles, occult props, den/parlor room. Visual target: original take on the candlelit Inscryption-style scene; real 3D meshes, animated, commercial-indie quality. Target engine: Godot 4.x (GLB/glTF preferred).

## Requirements analysis
| Need | Spec | Format | Budget |
|---|---|---|---|
| Hero table | heavy wood, single mesh, ~1–2m | GLB/glTF + PBR | <20k tris |
| Candles/lights | several variants, flame separate for shader anim | glTF | low |
| Props | books, chest, jug, bowl, mirror, dagger, clock, crates, barrels | glTF | <5k tris each |
| Room shell | walls/floor/door/backdrop | kitbash pieces or built geo | — |
| Textures | wood/felt/metal/wax PBR | 1–2k jpg/ktx2 | tileable |
| HDRI | dark moody interior ambient | .hdr 1–2k | lighting only |

## Sources compared
| Source | License | Format | Verdict |
|---|---|---|---|
| **Poly Haven** | CC0 | glTF/FBX/blend + PBR | ✅ primary — verified CC0, public API, high quality |
| **Quaternius Fantasy Props MegaKit** | CC0 (60–70% free) | glTF/FBX/OBJ; Godot-ready source version | ✅ strong for medieval props (skulls, potions, books, chests, candles) — free tier suffices |
| **ambientCG** | CC0 | PBR texture maps | ✅ wood/felt/leather/wax tiles |
| **KayKit** | CC0 | GLB | ✅ dice/chip props |
| Sketchfab (CC0/CC-BY) | mixed | varies | ⚠ per-item license check required — use only for hero pieces (carved table, balance scales, hourglass) not found elsewhere |
| OpenGameArt | mixed (GPL risk) | varies | ❌ license minefield — avoid for production |
| Unreal/Unity marketplace | per-pack | engine-locked | ⚠ check "can be used in other engines" clause per pack |

## Downloaded picks (in `assets_external/env-table/polyhaven/`, 20 models, ~55MB, all CC0)
Candles & light: `brass_candleholders`, `wooden_candlestick`, `wooden_lantern_01`, `lantern_chandelier_01`.
Furniture: `WoodenTable_02` (hero table), `ArmChair_01`, `WoodenChair_01`, `wooden_bookshelf_worn`, `GothicCabinet_01`.
Props: `book_encyclopedia_set_01`, `treasure_chest`, `ornate_mirror_01`, `gothic_statue`, `jug_01`, `wooden_bowl_01`, `wine_bottles_01`, `Barrel_01`, `wooden_crate_01`, `vintage_grandfather_clock_01`, `ornate_medieval_dagger`.
See `assets_external/env-table/LICENSES.md` for per-item license entries.

## Still needed (gaps for later scans / custom work)
- **Balance scales** (signature prop — likely custom or Sketchfab CC item; license-check per item)
- **Skull/bone piles** — Quaternius Fantasy Props MegaKit / Sketchfab CC0
- **Hourglass, quill+inkwell, chip stacks, dice** — KayKit dice (CC0); chips = simple custom cylinders
- **Room shell** — `large_castle_door` (PH) exists; walls/floor best built from tileable ambientCG textures + modular geo
- **Felt/cloth table surface** — ambientCG fabric texture over table top
- **HDRI** — pick a dark interior HDRI from Poly Haven HDRIs (not yet downloaded; e.g. search polyhaven.com/hdris for "dark"/"candle")

## Integration plan (Godot 4.x)
1. Drag `.gltf` (with `.bin` + `textures/` siblings) into `res://models/env/` — Godot imports glTF natively; keep 1k textures, swap to 2k only for hero table.
2. Merge per-prop materials where possible (PH models each carry own mats — plan a shared `wood_pbr`/`metal_pbr` material swap pass for draw-call batching).
3. Candles: hide baked flame sprite; drive `flame` material with a custom flicker shader (vertex sway + emissive pulse) + PointLight3D per group (max ~4 active shadows).
4. Table felt: overlay quad with cloth texture (ambientCG `fabric`/`felt`), slight green-black tint.
5. Perf: static props → `StaticBody3D`+trimesh or convex collision only where interacted; enable occlusion culling; target <1M tris scene, <150 draw calls after batching.
6. Testing: load in a test scene, orbit camera, check material correctness under a single warm PointLight + low ambient (WorldEnvironment ambient_light_energy ~0.05), confirm 60fps at target res.

## Risks
- PH models are archviz-grade (1k–20k tris) — watch total scene budget; decimate hero pieces only if needed.
- `.gltf` + external textures: keep folder structure intact on import.
- Sketchfab gap-fills: CC0 preferred; if CC-BY used → attribution file mandatory.

## Next step
`pawn-models`, `card-art`, `anim-vfx`, `audio`, `ui-fonts` categories are queued for worker sessions when SWE-2 capacity frees.
