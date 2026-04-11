# Quint Model-Based Testing with Odin

Formal specifications in [Quint](https://quint-lang.org/) driving automated tests for Odin implementations via Model-Based Testing (MBT).

## How it works

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
specs/              Quint specifications (.qnt)
traces/             Generated ITF trace files (.itf.json)
quint_mbt/          Shared Odin library: ITF parser + trace replayer
*_mbt/              Per-module Odin implementation + MBT test harness
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

## Quick start

```bash
just check       # typecheck all specs
just traces      # generate MBT traces
just test        # run all Odin MBT tests
just all         # all of the above

just check-one rpg          # typecheck one spec
just test-one rpg           # test one module
just trace rpg rpg_run      # regenerate one trace
```

## Prerequisites

- [Quint](https://quint-lang.org/) (tested with 0.32.0)
- [Odin](https://odin-lang.org/)
- [just](https://github.com/casey/just) (task runner)
