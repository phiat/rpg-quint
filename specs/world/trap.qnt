module trap {
  // Constants
  pure val TRAP_DAMAGE = 10
  pure val PERCEPTION_THRESHOLD = 3

  // Player state
  var pos_x: int
  var pos_y: int
  var hp: int
  var max_hp: int
  var perception: int

  // Trap presence (deterministic: traps at (1,0) and (0,1))
  var trap_present_00: bool
  var trap_present_01: bool
  var trap_present_10: bool
  var trap_present_11: bool

  // Trap revealed
  var trap_revealed_00: bool
  var trap_revealed_01: bool
  var trap_revealed_10: bool
  var trap_revealed_11: bool

  // Trap triggered
  var trap_triggered_00: bool
  var trap_triggered_01: bool
  var trap_triggered_10: bool
  var trap_triggered_11: bool

  // Helpers to get trap state at a position
  pure def get_present(x: int, y: int, p00: bool, p01: bool, p10: bool, p11: bool): bool =
    if (x == 0 and y == 0) p00
    else if (x == 0 and y == 1) p01
    else if (x == 1 and y == 0) p10
    else p11

  pure def get_revealed(x: int, y: int, r00: bool, r01: bool, r10: bool, r11: bool): bool =
    if (x == 0 and y == 0) r00
    else if (x == 0 and y == 1) r01
    else if (x == 1 and y == 0) r10
    else r11

  pure def get_triggered(x: int, y: int, t00: bool, t01: bool, t10: bool, t11: bool): bool =
    if (x == 0 and y == 0) t00
    else if (x == 0 and y == 1) t01
    else if (x == 1 and y == 0) t10
    else t11

  action init = all {
    pos_x' = 0,
    pos_y' = 0,
    hp' = 50,
    max_hp' = 50,
    perception' = 2,
    trap_present_00' = false,
    trap_present_01' = true,
    trap_present_10' = true,
    trap_present_11' = false,
    trap_revealed_00' = false,
    trap_revealed_01' = false,
    trap_revealed_10' = false,
    trap_revealed_11' = false,
    trap_triggered_00' = false,
    trap_triggered_01' = false,
    trap_triggered_10' = false,
    trap_triggered_11' = false,
  }

  // Internal move helper
  action do_move(nx: int, ny: int): bool = {
    val present = get_present(nx, ny, trap_present_00, trap_present_01, trap_present_10, trap_present_11)
    val revealed = get_revealed(nx, ny, trap_revealed_00, trap_revealed_01, trap_revealed_10, trap_revealed_11)
    val triggered = get_triggered(nx, ny, trap_triggered_00, trap_triggered_01, trap_triggered_10, trap_triggered_11)
    val will_trigger = present and not(revealed) and not(triggered)
    all {
      nx >= 0,
      nx <= 1,
      ny >= 0,
      ny <= 1,
      pos_x' = nx,
      pos_y' = ny,
      hp' = if (will_trigger) hp - TRAP_DAMAGE else hp,
      max_hp' = max_hp,
      perception' = perception,
      trap_present_00' = trap_present_00,
      trap_present_01' = trap_present_01,
      trap_present_10' = trap_present_10,
      trap_present_11' = trap_present_11,
      trap_revealed_00' = trap_revealed_00,
      trap_revealed_01' = trap_revealed_01,
      trap_revealed_10' = trap_revealed_10,
      trap_revealed_11' = trap_revealed_11,
      trap_triggered_00' = if (will_trigger and nx == 0 and ny == 0) true else trap_triggered_00,
      trap_triggered_01' = if (will_trigger and nx == 0 and ny == 1) true else trap_triggered_01,
      trap_triggered_10' = if (will_trigger and nx == 1 and ny == 0) true else trap_triggered_10,
      trap_triggered_11' = if (will_trigger and nx == 1 and ny == 1) true else trap_triggered_11,
    }
  }

  action move_right = all {
    pos_x < 1,
    do_move(pos_x + 1, pos_y),
  }

  action move_left = all {
    pos_x > 0,
    do_move(pos_x - 1, pos_y),
  }

  action move_down = all {
    pos_y < 1,
    do_move(pos_x, pos_y + 1),
  }

  action move_up = all {
    pos_y > 0,
    do_move(pos_x, pos_y - 1),
  }

  // Scan: reveal trap at current position if perception >= threshold
  action scan = all {
    perception >= PERCEPTION_THRESHOLD,
    pos_x' = pos_x,
    pos_y' = pos_y,
    hp' = hp,
    max_hp' = max_hp,
    perception' = perception,
    trap_present_00' = trap_present_00,
    trap_present_01' = trap_present_01,
    trap_present_10' = trap_present_10,
    trap_present_11' = trap_present_11,
    trap_revealed_00' = if (pos_x == 0 and pos_y == 0) true else trap_revealed_00,
    trap_revealed_01' = if (pos_x == 0 and pos_y == 1) true else trap_revealed_01,
    trap_revealed_10' = if (pos_x == 1 and pos_y == 0) true else trap_revealed_10,
    trap_revealed_11' = if (pos_x == 1 and pos_y == 1) true else trap_revealed_11,
    trap_triggered_00' = trap_triggered_00,
    trap_triggered_01' = trap_triggered_01,
    trap_triggered_10' = trap_triggered_10,
    trap_triggered_11' = trap_triggered_11,
  }

  // Upgrade perception (max 5)
  action upgrade_perception = all {
    perception < 5,
    pos_x' = pos_x,
    pos_y' = pos_y,
    hp' = hp,
    max_hp' = max_hp,
    perception' = perception + 1,
    trap_present_00' = trap_present_00,
    trap_present_01' = trap_present_01,
    trap_present_10' = trap_present_10,
    trap_present_11' = trap_present_11,
    trap_revealed_00' = trap_revealed_00,
    trap_revealed_01' = trap_revealed_01,
    trap_revealed_10' = trap_revealed_10,
    trap_revealed_11' = trap_revealed_11,
    trap_triggered_00' = trap_triggered_00,
    trap_triggered_01' = trap_triggered_01,
    trap_triggered_10' = trap_triggered_10,
    trap_triggered_11' = trap_triggered_11,
  }

  action step = any {
    move_right,
    move_left,
    move_down,
    move_up,
    scan,
    upgrade_perception,
  }

  // Invariants
  val triggered_implies_present =
    (trap_triggered_00 implies trap_present_00) and
    (trap_triggered_01 implies trap_present_01) and
    (trap_triggered_10 implies trap_present_10) and
    (trap_triggered_11 implies trap_present_11)

  val hp_bounded = hp >= 0 and hp <= max_hp

  val perception_bounded = perception >= 1 and perception <= 5

  val position_bounded = pos_x >= 0 and pos_x <= 1 and pos_y >= 0 and pos_y <= 1
}

module trap_run {
  import trap.*
}
