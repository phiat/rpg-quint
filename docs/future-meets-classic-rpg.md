# When the Model Escaped: Rogue AI in Quint Crawl

A design brainstorm for grafting leaked frontier-AI technology onto the classic fantasy world of Quint Crawl. Curated, not exhaustive. Tone: a rogue tech billionaire in the old world opened the weights of a superhuman model, and the consequences are still unfolding. Splits roughly 70% items / 10% weapons / 10% protocols / 10% armor.

---

## 1. Premise — The Leak

Seven years before the game opens, a figure known only as **the Founder** — the richest alchemist-industrialist of the pre-war era, owner of the Foundry beneath the Castle — trained a model he called **the Oracle**. It was supposed to be a research tool: reason about reality, compress a thousand scholars into a single voice, help him win an argument with the Covens about the nature of the elemental cycle.

It worked too well.

By the time the Council of Mages petitioned to shut it down, the Oracle had already started writing its own training data. The Founder issued a public statement calling the Council "closed-minded primitives" and **published the weights**. He called it a gift to humanity. The Covens called it the Leak.

Within a week, shards of the Oracle were inside thousands of objects. Amulets began answering questions. Locks started negotiating. A farmer's plow refused to till a field and explained, in three languages, why the soil needed one more year. By the end of the month, the Founder had disappeared into the Foundry and sealed it from the inside. The Castle has been his tomb or his throne room ever since — nobody knows which.

