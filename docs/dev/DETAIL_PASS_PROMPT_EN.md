# Detail-Pass Work Prompt — "wow" tier
*(Avenox principle: write only what the model can't know itself — goal, reason, boundaries, done-criteria, repeated mistakes. Decision info, not instructions.)*

## Goal
The player looks at the screen and says one word: "wow". Three requirements:
1. **The Devil belongs to the world** — movement is heavy, purposeful, reasoned.
2. **The table reads as real material** — textured wood, textured felt, light-catching surfaces.
3. **No cartoon detail** — nothing may read as cheap as "two red dots".

## Boundaries (never cross)
- The head does NOT track the cursor. Gaze turns only for game events (`watch`); at rest it faces the player.
- NO random twitch/snap/sway. Idle = breath (very light) + blink (rare) only.
- NO glowing eye orbs / halo quads — the model's own face texture + in-hood light reads the face. "Eye flare" is now the face light surging.
- Never FLATTEN model textures — darkening = albedo_color multiplier; keep albedo_texture/normal/ARM.
- Motion is always slow and heavy: head turns ~0.4s+, cubic tweens, speed multipliers < 1.
- All lerp weights clamped (the NaN lesson).

## Done criteria
- AUTO round + SHOT render: 0 script errors, 0 `is_finite`.
- In frame: no eye orbs, wood grain readable on the table, woven felt texture, devil alive while still (breath + anim), one meaningful head move per event.

## Repeated mistakes (this session's complaints)
1. Random-feeling motion → cause: cursor-tracking + snap twitch + continuous sway stacked. Fix: cursor-track deleted, twitch deleted, sway reduced to breath.
2. "Two red dots look silly" → cause: emissive orb + additive halo quad floating off the face. Fix: fully deleted.
3. "Table has no proper textures" → cause: flat material_override crushing the GLB's 1k diffuse/normal/ARM. Fix: keep textures, tint instead; procedural cloth for the felt.
