module enchantment {
  const ENCHANT_COST: int

  // Enchantment slots: 0=empty, 1=fire, 2=ice, 3=vampiric, 4=lightning
  var enchant_slot_1: int
  var enchant_slot_2: int
  var enchant_slot_3: int

  var total_atk_bonus: int
  var total_def_bonus: int

  var gold: int

  // Helper: compute attack bonus for a single slot
  pure def atk_for(slot: int): int = {
    if (slot == 1) 3       // Fire: +3 atk
    else if (slot == 4) 1  // Lightning: +1 atk
    else 0
  }

  // Helper: compute defense bonus for a single slot
  pure def def_for(slot: int): int = {
    if (slot == 2) 2       // Ice: +2 def
    else if (slot == 4) 1  // Lightning: +1 def
    else 0
  }

  // Helper: check if fire is present
  val has_fire = (enchant_slot_1 == 1 or enchant_slot_2 == 1 or enchant_slot_3 == 1)

  // Helper: check if ice is present
  val has_ice = (enchant_slot_1 == 2 or enchant_slot_2 == 2 or enchant_slot_3 == 2)

  action init = all {
    enchant_slot_1' = 0,
    enchant_slot_2' = 0,
    enchant_slot_3' = 0,
    total_atk_bonus' = 0,
    total_def_bonus' = 0,
    gold' = 100,
  }

  action apply_enchant_1(etype: int): bool = all {
    etype >= 1,
    etype <= 4,
    gold >= ENCHANT_COST,
    // Fire/Ice incompatibility check
    not(etype == 1 and has_ice),
    not(etype == 2 and has_fire),
    enchant_slot_1' = etype,
    enchant_slot_2' = enchant_slot_2,
    enchant_slot_3' = enchant_slot_3,
    gold' = gold - ENCHANT_COST,
    total_atk_bonus' = atk_for(etype) + atk_for(enchant_slot_2) + atk_for(enchant_slot_3),
    total_def_bonus' = def_for(etype) + def_for(enchant_slot_2) + def_for(enchant_slot_3),
  }

  action apply_enchant_2(etype: int): bool = all {
    etype >= 1,
    etype <= 4,
    gold >= ENCHANT_COST,
    not(etype == 1 and has_ice),
    not(etype == 2 and has_fire),
    enchant_slot_1' = enchant_slot_1,
    enchant_slot_2' = etype,
    enchant_slot_3' = enchant_slot_3,
    gold' = gold - ENCHANT_COST,
    total_atk_bonus' = atk_for(enchant_slot_1) + atk_for(etype) + atk_for(enchant_slot_3),
    total_def_bonus' = def_for(enchant_slot_1) + def_for(etype) + def_for(enchant_slot_3),
  }

  action apply_enchant_3(etype: int): bool = all {
    etype >= 1,
    etype <= 4,
    gold >= ENCHANT_COST,
    not(etype == 1 and has_ice),
    not(etype == 2 and has_fire),
    enchant_slot_1' = enchant_slot_1,
    enchant_slot_2' = enchant_slot_2,
    enchant_slot_3' = etype,
    gold' = gold - ENCHANT_COST,
    total_atk_bonus' = atk_for(enchant_slot_1) + atk_for(enchant_slot_2) + atk_for(etype),
    total_def_bonus' = def_for(enchant_slot_1) + def_for(enchant_slot_2) + def_for(etype),
  }

  action remove_enchant_1 = all {
    enchant_slot_1 != 0,
    enchant_slot_1' = 0,
    enchant_slot_2' = enchant_slot_2,
    enchant_slot_3' = enchant_slot_3,
    gold' = gold,
    total_atk_bonus' = atk_for(0) + atk_for(enchant_slot_2) + atk_for(enchant_slot_3),
    total_def_bonus' = def_for(0) + def_for(enchant_slot_2) + def_for(enchant_slot_3),
  }

  action remove_enchant_2 = all {
    enchant_slot_2 != 0,
    enchant_slot_1' = enchant_slot_1,
    enchant_slot_2' = 0,
    enchant_slot_3' = enchant_slot_3,
    gold' = gold,
    total_atk_bonus' = atk_for(enchant_slot_1) + atk_for(0) + atk_for(enchant_slot_3),
    total_def_bonus' = def_for(enchant_slot_1) + def_for(0) + def_for(enchant_slot_3),
  }

  action remove_enchant_3 = all {
    enchant_slot_3 != 0,
    enchant_slot_1' = enchant_slot_1,
    enchant_slot_2' = enchant_slot_2,
    enchant_slot_3' = 0,
    gold' = gold,
    total_atk_bonus' = atk_for(enchant_slot_1) + atk_for(enchant_slot_2) + atk_for(0),
    total_def_bonus' = def_for(enchant_slot_1) + def_for(enchant_slot_2) + def_for(0),
  }

  action compute_stats = all {
    enchant_slot_1' = enchant_slot_1,
    enchant_slot_2' = enchant_slot_2,
    enchant_slot_3' = enchant_slot_3,
    gold' = gold,
    total_atk_bonus' = atk_for(enchant_slot_1) + atk_for(enchant_slot_2) + atk_for(enchant_slot_3),
    total_def_bonus' = def_for(enchant_slot_1) + def_for(enchant_slot_2) + def_for(enchant_slot_3),
  }

  action step = {
    nondet etype = Set(1, 2, 3, 4).oneOf()
    any {
      apply_enchant_1(etype),
      apply_enchant_2(etype),
      apply_enchant_3(etype),
      remove_enchant_1,
      remove_enchant_2,
      remove_enchant_3,
      compute_stats,
    }
  }

  // Invariants

  val enchant_count_bounded = and {
    0 <= enchant_slot_1 and enchant_slot_1 <= 4,
    0 <= enchant_slot_2 and enchant_slot_2 <= 4,
    0 <= enchant_slot_3 and enchant_slot_3 <= 4,
  }

  val no_incompatible = not(has_fire and has_ice)

  val stats_deterministic = and {
    total_atk_bonus == atk_for(enchant_slot_1) + atk_for(enchant_slot_2) + atk_for(enchant_slot_3),
    total_def_bonus == def_for(enchant_slot_1) + def_for(enchant_slot_2) + def_for(enchant_slot_3),
  }
}

module enchantment_run {
  import enchantment(ENCHANT_COST = 10).*
}
