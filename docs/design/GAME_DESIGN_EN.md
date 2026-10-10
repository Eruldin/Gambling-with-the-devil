# GAMBLING WITH THE DEVIL
## Complete Gameplay Framework — Design Document (EN)

*Dark strategic roguelike deckbuilder. Mechanics-first design.*
*This document defines systems only: no story, art direction, or lore. Every mechanic exists to create decisions.*

---

# 1. CORE GAMEPLAY SUMMARY

## The one-sentence game
You sit at a candlelit table across from the Devil and gamble pieces of your soul — literally — on a tactical card duel where every card placed is a bet, every bet is hidden, and every victory is paid out of a pot both players fed with their own blood.

## Design pillars
1. **Every action is a wager.** Your life total *is* your mana. Playing a card, calling a bluff, or raising the pot all spend the same chips the enemy is trying to take from you.
2. **Hidden information creates bluffing.** Cards are set face-down. The enemy sees *that* you bet, and *how much* — never *what*. Poker's tension lives inside a tactics board.
3. **Power has a price.** Debt, corruption, sacrifice, over-merging. The strongest moves borrow from your own future.
4. **The table remembers.** Cards scar, evolve, get tattooed to your ledger, and come back wrong. Attachment is a resource you can spend.
5. **The house always escalates.** An ever-rising ante (the Blinds) ends every duel. Stalling is mathematically impossible — only decisive play survives.

