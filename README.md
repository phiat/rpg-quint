![Odin](https://img.shields.io/badge/Odin-lang-blue)
![Quint](https://img.shields.io/badge/Quint-formal%20spec-purple)
![Raylib](https://img.shields.io/badge/raylib-5.5-green)
![License](https://img.shields.io/badge/license-MIT-blue)

# Quint Crawl — Formally Verified RPG

A raylib RPG game built on formally verified game logic. Every game rule is specified in [Quint](https://quint-lang.org/), tested via Model-Based Testing (MBT), and implemented in [Odin](https://odin-lang.org/).

Inspired by: [Model-Based Testing for D&D](https://www.loskutoff.com/blog/model-based-testing-dnd/)

## The Game

**Quint Crawl** is a turn-based RPG rendered with raylib. Explore a 3x3 world grid, fight enemies, gather resources, craft gear, and level up to conquer the Castle.

```bash
just play             # build and run the game
```

Controls: WASD to move, E to fight, A to attack, P for potions, F to flee. See the HUD sidebar for zone-specific actions.

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
quint_crawl_game/   Raylib game executable (rendering, input, UI)
quint_crawl/        Shared game logic (Game_State, actions, constants)
specs/              Quint specifications (.qnt)
traces/             Generated ITF trace files (.itf.json)
quint_mbt/          Shared Odin library: ITF parser + trace replayer
*_mbt/              Per-module Odin implementation + MBT test harness
docs/               Design documents (asset specs, etc.)
justfile            Task runner for common workflows
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
| **world_grid** | 3x3 level-gated zone grid | Position bounded, zone matches, level gates respected |
| **quint_crawl** | Full RPG game state machine | HP bounded, gold non-negative, level gates, win condition correct |

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
```

## Prerequisites

- [Odin](https://odin-lang.org/) (with vendor:raylib)
- [Quint](https://quint-lang.org/) (tested with 0.32.0)
- [just](https://github.com/casey/just) (task runner)
- X server or WSLg (if running on WSL)

## Docs

- [Asset Design Guide](docs/asset-design.md) — sprite specs for V2 visual upgrade (17 PNGs)
