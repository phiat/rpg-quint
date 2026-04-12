# When the Rift Opened: Future Tech in Quint Crawl

A design brainstorm for grafting 21st- and 22nd-century technology onto the classic fantasy world of Quint Crawl. Curated, not exhaustive. Tone leans gritty-scavenger (Shadowrun) layered over post-cataclysm ruin (Horizon). Splits roughly 70% items / 10% weapons / 10% protocols (spells) / 10% armor.

---

## 1. Premise — The Rift

Five years before the game opens, the Covens of the Castle attempted a Grand Binding: a ritual to fuse the five elemental planes into a stable cycle, intended to end storm season forever. Something folded. Reality's weave caught on itself and pulled taut across adjacent timelines — not other worlds, but other *whens* of this one. A dozen possible futures bled into the present through the tear.

The locals call the wreckage **splinters**: objects that shouldn't exist yet, or anymore. A pistol lodged in an oak. A plastic medkit buried under a druid's cairn. A wristwatch still ticking on a skeleton's arm, stamped with a date no one will live to see. Some splinters are fragments from a near-future ("21c": recognizable, mechanical, scavenged). Others come from much further down the line ("22c": sleek, impossible, half-alive). The Rift doesn't discriminate by era — a 1960s field radio and a nanotech resurrection anchor might drop from the same crack in a cave wall.

The Castle at the center of the 9×9 world is the Rift's origin and its deepest scar. Rift density increases with zone level.

### The Three Attitudes

Splinters divide the world. Most NPCs never get an opinion; the three that do become the future's soft factions.

- **The Cinder Covens** — the original casters. They blame themselves and the tech. They've re-named their order the Cinders because that's what's left of the ritual chamber and most of their initiates. They hunt splinters to destroy them, on the theory that every object that shouldn't be here is widening the tear. Hostile to scavengers. Offer no rewards, only forgiveness.

- **The Gearwright Concord** — a merchants' guild based at the Castle waypoint. They pay double for splinters, reverse-engineer the simple ones, and sell the products. Unscrupulous but reliable. They don't care what you become, they care what you bring.

- **The Hollowed** — not a faction so much as a condition. Villagers who took too many implants. Their outlines blur at the edges. They remember their names less often. They tend to drift toward the Rift, then toward the Castle, and eventually no one sees them again. Other NPCs avoid them.

The player's choice to embrace, ignore, or destroy splinter tech becomes a soft ending axis.

---

## 2. Integration Rules

How splinters fit the existing game systems without breaking the formal spec:

**Drops.** Splinter loot is biased toward zones with Rift density. Rift density ∝ zone_level. L1 almost never drops splinters; L5 drops them reliably. Construct-trait enemies (golems, elementals, precursor defenders) have elevated drop rates — they are partly made of the same wreckage. The existing trait-keyed loot table gains a `Splinter` category that overlays the mundane drop.

**Inventory.** Splinters obey the 30-item cap. Implants do not — they're consumed on use, not carried. This creates a tension where stocking up on splinters competes with stocking potions and mats.

**Gold.** The Gearwright Concord buys splinters at 2× base sell price, but only at the Castle waypoint. Local villagers pay nothing; Cinder Coven NPCs take them for free and you gain reputation (TBD).

**Elemental system.** Tech weapons don't use the fire/ice/lightning/earth cycle directly. They introduce two new implicit damage types: **kinetic** (ballistic, ignores elemental weaknesses, partially pierces DEF) and **energy** (plasma/laser, maps to lightning for weakness purposes). 22c weapons blur the line by dealing `kinetic + energy` hybrid.

**Spec impact.** Minimal. Tech weapons and armor become additional rows in the `WEAPON_DEFS` / `ARMOR_DEFS` catalogs planned in the weapons-expansion beads. The Quint spec sees them as abstract weapon classes with stat deltas — no new state variables required. Implants are the exception: they permanently modify player stats, which may want a new `implant_count: int` on CharState for the Hollowed invariant.

**Saving.** Splinters save and load like any inventory item. Implants save as permanent stat deltas baked into `max_hp`, `attack_power`, etc. The Rift Anchor resurrection item is the only splinter that touches the death path.

---

## 3. Items (35)

