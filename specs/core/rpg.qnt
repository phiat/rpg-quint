// Quint specification for the RPG Character system
// Models the same domain as weba-fool/src/rpg.odin
//
// This spec captures the RULES of the system, not the implementation.
// The Odin code is one possible implementation; this spec defines
// what ANY correct implementation must satisfy.
module rpg {
  const MAX_INV: int       // inventory capacity (e.g. 3)
  const INIT_HP: int       // starting HP (e.g. 100)
  const INIT_ATK: int      // starting attack (e.g. 25)

  // --- State ---
  var hp: int
  var attack: int
  var inventory: List[str]

  // --- Init ---
  action init = all {
    hp' = INIT_HP,
    attack' = INIT_ATK,
    inventory' = List(),
  }

  // --- Actions (state transitions) ---

  // Take damage: HP decreases by dmg
  action take_damage(dmg: int): bool = all {
    dmg > 0,
    hp' = hp - dmg,
    attack' = attack,
    inventory' = inventory,
  }

  // Add an itm: succeeds only if inventory isn't full
  action add_itm(itm: str): bool = all {
    length(inventory) < MAX_INV,
    inventory' = inventory.append(itm),
    hp' = hp,
    attack' = attack,
  }

  // Attempt to add when full (models the "return false" path)
  action add_itm_full(itm: str): bool = all {
    length(inventory) >= MAX_INV,
    // State unchanged -- the operation was rejected
    hp' = hp,
    attack' = attack,
    inventory' = inventory,
  }

  // Nondeterministic step: the system can do any of these
  action step = {
    nondet dmg = 1.to(50).oneOf()
    nondet itm = Set("Sword", "Shield", "Axe", "Bow", "Potion").oneOf()
    any {
      take_damage(dmg),
      add_itm(itm),
      add_itm_full(itm),
    }
  }

  // --- Invariants (properties ANY correct implementation must hold) ---

  // Inventory never exceeds capacity
  val inv_bounded = length(inventory) <= MAX_INV

  // HP only changes via take_damage (attack and inv don't affect HP)
  // (This is structural -- enforced by action definitions)

  // A character with positive HP is alive
  val is_alive = hp > 0

  // Items are never lost (inventory only grows or stays same -- no remove action yet)
  // This is interesting: it's true given our current actions, but would
  // break if we added a "drop_itm" action. The spec documents this assumption.

  // HP can go negative (the Odin code allows it!) -- is that a bug or a feature?
  // Let's write an invariant that WILL BE VIOLATED to surface this:
  val hp_non_negative = hp >= 0
}

// Runner module: instantiate rpg with concrete values matching the Odin code
module rpg_run {
  import rpg(MAX_INV = 3, INIT_HP = 100, INIT_ATK = 25).*
}
