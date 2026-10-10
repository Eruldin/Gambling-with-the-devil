# Asset Research — pawn-models: board pieces & markers (EN)

Category: the physical 3D pieces standing on the felt as card representations — pawns (Piyon), idols (Put), seals (Mühür tokens), creature markers, plus trinket props. Requirement: small readable silhouettes, occult look, animated (idle sway, spawn/despawn, attack lunges), Godot 4.x.

## Requirements
| Piece class | Count | Spec | Source plan |
|---|---|---|---|
| Base pawns (card bodies) | ~6 archetype silhouettes | 5–15cm standing, distinct outlines | chess_set pieces (king/queen/bishop/knight/rook/pawn map to card archetypes) |
| Idols/boss pieces | 3–5 | larger, imposing | marble_bust, gothic_statue, horse_statue |
| Creature pawns | vermin/familiar types | small | street_rat, concrete_cat_statue |
| Seal/chip tokens | stackable markers | flat cylinders/coins | custom simple meshes (trivial) |
| Trinkets/props | mask, etc. | table dressing | old_gas_mask etc. |

## Sources compared
| Source | License | Format | Verdict |
|---|---|---|---|
| **Poly Haven** | CC0 | glTF + PBR | ✅ downloaded 6 items — chess_set is a near-perfect pawn family (6 silhouettes) |
| **Quaternius MegaKits** | CC0 (60–70% free) | glTF/FBX, Godot-ready | ✅ best next pass — stylized creatures, skeletons, monsters (not yet downloaded: pack is large, curate per-need) |
| **KayKit** (Skeletons/Adventurers) | CC0 | GLB | ✅ cartoon-proportioned figurines, animated rigs — candidate for creature pawns |
| Sketchfab CC | CC0/CC-BY | varies | ⚠ occult figurines exist but per-item license check mandatory |
| OpenGameArt | GPL/CC-SA risk | varies | ❌ |

## Downloaded (`assets_external/pawn-models/polyhaven/`, 6 items, ~18MB, all CC0)
- `chess_set` — 32 pieces + board: six archetype silhouettes ready-made (pawn→Söz/Peasant cards, rook→Çuha defenders, knight→attackers, bishop→seal-casters, queen→elite, king→boss-proxy). Realistic-marble look fits the candlelit table.
- `marble_bust_01`, `horse_statue_01`, `concrete_cat_statue`, `old_gas_mask`, `street_rat` — idols, familiars, occult trinkets.
- Cross-ref: `gothic_statue` in env-table pack doubles as a large idol.

## Gaps
- **Skull/bone pawns** — none on Poly Haven; Quaternius Fantasy/Skeleton packs (CC0) are the fix.
- **Raven/goat pieces** — Sketchfab CC or Quaternius; flagged for next pass.
- **Seal tokens** — custom flat cylinders with sigil decals (card-art icons) — trivial custom meshes, no download needed.

## Integration plan (Godot 4.x)
1. Import glTF into `res://models/pawns/`; chess pieces split into individual scenes (pawn/rook/knight/bishop/queen/king) — single mesh each, shared marble material.
2. Scale to ~8–14cm world height; snap base to felt plane (Y=0).
3. Animations: code-driven — idle breathing scale (1±0.02), spawn = rise-from-felt + dust burst (Kenney particles), attack = lunge tween toward lane target, death = tip-over + dissolve shader (anim-vfx doc).
4. Selection/hover: emissive rim shader + slight lift.
5. Perf: ≤10 pieces on board, each <3k tris — trivial budget; enable cast shadows only for the 2–3 key light sources.
6. Testing: silhouette readability at battle camera distance (name each piece without UI), spawn/death feel vs 300–500ms spec, no z-fighting on felt.

## Risks
- Realistic marble chess set vs. stylized occult theme — planned tint/blood/wax shader passes to unify style.
- chess_set board mesh included — ignore it; pieces only.
- Creature-pawn variety still thin — Quaternius/KayKit pass recommended before content lock.
