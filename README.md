![Odin](https://img.shields.io/badge/Odin-lang-blue)
![Quint](https://img.shields.io/badge/Quint-formal%20spec-purple)
![Raylib](https://img.shields.io/badge/raylib-5.5-green)
![License](https://img.shields.io/badge/license-MIT-blue)

# Quint Crawl — Formally Verified RPG

A raylib RPG game built on formally verified game logic. Every game rule is specified in [Quint](https://quint-lang.org/), tested via Model-Based Testing (MBT), and implemented in [Odin](https://odin-lang.org/).

Inspired by: [Model-Based Testing for D&D](https://www.loskutoff.com/blog/model-based-testing-dnd/)

![Title Screen](screenshots/title.png)
![Map Exploration](screenshots/map.png)
![Combat](screenshots/combat.png)

## The Game

**Quint Crawl** is a turn-based RPG rendered with raylib. Explore a 9x9 world grid (81 zones across 5 difficulty levels), fight enemies, gather resources, craft gear, and level up to conquer the Castle.

```bash
just play             # build and run the game
```

Controls: WASD to move, E to fight, A to attack, K for combo, H for heavy strike, Y for battle cry, Z for shield block, N for counter-attack, I for fortify, P for potions, V to poison, X for antidote, F to flee, R to rest, B to buy potions, G to gather wood, M to mine iron, C to craft (Lv2+), Q to equip, T to repair, O to craft venom sac, U to respec skills, \ to salvage sword, = to upgrade salvage, J to fast travel, L to claim victory (at Level 5 Castle), 1-7 to unlock skills (when points available), 8-0 to enchant sword slots 1-3 (at village), F5 to save, F9 to load. See the HUD sidebar for zone-specific actions.

Features:
- 9x9 world grid with 5 difficulty levels and biome tiling (3x3 pattern repeats across regions)
- Turn-based combat against 5 enemy tiers (Slime, Skeleton, Wolf, Wraith, Dragon)
- Mouse hover tooltips showing zone name, level, and available actions
- HUD minimap with biome region overview
- Stamina system — actions cost stamina, restored by resting
- Combo system — 3-hit chain (Slash → Thrust → Finisher) with damage multipliers
- Skill tree — 3 branches (Offense/Defense/Utility), 1 point per level-up, respec at village
- Cooldown abilities — heavy strike (2x damage), battle cry (ATK buff), fortify (extended DEF buff), counter-attack (block + retaliatory hit)
- Status effects — poison, ATK/DEF buffs with turn-based ticking
- Venom sac system — consumable for poison strike, dropped from ZL2+ enemies or crafted at village
- Per-zone weather (Clear/Rain/Fog/Storm) affecting combat, gathering, and movement
- Enemy respawn timer — 5-turn cooldown after defeating an enemy before new combat available
- Loot drops with pity-counter guarantee system
- Resource gathering (wood, iron), crafting, and equipment
- Elemental damage — 4-element cycle (Fire>Ice>Lightning>Earth>Fire) with 2x/1x/0.5x multipliers
- Enchantment system — 3 weapon slots (fire/ice/vampiric/lightning), ATK/DEF bonuses, fire/ice incompatible
- Inventory capacity (30 items max) with capacity-aware gathering, shopping, and loot
- Level-gated crafting — sword crafting requires Level 2+
- Salvage system — break down swords for materials at village, upgradeable salvage level (1-3)
- Sword durability — degrades per attack, repair at village
- Fog of war — unexplored tiles hidden, revealed by adjacency, visited tiles fully visible
- Fast travel — village waypoints unlocked on visit, teleport between them
- Save/load snapshot with full state round-trip
- Post-processing effects: zone tint, chromatic aberration, low-HP pulse, level-up bloom, poison overlay

The game logic in `quint_crawl/` is the single source of truth — shared by both the raylib game and the MBT test harness. Every state transition is formally specified and verified.

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

| Module | Spec | Invariants |
|--------|------|------------|
| **rpg** | Character with HP, attack, inventory | Inventory bounded, HP can go negative (design question) |
| **trade** | Two-player item trading | Items conserved, inventories bounded |
| **equip** | Equipment slots (weapon/armor/accessory) | Item conservation, no duplicates, inventory bounded |
| **healing** | HP + consumable potions | HP capped at max, potions non-negative |
| **stacking** | Quantity-based item stacks | Quantities non-negative, total bounded |
| **shop** | Gold economy with buy/sell | Gold conserved, items conserved, gold non-negative |
| **combat** | Turn-based two-character combat | Turns alternate, HP only decreases, attack constant |
| **status** | Poison/buff effects with duration | Durations non-negative, effects consistent, HP capped |
| **crafting** | Recipe-based item crafting | Materials non-negative, total mass conserved |
| **party** | 3-member party + shared stash | Items conserved across all inventories |
| **leveling** | XP gain and level-up thresholds | XP monotonic, stats match level deterministically |
| **cooldown** | Ability cooldown timers | Cooldowns non-negative, bounded by max |
| **quest** | Multi-step quests with prerequisite chains | Prerequisites respected, completion monotonic |
| **durability** | Weapon/armor degradation and repair | Broken iff durability==0, durability bounded |
| **loot** | Loot drops with pity/guarantee system | Pity counter bounded, rare drought capped |
| **respawn** | Enemy respawn with zone capacity | Population conserved, zones bounded |
| **dynamic_shop** | Shop with supply-based dynamic pricing | Gold conserved despite variable prices |
| **combat_full** | Combat + equipment + status effects | Effects consistent, poison-between-turns death |
| **capacity_craft** | Crafting with inventory capacity limits | Capacity bounded, atomic craft-or-reject |
| **gated_craft** | Level-gated crafting recipes + combat XP | Recipe access matches level, XP monotonic |
| **stamina** | Action stamina with regen | Stamina bounded, non-negative, constants stable |
| **skill_tree** | Prerequisite-based skill unlocks | Prerequisites respected, points conserved |
| **reputation** | Faction reputation with rivalries | Standings bounded [-100, 100] |
| **summoning** | Timed summon slots (3 max) | Count consistent, inactive zeroed, durations non-negative |
| **world_grid** | 9x9 level-gated zone grid with biome tiling | Position bounded, zone matches, level gates respected |
| **elemental** | 4-element damage affinity (Fire/Ice/Lightning/Earth) | Elements bounded, multiplier matrix consistent, damage symmetric |
| **enchantment** | 3-slot weapon enchantments (fire/ice/vampiric/lightning) | Mutual exclusion, slot count bounded, enchantment validity |
| **trap** | Trap/hazard system on 2x2 grid with perception | Triggered implies present, HP bounded, perception bounded |
| **companion** | Companion/pet system (wolf/hawk/turtle) with loyalty | Loyalty bounded, passives match type, one active companion |
| **salvage** | Salvage/disenchant inverse crafting | Level-based output, material conservation, non-negative quantities |
| **auction** | Timed auction house with bidding | Bids monotonic, winner pays highest, gold conserved |
| **faction** | Alliance/betrayal faction system | Faction membership consistent, betrayal costs enforced |
| **fast_travel** | Waypoint-based fast travel | Unlocked waypoints persistent, travel requires unlock |
| **dialogue** | Branching dialogue trees | Node reachability, visited tracking, choice validity |
| **fog_of_war** | Exploration reveal system | Revealed tiles monotonic, visibility radius bounded |
| **permadeath** | Permadeath with legacy bonuses | Death permanent, legacy bonuses carry forward |
| **bounty** | Bounty board quest system | Bounty rewards match difficulty, completion tracked |
| **quint_crawl** | Full RPG game state machine (9x9 grid, 5 levels) | HP bounded, gold non-negative, level gates, durability bounded, combo bounded, stamina bounded, cooldowns bounded (incl. fortify), loot pity bounded, status effects bounded, weather deterministic, skill points non-negative, skill prereqs respected, venom sac non-negative, enemy element bounded, enchant slots bounded, no fire/ice incompatible, enemy element only in combat, inventory bounded, salvage level bounded, win condition correct |

## Quick start

```bash
just play        # build and run the game

just check       # typecheck all specs
just traces      # generate MBT traces
just test        # run all Odin MBT tests
just all         # all of the above

just check-one rpg          # typecheck one spec
just test-one rpg           # test one module
just trace rpg rpg_run      # regenerate one trace
just trace-crawl            # regenerate quint_crawl traces (5x, 100k samples)
just test-crawl             # regen traces + run crawl MBT tests
```

## Prerequisites

- [Odin](https://odin-lang.org/) (with vendor:raylib)
- [Quint](https://quint-lang.org/) (tested with 0.32.0)
- [just](https://github.com/casey/just) (task runner)
- X server or WSLg (if running on WSL)

## Docs

- [Asset Design Guide](docs/assets-design.md) — sprite specs for V2 visual upgrade (26 required assets)
