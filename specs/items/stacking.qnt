module stacking {
  const MAX_TOTAL: int

  var qty_sword: int
  var qty_shield: int
  var qty_potion: int

  val total = qty_sword + qty_shield + qty_potion

  action init = all {
    qty_sword' = 2,
    qty_shield' = 1,
    qty_potion' = 3,
  }

  action add_sword = all {
    total < MAX_TOTAL,
    qty_sword' = qty_sword + 1,
    qty_shield' = qty_shield,
    qty_potion' = qty_potion,
  }

  action add_shield = all {
    total < MAX_TOTAL,
    qty_sword' = qty_sword,
    qty_shield' = qty_shield + 1,
    qty_potion' = qty_potion,
  }

  action add_potion = all {
    total < MAX_TOTAL,
    qty_sword' = qty_sword,
    qty_shield' = qty_shield,
    qty_potion' = qty_potion + 1,
  }

  action remove_sword = all {
    qty_sword > 0,
    qty_sword' = qty_sword - 1,
    qty_shield' = qty_shield,
    qty_potion' = qty_potion,
  }

  action remove_shield = all {
    qty_shield > 0,
    qty_sword' = qty_sword,
    qty_shield' = qty_shield - 1,
    qty_potion' = qty_potion,
  }

  action remove_potion = all {
    qty_potion > 0,
    qty_sword' = qty_sword,
    qty_shield' = qty_shield,
    qty_potion' = qty_potion - 1,
  }

  action step = any {
    add_sword,
    add_shield,
    add_potion,
    remove_sword,
    remove_shield,
    remove_potion,
  }

  /// All quantities are non-negative
  val non_negative = and {
    qty_sword >= 0,
    qty_shield >= 0,
    qty_potion >= 0,
  }

  /// Total items never exceed MAX_TOTAL
  val bounded = total <= MAX_TOTAL

  /// Combined invariant
  val quantities_non_negative = non_negative
}

module stacking_run {
  import stacking(MAX_TOTAL = 10).*
}
