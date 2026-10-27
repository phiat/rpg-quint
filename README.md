![Odin](https://img.shields.io/badge/Odin-lang-blue)
![Quint](https://img.shields.io/badge/Quint-formal%20spec-purple)
![Raylib](https://img.shields.io/badge/raylib-6.0-green)
![License](https://img.shields.io/badge/license-MIT-blue)

# Quint Crawl — Formally Verified RPG

A raylib RPG game built on formally verified game logic. Every game rule is specified in [Quint](https://quint-lang.org/), tested via Model-Based Testing (MBT), and implemented in [Odin](https://odin-lang.org/).

Inspired by: [Model-Based Testing for D&D](https://www.loskutoff.com/blog/model-based-testing-dnd/)

![Title Screen](screenshots/title.png)
![Map Exploration](screenshots/map.png)
![Combat](screenshots/combat.png)
![Inventory](screenshots/inventory.png)

## The Game

**Quint Crawl** is a turn-based RPG rendered with raylib. Explore a 9x9 world grid (81 zones across 5 difficulty levels), fight enemies, gather resources, craft gear, and level up to conquer the Castle.

```bash
just play             # build and run the game
```

The game logic in `quint_crawl/` is the single source of truth — shared by both the raylib game and the MBT test harness. Every state transition is formally specified and verified.

## Controls

### Movement

| Key | Action |
|-----|--------|
| WASD | Move between zones |
| J | Fast travel (between unlocked village waypoints) |

### Combat — Sword

| Key | Action |
|-----|--------|
| E | Initiate fight |
| A | Basic attack |
| K | Combo (3-hit chain: Slash → Thrust → Finisher) |
| H | Heavy strike (2x damage, cooldown) |

### Combat — Actions & Skills

| Key | Action |
|-----|--------|
| Y | Battle cry (ATK buff) |
| Z | Shield block |
| N | Counter-attack (block + retaliatory hit) |
| I | Fortify (extended DEF buff) |
| F | Flee |

### Combat — Tactical

| Key | Action |
|-----|--------|
| P | Use potion |
| V | Apply poison (venom sac) |
| X | Antidote |
| B | Throw bomb (flat damage, bypasses DEF) |
| M | Smoke bomb (guaranteed escape) |
| INS | Use holy water (full heal) |

### Exploration

| Key | Action |
|-----|--------|
| R | Rest (restore stamina) |
| G | Gather wood |
| M | Mine iron |
| Z | Open treasure chest (chest zones only) |
| - | Eat ration (restore stamina) |
| I | Open inventory (ESC to close) |

### Village

| Key | Action |
|-----|--------|
| B | Buy potions |
| F | Buy bombs |
| / | Buy smoke bombs |
| ' | Buy rations |
| C | Craft sword (Level 2+) (Shift+C: batch 3) |
| Q | Equip |
| T | Repair sword |
| O | Craft venom sac |
| U | Respec skills |
| \ | Salvage sword |
| = | Upgrade salvage level |
| 1–7 | Unlock skill (when points available) |
| 8–0 | Enchant sword slots 1–3 |
| F1 | Recycle 3 wood → ration |
| F2 | Recycle 3 iron → battery |
| F3 | Recycle 3 potion → holy water |
| L | Claim victory (at Level 5 Castle, after the Boss) |

### Companions

| Key | Action |
|-----|--------|
| , | Adopt local companion |
| . | Feed companion |
| ; | Dismiss companion |
| ' | Companion command (in combat) |

### System

| Key | Action |
|-----|--------|
| F5 | Save |
| F9 | Load |

See the HUD sidebar for zone-specific actions.

## Features

- **World** — 9x9 grid, 5 difficulty levels, biome tiling (3x3 pattern repeats across regions), fog of war, HUD minimap, mouse hover tooltips, per-zone weather (Clear/Rain/Fog/Storm) affecting combat/gathering/movement, village waypoints with fast travel, one-time treasure chests with tier-scaled gold rewards.
- **Combat** — turn-based, stamina-gated actions, 3-hit combo chain with damage multipliers, cooldown abilities (heavy strike, battle cry, fortify, counter-attack), status effects (poison, ATK/DEF buffs) with turn-based ticking, enemy respawn timer (5-turn cooldown after a kill), four weapon types (sword / dagger / battery pistol / staff; `weapon_type` gates combat actions — sword and dagger share blade-combat paths with per-weapon stamina + attack tuning).
- **Bestiary** — data-driven catalog of 200 named enemies across 20 archetypes (4 per tier, 5 tiers), 6 trait tags (Undead/Beast/Elemental/Construct/Humanoid/Aberration), trait-keyed secondary loot drops.
- **Elemental system** — 4-element cycle (Fire > Ice > Lightning > Earth > Fire) with 2x/1x/0.5x damage multipliers.
- **Companions** — data-driven species catalog (Wolf/Hawk/Turtle/Fox/Bear/Owl/Lynx/Sprite) with biome-gated adoption, trait affinities (Attacker/Defender/Scout/Support), rarity tiers (Common/Rare/Legendary), species-specific perks (HP regen / mana regen / stamina vigor / loyalty bond), loyalty-on-combat loop (inactive below LOW_LOYALTY until fed), in-combat command, village training to raise rarity, and a 3-stage companion quest chain. The spec verifies the abstract (trait × rarity) effect space; Odin grows the catalog freely without code changes.
- **Progression** — XP/level-up, skill tree with 3 branches (Offense/Defense/Utility), 1 point per level, respec at village, 3 prerequisite-gated quests (Slime Slayer → Venture Forth → Castle Conqueror) tracked in the HUD, Castle Boss encounter gates the final victory claim.
- **Items & crafting** — resource gathering (wood, iron), level-gated sword crafting (Lv2+, batch-of-3 option), sword durability with village repair, salvage system (upgradeable 1–3), 3-slot weapon enchantment (fire/ice/vampiric/lightning; fire/ice mutually exclusive), venom sac crafting, holy water crafting (holy_dust + wood → out-of-combat full heal), fire scrolls (bypass mana gate), loot drops with pity-counter guarantee, zone-tiered sword rarity drops (Common/Rare/Legendary with ATK scaling), per-tier unique archetype trophies (5 collectible drops that grant a permanent ATK bonus), village recycling (3-for-1 wood/iron/potion conversion), full-screen inventory overlay ([I] to open), inventory capacity (30 items) enforced across gathering/shopping/loot.
- **Persistence & polish** — save/load snapshot with full state round-trip; post-processing effects (zone tint, chromatic aberration, low-HP pulse, level-up bloom, poison overlay).

## How MBT works

```
specs/*.qnt  ──[quint run --mbt]──▶  traces/*.itf.json  ──[odin test]──▶  pass/fail
                                          │
                 Odin implementation  ◀───┘
                 (*_mbt/*.odin)        replayed against spec expectations
```

1. **Write a Quint spec** — state variables, actions (state transitions), invariants (properties that must always hold)
2. **Generate traces** — Quint explores the state space nondeterministically and records execution traces in ITF (Intermediate Trace Format)
3. **Write Odin glue** — a step handler (dispatches action names to your code) and a state getter (reads your implementation's state back for comparison)
4. **Replay** — the MBT runner walks each trace step, mutates your implementation, and checks that every state variable matches the spec's expectation

## Project structure

```
quint_crawl/           Shared game logic (Game_State, all action procs, constants)
quint_crawl_game/      Raylib game executable (rendering, input, UI, shaders)
  assets/              GLSL shaders (effects.fs)
quint_mbt/             Shared Odin library: ITF parser + trace replayer
quint_crawl_mbt/       MBT harness for the integrated game spec
specs/                 Quint formal specifications
  core/                Character fundamentals (rpg, healing, leveling, stamina)
  combat/              Combat systems (combat, combat_full, status, cooldown, elemental)
  items/               Equipment & crafting (equip, durability, enchantment, crafting, salvage, ...)
  economy/             Trade & loot (shop, dynamic_shop, trade, loot)
  world/               Exploration (world_grid, trap, respawn, companion)
  social/              Progression & social (party, quest, skill_tree, reputation, summoning)
  quint_crawl.qnt      Integrated game spec
mbt/                   Per-module Odin MBT test harnesses (mirroring specs/ layout)
  core/                ...
  combat/              ...
  items/               ...
  economy/             ...
  world/               ...
  social/              ...
traces/                Generated ITF trace files (.itf.json)
docs/                  Design documents (asset specs, etc.)
justfile               Task runner for common workflows
```

## Modules

The integrated game spec lives at `specs/quint_crawl.qnt` — 7 record-typed state vars, ~50 actions, ~46 invariants covering HP/gold/level/position/inventory bounds, level gates, skill prerequisites, quest counters, cooldowns, status effects, enchantment slots, companion loyalty, and victory conditions.

Alongside it, `specs/{core,combat,items,economy,world,social}/` holds 38 standalone spec modules (rpg, combat, equip, healing, stacking, shop, status, crafting, party, leveling, cooldown, quest, durability, loot, respawn, dynamic_shop, combat_full, capacity_craft, gated_craft, stamina, skill_tree, reputation, summoning, world_grid, elemental, enchantment, trap, companion, salvage, auction, faction, fast_travel, dialogue, fog_of_war, permadeath, bounty, trade) that each verify one subsystem in isolation — useful as unit tests for the underlying mechanics before integration.

## Quick start

```bash
just play            # build and run the game
just build-game      # build without running

just check           # typecheck all specs
just traces          # generate MBT traces for all specs
just test            # run all Odin MBT tests
just all             # check + traces + test
just retest          # traces + test

just check-one rpg             # typecheck one spec
just test-one rpg              # test one module
just trace rpg rpg_run         # regenerate one trace
just trace-crawl               # regenerate quint_crawl traces (5x, 100k samples)
just test-crawl                # regen traces + run crawl MBT tests
just verify NAME MAIN INVARIANT # run invariant check (100k traces, 20 steps)
```

## Prerequisites

- [Odin](https://odin-lang.org/) `dev-2026-10` (with vendor:raylib 6.0; pinned in `mise.toml`)
- [Quint](https://quint-lang.org/) (tested with 0.33.0)
- [just](https://github.com/casey/just) (task runner)
- X server or WSLg (if running on WSL)

## Docs

- [Asset Design Guide](docs/assets-design.md) — sprite specs for V2 visual upgrade (91 required assets)
