module fast_travel {
  // Constants
  pure val TRAVEL_COST = 5

  // Player position on 3x3 grid
  var pos_x: int
  var pos_y: int

  // Gold
  var gold: int

  // Unlocked waypoints (row y, col x) — wp_XY means x=X, y=Y
  var wp_00: bool
  var wp_10: bool
  var wp_20: bool
  var wp_01: bool
  var wp_11: bool
  var wp_21: bool
  var wp_02: bool
  var wp_12: bool
  var wp_22: bool

  // Helper: get waypoint unlock state by position
  pure def get_wp(x: int, y: int,
      w00: bool, w10: bool, w20: bool,
      w01: bool, w11: bool, w21: bool,
      w02: bool, w12: bool, w22: bool): bool =
    if (x == 0 and y == 0) w00
    else if (x == 1 and y == 0) w10
    else if (x == 2 and y == 0) w20
    else if (x == 0 and y == 1) w01
    else if (x == 1 and y == 1) w11
    else if (x == 2 and y == 1) w21
    else if (x == 0 and y == 2) w02
    else if (x == 1 and y == 2) w12
    else w22

  // Helper: set waypoint for position (returns bool per slot)
  pure def set_wp(slot_x: int, slot_y: int, target_x: int, target_y: int, old_val: bool): bool =
    if (slot_x == target_x and slot_y == target_y) true else old_val

  // Internal move helper — moves to (nx, ny) and unlocks that waypoint
  action do_move(nx: int, ny: int): bool = {
    all {
      nx >= 0,
      nx <= 2,
      ny >= 0,
      ny <= 2,
      pos_x' = nx,
      pos_y' = ny,
      gold' = gold,
      wp_00' = set_wp(0, 0, nx, ny, wp_00),
      wp_10' = set_wp(1, 0, nx, ny, wp_10),
      wp_20' = set_wp(2, 0, nx, ny, wp_20),
      wp_01' = set_wp(0, 1, nx, ny, wp_01),
      wp_11' = set_wp(1, 1, nx, ny, wp_11),
      wp_21' = set_wp(2, 1, nx, ny, wp_21),
      wp_02' = set_wp(0, 2, nx, ny, wp_02),
      wp_12' = set_wp(1, 2, nx, ny, wp_12),
      wp_22' = set_wp(2, 2, nx, ny, wp_22),
    }
  }

  action init = all {
    pos_x' = 0,
    pos_y' = 0,
    gold' = 20,
    wp_00' = true,
    wp_10' = false,
    wp_20' = false,
    wp_01' = false,
    wp_11' = false,
    wp_21' = false,
    wp_02' = false,
    wp_12' = false,
    wp_22' = false,
  }

  action move_up = all {
    pos_y > 0,
    do_move(pos_x, pos_y - 1),
  }

  action move_down = all {
    pos_y < 2,
    do_move(pos_x, pos_y + 1),
  }

  action move_left = all {
    pos_x > 0,
    do_move(pos_x - 1, pos_y),
  }

  action move_right = all {
    pos_x < 2,
    do_move(pos_x + 1, pos_y),
  }

  // Fast travel actions — teleport to an unlocked waypoint for TRAVEL_COST gold
  action fast_travel_00 = {
    val dest_unlocked = wp_00
    all {
      dest_unlocked,
      gold >= TRAVEL_COST,
      pos_x' = 0,
      pos_y' = 0,
      gold' = gold - TRAVEL_COST,
      wp_00' = wp_00,
      wp_10' = wp_10,
      wp_20' = wp_20,
      wp_01' = wp_01,
      wp_11' = wp_11,
      wp_21' = wp_21,
      wp_02' = wp_02,
      wp_12' = wp_12,
      wp_22' = wp_22,
    }
  }

  action fast_travel_10 = {
    val dest_unlocked = wp_10
    all {
      dest_unlocked,
      gold >= TRAVEL_COST,
      pos_x' = 1,
      pos_y' = 0,
      gold' = gold - TRAVEL_COST,
      wp_00' = wp_00,
      wp_10' = wp_10,
      wp_20' = wp_20,
      wp_01' = wp_01,
      wp_11' = wp_11,
      wp_21' = wp_21,
      wp_02' = wp_02,
      wp_12' = wp_12,
      wp_22' = wp_22,
    }
  }