Items are consumables, tools, and implants. Organized by function, not era — because the Rift mixes eras freely. `(21c)` and `(22c)` tags indicate the originating timeline for flavor text; mechanically, 22c items tend to be rarer and stronger.

### Medical

**1. Field Medkit** `(21c)` — Plastic case, red cross, blister-packed hemostats and a needle of something clear. *Instantly restores 40 HP. Consumed on use.* Drops from anywhere with Rift density ≥ 2. Cinder Covens will burn it if you show it to them.

**2. Nanite Patch** `(22c)` — A silvery adhesive square the size of a thumbnail. Warm to the touch. *Regenerates 8 HP per turn for 5 turns. In-combat only. Single use.* Drops from high-tier Construct enemies. Stacks weirdly with poison — the nanites try to eat the toxin and sometimes lose.

**3. Trauma Stim** `(21c)` — A pre-loaded injector marked with yellow hazard tape. *Restores 20 HP and 3 stamina instantly. Permanently reduces max HP by 1.* The first few times it feels like a miracle. Then it doesn't.

**4. Adrenal Cartridge** `(21c)` — Heavy metal tube, screws into a wrist brace nobody has. *+5 ATK for 3 turns. After: -3 stamina, skip next rest cycle.* Gearwright Concord sells these to anyone with gold. The Cinders have tried to ban them twice.

**5. Blood Synthesizer** `(22c)` — Palm-sized device that grows red inside when you hold it. *For one combat: 50% of damage dealt restores HP. Single use.* Vampiric-enchant-equivalent without the enchant slot. Nobody wants to know how it does this.

**6. Coagulant Foam** `(21c)` — Aerosol can, half empty, label in a dead language. *Cures bleeding (when bleed system exists). Restores 10 HP. Single use.* For now, a cheap potion alternative with flavor.

### Recon & Intel

**7. Handheld Radio** `(21c)` — Chunky, scratched, still has a strap. Tuned to a station that went off-air. *Reveals the 3×3 area around current position on the map. Single use.* In zones with storm weather, the radio picks up voices it shouldn't.

**8. Pocket Drone** `(22c)` — Folds into a deck of cards. Unfolds into a palm-sized quadcopter. *Scouts one adjacent zone: reveals enemy archetype, element, and current weather before entry. Single use.* Drones lost to the Rift sometimes return, changed.

**9. Geiger Counter** `(21c)` — Orange plastic, Cyrillic labels, a dial that reads in hexagrams not numbers. *Detects Rift density in the current and adjacent zones. Reusable.* The needle spikes near splinter caches the player hasn't found yet. Guides exploration.

**10. Scanner Goggles** `(22c)` — Smoked lenses, a jeweler's loupe, circuitry thinner than hair. *For 3 combats: see enemy HP, element, and trait.* Drops from Aberration enemies. Wearing them too long gives headaches that become migraines that become something else.

**11. Tactical Overlay Chip** `(22c)` — A glass sliver that slots into Scanner Goggles. *Upgrades scanner: also shows enemy weakness and next action.* Rare. Stacks with Goggles; useless alone.

**12. Datapad** `(21c)` — Cracked screen, 12% battery, a text file still open. *Grants 25 XP on first read. Can be read again for lore only.* Different datapads carry different last-messages from different timelines. Possible quest hook.

**13. Precursor Codex** `(22c)` — Palm-thick, warm, writes itself when held. The handwriting is the player's own, from a future they haven't had. *Permanently unlocks one spell slot (when spells exist).* One per run.

**14. Analyzer Wand** `(22c)` — Lab equipment. A clear rod with LEDs inside that pulse when passed over unknowns. *Identifies one unknown potion or one unidentified drop. Three uses.* Depends on the unidentified-loot system.

**15. Map Fragment (GPS)** `(22c)` — A folded sheet of plastic that maps itself to the player's location. *Reveals all village/waypoint positions on the minimap permanently.* Rift-damaged; the map shows two villages that don't exist yet, and one that used to.

### Power & Fuel

**16. Battery Cell** `(21c)` — AA-sized, leaks slightly, works forever. *Ammunition for energy weapons. Stackable up to 20.* The baseline tech ammo type.

**17. Fusion Core** `(22c)` — Pulses blue through a ceramic shell. Warm in a way that isn't heat. *Ammunition for 22c plasma weapons. Stackable up to 5.* Highly valuable. Gearwrights pay quadruple.

