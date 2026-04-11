module crafting {
  var qty_wood: int
  var qty_iron: int
  var qty_gem: int
  var qty_sword: int
  var qty_staff: int
  var qty_ring: int

  // Mass: wood=1, iron=1, gem=1, sword=3, staff=3, ring=2
  val total_mass = qty_wood + qty_iron + qty_gem + 3 * qty_sword + 3 * qty_staff + 2 * qty_ring

  val materials_non_negative = and {
    qty_wood >= 0,
    qty_iron >= 0,
    qty_gem >= 0,
    qty_sword >= 0,
    qty_staff >= 0,
    qty_ring >= 0,
  }

  val total_mass_conserved = total_mass == 12

  action init = all {
    qty_wood' = 5,
    qty_iron' = 4,
    qty_gem' = 3,
    qty_sword' = 0,
    qty_staff' = 0,
    qty_ring' = 0,
  }

  // Craft a sword: 1 wood + 2 iron -> 1 sword
  action craft_sword = all {
    qty_wood >= 1,
    qty_iron >= 2,
    qty_wood' = qty_wood - 1,
    qty_iron' = qty_iron - 2,
    qty_gem' = qty_gem,
    qty_sword' = qty_sword + 1,
    qty_staff' = qty_staff,
    qty_ring' = qty_ring,
  }

  // Craft a staff: 2 wood + 1 gem -> 1 staff
  action craft_staff = all {
    qty_wood >= 2,
    qty_gem >= 1,
    qty_wood' = qty_wood - 2,
    qty_iron' = qty_iron,
    qty_gem' = qty_gem - 1,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff + 1,
    qty_ring' = qty_ring,
  }

  // Craft a ring: 1 iron + 1 gem -> 1 ring
  action craft_ring = all {
    qty_iron >= 1,
    qty_gem >= 1,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron - 1,
    qty_gem' = qty_gem - 1,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff,
    qty_ring' = qty_ring + 1,
  }

  // Blocked actions: not enough materials, no-op
  action craft_blocked_sword = all {
    qty_wood < 1 or qty_iron < 2,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron,
    qty_gem' = qty_gem,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff,
    qty_ring' = qty_ring,
  }

  action craft_blocked_staff = all {
    qty_wood < 2 or qty_gem < 1,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron,
    qty_gem' = qty_gem,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff,
    qty_ring' = qty_ring,
  }

  action craft_blocked_ring = all {
    qty_iron < 1 or qty_gem < 1,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron,
    qty_gem' = qty_gem,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff,
    qty_ring' = qty_ring,
  }

  action step = any {
    craft_sword,
    craft_staff,
    craft_ring,
    craft_blocked_sword,
    craft_blocked_staff,
    craft_blocked_ring,
  }
}

module crafting_run {
  import crafting.*
}
