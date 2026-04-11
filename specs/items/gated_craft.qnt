module gated_craft {
  var xp: int
  var level: int
  var hp: int
  var qty_wood: int
  var qty_iron: int
  var qty_gem: int
  var qty_sword: int
  var qty_staff: int
  var qty_ring: int

  // Track previous xp for monotonicity check
  var prev_xp: int

  action init = all {
    xp' = 0,
    level' = 1,
    hp' = 100,
    qty_wood' = 5,
    qty_iron' = 4,
    qty_gem' = 3,
    qty_sword' = 0,
    qty_staff' = 0,
    qty_ring' = 0,
    prev_xp' = 0,
  }

  // Fight an enemy: gain XP (20..50), take damage (5..15), possibly level up
  action fight_enemy = {
    nondet xp_gain = 20.to(50).oneOf()
    nondet dmg = 5.to(15).oneOf()
    val new_xp = xp + xp_gain
    val threshold = level * 100
    val new_level = if (new_xp >= threshold) level + 1 else level
    all {
      xp' = new_xp,
      level' = new_level,
      hp' = hp - dmg,
      prev_xp' = xp,
      qty_wood' = qty_wood,
      qty_iron' = qty_iron,
      qty_gem' = qty_gem,
      qty_sword' = qty_sword,
      qty_staff' = qty_staff,
      qty_ring' = qty_ring,
    }
  }

  // Craft a sword: requires level >= 1, costs 1 wood + 2 iron
  action craft_sword = all {
    level >= 1,
    qty_wood >= 1,
    qty_iron >= 2,
    qty_wood' = qty_wood - 1,
    qty_iron' = qty_iron - 2,
    qty_gem' = qty_gem,
    qty_sword' = qty_sword + 1,
    qty_staff' = qty_staff,
    qty_ring' = qty_ring,
    xp' = xp,
    level' = level,
    hp' = hp,
    prev_xp' = xp,
  }

  // Craft a staff: requires level >= 2, costs 2 wood + 1 gem
  action craft_staff = all {
    level >= 2,
    qty_wood >= 2,
    qty_gem >= 1,
    qty_wood' = qty_wood - 2,
    qty_iron' = qty_iron,
    qty_gem' = qty_gem - 1,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff + 1,
    qty_ring' = qty_ring,
    xp' = xp,
    level' = level,
    hp' = hp,
    prev_xp' = xp,
  }

  // Craft a ring: requires level >= 3, costs 1 iron + 1 gem
  action craft_ring = all {
    level >= 3,
    qty_iron >= 1,
    qty_gem >= 1,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron - 1,
    qty_gem' = qty_gem - 1,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff,
    qty_ring' = qty_ring + 1,
    xp' = xp,
    level' = level,
    hp' = hp,
    prev_xp' = xp,
  }

  // Blocked: try to craft a recipe above current level — no-op
  action blocked_craft_level = all {
    (level < 2 and qty_wood >= 2 and qty_gem >= 1) or
    (level < 3 and qty_iron >= 1 and qty_gem >= 1),
    xp' = xp,
    level' = level,
    hp' = hp,
    prev_xp' = xp,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron,
    qty_gem' = qty_gem,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff,
    qty_ring' = qty_ring,
  }

  // Blocked: insufficient materials — no-op
  action blocked_craft_materials = all {
    (qty_wood < 1 or qty_iron < 2) or
    (qty_wood < 2 or qty_gem < 1) or
    (qty_iron < 1 or qty_gem < 1),
    xp' = xp,
    level' = level,
    hp' = hp,
    prev_xp' = xp,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron,
    qty_gem' = qty_gem,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff,
    qty_ring' = qty_ring,
  }

  action step = any {
    fight_enemy,
    craft_sword,
    craft_staff,
    craft_ring,
    blocked_craft_level,
    blocked_craft_materials,
  }

  /// Staff and ring are gated behind level requirements
  val level_gates_recipes: bool = and {
    qty_staff > 0 implies level >= 2,
    qty_ring > 0 implies level >= 3,
  }

  /// XP never decreases
  val xp_monotonic: bool = xp >= prev_xp

  /// Level is always at least 1
  val level_positive: bool = level >= 1

  /// All material and product quantities are non-negative
  val materials_non_negative: bool = and {
    qty_wood >= 0,
    qty_iron >= 0,
    qty_gem >= 0,
    qty_sword >= 0,
    qty_staff >= 0,
    qty_ring >= 0,
  }
}

module gated_craft_run {
  import gated_craft.*
}
