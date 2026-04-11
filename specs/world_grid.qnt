module world_grid {
  var player_x: int
  var player_y: int
  var player_level: int
  var visited_count: int
  var current_zone: str

  pure def zone_name(x: int, y: int): str =
    if (x == 0 and y == 0) "Village"
    else if (x == 1 and y == 0) "Forest"
    else if (x == 2 and y == 0) "Swamp"
    else if (x == 0 and y == 1) "Plains"
    else if (x == 1 and y == 1) "Cave"
    else if (x == 2 and y == 1) "Mountain"
    else if (x == 0 and y == 2) "Ruins"
    else if (x == 1 and y == 2) "Shrine"
    else if (x == 2 and y == 2) "Castle"
    else "Unknown"

  pure def zone_level_req(x: int, y: int): int =
    if (x == 0 and y == 0) 1
    else if (x == 1 and y == 0) 1
    else if (x == 2 and y == 0) 1
    else if (x == 0 and y == 1) 1
    else if (x == 1 and y == 1) 2
    else if (x == 2 and y == 1) 2
    else if (x == 0 and y == 2) 2
    else if (x == 1 and y == 2) 2
    else if (x == 2 and y == 2) 3
    else 99

  action init = all {
    player_x' = 0,
    player_y' = 0,
    player_level' = 1,
    visited_count' = 1,
    current_zone' = "Village",
  }

  action move_up = all {
    player_y > 0,
    zone_level_req(player_x, player_y - 1) <= player_level,
    player_x' = player_x,
    player_y' = player_y - 1,
    player_level' = player_level,
    visited_count' = visited_count + 1,
    current_zone' = zone_name(player_x, player_y - 1),
  }

  action move_down = all {
    player_y < 2,
    zone_level_req(player_x, player_y + 1) <= player_level,
    player_x' = player_x,
    player_y' = player_y + 1,
    player_level' = player_level,
    visited_count' = visited_count + 1,
    current_zone' = zone_name(player_x, player_y + 1),
  }

  action move_left = all {
    player_x > 0,
    zone_level_req(player_x - 1, player_y) <= player_level,
    player_x' = player_x - 1,
    player_y' = player_y,
    player_level' = player_level,
    visited_count' = visited_count + 1,
    current_zone' = zone_name(player_x - 1, player_y),
  }

  action move_right = all {
    player_x < 2,
    zone_level_req(player_x + 1, player_y) <= player_level,
    player_x' = player_x + 1,
    player_y' = player_y,
    player_level' = player_level,
    visited_count' = visited_count + 1,
    current_zone' = zone_name(player_x + 1, player_y),
  }

  action level_up = all {
    player_level < 3,
    player_x' = player_x,
    player_y' = player_y,
    player_level' = player_level + 1,
    visited_count' = visited_count,
    current_zone' = current_zone,
  }

  action blocked_move_level = all {
    any {
      all { player_y > 0, zone_level_req(player_x, player_y - 1) > player_level },
      all { player_y < 2, zone_level_req(player_x, player_y + 1) > player_level },
      all { player_x > 0, zone_level_req(player_x - 1, player_y) > player_level },
      all { player_x < 2, zone_level_req(player_x + 1, player_y) > player_level },
    },
    player_x' = player_x,
    player_y' = player_y,
    player_level' = player_level,
    visited_count' = visited_count,
    current_zone' = current_zone,
  }

  action step = any {
    move_up,
    move_down,
    move_left,
    move_right,
    level_up,
    blocked_move_level,
  }

  val position_bounded =
    0 <= player_x and player_x <= 2 and 0 <= player_y and player_y <= 2

  val zone_matches_position =
    current_zone == zone_name(player_x, player_y)

  val level_gate_respected =
    zone_level_req(player_x, player_y) <= player_level

  val level_bounded =
    1 <= player_level and player_level <= 3
}

module world_grid_run {
  import world_grid.*
}
