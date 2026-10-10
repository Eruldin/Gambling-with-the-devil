# Prototype — candlelit 3D table scene (EN)

First playable visual milestone: the Inscryption-style candlelit card table, assembled entirely from the licensed asset packs scanned earlier (Poly Haven CC0 + Kenney CC0). Godot 4.7.2, `gl_compatibility` renderer (safe on this VM; switch to `forward_plus` on real GPUs for SSR/glow).

## Run it
```
Godot_v4.7.2-stable_win64.exe --path .
# or open project.godot in the editor and press F5
```
Screenshot probe: `GWD_SHOT=1 godot --path .` → saves `C:/Users/Administrator/gwd_shot.png` then quits.

## What's in the scene
- Wooden table + dark felt board with two rows of five lane pads (The Felt)
- 4 candle holders with flipbook flames, flickering omni lights, rising smoke + one shadow-casting hero light
- Hanging lantern chandelier with sway animation
- Armchairs, bookshelf, gothic cabinet, statue, grandfather clock, chest, crate, lantern, table props (books, jug, bowl, bottles, dagger)
- Chess-set pawns instanced onto lanes (black king/knight/pawn vs white pawn/bishop)
- 5-card hand fanned toward camera (Kenney faces) + 2 face-down enemy cards; deal-in tween animation
- Hover inspection: card lifts, scales and tilts toward the viewer (mouse raycast)
- Soul-chip stacks (cylinder tokens)
- Bilingual HUD wiring: `i18n/gwd.en.po` + `gwd.tr.po` via `tr()` (Cinzel font from the ui-fonts pack)

## Animation coverage (the "no static work" bar)
Camera sway, flame flipbook + light flicker, smoke rise/fade loop, chandelier sway, card idle bob + deal + hover lift/tilt. Pawn idle anims come with the battle prototype.

## Structure
```
project.godot         — GL-compat renderer, main scene, i18n registrations
scenes/main.tscn      — root Node3D
scripts/main.gd       — scene assembly + camera/HUD/hover/probe
scripts/game_card.gd  — card mesh + deal + hover anim
scripts/candle_flame.gd — flame flipbook + flicker + smoke
scripts/sway.gd       — generic sway
i18n/gwd.{en,tr}.po   — translation keys
```
Assets are referenced in place from `assets_external/` (glTF loads natively; Godot imported them at `--import`).

## Next steps
- Battle loop: lanes wired to design doc rules (concealed placement, Blinds, Call the Bluff)
- Card faces → ViewportTexture pipeline (localized text + foil shader)
- Pawn archetype set → swap to occult silhouettes; dissolve-on-sacrifice shader
- Renderer: flip to `forward_plus` on target hardware for bloom/SSAO

## Battle slice (proto/battle-loop)
Round loop per the design doc: both sides ante the current Blind (1/2/3/5/8/13 chips), then place cards **concealed** (face-down) on their lane row; SPACE / REVEAL flips everything, cards stand as units, and each lane strikes the lane opposite — unit-vs-unit damage first, chip damage on open lanes. Blood (2/round) gates placement cost; right-clicking a hand card sacrifices it for `sacrifice_value` blood. Scripts: `battle.gd` (state machine, enemy AI, HUD), `card_def.gd` (card anatomy + 10-card starter deck), `game_card.gd` (select/glow, place/reveal/lunge/flash/die/burn). `GWD_AUTO=1` auto-plays a scripted round for headless probes.