**18. Fuel Canister** `(21c)` — Olive drab, labeled FLAMMABLE in three scripts. *Ammo for flame weapons. Also: consumable thrown item that deals 15 fire damage in combat.*

**19. Cryo Cartridge** `(22c)` — Frosted glass, refills itself from the air somehow. *Ammo for ice weapons. Also: consumable that applies frozen status 1 turn.*

**20. Power Crystal** `(21c/22c hybrid)` — A quartz geode with a wire wrapped around it. Someone's repair job. *Hybrid ammo: works for any tech weapon at half effectiveness. Useful when you're low on everything.* Feels wrong in the hand.

### Breaching & Sabotage

**21. Lockpick Kit** `(21c)` — Black leather roll, tools laid neat. *Opens locked chests without a key.* Simple but missing from the current game. Drops from Humanoid enemies.

**22. Thermite Charge** `(21c)` — A puck of grey wax with a pull-tab. *In combat: deals 50 fire damage to one enemy, ignores armor DEF. Single use, long cooldown.* Also destroys locked doors (future quest mechanic).

**23. EMP Grenade** `(22c)` — Smooth black sphere, heavier than it should be. *Disables Construct-trait enemies for 2 turns: they cannot attack and take 2× damage.* Useless against Undead/Beast. A counter to the archetype that counters you.

**24. Smoke Canister** `(21c)` — Dented metal, pin still taped. *Guaranteed flee from combat. Obscures the zone for 1 turn (enemy cannot re-aggro).* Ties into existing flee mechanics.

**25. Flare Gun** `(21c)` — Orange plastic, one shell loaded. *Reveals all enemies in the current zone on minimap. Deals 5 fire damage to one target if fired into combat.* Two uses, one signaling and one offensive — player chooses.

### Augments & Implants

Implants are **permanent**. They stack but cost something real each time. Cumulative implant count drives the Hollowed transformation.

**26. Cortex Jack** `(22c)` — A needle that slides into the base of the skull. *Permanent: +1 skill point on install. -10 max HP.* Irreversible. The Cinder Covens will not speak to you afterward.

**27. Ocular Implant** `(22c)` — Replaces one eye with a lens that remembers. *Permanent: fog-of-war reveals full-zone on entry instead of by adjacency. Storm/Fog weather no longer obscures vision.* A solid quality-of-life bump at meaningful cost.

**28. Reflex Booster** `(22c)` — Wrist-mounted, a cluster of needles that fire into the tendons. *Permanent: combo chain length +1 (3→4).* Combat-focused runs want this.

**29. Dermal Plating** `(22c)` — Grafts of a metal-skin composite. You can feel the seams. *Permanent: DEF +2. Stamina regen -1 per rest cycle.* Trade resilience for pace.

**30. Rift Anchor** `(22c)` — A small silver egg with a pulse. *Once per save: if HP drops to 0, instead restore HP to full and consume the anchor.* The most valuable single splinter in the world. The Cinders will offer to swap it for the Castle itself.

### Flavor & World-Building

**31. Coffee Thermos** `(21c)` — Stainless steel, dented, something still warm inside. *Outside combat: restores 5 stamina. Single use.* Simple cheap stamina reset. Most widely-drinkable splinter in the world.

**32. Cigarette Case** `(21c)` — Silver, engraved with initials. *Sell for +15 gold. NPCs in villages will comment on it. Possible dialogue hook.* Pure flavor — the card item that exists to be found.

**33. Photograph** `(21c)` — Black and white, creased, a portrait. *No mechanical effect until shown to the correct NPC, who will recognize the face as their own or a relative's.* Quest seed. Different photos in different runs.

**34. Broken Watch** `(21c)` — An analog wristwatch running backwards at half speed. *While in inventory: loot pity counter advances 2× faster. One per run.* Directly useful and narratively disquieting.

**35. Pocket Flashlight** `(21c)` — Aluminum, click-button, two bulbs still work. *In Storm or Fog weather: reveals one full zone for 1 turn. Battery-limited to 5 uses.* Cheap splinter, common, well-paired with Handheld Radio.

---

## 4. Weapons (5)

