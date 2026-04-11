// Loot drop system with pity/guarantee mechanics
// Demonstrates: constants, guards, pity counter, guaranteed rare drops
module loot {
  const PITY_THRESHOLD: int

  var pity_counter: int
  var total_drops: int
  var rare_drops: int
  var common_drops: int
  var last_rarity: str
  var guaranteed_next: bool

  action init = all {
    pity_counter' = 0,
    total_drops' = 0,
    rare_drops' = 0,
    common_drops' = 0,
    last_rarity' = "none",
    guaranteed_next' = false,
  }

  // Drop a common item -- only allowed when not in guaranteed-rare state
  action drop_common = all {
    not(guaranteed_next),
    pity_counter' = pity_counter + 1,
    total_drops' = total_drops + 1,
    common_drops' = common_drops + 1,
    rare_drops' = rare_drops,
    last_rarity' = "common",
    guaranteed_next' = if (pity_counter + 1 >= PITY_THRESHOLD) true else false,
  }

  // Drop a rare item (lucky roll, not forced by pity)
  action drop_rare = all {
    not(guaranteed_next),
    pity_counter' = 0,
    total_drops' = total_drops + 1,
    rare_drops' = rare_drops + 1,
    common_drops' = common_drops,
    last_rarity' = "rare",
    guaranteed_next' = false,
  }

  // Drop a guaranteed rare item when pity threshold is reached
  action drop_guaranteed_rare = all {
    guaranteed_next,
    pity_counter' = 0,
    total_drops' = total_drops + 1,
    rare_drops' = rare_drops + 1,
    common_drops' = common_drops,
    last_rarity' = "rare",
    guaranteed_next' = false,
  }

  action step = any {
    drop_common,
    drop_rare,
    drop_guaranteed_rare,
  }

  // --- Invariants ---

  // Pity counter never exceeds the threshold
  val pity_bounded = pity_counter <= PITY_THRESHOLD

  // Total drops always equals rare + common
  val counts_consistent = total_drops == rare_drops + common_drops

  // If guaranteed_next is set, pity counter must be at threshold
  val pity_guarantee = if (guaranteed_next) pity_counter >= PITY_THRESHOLD else true

  // Rare drought is capped -- pity counter never goes past threshold
  val no_long_drought = pity_counter <= PITY_THRESHOLD

  // Pity counter is always non-negative
  val counter_non_negative = pity_counter >= 0
}

module loot_run {
  import loot(PITY_THRESHOLD = 5).*
}
