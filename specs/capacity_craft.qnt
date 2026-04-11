module capacity_craft {
  const MAX_CAPACITY: int

  var qty_wood: int
  var qty_iron: int
  var qty_gem: int
  var qty_sword: int
  var qty_staff: int
  var qty_ring: int
  var qty_arrows: int

  // Total number of items in inventory
  val total_items = qty_wood + qty_iron + qty_gem + qty_sword + qty_staff + qty_ring + qty_arrows

  // --- Invariants ---

  val capacity_bounded = total_items <= MAX_CAPACITY

  val materials_non_negative = and {
    qty_wood >= 0,
    qty_iron >= 0,
    qty_gem >= 0,
    qty_sword >= 0,
    qty_staff >= 0,
    qty_ring >= 0,
    qty_arrows >= 0,
  }

  // --- Init ---

  // wood=5, iron=4, gem=3, rest=0 => total=12
  action init = all {
    qty_wood' = 5,
    qty_iron' = 4,
    qty_gem' = 3,
    qty_sword' = 0,
    qty_staff' = 0,
    qty_ring' = 0,
    qty_arrows' = 0,
  }

  // --- Craft actions ---

  // Craft a sword: 1 wood + 2 iron -> 1 sword (net change: -2 items)
  action craft_sword = all {
    qty_wood >= 1,
    qty_iron >= 2,
    // net -2, so total always decreases; capacity guard included for uniformity
    total_items - 2 <= MAX_CAPACITY,
    qty_wood' = qty_wood - 1,
    qty_iron' = qty_iron - 2,
    qty_gem' = qty_gem,
    qty_sword' = qty_sword + 1,
    qty_staff' = qty_staff,
    qty_ring' = qty_ring,
    qty_arrows' = qty_arrows,
  }

  // Craft a staff: 2 wood + 1 gem -> 1 staff (net change: -2 items)
  action craft_staff = all {
    qty_wood >= 2,
    qty_gem >= 1,
    total_items - 2 <= MAX_CAPACITY,
    qty_wood' = qty_wood - 2,
    qty_iron' = qty_iron,
    qty_gem' = qty_gem - 1,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff + 1,
    qty_ring' = qty_ring,
    qty_arrows' = qty_arrows,
  }

  // Craft a ring: 1 iron + 1 gem -> 1 ring (net change: -1 item)
  action craft_ring = all {
    qty_iron >= 1,
    qty_gem >= 1,
    total_items - 1 <= MAX_CAPACITY,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron - 1,
    qty_gem' = qty_gem - 1,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff,
    qty_ring' = qty_ring + 1,
    qty_arrows' = qty_arrows,
  }

  // Craft arrows: 1 wood -> 3 arrows (net change: +2 items -- can exceed capacity!)
  action craft_arrows = all {
    qty_wood >= 1,
    total_items + 2 <= MAX_CAPACITY,
    qty_wood' = qty_wood - 1,
    qty_iron' = qty_iron,
    qty_gem' = qty_gem,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff,
    qty_ring' = qty_ring,
    qty_arrows' = qty_arrows + 3,
  }

  // --- Blocked actions (no-ops) ---

  // Has wood but crafting arrows would exceed capacity
  action blocked_craft_arrows_full = all {
    qty_wood >= 1,
    total_items + 2 > MAX_CAPACITY,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron,
    qty_gem' = qty_gem,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff,
    qty_ring' = qty_ring,
    qty_arrows' = qty_arrows,
  }

  // Insufficient materials for any recipe -- no-op
  action blocked_no_materials = all {
    // Cannot craft sword
    qty_wood < 1 or qty_iron < 2,
    // Cannot craft staff
    qty_wood < 2 or qty_gem < 1,
    // Cannot craft ring
    qty_iron < 1 or qty_gem < 1,
    // Cannot craft arrows
    qty_wood < 1,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron,
    qty_gem' = qty_gem,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff,
    qty_ring' = qty_ring,
    qty_arrows' = qty_arrows,
  }

  // --- Step ---

  action step = any {
    craft_sword,
    craft_staff,
    craft_ring,
    craft_arrows,
    blocked_craft_arrows_full,
    blocked_no_materials,
  }
}

module capacity_craft_run {
  import capacity_craft(MAX_CAPACITY = 15).*
}