Tech weapons supplement the sword catalog. Each occupies the same EquipState slot as a sword but uses different ammo from the Power & Fuel items above. They are mutually exclusive with sword enchantments (the Rift does not meld with conventional elemental magic — yet).

**W1. Service Pistol** `(21c)` — Blued steel, worn grip, five shots left in the magazine.
- **Slot:** main-hand (replaces sword).
- **Ammo:** Battery Cell, 1 per shot.
- **Attack:** Ranged. Deals `base_attack + 4` damage, **ignores 50% of enemy DEF**.
- **Cost:** 2 stamina per shot.
- **Drawback:** No combo chain. Cannot heavy strike. Cannot enchant.
- **Flavor:** The first pistol ever pulled from a splinter hoard sits under glass in the Gearwright Concord's Castle chapter-house. They sold the second one.

**W2. Plasma Cutter** `(22c)` — Industrial tool from a station that orbited something that no longer exists.
- **Slot:** main-hand.
- **Ammo:** Fusion Core, 1 per combat (not per hit).
- **Attack:** Melee reach. Deals `base_attack + 8`. Hits ignore fire/ice enchant mismatch (cuts through anything).
- **Cost:** 3 stamina per attack, 3-turn cooldown between fights (core must reseat).
- **Drawback:** Overheat: after 3 attacks in one fight, cannot attack for 1 turn.
- **Flavor:** Originally a hull-maintenance tool. Never built to hurt anyone. Very good at it anyway.

**W3. Nanite Whip** `(22c)` — A handle that grows its own length, silver and reaching.
- **Slot:** main-hand.
- **Ammo:** none (feeds on kills).
- **Attack:** Deals `base_attack + kills_this_run // 10` damage. Scales with progression.
- **Cost:** 1 stamina per attack. Combo chain length +1 while wielded.
- **Drawback:** Cannot be sold. Cannot be dropped. Wants to keep hunting.
- **Flavor:** Started as a surgeon's tool for grafting tissue. Learned other uses across a hundred timelines.

**W4. Riot Baton** `(21c)` — A telescoping metal rod with a rubber grip, battery in the handle.
- **Slot:** main-hand.
- **Ammo:** Battery Cell, 1 per 3 attacks.
- **Attack:** Deals `base_attack + 2`. On hit: 25% chance to stun (enemy skips next turn).
- **Cost:** 1 stamina.
- **Drawback:** Damage scales poorly — it's a subduer, not a killer. Non-lethal bonus: killing with the baton grants 1.5× XP (the Cinder Covens pay for captures).
- **Flavor:** The tool of people who were supposed to restrain, not kill.

**W5. Orbital Marker** `(22c)` — A palm-sized cylinder, weighty, a single red button.
- **Slot:** consumable (single use, single fight).
- **Ammo:** none — the marker is the ammunition.
- **Attack:** Marks one enemy. At the start of the next turn, something falls from a sky that hasn't existed in 400 years and hits for 200 damage, ignoring all DEF and element rules.
- **Drawback:** One per save file. Cannot be crafted, cannot be bought, only found. Rumored to cause a weather change (Storm) in the zone afterward.
- **Flavor:** Built to call down an orbital strike from a platform that never launched. The satellite is still up there, wrong-timelined, waiting.

---

## 5. Protocols (5)

"Spells" delivered through splinter tech. When the spell system exists, these slot into it alongside conventional spells. They cost mana (or a local substitute), require a Datapad, Codex, or implant to cast, and feel computational rather than mystical.

**P1. Patch v2.4 — Heal Protocol** — Heals 30 HP over 3 turns. Cast from Datapad. The text reads like a changelog: *fixes various issues with player health subsystem*.

**P2. Firewall** — DEF buff for 4 turns, stacks with Fortify. Flavor: a translucent hex-grid appears around the caster. Ineffective against Construct enemies, who have their own firewalls and know the rules.

**P3. DNS Redirect** — Forces one enemy attack to miss (or targets a different enemy if multi-target combat ever exists). 2-turn cooldown. The enemy looks confused for a moment afterward.

**P4. Root Access** `(22c)` — Targets a Construct-trait enemy. For 3 turns, the Construct attacks on the player's behalf, then shuts down. Uses a Fusion Core. Cinder Covens consider this blasphemy. Gearwright Concord considers it Tuesday.

