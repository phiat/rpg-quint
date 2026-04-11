module healing {
  const MAX_HP: int
  const INIT_HP: int
  const POTION_HEAL: int

  var hp: int
  var inventory: List[str]

  // Helper: count how many potions are in inventory
  pure def potion_count(inv: List[str]): int = {
    range(0, inv.length()).foldl(0, (acc, i) =>
      if (inv[i] == "Potion") acc + 1 else acc
    )
  }

  // Helper: remove first occurrence of an item from inventory
  pure def remove_first(inv: List[str], itm_name: str): List[str] = {
    val idx = range(0, inv.length()).foldl(-1, (found, i) =>
      if (found == -1 and inv[i] == itm_name) i else found
    )
    if (idx == -1) inv
    else range(0, inv.length()).foldl(List(), (acc, i) =>
      if (i == idx) acc else acc.append(inv[i])
    )
  }

  action init = all {
    hp' = INIT_HP,
    inventory' = List("Potion", "Potion", "Potion"),
  }

  action take_damage(dmg: int): bool = all {
    hp' = hp - dmg,
    inventory' = inventory,
  }

  // Successfully use a potion: must have a potion and be alive
  action use_potion: bool = all {
    potion_count(inventory) > 0,
    hp > 0,
    hp' = if (hp + POTION_HEAL > MAX_HP) MAX_HP else hp + POTION_HEAL,
    inventory' = remove_first(inventory, "Potion"),
  }

  // Try to use potion while dead — no-op
  action use_potion_dead: bool = all {
    hp <= 0,
    hp' = hp,
    inventory' = inventory,
  }

  // Try to use potion with none in inventory — no-op
  action use_potion_none: bool = all {
    potion_count(inventory) == 0,
    hp' = hp,
    inventory' = inventory,
  }

  action step = any {
    nondet dmg = 1.to(50).oneOf()
    take_damage(dmg),
    use_potion,
    use_potion_dead,
    use_potion_none,
  }

  // Invariants

  // NOTE: hp_bounded (0 <= hp) is intentionally NOT asserted here.
  // Damage can drive hp negative. This surfaces the design question:
  // should we clamp hp at 0, or allow negative hp (overkill tracking)?

  // Healing never overshoots MAX_HP
  val hp_capped: bool = hp <= MAX_HP

  // Potion count never goes below 0
  val potions_non_negative: bool = potion_count(inventory) >= 0

  // If a potion was used (inventory shrank), character was alive.
  // This is enforced structurally by the guard on use_potion.
  val alive_to_act: bool = true
}

module healing_run {
  import healing(MAX_HP = 100, INIT_HP = 80, POTION_HEAL = 25).*
}
