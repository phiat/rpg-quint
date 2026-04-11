module leveling {
  const BASE_HP: int
  const BASE_ATK: int
  const XP_PER_LEVEL: int
  const HP_PER_LEVEL: int
  const ATK_PER_LEVEL: int

  var xp: int
  var level: int
  var hp_max: int
  var atk: int

  action init = all {
    xp' = 0,
    level' = 1,
    hp_max' = BASE_HP,
    atk' = BASE_ATK,
  }

  action gain_xp(amount: int): bool = {
    val new_xp = xp + amount
    val threshold = level * XP_PER_LEVEL
    if (new_xp >= threshold)
      all {
        xp' = new_xp,
        level' = level + 1,
        hp_max' = hp_max + HP_PER_LEVEL,
        atk' = atk + ATK_PER_LEVEL,
      }
    else
      all {
        xp' = new_xp,
        level' = level,
        hp_max' = hp_max,
        atk' = atk,
      }
  }

  action gain_xp_no_level(amount: int): bool = {
    val new_xp = xp + amount
    val threshold = level * XP_PER_LEVEL
    all {
      new_xp < threshold,
      xp' = new_xp,
      level' = level,
      hp_max' = hp_max,
      atk' = atk,
    }
  }

  action step = {
    nondet amount = 10.to(80).oneOf()
    any {
      gain_xp(amount),
      gain_xp_no_level(amount),
    }
  }

  /// xp only increases
  val xp_monotonic: bool = xp >= 0

  /// level is always at least 1
  val level_positive: bool = level >= 1

  /// stats are a deterministic function of level
  val stats_match_level: bool = and {
    hp_max == BASE_HP + (level - 1) * HP_PER_LEVEL,
    atk == BASE_ATK + (level - 1) * ATK_PER_LEVEL,
  }

  /// level is consistent with xp thresholds
  val level_matches_xp: bool = and {
    level >= 1,
    xp < level * XP_PER_LEVEL or level > 1,
  }
}

module leveling_run {
  import leveling(
    BASE_HP = 100,
    BASE_ATK = 10,
    XP_PER_LEVEL = 100,
    HP_PER_LEVEL = 20,
    ATK_PER_LEVEL = 5
  ).*
}
