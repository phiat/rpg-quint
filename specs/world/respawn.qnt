module respawn {
  const ZONE1_CAP: int
  const ZONE2_CAP: int
  const RESPAWN_TIME: int
  const TOTAL_ENEMIES: int

  var zone1_count: int
  var zone2_count: int
  var dead_count: int
  var timer1: int
  var timer2: int

  action init = all {
    zone1_count' = 3,
    zone2_count' = 2,
    dead_count' = 0,
    timer1' = 0,
    timer2' = 0,
  }

  action kill_zone1 = all {
    zone1_count > 0,
    zone1_count' = zone1_count - 1,
    zone2_count' = zone2_count,
    dead_count' = dead_count + 1,
    timer1' = RESPAWN_TIME,
    timer2' = timer2,
  }

  action kill_zone2 = all {
    zone2_count > 0,
    zone1_count' = zone1_count,
    zone2_count' = zone2_count - 1,
    dead_count' = dead_count + 1,
    timer1' = timer1,
    timer2' = RESPAWN_TIME,
  }

  action tick_respawn = all {
    timer1' = if (timer1 > 0) timer1 - 1 else 0,
    timer2' = if (timer2 > 0) timer2 - 1 else 0,
    zone1_count' = zone1_count,
    zone2_count' = zone2_count,
    dead_count' = dead_count,
  }

  action spawn_zone1 = all {
    timer1 == 0,
    dead_count > 0,
    zone1_count < ZONE1_CAP,
    zone1_count' = zone1_count + 1,
    zone2_count' = zone2_count,
    dead_count' = dead_count - 1,
    timer1' = timer1,
    timer2' = timer2,
  }

  action spawn_zone2 = all {
    timer2 == 0,
    dead_count > 0,
    zone2_count < ZONE2_CAP,
    zone1_count' = zone1_count,
    zone2_count' = zone2_count + 1,
    dead_count' = dead_count - 1,
    timer1' = timer1,
    timer2' = timer2,
  }

  action blocked_spawn_full = all {
    zone1_count >= ZONE1_CAP,
    zone2_count >= ZONE2_CAP,
    zone1_count' = zone1_count,
    zone2_count' = zone2_count,
    dead_count' = dead_count,
    timer1' = timer1,
    timer2' = timer2,
  }

  action step = any {
    kill_zone1,
    kill_zone2,
    tick_respawn,
    spawn_zone1,
    spawn_zone2,
    blocked_spawn_full,
  }

  val population_conserved =
    zone1_count + zone2_count + dead_count == TOTAL_ENEMIES

  val zones_bounded = and {
    zone1_count <= ZONE1_CAP,
    zone2_count <= ZONE2_CAP,
  }

  val counts_non_negative = and {
    zone1_count >= 0,
    zone2_count >= 0,
    dead_count >= 0,
  }

  val timers_non_negative = and {
    timer1 >= 0,
    timer2 >= 0,
  }
}

module respawn_run {
  import respawn(
    ZONE1_CAP = 4,
    ZONE2_CAP = 3,
    RESPAWN_TIME = 3,
    TOTAL_ENEMIES = 5
  ).*
}
