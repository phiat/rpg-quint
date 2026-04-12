// Quint specification for a Bounty Board system.
// Models a board with 3 bounty slots. Players accept one bounty at a time,
// record kills toward the target, then claim the reward or abandon the bounty.
// The board can be refreshed to post new bounties on all slots.
module bounty {
  // --- State ---
  // Slot 1
  var slot1_active:        bool
  var slot1_kills_needed:  int
  var slot1_current_kills: int
  var slot1_reward_gold:   int
  // Slot 2
  var slot2_active:        bool
  var slot2_kills_needed:  int
  var slot2_current_kills: int
  var slot2_reward_gold:   int
  // Slot 3
  var slot3_active:        bool
  var slot3_kills_needed:  int
  var slot3_current_kills: int
  var slot3_reward_gold:   int
  // Player
  var player_gold:             int
  var active_bounty_idx:       int  // 0 = none, 1-3 = slot index

  // --- Init ---
  action init = all {
    slot1_active'        = true,
    slot1_kills_needed'  = 3,
    slot1_current_kills' = 0,
    slot1_reward_gold'   = 50,
    slot2_active'        = true,
    slot2_kills_needed'  = 5,
    slot2_current_kills' = 0,
    slot2_reward_gold'   = 80,
    slot3_active'        = true,
    slot3_kills_needed'  = 2,
    slot3_current_kills' = 0,
    slot3_reward_gold'   = 30,
    player_gold'         = 0,
    active_bounty_idx'   = 0,
  }

  // --- Actions ---

  // Accept bounty slot 1: requires slot active, player has no active bounty
  action accept_bounty_1 = all {
    slot1_active,
    active_bounty_idx == 0,
    active_bounty_idx'   = 1,
    player_gold'         = player_gold,
    slot1_active'        = slot1_active,
    slot1_kills_needed'  = slot1_kills_needed,
    slot1_current_kills' = slot1_current_kills,
    slot1_reward_gold'   = slot1_reward_gold,
    slot2_active'        = slot2_active,
    slot2_kills_needed'  = slot2_kills_needed,
    slot2_current_kills' = slot2_current_kills,
    slot2_reward_gold'   = slot2_reward_gold,
    slot3_active'        = slot3_active,
    slot3_kills_needed'  = slot3_kills_needed,
    slot3_current_kills' = slot3_current_kills,
    slot3_reward_gold'   = slot3_reward_gold,
  }

  // Accept bounty slot 2
  action accept_bounty_2 = all {
    slot2_active,
    active_bounty_idx == 0,
    active_bounty_idx'   = 2,
    player_gold'         = player_gold,
    slot1_active'        = slot1_active,
    slot1_kills_needed'  = slot1_kills_needed,
    slot1_current_kills' = slot1_current_kills,
    slot1_reward_gold'   = slot1_reward_gold,
    slot2_active'        = slot2_active,
    slot2_kills_needed'  = slot2_kills_needed,
    slot2_current_kills' = slot2_current_kills,
    slot2_reward_gold'   = slot2_reward_gold,
    slot3_active'        = slot3_active,
    slot3_kills_needed'  = slot3_kills_needed,
    slot3_current_kills' = slot3_current_kills,
    slot3_reward_gold'   = slot3_reward_gold,
  }

  // Accept bounty slot 3
  action accept_bounty_3 = all {
    slot3_active,
    active_bounty_idx == 0,
    active_bounty_idx'   = 3,
    player_gold'         = player_gold,
    slot1_active'        = slot1_active,
    slot1_kills_needed'  = slot1_kills_needed,
    slot1_current_kills' = slot1_current_kills,
    slot1_reward_gold'   = slot1_reward_gold,
    slot2_active'        = slot2_active,
    slot2_kills_needed'  = slot2_kills_needed,
    slot2_current_kills' = slot2_current_kills,
    slot2_reward_gold'   = slot2_reward_gold,
    slot3_active'        = slot3_active,
    slot3_kills_needed'  = slot3_kills_needed,
    slot3_current_kills' = slot3_current_kills,
    slot3_reward_gold'   = slot3_reward_gold,
  }

  // Record a kill: increments current kills on the active bounty slot.
  // Flat `all` (not nested `any`) so Quint MBT captures the action name.
  action record_kill = all {
    or {
      active_bounty_idx == 1 and slot1_current_kills < slot1_kills_needed,
      active_bounty_idx == 2 and slot2_current_kills < slot2_kills_needed,
      active_bounty_idx == 3 and slot3_current_kills < slot3_kills_needed,
    },
    slot1_current_kills' = if (active_bounty_idx == 1) slot1_current_kills + 1 else slot1_current_kills,
    slot2_current_kills' = if (active_bounty_idx == 2) slot2_current_kills + 1 else slot2_current_kills,
    slot3_current_kills' = if (active_bounty_idx == 3) slot3_current_kills + 1 else slot3_current_kills,
    active_bounty_idx'   = active_bounty_idx,
    player_gold'         = player_gold,
    slot1_active'        = slot1_active,
    slot1_kills_needed'  = slot1_kills_needed,
    slot1_reward_gold'   = slot1_reward_gold,
    slot2_active'        = slot2_active,
    slot2_kills_needed'  = slot2_kills_needed,
    slot2_reward_gold'   = slot2_reward_gold,
    slot3_active'        = slot3_active,
    slot3_kills_needed'  = slot3_kills_needed,
    slot3_reward_gold'   = slot3_reward_gold,
  }