  action fast_travel_20 = {
    val dest_unlocked = wp_20
    all {
      dest_unlocked,
      gold >= TRAVEL_COST,
      pos_x' = 2,
      pos_y' = 0,
      gold' = gold - TRAVEL_COST,
      wp_00' = wp_00,
      wp_10' = wp_10,
      wp_20' = wp_20,
      wp_01' = wp_01,
      wp_11' = wp_11,
      wp_21' = wp_21,
      wp_02' = wp_02,
      wp_12' = wp_12,
      wp_22' = wp_22,
    }
  }

  action fast_travel_01 = {
    val dest_unlocked = wp_01
    all {
      dest_unlocked,
      gold >= TRAVEL_COST,
      pos_x' = 0,
      pos_y' = 1,
      gold' = gold - TRAVEL_COST,
      wp_00' = wp_00,
      wp_10' = wp_10,
      wp_20' = wp_20,
      wp_01' = wp_01,
      wp_11' = wp_11,
      wp_21' = wp_21,
      wp_02' = wp_02,
      wp_12' = wp_12,
      wp_22' = wp_22,
    }
  }

  action fast_travel_11 = {
    val dest_unlocked = wp_11
    all {
      dest_unlocked,
      gold >= TRAVEL_COST,
      pos_x' = 1,
      pos_y' = 1,
      gold' = gold - TRAVEL_COST,
      wp_00' = wp_00,
      wp_10' = wp_10,
      wp_20' = wp_20,
      wp_01' = wp_01,
      wp_11' = wp_11,
      wp_21' = wp_21,
      wp_02' = wp_02,
      wp_12' = wp_12,
      wp_22' = wp_22,
    }
  }

  action fast_travel_21 = {
    val dest_unlocked = wp_21
    all {
      dest_unlocked,
      gold >= TRAVEL_COST,
      pos_x' = 2,
      pos_y' = 1,
      gold' = gold - TRAVEL_COST,
      wp_00' = wp_00,
      wp_10' = wp_10,
      wp_20' = wp_20,
      wp_01' = wp_01,
      wp_11' = wp_11,
      wp_21' = wp_21,
      wp_02' = wp_02,
      wp_12' = wp_12,
      wp_22' = wp_22,
    }
  }

  action fast_travel_02 = {
    val dest_unlocked = wp_02
    all {
      dest_unlocked,
      gold >= TRAVEL_COST,
      pos_x' = 0,
      pos_y' = 2,
      gold' = gold - TRAVEL_COST,
      wp_00' = wp_00,
      wp_10' = wp_10,
      wp_20' = wp_20,
      wp_01' = wp_01,
      wp_11' = wp_11,
      wp_21' = wp_21,
      wp_02' = wp_02,
      wp_12' = wp_12,
      wp_22' = wp_22,
    }
  }

  action fast_travel_12 = {
    val dest_unlocked = wp_12
    all {
      dest_unlocked,
      gold >= TRAVEL_COST,
      pos_x' = 1,
      pos_y' = 2,
      gold' = gold - TRAVEL_COST,
      wp_00' = wp_00,
      wp_10' = wp_10,
      wp_20' = wp_20,
      wp_01' = wp_01,
      wp_11' = wp_11,
      wp_21' = wp_21,
      wp_02' = wp_02,
      wp_12' = wp_12,
      wp_22' = wp_22,
    }
  }

  action fast_travel_22 = {
    val dest_unlocked = wp_22
    all {
      dest_unlocked,
      gold >= TRAVEL_COST,
      pos_x' = 2,
      pos_y' = 2,
      gold' = gold - TRAVEL_COST,
      wp_00' = wp_00,
      wp_10' = wp_10,
      wp_20' = wp_20,
      wp_01' = wp_01,
      wp_11' = wp_11,
      wp_21' = wp_21,
      wp_02' = wp_02,
      wp_12' = wp_12,
      wp_22' = wp_22,
    }
  }

  action step = any {
    move_up,
    move_down,
    move_left,
    move_right,
    fast_travel_00,
    fast_travel_10,
    fast_travel_20,
    fast_travel_01,
    fast_travel_11,
    fast_travel_21,
    fast_travel_02,
    fast_travel_12,
    fast_travel_22,
  }

  // Invariants
  val position_bounded =
    0 <= pos_x and pos_x <= 2 and 0 <= pos_y and pos_y <= 2

  val current_pos_unlocked =
    get_wp(pos_x, pos_y, wp_00, wp_10, wp_20, wp_01, wp_11, wp_21, wp_02, wp_12, wp_22)

  val gold_non_negative =
    gold >= 0
}

module fast_travel_run {
  import fast_travel.*
}
