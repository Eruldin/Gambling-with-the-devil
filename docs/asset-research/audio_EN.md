# Asset Research — audio: SFX, ambience & music (EN)

Category: card/table foley, UI sounds, ambient loops, creature/boss one-shots, win/lose stingers, and the music plan. Dark candlelit-table soundscape. Target: Godot 4.x audio buses.

## Requirements
| Class | Examples | Source plan |
|---|---|---|
| Card foley | draw, deal, slide, flip, slap-down | Kenney casino-audio |
| Chip/pot | clink, stack, push, scatter | Kenney casino-audio |
| Dice/seals | roll, bone clicks | Kenney casino-audio |
| UI | hover tick, confirm, error, page turn | Kenney interface-sounds |
| Ambience | candle room tone, wind, fire crackle | Freesound CC0 (later; needs API key) or generated noise loop |
| Sacrifice/VFX | whoosh, dissolve, squelch | Kenney impact-adjacent picks + synth layering |
| Boss/creature | growls, whispers, bells | Freesound/CC later or synthesized — flagged gap |
| Stingers | win, lose, blinds-up | custom/synth |
| Music | table loop, tension layers, boss themes | original composition — licensed tracks rejected (see below) |

## Sources compared
| Source | License | Verdict |
|---|---|---|
| **Kenney audio packs** | CC0 | ✅ downloaded casino-audio + interface-sounds |
| **Freesound.org** | CC0 / CC-BY / CC-BY-NC per file | ⚠ usable with per-file license filter (CC0 only); requires account — defer |
| BBC Sound Effects | RemArc (non-commercial) | ❌ rejected — commercial use excluded |
| OpenGameArt | GPL/CC-SA risk | ❌ rejected |
| Kevin MacLeod (incompetech) | CC-BY 3.0 | ⚠ fallback only — attribution burden |
| Unity/Unreal audio | store license | ❌ |

## Downloaded
`assets_external/audio/kenney/casino-audio/` — 59 files: card foley, chips, dice (`License.txt` CC0).
`assets_external/audio/kenney/interface-sounds/` — 104 files: UI clicks/confirms/errors/bells (`License.txt` CC0).
Both in original zips alongside extracted dirs (~4MB total).

## Gaps
- **Ambience bed** (candle room tone, distant wind) — best sources: Freesound CC0 items or a generated noise/rumble loop; needs later session w/ freesound account.
- **Music** — deliberate decision: original layered composition (low drone + sparse piano/celesta + tension stems per blinds level). No pack found that fits license + mood; composing or commissioning recommended.
- **Voice/whisper effects** — record or synthesize; no clean CC0 whisper pack located.

## Integration plan (Godot 4.x)
1. Audio buses: `Master > Music, Ambience, SFX, UI` — casino→SFX, interface→UI.
2. `AudioManager` autoload with pooled AudioStreamPlayer3D (positional on table) + AudioStreamPlayer (UI/2D); randomize pitch ±5% on repeats to kill machine-gun feel.
3. Map: card draw→`cardX.ogg`, play→`cardPlaceX`, chips→`chipLayX`, blinds-up→bell+bass stinger.
4. Ambience: seamless loop on Ambience bus at −18dB under everything; duck under music swells.
5. Format: keep .ogg/.wav as shipped; convert to ogg if a pack is wav-only (size).
6. Testing: play 100 random triggers, watch for clipping on SFX bus; verify ducking and positional falloff vs table camera.

## Risks
- Kenney SFX are clean/gamey — need EQ/reverb to sit in the occult scene (planned mix pass).
- Music is the biggest unresourced item — flagged explicitly rather than settling for a license-burdened track.
