module stamina {
  var current_stamina: int
  var max_stamina: int
  var regen_rate: int
  var turn: int

  action init = all {
    current_stamina' = 10,
    max_stamina' = 10,
    regen_rate' = 3,
    turn' = 0,
  }

  action attack = all {
    current_stamina >= 3,
    current_stamina' = current_stamina - 3,
    max_stamina' = max_stamina,
    regen_rate' = regen_rate,
    turn' = turn + 1,
  }

  action defend = all {
    current_stamina >= 2,
    current_stamina' = current_stamina - 2,
    max_stamina' = max_stamina,
    regen_rate' = regen_rate,
    turn' = turn + 1,
  }

  action special = all {
    current_stamina >= 6,
    current_stamina' = current_stamina - 6,
    max_stamina' = max_stamina,
    regen_rate' = regen_rate,
    turn' = turn + 1,
  }

  action rest = all {
    current_stamina' = if (current_stamina + regen_rate > max_stamina) max_stamina else current_stamina + regen_rate,
    max_stamina' = max_stamina,
    regen_rate' = regen_rate,
    turn' = turn + 1,
  }

  action blocked_no_stamina = all {
    current_stamina < 2,
    current_stamina' = current_stamina,
    max_stamina' = max_stamina,
    regen_rate' = regen_rate,
    turn' = turn + 1,
  }

  action step = any {
    attack,
    defend,
    special,
    rest,
    blocked_no_stamina,
  }

  val stamina_bounded = and {
    current_stamina >= 0,
    current_stamina <= max_stamina,
  }

  val stamina_non_negative = current_stamina >= 0

  val constants_stable = and {
    max_stamina == 10,
    regen_rate == 3,
  }
}

module stamina_run {
  import stamina.*
}
