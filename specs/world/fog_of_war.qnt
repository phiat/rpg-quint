module fog_of_war {
  // 3x3 grid fog-of-war system
  // Visibility states: hidden < revealed < visited
  // visited: player has stood on this cell
  // revealed: player has seen this cell (orthogonal neighbor of a visited cell)

  var pos_x: int
  var pos_y: int

  // Visited flags (player has been here)
  var visited_00: bool
  var visited_01: bool
  var visited_02: bool
  var visited_10: bool
  var visited_11: bool
  var visited_12: bool
  var visited_20: bool
  var visited_21: bool
  var visited_22: bool

  // Revealed flags (player can see this cell)
  var revealed_00: bool
  var revealed_01: bool
  var revealed_02: bool
  var revealed_10: bool
  var revealed_11: bool
  var revealed_12: bool
  var revealed_20: bool
  var revealed_21: bool
  var revealed_22: bool

  // Get visited state for a cell
  pure def get_visited(x: int, y: int,
      v00: bool, v01: bool, v02: bool,
      v10: bool, v11: bool, v12: bool,
      v20: bool, v21: bool, v22: bool): bool =
    if (x == 0 and y == 0) v00
    else if (x == 0 and y == 1) v01
    else if (x == 0 and y == 2) v02
    else if (x == 1 and y == 0) v10
    else if (x == 1 and y == 1) v11
    else if (x == 1 and y == 2) v12
    else if (x == 2 and y == 0) v20
    else if (x == 2 and y == 1) v21
    else v22

  // Get revealed state for a cell
  pure def get_revealed(x: int, y: int,
      r00: bool, r01: bool, r02: bool,
      r10: bool, r11: bool, r12: bool,
      r20: bool, r21: bool, r22: bool): bool =
    if (x == 0 and y == 0) r00
    else if (x == 0 and y == 1) r01
    else if (x == 0 and y == 2) r02
    else if (x == 1 and y == 0) r10
    else if (x == 1 and y == 1) r11
    else if (x == 1 and y == 2) r12
    else if (x == 2 and y == 0) r20
    else if (x == 2 and y == 1) r21
    else r22

  // Compute whether a cell should be revealed given a set of visited cells.
  // A cell is revealed if it is visited, or is an orthogonal neighbor of a visited cell.
  pure def should_reveal(cx: int, cy: int,
      v00: bool, v01: bool, v02: bool,
      v10: bool, v11: bool, v12: bool,
      v20: bool, v21: bool, v22: bool): bool =
    get_visited(cx, cy, v00, v01, v02, v10, v11, v12, v20, v21, v22) or
    (cx > 0 and get_visited(cx - 1, cy, v00, v01, v02, v10, v11, v12, v20, v21, v22)) or
    (cx < 2 and get_visited(cx + 1, cy, v00, v01, v02, v10, v11, v12, v20, v21, v22)) or
    (cy > 0 and get_visited(cx, cy - 1, v00, v01, v02, v10, v11, v12, v20, v21, v22)) or
    (cy < 2 and get_visited(cx, cy + 1, v00, v01, v02, v10, v11, v12, v20, v21, v22))

  // Perform a move to (nx, ny): mark as visited, update all revealed cells
  action do_move(nx: int, ny: int): bool = {
    val nv00 = visited_00 or (nx == 0 and ny == 0)
    val nv01 = visited_01 or (nx == 0 and ny == 1)
    val nv02 = visited_02 or (nx == 0 and ny == 2)
    val nv10 = visited_10 or (nx == 1 and ny == 0)
    val nv11 = visited_11 or (nx == 1 and ny == 1)
    val nv12 = visited_12 or (nx == 1 and ny == 2)
    val nv20 = visited_20 or (nx == 2 and ny == 0)
    val nv21 = visited_21 or (nx == 2 and ny == 1)
    val nv22 = visited_22 or (nx == 2 and ny == 2)
    all {
      nx >= 0, nx <= 2, ny >= 0, ny <= 2,
      pos_x' = nx,
      pos_y' = ny,
      visited_00' = nv00,
      visited_01' = nv01,
      visited_02' = nv02,
      visited_10' = nv10,
      visited_11' = nv11,
      visited_12' = nv12,
      visited_20' = nv20,
      visited_21' = nv21,
      visited_22' = nv22,
      revealed_00' = should_reveal(0, 0, nv00, nv01, nv02, nv10, nv11, nv12, nv20, nv21, nv22),
      revealed_01' = should_reveal(0, 1, nv00, nv01, nv02, nv10, nv11, nv12, nv20, nv21, nv22),
      revealed_02' = should_reveal(0, 2, nv00, nv01, nv02, nv10, nv11, nv12, nv20, nv21, nv22),
      revealed_10' = should_reveal(1, 0, nv00, nv01, nv02, nv10, nv11, nv12, nv20, nv21, nv22),
      revealed_11' = should_reveal(1, 1, nv00, nv01, nv02, nv10, nv11, nv12, nv20, nv21, nv22),
      revealed_12' = should_reveal(1, 2, nv00, nv01, nv02, nv10, nv11, nv12, nv20, nv21, nv22),
      revealed_20' = should_reveal(2, 0, nv00, nv01, nv02, nv10, nv11, nv12, nv20, nv21, nv22),
      revealed_21' = should_reveal(2, 1, nv00, nv01, nv02, nv10, nv11, nv12, nv20, nv21, nv22),
      revealed_22' = should_reveal(2, 2, nv00, nv01, nv02, nv10, nv11, nv12, nv20, nv21, nv22),
    }
  }

  // Initialize: start at (0,0), which is visited; orthogonal neighbors (1,0) and (0,1) are revealed
  action init = all {
    pos_x' = 0,
    pos_y' = 0,
    visited_00' = true,
    visited_01' = false,
    visited_02' = false,
    visited_10' = false,
    visited_11' = false,
    visited_12' = false,
    visited_20' = false,
    visited_21' = false,
    visited_22' = false,
    revealed_00' = true,
    revealed_01' = true,
    revealed_02' = false,
    revealed_10' = true,
    revealed_11' = false,
    revealed_12' = false,
    revealed_20' = false,
    revealed_21' = false,
    revealed_22' = false,
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

  action step = any {
    move_up,
    move_down,
    move_left,
    move_right,
  }

  // Invariants

  // visited implies revealed
  val visited_implies_revealed =
    (visited_00 implies revealed_00) and
    (visited_01 implies revealed_01) and
    (visited_02 implies revealed_02) and
    (visited_10 implies revealed_10) and
    (visited_11 implies revealed_11) and
    (visited_12 implies revealed_12) and
    (visited_20 implies revealed_20) and
    (visited_21 implies revealed_21) and
    (visited_22 implies revealed_22)

  // Position is always within grid bounds
  val position_bounded =
    pos_x >= 0 and pos_x <= 2 and pos_y >= 0 and pos_y <= 2

  // Starting cell (0,0) is always visited
  val start_always_visited = visited_00
}

module fog_of_war_run {
  import fog_of_war.*
}