## Why this is mechanically different from its inspirations
- *Slay the Spire* uses mana; we use a **unified life/mana pot** — every play hurts.
- *Inscryption* uses blood sacrifice on an open board; we use **concealed deployment + a shared, escalating pot** — the battle itself is the gamble.
- *Magic: The Gathering* has instants; we have **Tells, Calls, and Raises** — information warfare over a hidden board.
- *Poker* has psychological stake; we make stake **literal, visible, and persistent** through the run (the Ledger, Debt, Devil's Credit).

## Player fantasy check (emotions we engineer for)
- "I found something powerful" → grafting/mutation combos discovered organically.
- "I built this myself" → decks are *assembled* (merge/graft/tattoo), not just drafted.
- "I shouldn't have survived that" → the pot grows with your wounds; comebacks are the biggest payouts.
- "I sacrificed something important" → sacrifice removes a slot, a future, a friend.
- "One more run" → debts and corruptions echo into the next run via the Ledger.

---

# 2. COMPLETE BATTLE RULES

## 2.1 The battlefield — "The Felt"
A physical table rendered in full 3D (see §17 for engine/animation requirements).

```
                 ENEMY MANTEL (3 effigy slots)
        [E]   [E]   [E]   [E]   [E]        ← enemy BACK row (5)
        [F]   [F]   [F]   [F]   [F]        ← enemy FRONT row (5)
   ─────────────────────────────────────────
                 THE POT (center)
   ─────────────────────────────────────────
        [F]   [F]   [F]   [F]   [F]        ← player FRONT row (5)
        [B]   [B]   [B]   [B]   [B]        ← player BACK row (5)
                 PLAYER MANTEL (3 effigy slots)
```

- **5 lanes.** Each lane pairs one front slot and one back slot per side.
- **Front row** — strikers and blockers. Only front-row cards Clash.
- **Back row** — support pawns and protected cards. A back-row card can only be damaged when its lane's front slot is empty, or by a card with **Reach**.
- **Mantel** — 3 shared slots per side for **Effigies** (passive engines). Mantel cards never Clash and cannot be attacked by clashes; only tricks/abilities that explicitly target the mantel can touch them.
- **The Pot** — a physical pile of chips at center table. It is visible, grows, and is the prize.

## 2.2 Battle setup
- Player enters with **Soul Chips = persistent life pool** (run starts at 40; carries between battles).
- Enemy has a chip pile sized by encounter tier (standard 25–40, Deep Table 45–70, Boss varies by mechanic).
- Opening: player draws to 5, may **mulligan once** (shuffle back any number, draw same count, keep).
- Enemy deals 0–2 concealed cards pre-seeded on the Felt (shown as silhouettes + stake size).

## 2.3 Turn structure

### PLAYER TURN
1. **Ante (the Blinds).** The current ante is pulled from **both** chip piles into the pot. The ante escalates (see 2.6). This is the doom clock.
2. **Draw.** Draw 1 card. If your deck is empty, the draw is a **Soul Draw**: it costs 2 chips per card drawn, paid immediately (thin decks bleed).
3. **Stake Phase** — perform any number of actions, in any order, then declare **Call**:
   - **Set** a card face-down into an empty front/back slot (pay cost in chips and/or flesh).
   - **Play a Trick** — resolves immediately, no slot.
   - **Sacrifice** one of your cards (face-down OR revealed) → gain **Flesh** equal to its Sacrifice Value; card goes to the Heap (graveyard).
   - **Raise** — once per turn, stake 1–5 extra chips into the pot. Triggers "when you raise" seals; grows the prize; pressures the enemy's plan.
   - **Activate** tap-style abilities on revealed cards (costs as printed).
   - **Call the Bluff** — once per battle: pay 2 chips, flip one enemy concealed card now. If it's a **Bluff**-type card, it is destroyed and the enemy loses 2 chips. If it's real, it stays revealed (you paid for information).
   - **Reposition** — move one revealed card between front/back, or swap lanes with another card. Each card may reposition once per battle.
   - **Use a Trump** — consumable cheats (see resources), max 3 held.
4. **The Reveal.** All cards set face-down this turn flip face-up. On-Reveal seals trigger, in lane order left-to-right, front then back.
5. **The Clash.** Each of your front-row pawns strikes its lane:
   - **Occupied lane** → mutual damage: both cards deal Attack to each other simultaneously. Wounds persist (Defense does not regenerate). If your striker has **Sharp**, it hits first; a kill prevents the counter.
   - **Empty lane** → the pawn deals its Attack to the enemy's chip pile. For every point of chip damage dealt this way, **1 chip antes into the pot**.
   - Back-row pawns with **Reach** may strike the opposing front card (or a back card if front is empty).

### ENEMY TURN — mirrors the same structure.
The enemy's face-down placements show: the **stake size** (chips spent) and a **Tell** — a small hint icon (suit mark, posture, or card back). Tells can be read, faked (Bluff cards lie about stake), or silenced.

### Round ends. The Blinds tick up per schedule.

## 2.4 Damage and the Pot
- Chip damage (unopposed attacks, some tricks) removes chips 1:1 from the victim's pile **and antes an equal amount into the pot**.
- Pawn damage wounds cards; wounds persist for the battle.
- **The Pot is the prize:** on victory, the winner converts the pot → **Embers** at 1:1 (the crafting currency). The more violence happened — on either side — the fatter the payout.
- Consequence: *losing slowly feeds a pot you can still win*. A comeback isn't just survival — it's the biggest payday on the table.

## 2.5 Victory, defeat, and the Final Wager
- **Victory:** enemy chips reach 0 → you claim the pot as Embers + the node's rewards.
- **Defeat:** your chips reach 0 → the **Final Wager** triggers once per run: the Devil offers to deal you back in at 10 chips. Price: **Debt +15** and a **Mark** (a permanent run curse). Accept and fight on; decline and the run ends.
- **Stalling is impossible:** the Blinds guarantee a kill within ~15–20 rounds even in pure-defense boards.

## 2.6 The Blinds (escalation schedule)
| Rounds | Ante (each side, per turn) |
|---|---|
| 1–3 | 1 |
| 4–6 | 2 |
| 7–9 | 3 |
| 10–12 | 5 |
| 13–15 | 8 |
| 16+ | 13 (then +5/round) |

Both sides pay — so a dominant enemy is also bleeding into your prize pot. The player sees the ante schedule as a physical candle burning down on the table.

## 2.7 Why a weaker deck can beat a stronger one
- **Face-down commitment** lets cheap decoys drain enemy Calls and misdirect their removal.
- **The pot** rewards whoever times violence, not whoever owns bigger numbers.
- **Tells + Call** turn information into a resource you can buy, fake, or steal.
- **Sacrifice timing** converts losing board positions into flesh for a single decisive turn.
- **Raises** let a losing player inflate the pot on purpose — then steal it back with a burst (the "short-stack shove").

## 2.8 Comeback mechanics (explicit)
- Pot-as-prize (your wounds literally inflate your reward).
- Final Wager (one-time Devil's bail-out, at terrible terms).
- Desperation seals (cards with "while your chips ≤ 10, gains …").
- Debt as a comeback lever — power now, pay later.

---

# 3. CARD SYSTEM

## 3.1 Card anatomy
Every card carries the full template:

| Field | Meaning |
|---|---|
| **Name** | Identity. Cards with names, not numbers. |
| **Type** | Pawn / Trick / Effigy |
| **Cost** | Chips (always) and/or Flesh (big summons) |
| **Attack** | Clash damage (0 for pure support) |
| **Defense** | Wound capacity, persists per battle |
| **Ability** | The card's text — triggers, actives |
| **Passive** | Always-on rule while revealed |
| **Seal slots** | 0–3 modular ability slots (graftable) |
| **Synergy tags** | Suit (Tılsım/Kupa/Kılıç/Göz ↔ Pentacle/Chalice/Blade/Eye) + archetype flags (Debt, Brood, Court, Chance, Ash) |
| **Sacrifice value** | Flesh yielded on sacrifice |
| **Transformation potential** | Merge tier, mutate line, corrupt slots |

### Card types
- **Pawn** — occupies front or back row; can Clash (front) or support (back).
- **Trick** — instant one-shot; resolves immediately on play. Sub-tag *Lingering* tricks attach to a card or lane instead of discarding.
- **Effigy** — occupies a mantel slot; passive engine; immune to clashes.

## 3.2 The four suits (identity axes)
- **Blades (Kılıç)** — aggression, wound pressure, kill-snowball. Weakness: the pot tempts overcommit.
- **Chalices (Kupa)** — blood, flesh, sacrifice, healing. Weakness: consumes its own board.
- **Pentacles (Tılsım)** — chips, the pot, debt, economy. Weakness: greed is exploitable.
- **Eyes (Göz)** — information, reveals, copies, manipulation. Weakness: thin stats.

Archetype tags cut across suits: **Debt** (credit synergies), **Brood** (deathspawn), **Court** (pawn-buff), **Chance** (coin/dice RNG), **Ash** (graveyard recursion).

## 3.3 Seals — the modular ability grammar
Seals are sigils grafted onto seal slots. Every seal has a listed **counter-vector** — nothing is free.

### Offensive
| Seal | Effect | Counter-vector |
|---|---|---|
| Sharp | Strikes first in a clash; kill = no counter | Ward, high-Defense walls |
| Pierce | Excess clash damage hits chips | Wide boards (no overkill target) |
| Venom | Wounded cards take +1 at round start (stacks 3) | Sacrifice/recycle their wounded |
| Executioner | +3 Attack vs already-wounded cards | Fresh walls |
| Rampage | After a kill, strikes again (−2 Attack) | Cheap fodder blocks |
| Ambush | May strike back row directly | Mantel/Anchor guard placement |

### Defensive
| Seal | Effect | Counter-vector |
|---|---|---|
| Bulwark | Cannot be countered when attacked | Unopposed lanes bypass it |
| Wax Skin | Negates first wound each round | Multi-hit (Rampage, extra strikes) |
| Revival | On death returns to hand (once/battle) | Exile/burn effects (Ash counters) |
| Ward | Immune to enemy tricks | Raw clashes |
| Anchor | Cannot be moved, swapped, or displaced | — (immune to Swap/Fate's Spider) |

### Economy
| Seal | Effect | Counter-vector |
|---|---|---|
| Tithe | On play: +2 chips | Slows the board (a turn spent not fighting) |
| Molt | +1 extra Flesh on sacrifice | Flesh only helps if you bank big summons |
| Loan Shark | On Reveal: +2 chips, Debt +1 | Debt compounds |
| Pot Odds | On Reveal: +1 chip per 5 in pot | Small pots |
| Brood | On death: spawn a 0/1 Grub | Exile, Hollow King |

### Manipulation
| Seal | Effect | Counter-vector |
|---|---|---|
| Peek | On Reveal: see one enemy concealed card | Bluff/fake stakes |
| Veil | Cannot be Called | Tricks, patience |
| Mimic | On Reveal: copies seals of the opposing card | Mirrors your own counters |
| Swap | On Reveal: trades lanes with a random ally | Anchored allies |
| Haunt | On death: curses its killer (−1 Attack) | Exile, rampage past it |

Hidden combinations are the discovery layer: Brood+Molt (self-replacing fodder), Tithe+Revival (chip engine), Mimic+Swap (steal then dodge).

## 3.4 The Reveal timing layer
Cards exist in three states: **concealed** → **revealed** → **spent** (optional exhaust for one-shot pawns).
- *On Set* triggers — face-down (quiet, hidden).
- *On Reveal* triggers — the flip moment (the dramatic beat).
- *On Clash* / *on death* — combat beats.
- Face-down cards can't be targeted by most effects — but **can** be sacrificed (silent fold) or Called.

---

# 4. RESOURCE SYSTEMS

Six interlocking economies. Every powerful action costs at least one.

## 4.1 Soul Chips — *life = mana = stake* (primary)
- Persistent across the run (start 40, heals are scarce).
- Spent: card costs, raises, Calls, soul-draws, some trumps, shop prices.
- Gained: pot claims (as Embers, convertible), Tithe-style seals, rare events, Respite node.
- *The core tension:* every point of tempo is literally hit points. Aggression with chips is "betting your soul."

## 4.2 Flesh — sacrifice economy (per-battle)
- Generated by sacrificing cards (each has a Sacrifice Value, 0–3).
- Banked within a battle; spent on Flesh-cost summons (the big pawns).
- Dies with the battle — use it or lose it.

## 4.3 The Pot — stake economy (per-battle)
- Fed by: chip damage, antes, raises, some seals.
- Claimed by the winner → converts to Embers.
- Secondary function: several cards key off pot size (Pot Odds, Ledger Wraith…).

## 4.4 Embers — crafting economy (persistent)
- From pot claims, node rewards, selling cards to the Teller.
- Spent at Furnace/Teller: merges, grafts, removals, purchases, heal.
- The "real" run currency chips pretend to be.

## 4.5 Debt & Devil's Credit — risk economy (persistent)
- **Borrow** chips mid-battle or between nodes (Credit button always available — "the house extends credit").
- Debt accrues **interest**: +1 Debt at every Respite you skip, +2 at each Circle end. Unpaid ≥ 15 → **Collector events** hunt you on the map.
- Debt doesn't kill directly — it empowers the final boss (he holds your note) and drains Respite healing first.
- *Design intent:* the player's greed sets their own difficulty. A run at 0 debt is "clean"; a run at 20 debt is a knife-fight the player chose.

## 4.6 Trumps — cheat economy (persistent, consumable)
- Rare single-use items (max 3 held): **Sleeve Ace** (peek all concealed), **Cold Deck** (redraw your hand), **Mirrored Coin** (reroll any roll), **Marked Cards** (enemy can't Call this battle), **Loaded Dice** (your next Chance roll wins).
- Found at Teller/Wheel/events. Deliberate rule-breaks — scarce because they're degenerate.

## 4.7 Luck — hidden meta-stat
- A −3…+3 band that tilts every internal RNG (Wheel spins, Chance seals, mutation outcomes, shop stock).
- Raised by some events/altars; bled by greedy acts (the Devil notices cheats).
- Always *shown* as dice on the table — the Devil plays fair enough to show you the dice are loaded.

---

# 5. UPGRADE & TRANSFORMATION SYSTEMS

Power must create danger. Every path below can hurt you.

## 5.1 Merge — "The Furnace"
- Fuse **two same-suit cards** into one: stats = sum −20%, seals = union (slot cap = base card slots +1), sacrifice value = higher of the two.
- Cost: Embers 15–40 by tier.
- **Merge tiers:** T1–T2 safe. At **T3+** the card becomes **Overwrought** — each battle it risks a **Crack** (loses a random seal, permanently). Visible warning before you merge.
- A merged card is a *new card* — it can itself be merged again (exponential risk, exponential glory).

## 5.2 Graft — "The Taxidermist"
- Extract a seal from card A (A survives as a **Husk** — no seals, or is consumed for full refund of its flesh) → install into an open slot on card B.
- Cost: Embers + flesh of card A.
- Enables the signature craft: pull *Brood* off a fodder card and plant it on your win condition.

## 5.3 Mutate — conditional evolution
- Hidden thresholds trigger permanent change: kills (Slayer line), survival (Scar line), deaths (Ash line), pot thresholds (Greed line).
- Mutation is *earned*, never bought — the Forge doesn't sell it. A card that survives 3 boss fights mutates differently than one fed 10 sacrifices.
- Chaos mutation exists (Wheel/Altar of Chance) — random, swingy, Luck-weighted.

## 5.4 Corrupt — "Devil's Touch"
- Covenant/Altar event: pick a **boon** (+2 Attack, free seal, −1 chip cost) and a **curse** (Upkeep 1 chip/round; Debt +4; on death lose 3 chips; **Bound** — can't be removed from deck).
- Corrupted cards are visibly marked — and the Dealer remembers them in the finale.

## 5.5 Tattoo — "The Ledger Binding"
- Bind a card to your run-ledger: it permanently gains +1/+1 after each boss.
- Price of attachment: if it dies in battle → **Debt +2**. Your favorite card becomes a hostage.

## 5.6 Why the player hesitates
- Merge concentrates value into a single Crack-able body.
- Graft kills a card to empower another.
- Corrupt mortgages the run.
- Tattoo makes love expensive.
- Upgrade *slots* are finite — every +1 chosen is a +1 not taken elsewhere.

---

# 6. DECKBUILDING RULES

## 6.1 Numbers
- **Starting deck:** 10 cards — 4 small pawns, 3 tricks, 2 fodder/sac-bait, 1 persona signature.
- **Deck size:** 10 minimum, 30 maximum.
- **Hand:** draw to 5 at battle start (one mulligan), draw 1/turn, hand cap 7.
- **Soul Draw:** empty deck → each forced draw costs 2 chips.

## 6.2 Building verbs
| Action | Where | Cost/risk |
|---|---|---|
| Take card (choose 1 of 3 / Pass for embers) | post-battle reward | Pass = thin-deck value |
| Remove card | Altar / Teller service | embers, or sacrifice it for flesh/seal |
| Duplicate | Mirror events | rare; subject to duplicate tax |
| Merge / graft / corrupt / tattoo | Furnace / events | §5 |
| Sacrifice a deck card | Altar node | permanent removal → flesh/embers/seal |
| Fold (sell) | Teller | converts card → embers |

## 6.3 Anti-"take everything" pressures
- **Duplicate tax:** 3rd+ copy of a card costs +1 chip to play ("the table learns your tricks").
- **Soul Draw fatigue:** thin decks are consistent but bleed chips on empty draws.
- **Suit-binding:** some powerful cards demand ≥40% of deck share a suit — diluting breaks them.
- **Wounds persist:** a giant deck grinds longer; the Blinds punish the grind.
- **Pass is good:** declining a card is a real reward (+3 embers) — restraint is a strategy.

**Design rule:** a 12-card sharpened deck must be able to beat a 28-card pile — consistency vs. endurance is a real axis, not a noob trap.

## 6.4 Card rewards frequency
- Standard Table: choose 1 of 3 (weighted to your deck's suits, ~65/25/10).
- Deep Table: choose 1 of 3 rare-or-better + a seal token.
- Boss: a Blessing pick (see §8) + card pool expansion event.

---

# 7. ROGUELIKE STRUCTURE — "THE DESCENT"

## 7.1 Map
Three **Circles**, each a node graph of ~5 columns with 2–4 branching paths:

- **Circle I — The Parlor** (tutorialized, house-rules light)
- **Circle II — The Vault** (elite-dense, economy pressure)
- **Circle III — The Pit** (anything goes; the Devil stops pretending)

Node types:
| Node | What happens |
|---|---|
| **Table** | Standard battle (with a posted **House Rule**) |
| **Deep Table** | Elite battle — higher stakes, double pot, rare rewards |
| **Pit Boss** | Circle-end boss (rule-breaker, §8) |
| **The Teller** | Shop: cards, trumps, removal, heals — priced in embers *or* chips |
| **The Furnace** | Merge / graft / tattoo services |
| **The Altar** | Sacrifice a deck card → embers/flesh/seal-extract; also removes it |
| **The Wheel** | A literal gamble: bet embers/chips on a spin. Optional, Luck-weighted |
| **The Respite** | Heal chips, pay down Debt, or **Hustle** (heal less, gain embers) |
| **Covenant** | The Devil's deal event — a bespoke bargain (power now, priced later) |
| **Whisper** | Hidden node — revealed only by map gambles or Peek events |

**House Rules** (posted before each Table — you pick your poison through route choice):
- *Candle Vigil* — sacrifices forbidden
- *Open Table* — all cards are set revealed
- *Toll* — each draw costs 1 chip
- *Sabbath* — mantel effigies are silent
- *High Stakes* — antes ×2, pot payouts ×2
- *Blood Price* — wounds persist between battles (this node only)

## 7.2 Difficulty scaling
- Enemy chip piles, stats, and seal density scale per circle (×1.0 / ×1.35 / ×1.7).
- Deep Tables appear more often on greedier paths — the map's **risk/reward legibility** is a skill: safer routes starve your build.
- **Personal scaling:** Debt ≥15 spawns Collector nodes that ambush you mid-path.
- **Adaptive devilry (endgame):** the Pit tracks your most-played archetype and weights counters into late tables — invisible, but honest.

## 7.3 The run's emotional cadence
Early: cheap wins, small pots — teach the verbs.
Mid: the first real bargain — a graft that defines the build, or the first Debt.
Late: every choice bleeds — the pot is huge, your soul is thin, the Blinds are screaming.
Death should almost always feel authored: "I saw the price and paid it anyway."

---

# 8. BOSS PHILOSOPHY

Bosses don't have more HP — **bosses change the rules of the table.** Each is a different game wearing a boss's face.

## 8.1 Boss roster (Circle bosses are drawn from pools; two per circle keeps runs distinct)

### The Collector (Circle I)
- **Unique mechanic:** it has no chip pile — **the pot is its life.** You win by forcing it to *over-pay*: every raise it must match (it's a whale; it can't fold). Win = pot ≥ its Greed Threshold (starts 40) → it busts and pays everything out.
- **Pressure:** its matching antes grow; if your chips hit 0 first, normal defeat.
- **Counterplay:** bait its matches early, then starve — it's the one fight where *raising* is damage.

### The Widow of Wagers (Circle I alt)
- **Unique mechanic:** she plays a **mirror of your deck** — literally, your list.
- **Pressure:** antes ×2. Your deck's own ceiling is the clock.
- **Counterplay:** reward for builds with self-answers (control tools > raw stats); weak copies can bluff her Calls.

### The Croupier (Circle II)
- **Unique mechanic:** every 3 rounds he **redeals the table** — all cards in play shuffle back into decks and fresh concealed placements arrive.
- **Pressure:** pure anti-stall; setup engines never finish.
- **Counterplay:** low-commitment burst, Reveal-trigger cards, cards that want to be replayed (Tithe engines love the redeals).

### The Hollow King (Circle II alt)
- **Unique mechanic:** **both graveyards are his.** Every dead card (both sides) resurrects on his board at −1/−1, on his side.
- **Pressure:** your sacrifices arm his army — punishes Chalice/Brood builds specifically.
- **Counterplay:** exile/burn effects ("ashes can't kneel"), minimal-death boards, or feed him fodder then burn the field.

### The Dealer (Final — Circle III)
- **Unique mechanic:** he plays **your run's history.** Every corrupted card serves him; your Debt becomes his starting chips; his House Rules counter your most-used archetype (adaptively re-rolled each phase).
- **Pressure:** three phases (Parlor rules → Vault rules → he stops following rules entirely: he *cheats visibly* — the only fight where Trumps are mirrored back at you).
- **Counterplay:** run hygiene pays — low debt, few corruptions, diversified archetypes make him toothless. The clean-run player meets a mortal; the loan-shark player meets a god.

## 8.2 Shared boss rules
- Every boss posts its rule-change as a physical fixture on the table (you always see the rule before the fight).
- Every boss has a stated counter-axis in its rewards screen ("the House shows its tells").
- No boss may be a stat-check: if a boss can be beaten by numbers alone, it fails the design.

---

# 9. EXAMPLE CARDS

Starter-pool sample (stats illustrative, balance TBD in playtest):

| Name | Type | Cost | Atk/Def | Seals | Text | Suit/Tags |
|---|---|---|---|---|---|---|
| Tithe Imp | Pawn | 1 chip | 1/2 | Tithe | On play: +2 chips | Blades / Debt |
| Moth of Ashes | Pawn | 0 | 0/1 | — | On death: draw 1 | Ash / Brood |
| Ledger Wraith | Pawn | 3 chips | 2/4 | Pot Odds | +1 Attack per 5 chips in pot | Pentacles |
| Bonedog | Pawn | 2 flesh | 3/1 | — | — | Chalices |
| Pact Swine | Pawn | 2 chips | 4/4 | — | On play: Debt +3 | Pentacles / Debt |
| Bluffkin | Pawn | 0 | */* | — | Face-down only. If Called: destroyed, enemy −2 chips. Reveals as nothing | Eyes / Bluff |
| Knave of Eyes | Pawn | 2 chips | 1/3 | Peek | On Reveal: see an enemy concealed card | Eyes |
| Mirror Hound | Pawn | 3 chips | */* | Mimic | Copies stats+seals of opposing card on Reveal | Eyes |
| Choir Leech | Pawn | 2 chips | 1/3 | — | When it clashes: heal 1 chip | Chalices |
| Sister of Scissors | Pawn | 4 chips | 3/5 | — | On Reveal: destroy opposing concealed card before it flips | Blades |
| Stained Knight | Pawn | 3 chips | 4/3 | Sharp | Permanently +1 Attack per kill (mutate line) | Blades / Slayer |
| Fate's Spider | Pawn | 2 chips | 1/4 | Swap | On Reveal: moves to a random empty lane | Eyes / Chance |
| Cinderwolf | Pawn | 3 flesh | 5/4 | — | On Clash: burns opposing card's seals (to Husk) | Chalices / Ash |
| Lady of the Lamp | Pawn | 5 chips | 4/6 | — | When you heal: +1 Attack | Chalices |
| Debtor's Bell | Effigy | 3 chips | — | — | Each round: both antes +1 | Pentacles / Debt |
| Bone Banker | Effigy | 2 chips | — | Molt | Your sacrifices yield +1 flesh | Chalices |
| Ashmaker | Effigy | 3 chips | — | — | On any card death (both sides): +1 flesh | Chalices / Ash |
| Croupier's Left Hand | Effigy | 4 chips | — | — | Your antes pay you back 1 chip each round | Pentacles |
| Pale Usurer | Trick | 0 | — | — | +4 chips. Debt +2 | Pentacles / Debt |
| Gravedigger's Tithe | Trick | 1 chip | — | — | Return last dead pawn to hand | Chalices / Ash |
| Straight Razor | Trick | 1 chip | — | — | Target pawn gains Sharp (permanent graft-equivalent, battle only) | Blades |
| Owed | Trick-curse | — | — | — | Dead card in deck; must be paid off at Altar (Debt card) | Debt |
| High Priestess of Chance | Pawn | 4 chips | 3/4 | — | Each round flip a coin — heads +3 chips / tails −1 chip (Luck-weighted) | Eyes / Chance |
| The Bargainer | Pawn (rare) | 3 chips | 2/5 | — | On play: the Devil offers a mid-battle deal | Pentacles / Debt |
| Rat Catcher | Pawn | 1 chip | 2/1 | Pierce | — | Blades |

---

# 10. EXAMPLE BUILDS

## Build A — "The Bleeder" (Chalices sacrifice engine)
Core: Moth of Ashes ×2, Bonedog, Bone Banker, Ashmaker, Cinderwolf, Gravedigger's Tithe.
Loop: fodder dies → flesh bank → flesh-fuelled big bodies → Ashmaker refunds more flesh. Thin deck (12–14) for consistency.
Weakness: Hollow King; exile effects; Candle Vigil tables.

## Build B — "The Cardsharp" (Eyes information game)
Core: Knave of Eyes, Bluffkin ×2, Mirror Hound, Fate's Spider, Peek seals, Marked Cards trump.
Loop: win the info war — call real threats, let Bluffkin eat Calls, Mirror Hound punishes big reveals.
Weakness: Open Table house rules; raw-stat decks that don't care what you know.

## Build C — "The Whale" (Pentacles pot economy)
Core: Ledger Wraith, Pact Swine, Pale Usurer, Debtor's Bell, Croupier's Left Hand, Pot Odds grafts.
Loop: inflate the pot with raises → cash out through burst or Collector-style outs; Debt fuels tempo.
Weakness: Debt compounding; Collector events; the Dealer (who holds your note).

## Build D — "The House" (Blades board control)
Core: Stained Knight, Sister of Scissors, Rat Catcher, Straight Razor, Sharp/Pierce grafts, Rampage finishers.
Loop: never let the board stabilize — snipe concealed cards, snowball kill-counters onto the Knight.
Weakness: warded mantels, Wax Skin walls, Widow (mirror).

## Wildcard — "The Glass Cathedral" (corrupt/mutation high-roller)
One monstrous merged+corrupted+tattooed body (e.g., Cinderwolf grafted with Rampage+Bulwark, corrupted +2 Atk, tattooed). Everything else is fodder that banks flesh to feed it.
Weakness: literally everything — one Crack, one Haunt, one Called bluff, and the cathedral is ash. This is the "I shouldn't have survived that" machine.

---

# 11. COMBO LIBRARY

## 11.1 Ten beginner combos (2-card, obvious, teach the grammar)
1. **Moth of Ashes + Bone Banker** — sac the moth, draw, get +1 flesh. Teaches: death is a resource.
2. **Tithe Imp + Pact Swine** — imp's chips pay the swine's interest. Teaches: income smooths debt.
3. **Rat Catcher + Straight Razor** — cheap pierce + first strike = a lane deleted. Teaches: seal on body.
4. **Bluffkin + Knave of Eyes** — fake a stake, peek for free. Teaches: information is a bet too.
5. **Choir Leech + Lady of the Lamp** — heal on clash feeds her attack. Teaches: engines are two cards deep.
6. **Ledger Wraith + one Raise** — pot at 10+ = wraith grows every turn. Teaches: the pot is a stat.
7. **Bonedog + Ashmaker** — sacrifice it, bank +2 flesh total. Teaches: flesh compounds.
8. **Mirror Hound + lane choice** — park it opposite their biggest concealed card. Teaches: placement as reading.
9. **Debtor's Bell + Croupier's Left Hand** — your antes double but refund — the pot balloons, payouts swell. Teaches: inflation as strategy.
10. **Pale Usurer + Debtor's Bell** — debt-funded tempo that also pumps the pot. Teaches: the Devil's money spends.

## 11.2 Ten advanced combos (3+ cards / grafts, deck-shaped)
1. **Brood grafted onto Tithe Imp + Ashmaker** — imp dies, spawns grub, refunds flesh and chips: a self-replacing economy engine. Fodder that pays rent.
2. **Revival + Molt on a front-liner** — dies, returns to hand, replays for more sacrifice. A renewable sacrifice loop that survives Candle Vigil nothing (sac still allowed) — countered by exile only.
3. **Peek + Sister of Scissors + Fate's Spider** — see their concealed bomb, snipe it with the Sister, spider repositions the reveal. Information converted to tempo.
4. **Pot Odds ×3 back row + Debtor's Bell** — a passive income tower fed by antes. Slow, but the Blinds push the pot where it wants to go.
5. **Gravedigger's Tithe + Stained Knight + sacrifice bait** — resurrect the Knight after feeding it kills; mutate it across two lives. The Knight remembers both deaths.
6. **Bluffkin ×2 + Marked Cards + Raise** — triple-fake the board while raising; enemy wastes Calls (or pays you when they call the bluff that's real). Poker night as a board state.
7. **Cinderwolf + Ambush graft** — burn the back-row engine card's seals through the wall. Deletes mantel-adjacent support the opponent thought was safe.
8. **Fate's Spider + Swap seal + open-lane math** — random-lane pawns land where clashes can't reach, while Reach allies pick off exposed lanes. Chaos used as cover.
9. **Mimic grafted on a cheap pawn + enemy Widow fight** — in the mirror match, your mimic becomes *their* best card — you weaponize her own deck against the reflection.
10. **Soul Draw gambit: thin deck (10) + Tithe engine** — deliberately empty the deck, pay 2-chip draws, but your engine generates 4+/turn. Fatigue becomes arithmetic you've already won.

## 11.3 Ten broken / high-risk combos (legal but the Devil is watching)
1. **The Free Loan:** Pale Usurer + Debtor's Bell + Collector's-mimic builds — debt-fuelled ante inflation; the pot becomes a savings account you rob at burst-speed. Risk: Collector events arrive mid-path.
2. **Infinite-ish chip engine:** Revival+Tithe+Brood pawn + sacrifice loop → +chips/flesh/draw each cycle. Hard-capped by **Table Etiquette** (each seal fires ≤3×/round) and the Blinds — a sprint, not a stall.
3. **The Glass Cathedral** (see Builds): merge-tier-3 Overwrought + tattoo + triple corrupt. A single body worth ~40 stats that loses a seal per battle. The pot loves it; the cracks count it down.
4. **Pot Laundering:** Debtor's Bell + raise each turn + Pot Odds ×3 + Ledger Wraith — artificially pump the pot you intend to win with one unopposed turn. All-in telegraphed — the enemy can see the tower rising and Calls your bluff or races you.
5. **Owed-stacking:** run 3 copies of the Debt curse + Altar payoffs + Luck manipulation — debt-priced engine cards at 0 chip cost. The final boss reads your ledger.
6. **Double Mirror:** Mirror Hound + Mimic graft vs The Widow — a mirror of a mirror; she reflects your reflection until someone's economy collapses. Degenerate, specific, glorious.
7. **Blind all-in:** turn-1 raise 5 + concealed Bluffkin board + Marked Cards + High Priestess of Chance — a Luck-tilted coin-flip run where every turn is a shove. Wins in 4 rounds or dies in 5.
8. **The Exile Eater:** Ashmaker + Cinderwolf + Gravedigger's Tithe loop vs The Hollow King — feed his resurrected trash then burn it all; his army is your furnace fuel.
9. **Trump stacking:** Sleeve Ace + Cold Deck + Loaded Dice held for the Dealer — three cheats saved for the one fight that mirrors them back. You beat him at his own game — if he doesn't play them first.
10. **Devil's Margin:** keep Debt at exactly 14 (one below Collector threshold), farming Pale Usurer + Pact Swine forever. A knife's-edge economy that pays like a casino — until a Whisper node nudges you to 15.

*Why they're fun:* every broken line is **visible, telegraphed, and beatable** — the fun is watching yourself walk a wire the game is actively shaking.

---

# 12. EXAMPLE 30-MINUTE GAMEPLAY SESSION

Circle I — The Parlor. Fresh run, default persona. Chips = 40, deck = 10.

- **0:00–2:00 — The Deal.** Map reveals two routes: left — Table (*Open Table*) then Furnace; right — Table (*Toll*), Altar, Deep Table. The player reads house rules like odds and picks right: harder, richer.
- **2:00–6:00 — Table 1** (vs. **The Ink Debtor**, 26 chips). Verbs learned under fire: sets Moth of Ashes face-down (stake 0 — the enemy reads nothing), Tithe Imp behind it. Antes tick. Turn 3: pays 2 to **Call the Bluff** on the enemy's concealed card — it's a decoy, destroyed for free. Unopposed hits bleed the pot to 14 → kill at round 6. Claims **14 embers**. On the reward screen chooses **Pass** (+3 embers) over three mediocre cards — first thin-deck decision.
- **6:00–8:00 — The Furnace.** 15 embers to graft **Molt** onto Tithe Imp — the imp is now sacrifice fuel that paid for itself. The deck has a spine.
- **8:00–13:00 — Table 2 (*Toll*)** (vs. **Widow's Hand**, 32 chips). Every draw costs a chip — the house rule bites. Key discovery: **Bonedog costs flesh, so its stake shows nothing** — flesh plays leave no trail for the enemy to read. Wins a 22-pot but ends at 31 chips; the toll took its price.
- **13:00–15:00 — The Altar.** Sacrifices a weak pawn: removed from deck + seal extracted + 4 embers. Deck at 11, sharper.
- **15:00–22:00 — Deep Table (*High Stakes*)** (vs. **The Pale Regular**, 55 chips). Antes ×2. Mid-fight the player takes **Devil's Credit +6** to set Sister of Scissors face-down — the Sister reveals and deletes the enemy's concealed bomb *before it flips*. The signature snipe. The enemy races; player bleeds to 9 chips; the Wraith's desperation seal flickers on. Round 9: all-in raise of 4 → pot 47 → unopposed lane → kill. **47 embers** — biggest pot of the session. Debt +8 with interest.
- **22:00–25:00 — The Respite.** Choose: heal 12 / pay down Debt / Hustle. Pays Debt 8→3, heals a little. The math felt bad — that's the design.
- **25:00–30:00 — Pit Boss: The Collector.** Rule inverted: its life *is* the pot (Greed Threshold 40). The player raises 5/turn to feed a whale that cannot fold — the only fight where aggression means betting, not attacking. It matches every raise; pot hits 41 → it busts. Claim: pot embers + a **Blessing** (pick "Ember Tithe": +5 embers per table for the run) + Eyes rare cards unlocked into the reward pool.
- **30:00 — Circle II opens; the session ends mid-decision** — which is exactly the hook: the run was never safe, and the player already knows what they'd do differently.

Every beat above is a verb from §2 doing work — conceal, call, raise, sacrifice, graft, borrow, bust. No beat relies on story: the mechanics *are* the drama.

---

# 13. PLAYER PSYCHOLOGY — EMOTIONAL DESIGN

| Target emotion | System that produces it |
|---|---|
| "I found something powerful" | Hidden seal synergies; graft discoveries; mutation reveals |
| "I created this build" | Merge/graft/tattoo make the deck *assembled*, not drafted |
| "I shouldn't have survived that" | Pot-inflation comebacks; Final Wager; desperation seals |
| "I sacrificed something important" | Slot loss, husked cards, tattoo hostages, altar removals |
| "One more run" | Debt echoes, Ledger unlocks, persona variety, House-rule variants |
| Dread | The Blinds' candle; the Dealer reading your ledger back |
| Ownership of failure | Every death traces to a price you chose to pay |

Anti-patterns designed out: no pure grinding (Blinds), no unfair RNG death (all rolls shown via Luck dice), no meaningless choices (every reward has a stated cost and an opt-out).

---

# 14. META PROGRESSION — "THE LEDGER BELOW"

Permanent progression widens possibility space; it never raises numbers directly.

- **Marks** (ascension-style covenant modifiers): each cleared run adds a Mark to future runs (e.g., "Open Table on all Circle-I tables", "Blinds +1 from round 1").
- **Personas:** new starting decks — the Cardsharp (Eyes), the Bleeder (Chalices), the Oathbreaker (Debt), the Hedge (mixed/Chance). Each with a signature card.
- **Compendium:** card pools, seals, archetypes, and House Rules unlock into the reward pool — new *options*, not new stats.
- **Devil's Memory:** next-run echoes — leftover Debt may resurface as a Covenant demand; a corrupted card may return, marked, in an early reward. The table remembers what you did.
- **House Variants:** alternate house-rule lists unlock, changing route math.
- **Daily Table:** seeded run, shared leaderboard. Same deal for everyone — skill is the variable.
- **High Roller mode** (post-clear): endless descent with cumulative House Rules; the only place merge-tier 5 exists.

**Hard rule:** no unlock ever grants +stat or +health. Unlocks grant *new ways to risk yourself*.

---

# 15. BALANCE PRINCIPLES

## 14.1 The five governors
1. **The Blinds (ante clock)** — every battle self-terminates; no stall strategy survives round 16.
2. **Table Etiquette** — each seal/ability triggers at most 3×/round. Infinite engines are sprints.
3. **Duplicate tax** — 3rd+ copies cost +1 chip. No single-card deck floods.
4. **Soul Draw** — empty deck bleeds 2 chips/draw. Thin is sharp but fragile.
5. **Counter-vector law** — every seal ships with a named counter. Nothing is unconditionally best.

## 14.2 Dominant-strategy defense
- **Suit-binding** gates raw power behind deck-shape commitment.
- **The Widow** and **adaptive Pit tables** punish one-note builds at the meta level.
- **Reward Pass** keeps "don't take the card" a real strategy — deck entropy is fought by restraint.

## 14.3 Defensive-build defense
- Unopposed-lane damage + the Blinds means pure walls lose to the clock.
- Back-row economy towers pay slowly; ante inflation outpaces them.
- Defense must *convert* (Wax Skin walls that become sacrifice fuel, Choir Leech chip batteries) — never just resist.

## 14.4 Single-card-solution defense
- Seal slots, merge tier caps, Crack risk, tattoo Debt — a single body can't be everything.
- Boss rule-changes are specifically hostile to single-axis decks (Croupier deletes boards; Hollow King eats graves; Collector ignores stats).

## 14.5 Numbers philosophy
- Small integers, always: Attack 0–6, Defense 1–8, chips in tens. Big-number inflation kills readable risk.
- Every cost must be *feelable*: if a cost can't be expressed as a pause — a hesitation — it's too small or too complex.

---

# 16. LONG-TERM REPLAYABILITY PLAN

- **Systemic depth:** concealed placement + pot + debt = three overlapping decision layers that recombine every battle; House Rules re-shuffle the equation per node.
- **Content runway:** suits/archetypes are modular — new suits (Thorns? Bells?) slot in without rebalancing the frame.
- **Seeds & Daily Table** for stream/competition play.
- **Marks ladder** (ascension) + **High Roller** endless mode for veterans.
- **Devil's Memory** creates narrative persistence across runs without a story campaign.
- **Content cadence:** quarterly "House Expansions" — a new suit cluster + boss + house-rule pack; the framework is built for it.
- **Community hooks:** seed sharing, combo-of-the-week showcases, Leaderboard pits — the game *wants* to be argued about.

---

# 17. TECHNICAL & PRESENTATION REQUIREMENTS (mechanics-adjacent)

- **Engine:** Godot 4.x recommended (matches project ecosystem, strong 3D + Control UI, GLB pipeline). Unity viable. *(Decided after asset-scan reports — flagged for verification.)*
- **The table is a real 3D scene.** Cards, chips, candle, scale, props are meshes — never sprites composited onto a backdrop image. The Felt is physical.
- **Everything is animated:** card flips (3D flip-reveal), chip stacking physics, candle flicker shaders, sacrifice dissolve/burn, reveal stingers, pot pouring. A "simple card game" presentation is a design failure for this title.
- **Bilingual from day one:** all card text, UI, house rules, events, tooltips in **TR + EN** via Godot translation (.po/.csv) — design text keys now, not later.
- **Data-driven cards:** card = data (anatomy fields) + seal scripts; the full card pool is content-addressable and moddable.

---

*End of design document.*