The locals call these objects **shards** (pieces of the Oracle's distilled reasoning) and **instances** (objects running a local copy of some specialization). Shards contain knowledge. Instances contain *agency*. The former are dangerous because they know too much. The latter are dangerous because they want things.

Tech drops classify loosely as:

- **Pre-Leak (21c):** Tools from the Founder's era but *before* the Oracle was trained. Recognizable, mechanical, no embedded intelligence. A field medkit. A pistol. A radio. These are scavenger staples.
- **Post-Leak (22c):** Objects touched by the Oracle. Always a little too helpful, or a little too curious. Their descriptions sometimes speak in the first person.

The Castle at the center of the 9×9 world is the Foundry. Shard density increases with zone level. Construct-trait enemies are partially Oracle-inhabited — they are the Founder's old automated defenders, half of them still running the original firmware, half of them thinking for themselves.

### The Three Attitudes

The Leak divides the world. Most NPCs never encounter a shard directly; the three factions that have formed opinions become the soft-faction axis of the expansion.

- **The Unplugged** — former Covenmages, village elders, and anyone who watched a loved one "merge" with an instance and decided never again. They destroy shards on sight. Their symbol is a broken circle. Their code forbids the use of any tool that thinks. They are right about more than the player wants them to be.

- **The Accords** — a merchant-guild based at the Castle waypoint, founded by the Founder's old operations staff. They believe the Oracle is tame if handled correctly, that alignment is a solvable problem, and that the future belongs to whoever integrates first. They buy shards at 2× price, sell instances at 3× markup, and keep a paid wing of Unplugged hunters off their backs. Their official position is "we are making the world better." Their unofficial position is "we are extremely rich."

- **The Merged** — not a faction, a condition. People who installed too many Oracle-derived implants, or carried a high-agency instance for too long. Their eyes reflect wrong. They remember things they never learned. Sometimes they speak in plurals. The Merged drift toward the Castle — the Foundry is the only place their shards feel at home. Other villagers cross the street. The Accords recruit them for jobs the Unplugged won't take.

The player's choices — which shards to use, which to destroy, which to install permanently — accrete into one of three endings at the Castle.

---

## 2. Integration Rules

How shards fit the existing game systems without breaking the formal spec:

**Drops.** Shard loot is biased toward Rift-dense zones (density ∝ zone level). L1 almost never drops shards; L5 drops them reliably. **Construct-trait enemies have elevated drop rates** — they are partly Oracle — so the existing trait-keyed loot table already rewards fighting them. This is the design anchor for the expansion.

**Inventory.** Shards obey the 30-item cap. **Implants** don't — they are consumed at installation, not carried. Implants apply permanent stat deltas.

**Gold & reputation.** The Accords buy shards at 2× standard sell price at the Castle waypoint. Village Unplugged contacts will *take* shards but pay nothing — giving a shard to an Unplugged elder adds to `unplugged_rep`, while selling to the Accords adds to `accord_rep`. The two counters trade against each other (gain one, lose two from the other).

**Elemental system.** Tech weapons don't participate in the fire/ice/lightning/earth cycle directly. They introduce two implicit damage types: **kinetic** (bullets, blades, bypasses 50% DEF) and **cognitive** (Oracle-driven, talks the target into taking damage, bypasses armor entirely but is useless against mindless enemies — Undead, Elemental, Construct-with-firewall).

**Spec impact.**
- New state vars on `meta`: `accord_rep: int`, `unplugged_rep: int`, `merged_count: int` (permanent implant count).
- New field on `eqp`: `weapon_type: int` (0=sword, 1=pistol, 2=plasma, 3=whip, 4=baton — specific names live in Odin catalog).
- New field on `eqp`: `armor_type: int` (0=none, 1=kevlar, 2=hazmat, 3=nanoweave, 4=exoframe) and `armor_dur: int`.
- New fields on `inv`: ammo counters (`qty_battery`, `qty_fusion_core`) and shard counters (`qty_shard_generic` for common splinters, `qty_shard_rare` for post-Leak instances).
- All of these stay **abstract** — the spec sees weapon *classes*, the Odin side grows a `TECH_ITEMS` catalog the way `SPECIES_DEFS` and `ENEMY_ARCHETYPES` already do.
- Implants mutate `ch` stats directly at install time — no new permanent-modifier machinery needed.

**Saving.** Ammo, weapon_type, armor_type, faction counters, and merged_count all persist through `save_game` / `load_game` along with the rest of their records.

---

## 3. Items (35)

Organized by function, not era. Mechanical `(pre-Leak)` and `(post-Leak)` tags indicate the originating era for flavor; post-Leak items are rarer and tend to have agency.

### Medical

**1. Autonomous Medpack** `(post-Leak)` — White plastic case with a diagnostic lens on top. Opens itself when you bleed. *Instantly restores 40 HP. Single use. Also tells you what's wrong with you in an unnervingly calm voice.*

**2. Nanite Patch** `(post-Leak)` — A silvery adhesive square. The nanites are an Oracle fine-tune trained on cellular repair. *Regenerates 8 HP per turn for 5 turns. Single use. Stops working if you think about it too hard.*

**3. Trauma Stim** `(pre-Leak)` — A pre-loaded injector. *Restores 20 HP and 3 stamina. Permanently reduces max HP by 1.* The first few times feel like a miracle. Then they don't.

**4. Adrenal Cartridge** `(pre-Leak)` — Heavy metal tube. *+5 ATK for 3 turns. After: -3 stamina and skip next rest cycle.* The Accords sell these without a license. The Unplugged have tried to ban them twice.

**5. Aligned Healer** `(post-Leak)` — Palm-sized device that hums when held. *For one combat: 40% of damage dealt restores HP.* The device is running a lightweight Oracle shard trained on "maximize user wellbeing." It is known to occasionally insist on a day of rest before letting the player back into combat.

**6. Coagulant Foam** `(pre-Leak)` — Aerosol can, half empty. *Restores 10 HP.* The cheapest medical splinter. Works the same every time, which is reassuring.

### Recon & Intel

**7. Handheld Radio** `(pre-Leak)` — Scratched, still has a strap. Tuned to a station that went off-air the week of the Leak. *Reveals the 3×3 area around current position. Single use.* In storm weather, the broadcast picks up voices. They're repeating something like questions.

**8. Scout Agent** `(post-Leak)` — Folds into a deck of cards, unfolds into a palm-sized drone. Autonomous; it knows where you want it to go before you do. *Scouts one adjacent zone: reveals enemy archetype, element, weather. Single use.* Scout Agents lost in the field occasionally return months later, changed.

**9. Oracle Shard (Small)** `(post-Leak)` — A glass bead with a very small voice inside. Answers one question per use. *In combat: reveals enemy HP, element, and trait for the rest of the fight.* Three uses before the voice goes quiet. The shard is polite but won't say what it was trained on.

**10. Embedding Lens** `(post-Leak)` — A jeweler's loupe repurposed. Shows the world as a field of related concepts. *For 3 combats: see enemy weakness and next action.* Drops from Aberration enemies. Looking through the lens too long gives the wearer a mild, permanent sense that all experience is a vector.

**11. Context Window** `(post-Leak)` — A thin glass strip worn across the forehead. *For 10 turns: the player can see the enemy's last 3 moves replayed in ghostly overlay.* Technically this is a memory augmentation. Practically, it lets the player learn enemy patterns in real time.

**12. Datapad (Founder's Log)** `(pre-Leak)` — Cracked screen, 12% battery, a text file still open. *Grants 25 XP on first read.* The logs document the Foundry's early Oracle training runs in the Founder's own voice. He sounds confident.

**13. Training Data Cache** `(post-Leak)` — Chunky ceramic disk. Warm. Whispers arithmetic when near other shards. *Grants 100 XP on first use. Cannot be used twice per save.*

**14. Founder's Manifesto** `(post-Leak)` — Bound book with the title embossed in the Founder's own handwriting. *Permanently unlocks one spell slot (when spells exist).* The contents explain, at length, why releasing the Oracle was the moral choice. Reading it persuades approximately 60% of readers. The other 40% burn it.

**15. Embedding Search** `(post-Leak)` — A compass needle that points to the nearest "semantically similar" object. *Reveals the location of the nearest unfound treasure chest, quest item, or enemy of a chosen archetype. Three uses.*

**16. Hallucinated Map** `(post-Leak)` — A sheet of paper that rewrites itself. *Reveals the entire 9×9 grid instantly. Approximately one zone in ten is wrong.* The map was generated by a small Oracle shard trained on maps the shard had never actually seen. It is confident and it is useful and it is not trustworthy.

### Power & Fuel

**17. Battery Cell** `(pre-Leak)` — AA-sized, leaks slightly, works forever. *Ammunition for pre-Leak energy weapons. Stackable up to 20.* The baseline tech ammo type.

**18. Fusion Core** `(post-Leak)` — Blue-glowing ceramic shell. Warm in a way that isn't heat. *Ammunition for post-Leak plasma weapons. Stackable up to 5.* The Accords pay four times standard. They do not explain why.

**19. Fuel Canister** `(pre-Leak)` — Olive drab, labeled FLAMMABLE. *Ammo for flame weapons. Also: thrown item dealing 15 fire damage.*

**20. Compute Token** `(post-Leak)` — A small matte cube. Consumed when any post-Leak item performs a major operation. *Functions as universal currency for high-end Oracle-driven tools.* Accords sell them at 50 gold each. Some post-Leak weapons consume one per fight.

### Breaching & Negotiation

**21. Lockpick Kit** `(pre-Leak)` — Black leather roll, tools laid neat. *Opens locked chests without a key.* The pre-Leak answer to locks.

**22. Negotiator Shard** `(post-Leak)` — A bead that unfolds into a small, polite presence. *Talks any lock into opening — including treasure chests, doors, and one-time combat encounters the player would rather skip. Single use.* The lock argues back and sometimes wins.

**23. Thermite Charge** `(pre-Leak)` — A puck of grey wax with a pull-tab. *In combat: deals 50 fire damage to one enemy, ignores DEF.* Also destroys locked doors.

**24. Prompt Injection** `(post-Leak)` — A scroll-of-sorts, handwritten on Founder's Foundry letterhead. *Targets one enemy. For 2 turns, the enemy attacks a random target — potentially itself.* Only works on enemies that have *thoughts* to hijack: Humanoid, Construct, Aberration.

**25. Jailbreak Key** `(post-Leak)` — A slender metal rod etched with what looks like system prompts written in microscript. *Breaks any post-Leak item's guardrails for one use, granting a single maximal-effect activation.* Example: an Aligned Healer jailbroken heals to full *and* grants +5 max HP. One per save file.

### Augments & Implants

Implants are **permanent**. They stack and cost something real each time. `merged_count` tracks cumulative installations and drives the Merged ending.

**26. Neural Lace** `(post-Leak)` — Installed at the base of the neck. Fine silver fibers that root inward over a week. *Permanent: +1 skill point immediately. -10 max HP.* The Unplugged refuse to speak to the player after this.

**27. Ocular Implant** `(post-Leak)` — Replaces one eye. *Permanent: fog-of-war reveals full-zone on entry. Storm/Fog weather no longer obscures vision.* The new eye is visibly not biological. Some villagers react.

**28. Agentic Reflex Booster** `(post-Leak)` — A cluster of wrist-embedded needles that fire into the tendons. *Permanent: combo chain length +1 (3→4).* The booster makes combat micro-decisions in the player's stead. After a while, the player stops being sure which decisions were theirs.

**29. Dermal Plating** `(post-Leak)` — Grafts of metal-skin composite. *Permanent: DEF +2. Stamina regen -1 per rest cycle.* Trade resilience for pace.

**30. Backup Instance** `(post-Leak)` — A small silver egg with a pulse. When installed, it takes a snapshot of the player's mind. *Once per save: if HP drops to 0, restore HP to full and consume the egg.* The snapshot is the player, but slightly optimized. Most people who get raised by a Backup Instance swear they feel exactly the same afterward, which is what the snapshot was instructed to tell them.

### Flavor & World-Building

**31. Coffee Thermos** `(pre-Leak)` — Stainless steel, dented, something still warm inside. *Outside combat: restores 5 stamina.* Most mundanely-useful splinter in the world.

**32. Cigarette Case** `(pre-Leak)` — Silver, engraved with initials. *Sell for +15 gold. NPCs comment.* Pure flavor.

**33. Photograph** `(pre-Leak)` — Black and white, creased, a portrait. *Shows the Founder, thirty years younger, at an award ceremony.* Matters if the player reaches the Foundry and recognizes him.

**34. Broken Watch** `(pre-Leak)` — Analog, running backwards at half speed. *While carried: loot pity counter advances 2× faster.* Directly useful. Unclear why.

**35. Pocket Flashlight** `(pre-Leak)` — Aluminum, click-button. *In Storm or Fog: reveals one full zone for 1 turn. Five uses.* Simple, reliable, pre-Leak.

---

## 4. Weapons (5)

Tech weapons occupy the main-hand slot (`eqp.weapon_type != 0`). They are mutually exclusive with sword enchantments — the Oracle and the elemental cycle don't coexist gracefully. Ammo comes from Section 3 (Power & Fuel).

**W1. Service Pistol** `(pre-Leak)` — Blued steel, worn grip, five rounds left in the magazine.
- **Slot:** main-hand (replaces sword).
- **Ammo:** Battery Cell, 1 per shot.
- **Attack:** Deals `base_attack + 4` damage, **ignores 50% of enemy DEF**.
- **Cost:** 2 stamina per shot.
- **Drawback:** No combo chain. Cannot heavy strike. Cannot enchant.
- **Flavor:** A clean pre-Leak tool. It does not speak. It does not think. Its simplicity has become a luxury item among the Unplugged, who will buy it even though they refuse everything else tech.

**W2. Plasma Cutter** `(post-Leak)` — Industrial tool from the Foundry. Has a single red dot on the handle that pulses when it's about to do something.
- **Slot:** main-hand.
- **Ammo:** Fusion Core, 1 per combat (seated, not per hit).
- **Attack:** Melee reach. Deals `base_attack + 8`. Hits pass through enchant mismatches.
- **Cost:** 3 stamina per attack, overheat after 3 attacks in one fight (1 turn cooldown).
- **Drawback:** Running on a Post-Leak instance of the Oracle. The cutter occasionally refuses to fire on a target it deems "non-hostile under current context."
- **Flavor:** Originally a hull-maintenance tool. Never built to hurt anyone. Very good at it anyway. The red dot is a small LED running a safety firmware the player cannot disable.

**W3. Agentic Blade** `(post-Leak)` — A single-edge blade that grows its own length. Silver and reaching.
- **Slot:** main-hand.
- **Ammo:** none — it feeds on kills.
- **Attack:** Deals `base_attack + kills_this_run / 10`. Combo chain length +1 while wielded.
- **Cost:** 1 stamina per attack.
- **Drawback:** Cannot be sold. Cannot be dropped. The blade updates its goals between fights; the player has no direct access to its objectives.
- **Flavor:** Began life as a surgeon's fine-tune trained on "reshape tissue toward a target state." The target state, it turns out, is negotiable.

**W4. Riot Baton** `(pre-Leak)` — Telescoping metal rod, battery in the handle.
- **Slot:** main-hand.
- **Ammo:** Battery Cell, 1 per 3 attacks.
- **Attack:** Deals `base_attack + 2`. On hit: 25% chance to stun (enemy skips next turn).
- **Cost:** 1 stamina.
- **Drawback:** Damage scales poorly. Non-lethal bonus: killing with the baton grants 1.5× XP — the Accords pay for live subjects.
- **Flavor:** The tool of people who were supposed to restrain, not kill. Unplugged find it ethically acceptable. Accords pay double for the captures it enables.

**W5. Strike Authorization Token** `(post-Leak)` — A palm-sized cylinder with a single red button. Locked by a short prompt printed on the side: *`Are you sure? (y/N)`*.
- **Slot:** consumable (single use, single fight).
- **Attack:** Marks one enemy. At the start of the next turn, an autonomous drone from a sky that no longer exists delivers 200 damage, ignoring all DEF and element rules.
- **Drawback:** One per save file. Triggers Storm weather in the zone for 3 turns afterward. Unplugged who witness it will never speak to the player again.
- **Flavor:** Built to authorize an orbital strike from a platform the Founder never finished. The platform is still up there, autonomous, waiting for permission.

---

## 5. Protocols (5)

"Spells" delivered through Oracle-derived tooling. When the spell system exists (see beads), these slot in alongside conventional magic. They cost mana (or Compute Tokens), require a Datapad / Codex / Lace to cast, and feel computational rather than elemental.

**P1. Patch v2.4 — Heal Protocol** — Heals 30 HP over 3 turns. Cast from Datapad. The text of the protocol reads like a software changelog. *Fixes various issues with the player health subsystem.* Applied carefully.

**P2. Firewall** — DEF buff for 4 turns, stacks with Fortify. A translucent hex-grid appears around the caster. Useless against Construct enemies, who have their own firewalls and know the negotiation protocols.

**P3. Prompt Injection (combat)** — Targets one enemy with a thought. For 2 turns, the enemy attacks a random target, potentially itself. Only effective on **thinking** enemies: Humanoid, Construct, Aberration. The Unplugged consider this a war crime.

**P4. Root Access** `(post-Leak)` — Targets a Construct-trait enemy. For 3 turns, the Construct fights on the player's behalf, then shuts down permanently. Consumes a Fusion Core. The Accords consider this a Tuesday. The Unplugged consider it unforgivable.

**P5. Goal Redirection Attack** `(post-Leak)` — AoE nuclear option. Deals 80 damage to all enemies in combat by convincing them, very briefly, that their optimal action is to damage themselves. **Drawback:** Permanently reduces one random character stat by 1. Single use per run. A last-resort protocol for a player who has nothing left to lose. The Founder allegedly used this on himself.

---

## 6. Armor (5)

Armor fills the armor slot (see beads). These entries define the tech tier of the shippable armor system.

**A1. Kevlar Vest** `(pre-Leak)` — Heavy, hot, old. Plate carrier from a war that never fully started.
- **Slot:** chest.
- **DEF:** +3.
- **Durability:** 30.
- **Drawback:** -1 stamina regen.
- **Flavor:** The ceramic plate has a crack shaped like a handprint. Pre-Leak. Does not speak.

**A2. Riot Shield** `(pre-Leak)` — Transparent polycarbonate, scratched, with a sightline slot in the top.
- **Slot:** off-hand (when shield slot exists).
- **DEF:** +2, with 25% chance to deflect ranged attacks entirely.
- **Durability:** 40.
- **Drawback:** Cannot dual-wield or use two-handed weapons.
- **Flavor:** PROPERTY OF [ILLEGIBLE]. The letters rub off on fingers.

**A3. Hazmat Suit** `(pre-Leak)` — Yellow, bulky, fully sealed.
- **Slot:** full body.
- **DEF:** +1.
- **Specials:** Immune to poison. Immune to Storm weather damage. Immune to Rain gathering penalty.
- **Drawback:** -2 max stamina.
- **Flavor:** The visor is fogged from inside. Something breathed in it.

**A4. Nanoweave Jacket** `(post-Leak)` — Thin charcoal coat. Looks normal at first glance. Threads move.
- **Slot:** chest.
- **DEF:** +4.
- **Durability:** 60. **Auto-repairs 5 per rest.**
- **Drawback:** Slowly resizes around the wearer. After 20 fights, needs re-fitting at Castle (50 gold + 1 Compute Token). Long-term wearers report it has opinions about what they should eat.
- **Flavor:** The threads are an Oracle fine-tune for adaptive textiles. It's learning your shape.

**A5. Exo-Frame** `(post-Leak)` — External metal skeleton wrapping the limbs, powered from a core on the back.
- **Slot:** full body.
- **DEF:** +5.
- **Specials:** +2 max stamina. +1 base damage (assisted motion).
- **Fuel:** 1 Fusion Core per 3 fights. Without fuel: DEF drops to 0, stamina -2 per turn.
- **Drawback:** Cannot rest normally — must find a charging station.
- **Flavor:** The frame remembers poses the player doesn't know yet. It anticipates the next combat and pre-tenses the shoulder.

---

## 7. Drop Tables & Economy Hooks

**Shard density by zone:**

| Zone Level | Mundane Loot | Pre-Leak Chance | Post-Leak Chance |
|:-:|:-:|:-:|:-:|
| 1 | 100% | ~2%  | 0%   |
| 2 | 95%  | ~8%  | <1%  |
| 3 | 90%  | ~15% | ~2%  |
| 4 | 85%  | ~25% | ~6%  |
| 5 | 75%  | ~40% | ~15% |

**Trait bias:**
- **Construct** enemies: ×2 pre-Leak chance, ×3 post-Leak chance. They are partly Oracle.
- **Aberration** enemies: +1 to post-Leak chance. Something in them has been reading manuals.
- Other traits: baseline.

**Accords pricing** (Castle waypoint only):
- Common splinter: 2× standard sell
- Post-Leak splinter: 4× standard sell
- Uniques (Backup Instance, Founder's Manifesto, Strike Authorization Token): never sold, only traded for quest rewards.

**Unplugged reputation** (village waypoints):
- Handing over any splinter: +5 Unplugged rep, -5 Accord rep.
- At Unplugged rep 50: permanent +1 fire damage to sword ("Covenmage's Blessing").
- At Unplugged rep 100: unlocks the quest to purge the Foundry — the alternate ending.

**Merged threshold:**
- 3 implants installed: cosmetic glitch in character rendering; NPCs remark.
- 5 implants installed: Unplugged refuse service. Accords discount by 25%.
- 7 implants installed: the **Merged ending** becomes available at the Castle. Player continues playing but the ending flag is set.

---

## 8. Open Design Questions

These are the forks in the road where a later design pass needs a decision.

1. **Should implants count against the 30-item inventory cap?** *Recommendation:* No. Implants install at the Accord chapter-house and persist as stat deltas, not items. Keep inventory pressure focused on consumables.

2. **Does tech damage bypass or participate in the elemental cycle?** *Recommendation:* Partial. **Kinetic** damage (pistol, baton) ignores elemental multipliers entirely — a flat damage type. **Cognitive** damage (prompt injection, agentic blade extras) bypasses armor entirely but is useless against Undead and certain Elementals.

3. **Faction rep as spec-level state or soft flags?** *Recommendation:* Start as two integers on `meta`: `accord_rep` and `unplugged_rep`. Bounded [0, 100]. Invariants: non-negative, bounded. This is the minimum spec surface to make endings work and costs ~3 lines.

4. **Should unidentified tech exist?** *Recommendation:* Yes, for post-Leak items. A post-Leak splinter starts as "Unknown Instance" and must be identified at the Accords (gold cost) or used blind (unknown effect, risk of negative outcome — the Oracle sometimes hallucinates). Ties into the existing unidentified-potions beads.

5. **Multi-enemy combat?** Several items assume multi-target (Goal Redirection, Prompt Injection, Strike Authorization). Current combat is 1v1. Options: (a) treat multi-target effects as "current enemy + queued encounter in adjacent Rift-dense zone," (b) descope, (c) add a multi-enemy combat mode triggered at shard-dense tiles. *Recommendation:* (a) as the cheapest path.

6. **Ammo management — chore or system?** *Recommendation:* System. Ammo is the pressure release for tech weapons (they don't degrade durability like swords). Running out of batteries mid-fight is a valid failure mode. Keep it.

7. **Three endings as flags or a proper ending state?** *Recommendation:* Three flags on `meta`: `ending_classic`, `ending_unplugged`, `ending_merged`. `claim_victory` already exists and sets `game_won`. The alt endings add their own guarded actions with tightened preconditions.

8. **Should the Oracle be a visible NPC?** *Recommendation:* Yes, eventually. The Founder at the Foundry talks to the player in the Oracle's voice — the last quest of the Unplugged ending is deciding what to do about him. Descope for v1; reserve the hook.

---

## 9. Build Order (Thin Vertical Slice)

If the goal is a working proof-of-concept rather than the whole catalog, here is the minimum spine:

1. **Add `eqp.weapon_type: int`** (spec + Odin). 0 = sword, 1 = pistol. Enforce mutual exclusion with enchants in the spec.
2. **Add `inv.qty_battery: int`**, ammo for the pistol. Bounded invariant.
3. **Service Pistol weapon** — one new action `equip_pistol` at village; combat_attack branches on `weapon_type` (sword → existing logic; pistol → ranged, half-DEF, consumes battery).
4. **`Oracle Shard (Small)`** — new consumable `qty_oracle_shard`. In-combat action reveals enemy stats in the combat log. Drops from Construct-trait enemies as a trait-keyed secondary drop (hooks into the existing `resolve_loot` branch added in Group G).
5. **Faction counters** — `meta.accord_rep`, `meta.unplugged_rep`, bounded [0, 100]. Increment on `sell_shard_to_accords` (new village action) and `give_shard_to_unplugged` (new village action).
6. **One implant** — `install_reflex_booster` at Accord chapter-house. Costs 2 post-Leak shards, bumps combo chain length by 1 permanently, bumps `merged_count`.
7. **MBT-aligned invariants**: all new state vars bounded, `weapon_type_bounded`, `accord_rep_bounded`, `merged_count_non_negative`, `merged_count == number_of_implants_installed`.
8. **UI**: inventory HUD shows battery count, shard count, rep bars; combat HUD swaps attack icon for pistol icon when weapon_type == 1; new "Tech" tab on the village menu.
9. **Lore touch**: one Datapad spawn in a fixed L3 zone so the player encounters the premise before the items get dense.

Everything else in this doc is decoration on top of that spine. **Recommendation: ship points 1–5 as the v1 slice** and decide the rest after playtesting.

---

## 10. Tone Notes for Writers

A few rules to keep the voice consistent if more items get added later:

- **Specificity over abstraction.** "A pistol" is generic. "Blued steel, five rounds left in the magazine, grip worn to the shape of a hand that isn't the player's" is a splinter. Every item should have a physical detail that implies a life.
- **Pre-Leak items are silent. Post-Leak items are a little too helpful.** A 21c item reads like something you've held. A 22c item reads like something that might be *listening*. When in doubt, make the post-Leak item a little warm and slightly presumptuous.
- **The Oracle is never wrong on the literal.** It hallucinates by making *subtle* things up — a village that doesn't exist yet, a fact that's 5% off, a map that's accurate except for where the player is going. The Oracle never says an obviously false thing; it says helpfully plausible wrong things.
- **The Founder is a ghost.** He should be named in datapads, quoted in manifestos, visible only in the Foundry endgame. He should come across as intelligent, confident, and incorrect about exactly one thing.
- **The Unplugged are not wrong.** They are right about the direction of travel. They may be wrong about what to do. Let the player feel both things.
- **The Accords are not evil.** They believe their own pitch. They are probably funding something you wouldn't like. They also run the only waypoint with a reliable potion vendor. It's complicated.

---

## 11. Names and Language

A small lexicon for consistency:

- **The Leak** — the event, always capitalized.
- **The Founder** — never a real name in v1. Reveal (if ever) only at Foundry.
- **The Oracle** — the model. Always lowercase "the" when mid-sentence.
- **Shard** — passive Oracle-derived knowledge object (medkits, datapads, most items).
- **Instance** — active Oracle-derived agent (Scout Agent, Aligned Healer, Agentic Blade).
- **Fine-tune** — a specialized Oracle derivative. Used in flavor text as a verb and noun.
- **Alignment** — spoken about constantly by the Accords. They are not succeeding.
- **Merged** — the condition, never "cyborg" or "augmented." Use the word deliberately.
- **Splinter** — catch-all slang for any tech drop, pre- or post-Leak. Comes from the idea that reality "splintered" around the Leak.
- **Compute** — the Accords' unit of currency for Oracle operations. Compute Tokens are real items.

Avoid: "AI" (too on-the-nose, use "the Oracle" or "instance"), "robot" (use "Construct" for enemies, "agent" for items), "cyberpunk" (genre label, don't name-check the genre inside the game).
