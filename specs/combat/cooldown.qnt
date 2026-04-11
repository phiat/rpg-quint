module cooldown {
  const FIREBALL_CD: int
  const HEAL_CD: int
  const SHIELD_CD: int

  var cd_fireball: int
  var cd_heal: int
  var cd_shield: int
  var current_turn: int

  action init = all {
    cd_fireball' = 0,
    cd_heal' = 0,
    cd_shield' = 0,
    current_turn' = 0,
  }

  action use_fireball = all {
    cd_fireball == 0,
    cd_fireball' = FIREBALL_CD,
    cd_heal' = cd_heal,
    cd_shield' = cd_shield,
    current_turn' = current_turn + 1,
  }

  action use_heal = all {
    cd_heal == 0,
    cd_heal' = HEAL_CD,
    cd_fireball' = cd_fireball,
    cd_shield' = cd_shield,
    current_turn' = current_turn + 1,
  }

  action use_shield = all {
    cd_shield == 0,
    cd_shield' = SHIELD_CD,
    cd_fireball' = cd_fireball,
    cd_heal' = cd_heal,
    current_turn' = current_turn + 1,
  }

  action tick = all {
    cd_fireball' = if (cd_fireball > 0) cd_fireball - 1 else 0,
    cd_heal' = if (cd_heal > 0) cd_heal - 1 else 0,
    cd_shield' = if (cd_shield > 0) cd_shield - 1 else 0,
    current_turn' = current_turn + 1,
  }

  action blocked_fireball = all {
    cd_fireball > 0,
    cd_fireball' = cd_fireball,
    cd_heal' = cd_heal,
    cd_shield' = cd_shield,
    current_turn' = current_turn + 1,
  }

  action blocked_heal = all {
    cd_heal > 0,
    cd_fireball' = cd_fireball,
    cd_heal' = cd_heal,
    cd_shield' = cd_shield,
    current_turn' = current_turn + 1,
  }

  action blocked_shield = all {
    cd_shield > 0,
    cd_fireball' = cd_fireball,
    cd_heal' = cd_heal,
    cd_shield' = cd_shield,
    current_turn' = current_turn + 1,
  }

  action step = any {
    use_fireball,
    use_heal,
    use_shield,
    tick,
    blocked_fireball,
    blocked_heal,
    blocked_shield,
  }

  val cooldowns_non_negative = and {
    cd_fireball >= 0,
    cd_heal >= 0,
    cd_shield >= 0,
  }

  val cooldowns_bounded = and {
    cd_fireball <= FIREBALL_CD,
    cd_heal <= HEAL_CD,
    cd_shield <= SHIELD_CD,
  }
}

module cooldown_run {
  import cooldown(FIREBALL_CD = 3, HEAL_CD = 5, SHIELD_CD = 2).*
}
