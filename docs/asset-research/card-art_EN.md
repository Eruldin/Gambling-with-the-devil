# Asset Research — card-art: card visuals, frames, icons (EN)

Category: card frame/template, card back, suit icons (Blades/Kılıç, Chalices/Kupa, Pentacles/Tılsım, Eyes/Göz), seal sigils, stat pips, rarity treatments — plus the pipeline for card illustrations. Constraint from user: cards are real 3D meshes with live textures (viewport art), not flat sprites; everything animates.

## Requirements
| Element | Spec | Source plan |
|---|---|---|
| Card frame | worn parchment/leather look, 4 suit colorways, foil-capable | custom texture over quad mesh; Kenney refs for layout |
| Card back | single occult design | custom (see illustration pipeline) |
| Suit icons | 4 distinct sigils, readable at 16px | game-icons.net CC-BY or custom vector |
| Seal sigils | ~20 rune-like marks | game-icons.net runes or custom |
| Stat pips/icons | attack/health/cost shapes | Kenney boardgame-pack PNGs + custom |
| Rarity treatments | tint/foil variants | shader-driven (anim-vfx doc) |
| Illustration | ~150+ card arts, consistent dark style | AI-assisted base + human paint-over, or commission — pipeline decision needed |

## Sources compared
| Source | License | Verdict |
|---|---|---|
| **Kenney boardgame-pack** | CC0 | ✅ downloaded — pips, chips, dice, card backs for prototyping |
| **game-icons.net** | CC-BY 3.0 | ✅ best icon vocabulary (weapons, chalices, eyes, runes); needs ATTRIBUTION.md |
| OpenGameArt | GPL/CC-SA risk | ❌ |
| itch.io card templates | mixed/paid | ⚠ per-item check; mostly too generic anyway |
| DeviantArt/ArtStation scrapes | non-licensed | ❌ never — license unknown |

## Downloaded
`assets_external/card-art/kenney/boardgame-pack/` — 534 PNGs, 25 vectors, spritesheets (`license.txt` CC0). Use for prototyping card elements and reference layout; final art is custom.

## Illustration pipeline (decision point)
Card faces need ~150+ consistent dark-occult illustrations. Options:
1. **AI-assisted**: SDXL/Flux base gen → human paint-over for consistency (fast, needs style LoRA + curation effort).
2. **Commission**: ~10-15 key arts commissioned, rest derived/templated (slow, highest quality).
3. **Hybrid (recommended)**: AI base for texture/composition → heavy paint-over + shared palette/grading pass → uniform frame hides residual inconsistency.
License note: AI-generated images carry no copyright in most jurisdictions — document the process anyway; avoid artist-name prompts (style/IP risk).

## Integration plan (Godot 4.x)
1. Card = MeshInstance3D (beveled quad) + front/back materials; art via ViewportTexture rendering a CardViewport scene (frame PNG + art + localized text) — enables animated/foil art per design.
2. Frame/art layering: `back | frame | illustration | suit+sigil decals | text (ui-fonts set) | foil shader overlay`.
3. i18n: text layers render via `tr()` keys — TR/EN swap without re-exporting art.
4. Suit icons as SVG→PNG at 4 sizes; seals as separate decal materials so they can glow/pulse.
5. Perf: viewport budget — only visible cards render live (≤12), others use baked snapshots.
6. Testing: readability at arm's-length camera (name + stats legible), TR text fit (longer words), foil at multiple light angles.

## Risks
- Viewport-texture cards are the heaviest line item in the frame budget — cap live viewports, bake the rest.
- Icon consistency across 4 suits + seals — single source (game-icons or one artist) recommended.
- Art pipeline undecided → blocks card-art production; flagged for user decision.
