module durability {
  const REPAIR_COST: int

  var dur_sword: int
  var dur_shield: int
  var dur_bow: int

  var max_sword: int
  var max_shield: int
  var max_bow: int

  var broken_sword: bool
  var broken_shield: bool
  var broken_bow: bool

  var gold: int

  action init = all {
    dur_sword' = 10,
    dur_shield' = 8,
    dur_bow' = 6,
    max_sword' = 10,
    max_shield' = 8,
    max_bow' = 6,
    broken_sword' = false,
    broken_shield' = false,
    broken_bow' = false,
    gold' = 100,
  }

  action use_sword = all {
    not(broken_sword),
    dur_sword' = dur_sword - 1,
    broken_sword' = (dur_sword - 1 == 0),
    dur_shield' = dur_shield,
    dur_bow' = dur_bow,
    max_sword' = max_sword,
    max_shield' = max_shield,
    max_bow' = max_bow,
    broken_shield' = broken_shield,
    broken_bow' = broken_bow,
    gold' = gold,
  }

  action use_shield = all {
    not(broken_shield),
    dur_shield' = dur_shield - 1,
    broken_shield' = (dur_shield - 1 == 0),
    dur_sword' = dur_sword,
    dur_bow' = dur_bow,
    max_sword' = max_sword,
    max_shield' = max_shield,
    max_bow' = max_bow,
    broken_sword' = broken_sword,
    broken_bow' = broken_bow,
    gold' = gold,
  }

  action use_bow = all {
    not(broken_bow),
    dur_bow' = dur_bow - 1,
    broken_bow' = (dur_bow - 1 == 0),
    dur_sword' = dur_sword,
    dur_shield' = dur_shield,
    max_sword' = max_sword,
    max_shield' = max_shield,
    max_bow' = max_bow,
    broken_sword' = broken_sword,
    broken_shield' = broken_shield,
    gold' = gold,
  }

  action repair_sword = all {
    broken_sword,
    gold >= REPAIR_COST,
    dur_sword' = max_sword,
    broken_sword' = false,
    gold' = gold - REPAIR_COST,
    dur_shield' = dur_shield,
    dur_bow' = dur_bow,
    max_sword' = max_sword,
    max_shield' = max_shield,
    max_bow' = max_bow,
    broken_shield' = broken_shield,
    broken_bow' = broken_bow,
  }

  action repair_shield = all {
    broken_shield,
    gold >= REPAIR_COST,
    dur_shield' = max_shield,
    broken_shield' = false,
    gold' = gold - REPAIR_COST,
    dur_sword' = dur_sword,
    dur_bow' = dur_bow,
    max_sword' = max_sword,
    max_shield' = max_shield,
    max_bow' = max_bow,
    broken_sword' = broken_sword,
    broken_bow' = broken_bow,
  }

  action repair_bow = all {
    broken_bow,
    gold >= REPAIR_COST,
    dur_bow' = max_bow,
    broken_bow' = false,
    gold' = gold - REPAIR_COST,
    dur_sword' = dur_sword,
    dur_shield' = dur_shield,
    max_sword' = max_sword,
    max_shield' = max_shield,
    max_bow' = max_bow,
    broken_sword' = broken_sword,
    broken_shield' = broken_shield,
  }

  action blocked_use_broken = all {
    broken_sword or broken_shield or broken_bow,
    dur_sword' = dur_sword,
    dur_shield' = dur_shield,
    dur_bow' = dur_bow,
    max_sword' = max_sword,
    max_shield' = max_shield,
    max_bow' = max_bow,
    broken_sword' = broken_sword,
    broken_shield' = broken_shield,
    broken_bow' = broken_bow,
    gold' = gold,
  }

  action blocked_repair_no_gold = all {
    (broken_sword or broken_shield or broken_bow),
    gold < REPAIR_COST,
    dur_sword' = dur_sword,
    dur_shield' = dur_shield,
    dur_bow' = dur_bow,
    max_sword' = max_sword,
    max_shield' = max_shield,
    max_bow' = max_bow,
    broken_sword' = broken_sword,
    broken_shield' = broken_shield,
    broken_bow' = broken_bow,
    gold' = gold,
  }

  action step = any {
    use_sword,
    use_shield,
    use_bow,
    repair_sword,
    repair_shield,
    repair_bow,
    blocked_use_broken,
    blocked_repair_no_gold,
  }

  // Invariants

  val durability_bounded = and {
    0 <= dur_sword and dur_sword <= max_sword,
    0 <= dur_shield and dur_shield <= max_shield,
    0 <= dur_bow and dur_bow <= max_bow,
  }

  val broken_consistent = and {
    broken_sword == (dur_sword == 0),
    broken_shield == (dur_shield == 0),
    broken_bow == (dur_bow == 0),
  }

  val gold_non_negative = gold >= 0

  val max_constant = and {
    max_sword == 10,
    max_shield == 8,
    max_bow == 6,
  }
}

module durability_run {
  import durability(REPAIR_COST = 15).*
}