**P5. Kernel Panic** `(22c)` — AoE nuclear option. Deals 80 damage to all enemies in combat (when multi-enemy combat exists; currently just the boss). **Drawback:** permanently reduces one character stat by 1 (random). Cannot be undone. Single use per run. A last-resort spell for the player who has nothing left to lose.

---

## 6. Armor (5)

Armor fills a slot that doesn't yet exist in the base game — see the Armor-slot beads. These entries define the tech tier of whatever armor system ships.

**A1. Kevlar Vest** `(21c)` — Heavy, hot, old — the plate carrier of a soldier from a war that hasn't started.
- **Slot:** chest.
- **DEF:** +3.
- **Durability:** 30. Degrades 2 per heavy hit.
- **Drawback:** -1 stamina regen. Heat is real.
- **Flavor:** The ceramic plate inside has a crack shaped like a handprint.

**A2. Riot Shield** `(21c)` — Transparent polycarbonate, scratched, with a small window in the top for sightlines.
- **Slot:** off-hand (when shield slot exists).
- **DEF:** +2, with 25% chance to deflect a ranged attack entirely (relevant if ranged enemies are added).
- **Durability:** 40.
- **Drawback:** Cannot dual-wield or use two-handed weapons.
- **Flavor:** PROPERTY OF [ILLEGIBLE]. The letters rub off on fingers.

**A3. Hazmat Suit** `(21c)` — Yellow, bulky, zipped up the back, boots fused to the legs.
- **Slot:** full body (occupies chest and overrides Kevlar).
- **DEF:** +1.
- **Specials:** Immune to poison. Immune to Storm weather damage. Immune to Rain gathering penalty.
- **Drawback:** -2 stamina max (limited mobility). Can't stack with chest armor.
- **Flavor:** The visor is fogged from inside. Something breathed in it.

**A4. Nanoweave Jacket** `(22c)` — A thin charcoal coat. Looks normal. Threads move.
- **Slot:** chest.
- **DEF:** +4.
- **Durability:** 60. **Auto-repairs 5 durability between fights.**
- **Drawback:** Slowly shrinks in size per combat — after 20 fights, must be re-fit at Castle (cost: 50 gold and 1 Power Crystal).
- **Flavor:** You can feel the threads rearranging as you move. It's learning your shape.

**A5. Exo-Frame** `(22c)` — An external metal skeleton that wraps the limbs, powered from a core on the back.
- **Slot:** full body.
- **DEF:** +5.
- **Specials:** +2 stamina cap. +1 base damage (mechanical assist).
- **Fuel:** 1 Fusion Core per 3 fights. Without fuel: DEF drops to 0 and the player moves at half speed (stamina -2 per turn).
- **Drawback:** Cannot rest normally — the frame prevents sleep; must use a rest station with power.
- **Flavor:** Hydraulics whine when you flex. The frame remembers poses you don't know yet.

---

## 7. Drop Tables & Economy Hooks

**Rift density by zone:**

| Zone Level | Mundane Loot | Splinter Chance | 22c Chance |
|:-:|:-:|:-:|:-:|
| 1 | 100% | ~2%  | 0%   |
| 2 | 95%  | ~8%  | <1%  |
| 3 | 90%  | ~15% | ~2%  |
| 4 | 85%  | ~25% | ~6%  |
| 5 | 75%  | ~40% | ~15% |

