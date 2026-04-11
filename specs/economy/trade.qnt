// Two-player inventory trade system
// Invariant: items are conserved — no duplication, no loss
module trade {
  const MAX_INV: int      // per-player inventory capacity

  // --- State ---
  var inv_a: List[str]    // player A's inventory
  var inv_b: List[str]    // player B's inventory
  var last_action: str    // for trace readability

  // --- Init ---
  action init = all {
    inv_a' = List("Sword", "Shield"),
    inv_b' = List("Potion"),
    last_action' = "init",
  }

  // --- Helpers ---
  // Remove first occurrence of item from a list
  pure def remove_first(lst: List[str], itm: str): List[str] = {
    val idx = lst.indices().filter(i => lst[i] == itm)
    if (idx.size() == 0) lst
    else {
      val first_idx = idx.fold(lst.length(), (acc, i) => if (i < acc) i else acc)
      range(0, lst.length()).foldl(List(), (acc, i) =>
        if (i == first_idx) acc else acc.append(lst[i])
      )
    }
  }

  pure def has_item(lst: List[str], itm: str): bool = {
    lst.indices().exists(i => lst[i] == itm)
  }

  // --- Actions ---

  // Player A gives item to Player B
  action give_a_to_b(itm: str): bool = all {
    inv_a.has_item(itm),
    length(inv_b) < MAX_INV,
    inv_a' = inv_a.remove_first(itm),
    inv_b' = inv_b.append(itm),
    last_action' = "give_a_to_b",
  }

  // Player B gives item to Player A
  action give_b_to_a(itm: str): bool = all {
    inv_b.has_item(itm),
    length(inv_a) < MAX_INV,
    inv_b' = inv_b.remove_first(itm),
    inv_a' = inv_a.append(itm),
    last_action' = "give_b_to_a",
  }

  // Trade blocked: A tries to give but B is full
  action trade_blocked_b_full(itm: str): bool = all {
    inv_a.has_item(itm),
    length(inv_b) >= MAX_INV,
    inv_a' = inv_a,
    inv_b' = inv_b,
    last_action' = "trade_blocked_b_full",
  }

  // Trade blocked: B tries to give but A is full
  action trade_blocked_a_full(itm: str): bool = all {
    inv_b.has_item(itm),
    length(inv_a) >= MAX_INV,
    inv_a' = inv_a,
    inv_b' = inv_b,
    last_action' = "trade_blocked_a_full",
  }

  // Nondeterministic step
  action step = {
    nondet itm = Set("Sword", "Shield", "Potion").oneOf()
    any {
      give_a_to_b(itm),
      give_b_to_a(itm),
      trade_blocked_b_full(itm),
      trade_blocked_a_full(itm),
    }
  }

  // --- Invariants ---

  // Neither inventory exceeds capacity
  val inv_bounded = length(inv_a) <= MAX_INV and length(inv_b) <= MAX_INV

  // Total item count is conserved (no duplication, no loss)
  val items_conserved = length(inv_a) + length(inv_b) == 3
}

// Runner module with concrete values
module trade_run {
  import trade(MAX_INV = 3).*
}
