# Asset Research — ui-fonts: typography for UI & cards (EN)

Category: fonts for UI, card names/rules text, numbers, and bilingual (TR+EN) text rendering. Dark occult aesthetic, must support Turkish glyphs (ğşıİçöü), readable at small sizes on cards.

## Requirements
| Role | Style | Weight range | Notes |
|---|---|---|---|
| Card names / headers | engraved serif, occult | 600–800 | display only |
| Rules / body text | readable serif | 400–600 | 12–18px on card |
| UI chrome / menus | elegant serif or smallcaps | 400–700 | buttons, HUD |
| Numbers (chips, HP, cost) | tabular/mono | 400–800 | stats must not shift |
| Manuscript/event text | antiquarian hand-print | 400 + italic | lore-adjacent panels |

## Sources compared
| Source | License | Verdict |
|---|---|---|
| **Google Fonts** | OFL-1.1 (all fonts) | ✅ primary — free commercial, TTF, guaranteed Turkish subsets |
| Font Squirrel | mixed per-font | ⚠ usable but redundant — GF catalog covers picks |
| itch.io font packs | mixed | ⚠ per-item check; niche pixel fonts not needed here |
| DaFont / 1001fonts | many "free for personal use" | ❌ license trap — most forbid commercial use |
| Adobe Fonts | subscription-tied | ❌ redistribution not allowed |

## Downloaded picks (`assets_external/ui-fonts/`, 5 families, OFL-1.1)
| Font | Role | Why |
|---|---|---|
| **Cinzel** | card names, headers, boss titles | engraved Roman capitals — occult/dignified, all-caps display |
| **Cormorant Garamond** | UI chrome, menu headers | elegant high-contrast serif, pairs with Cinzel |
| **IM Fell English** | event/manuscript text, special card text | genuine 17th-c. Fell type revival — the "old book" voice |
| **Alegreya** | card body/rules text | designed for long-form reading at small sizes; strong Turkish glyph set |
| **JetBrains Mono** | chip counts, damage numbers, debug | tabular figures — stable stat readouts |

Pairing: Cinzel (titles) + Alegreya (body) + JetBrains Mono (numbers) is the working set; Cormorant and IM Fell are accent/context fonts.

## Gaps / notes
- If a handwritten "deal" script is wanted later for signatures, add **Nanum Pen Script**-style or GF "Caveat"/"Kalam" (OFL) — not downloaded (readability risk for Turkish).
- Icon font need is TBD — likely custom SVG icons instead (see ui category in card-art scan).
- TR+EN verified: all five ship latin-ext subsets (Turkish glyphs confirmed in GF specimen).

## Integration plan (Godot 4.x)
1. Drop .ttf into `res://fonts/`; create `FontFile` resources; enable **MSDF** (multichannel signed distance field) for Cinzel/Cormorant at dynamic sizes — crisp at any card zoom.
2. Theme defaults: body=Alegreya 16px, headers=Cinzel, numbers=JetBrains Mono; set per-Control overrides, not per-label.
3. i18n: single font stack covers TR+EN — no per-locale font swap needed; keep `tr()` keys as designed.
4. Perf: pre-import fallback chain `Cinzel→Cormorant→system serif`; MSDF atlas ~4MB per family — acceptable.
5. Testing: render a card at 0.5×–2× zoom, check Turkish glyphs (Ğüşİıçö), contrast on dark felt background (min 4.5:1), and number stability during chip-count tweening.

## Risks
- IM Fell's distressed glyphs look poor at <14px — reserve for large panels.
- MSDF atlases add memory; limit MSDF to the 3 working fonts.