  // Claim bounty: kills >= needed; collect reward, deactivate slot, clear active bounty
  action claim_bounty = any {
    // claim slot 1
    all {
      active_bounty_idx == 1,
      slot1_current_kills >= slot1_kills_needed,
      player_gold'         = player_gold + slot1_reward_gold,
      slot1_active'        = false,
      active_bounty_idx'   = 0,
      slot1_kills_needed'  = slot1_kills_needed,
      slot1_current_kills' = slot1_current_kills,
      slot1_reward_gold'   = slot1_reward_gold,
      slot2_active'        = slot2_active,
      slot2_kills_needed'  = slot2_kills_needed,
      slot2_current_kills' = slot2_current_kills,
      slot2_reward_gold'   = slot2_reward_gold,
      slot3_active'        = slot3_active,
      slot3_kills_needed'  = slot3_kills_needed,
      slot3_current_kills' = slot3_current_kills,
      slot3_reward_gold'   = slot3_reward_gold,
    },
    // claim slot 2
    all {
      active_bounty_idx == 2,
      slot2_current_kills >= slot2_kills_needed,
      player_gold'         = player_gold + slot2_reward_gold,
      slot2_active'        = false,
      active_bounty_idx'   = 0,
      slot1_active'        = slot1_active,
      slot1_kills_needed'  = slot1_kills_needed,
      slot1_current_kills' = slot1_current_kills,
      slot1_reward_gold'   = slot1_reward_gold,
      slot2_kills_needed'  = slot2_kills_needed,
      slot2_current_kills' = slot2_current_kills,
      slot2_reward_gold'   = slot2_reward_gold,
      slot3_active'        = slot3_active,
      slot3_kills_needed'  = slot3_kills_needed,
      slot3_current_kills' = slot3_current_kills,
      slot3_reward_gold'   = slot3_reward_gold,
    },
    // claim slot 3
    all {
      active_bounty_idx == 3,
      slot3_current_kills >= slot3_kills_needed,
      player_gold'         = player_gold + slot3_reward_gold,
      slot3_active'        = false,
      active_bounty_idx'   = 0,
      slot1_active'        = slot1_active,
      slot1_kills_needed'  = slot1_kills_needed,
      slot1_current_kills' = slot1_current_kills,
      slot1_reward_gold'   = slot1_reward_gold,
      slot2_active'        = slot2_active,
      slot2_kills_needed'  = slot2_kills_needed,
      slot2_current_kills' = slot2_current_kills,
      slot2_reward_gold'   = slot2_reward_gold,
      slot3_kills_needed'  = slot3_kills_needed,
      slot3_current_kills' = slot3_current_kills,
      slot3_reward_gold'   = slot3_reward_gold,
    },
  }

  // Abandon bounty: give up the active bounty (no reward, slot stays active)
  action abandon_bounty = all {
    active_bounty_idx != 0,
    active_bounty_idx'   = 0,
    player_gold'         = player_gold,
    slot1_active'        = slot1_active,
    slot1_kills_needed'  = slot1_kills_needed,
    slot1_current_kills' = slot1_current_kills,
    slot1_reward_gold'   = slot1_reward_gold,
    slot2_active'        = slot2_active,
    slot2_kills_needed'  = slot2_kills_needed,
    slot2_current_kills' = slot2_current_kills,
    slot2_reward_gold'   = slot2_reward_gold,
    slot3_active'        = slot3_active,
    slot3_kills_needed'  = slot3_kills_needed,
    slot3_current_kills' = slot3_current_kills,
    slot3_reward_gold'   = slot3_reward_gold,
  }

  // Refresh board: reset all 3 slots with new bounty values, clear active bounty
  action refresh_board = all {
    active_bounty_idx == 0,
    active_bounty_idx'   = 0,
    player_gold'         = player_gold,
    slot1_active'        = true,
    slot1_kills_needed'  = 4,
    slot1_current_kills' = 0,
    slot1_reward_gold'   = 60,
    slot2_active'        = true,
    slot2_kills_needed'  = 6,
    slot2_current_kills' = 0,
    slot2_reward_gold'   = 100,
    slot3_active'        = true,
    slot3_kills_needed'  = 3,
    slot3_current_kills' = 0,
    slot3_reward_gold'   = 45,
  }

  // Nondeterministic step
  action step = any {
    accept_bounty_1,
    accept_bounty_2,
    accept_bounty_3,
    record_kill,
    claim_bounty,
    abandon_bounty,
    refresh_board,
  }

  // --- Invariants ---

  // Kill counts never exceed needed for each slot
  val kills_bounded = and {
    slot1_current_kills >= 0 and slot1_current_kills <= slot1_kills_needed,
    slot2_current_kills >= 0 and slot2_current_kills <= slot2_kills_needed,
    slot3_current_kills >= 0 and slot3_current_kills <= slot3_kills_needed,
  }

  // Player gold is always non-negative
  val gold_non_negative = player_gold >= 0

  // At most one active bounty at a time (enforced by active_bounty_idx being a single value)
  val at_most_one_bounty = active_bounty_idx >= 0 and active_bounty_idx <= 3

  // If player has an active bounty, that slot must be active
  val active_bounty_valid = and {
    (active_bounty_idx == 1) implies slot1_active,
    (active_bounty_idx == 2) implies slot2_active,
    (active_bounty_idx == 3) implies slot3_active,
  }
}

// Runner module
module bounty_run {
  import bounty.*
}