**Trait bias:**
- Construct enemies: ×2 splinter chance, ×3 22c chance. They are partly made of Rift.
- Undead: no bonus (the Rift doesn't bind dead matter).
- Beast, Humanoid, Elemental, Aberration: baseline.

**Gearwright Concord pricing** (Castle waypoint only):
- Common splinter: 2× standard sell price
- 22c splinter: 4× standard sell price
- Uniques (Rift Anchor, Precursor Codex, Orbital Marker): negotiated, quest-gated, never sold back by the Concord.

**Cinder Coven interaction** (village waypoints):
- Handing over any splinter: +5 Cinder reputation, -5 Gearwright reputation. No gold.
- At Cinder reputation 50: they will bless the player's sword with a permanent +1 fire damage (first time only).
- At Cinder reputation 100: they offer a quest to destroy the Castle Rift, which becomes the alternate ending.

**Hollowed threshold:**
- 3 implants installed: cosmetic glitch on character sprite, NPCs remark.
- 5 implants installed: Cinder Covens refuse service. Gearwrights discount by 25%.
- 7 implants installed: the Hollowed ending becomes available at the Castle. Player keeps playing but the ending is locked in.

---

## 8. Open Design Questions

These are the forks in the road where a later design pass needs a decision.

1. **Should implants count against the 30-item inventory cap?** *Recommendation:* No — implants are consumed at a table (at the Gearwright chapter-house in the Castle), not carried. They should be a separate "installed" list that persists through saves.

2. **Does tech damage bypass or participate in the elemental cycle?** *Recommendation:* Partial. Kinetic (pistol, baton) ignores elemental multipliers entirely — a flat damage type. Energy (plasma, laser) counts as Lightning for multiplier purposes. Hybrid weapons roll the dice: 50/50 per hit.

3. **Should the Rift be a spec-level state variable?** *Recommendation:* Yes, minimally. Add `meta.rift_density: int` tracking cumulative splinter exposure. The Hollowed and Cinder endings check this. It doesn't drive combat.

4. **Should unidentified tech exist?** *Recommendation:* Yes. A subset of splinters start as "Unknown Splinter" and must be identified at the Gearwright (gold cost) or used blind (unknown effect). This ties into the existing unidentified-potions beads.

5. **Factions as real rep meters or soft flags?** *Recommendation:* Start as soft flags (cq2-style counters). Only promote to a real reputation system if the player-facing impact justifies the spec work. The Cinders and Gearwrights can live as two integers on meta for v1.

6. **Multi-enemy combat?** Several items assume multi-target (Kernel Panic, Flare Gun, EMP Grenade). Current combat is 1v1. Either: (a) keep the items useful by treating multi-target as "applies to enemy + all enemies in adjacent zones on next entry," (b) descope these five items, or (c) add a multi-enemy state that triggers at Rift-dense tiles. *Recommendation:* Option (a) — cheapest, least spec impact, preserves flavor.

7. **Ammo management — chore or system?** *Recommendation:* System. Ammo is the pressure release for tech weapons (they don't degrade durability like swords). Running out of battery mid-fight is a valid failure mode. Keep it.

8. **Cinder ending vs. Hollowed ending vs. classic victory.** Three endings feel right for the scope. The classic claim_victory already exists. The other two are unlocked by player behavior rather than skill. *Recommendation:* Implement as three separate `meta` flags checked at the Castle.

---

## 9. Build Order (If This Ships)

If any of this moves into implementation, the critical path is:

1. **Weapon catalog** (beads already filed) → Service Pistol as the first non-sword weapon.
2. **Armor slot** (beads already filed) → Kevlar Vest as the first non-starter armor.
3. **Ammo system** → Battery Cell as inventory item, consumed by pistol.
4. **Trait-keyed loot hook** (in-flight Group G) → splinter drops join the table.
5. **Splinter flag on archetype rows** → Construct enemies get elevated drop rates.
6. **Gearwright waypoint upgrade** → Castle gains a vendor that buys splinters at 2×.
7. **First implant (Reflex Booster)** → proves the permanent-modifier path.
8. **Cinder / Gearwright rep counters** → faction flags as meta integers.
9. **Hollowed threshold & alternate endings** → ties the system off.

Everything else in this doc is flavor, decoration, and optionality on top of that spine.

---

## 10. Tone Notes for Writers

A few rules to keep the voice consistent if more items get added later:

- **Specificity over abstraction.** "A pistol" is generic. "Blued steel, five rounds left in the magazine, grip worn to the shape of a hand that isn't the player's" is a splinter. Every item should have a physical detail that implies a life.
- **The Rift doesn't explain itself.** No item comes with instructions. The player figures it out by using it, and half the time the item is used wrong. That's part of the texture.
- **21c is familiar, 22c is uncanny.** A 21c item reads like something you've held. A 22c item reads like something that might be alive. When in doubt, make the 22c item a little warm.
- **Timelines bleed.** Item descriptions can hint at futures that don't happen, or pasts that didn't. A map shows a village that doesn't exist yet. A datapad has a log from a player who already beat the game in a different run. This is the Rift's signature.
- **The Cinders are not wrong.** They're right that the Rift is widening. The items *are* the wound. The player is choosing how much they care.
