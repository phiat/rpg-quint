module permadeath {
  var hp: int
  var alive: bool
  var generation: int
  var legacy_gold: int
  var legacy_bonus_atk: int
  var gold: int
  var total_deaths: int

  action init = all {
    hp' = 100,
    alive' = true,
    generation' = 1,
    legacy_gold' = 0,
    legacy_bonus_atk' = 0,
    gold' = 0,
    total_deaths' = 0,
  }

  // Take damage; if hp drops to 0 or below, set alive to false
  action take_damage(amount: int): bool = {
    val new_hp = hp - amount
    all {
      amount > 0,
      alive,
      hp' = if (new_hp <= 0) 0 else new_hp,
      alive' = if (new_hp <= 0) false else true,
      generation' = generation,
      legacy_gold' = legacy_gold,
      legacy_bonus_atk' = legacy_bonus_atk,
      gold' = gold,
      total_deaths' = total_deaths,
    }
  }

  // Die and inherit: requires !alive; starts next generation with inherited benefits
  action die_and_inherit: bool = {
    val new_gen = generation + 1
    val new_bonus = if (new_gen < 5) new_gen else 5
    all {
      not(alive),
      generation' = new_gen,
      gold' = legacy_gold / 2,
      legacy_bonus_atk' = new_bonus,
      hp' = 50,
      alive' = true,
      legacy_gold' = legacy_gold,
      total_deaths' = total_deaths + 1,
    }
  }

  // Earn gold (must be alive)
  action earn_gold(amount: int): bool = all {
    amount > 0,
    alive,
    gold' = gold + amount,
    hp' = hp,
    alive' = alive,
    generation' = generation,
    legacy_gold' = legacy_gold,
    legacy_bonus_atk' = legacy_bonus_atk,
    total_deaths' = total_deaths,
  }

  // Deposit gold into legacy pool (must be alive)
  action deposit_legacy(amount: int): bool = all {
    amount > 0,
    gold >= amount,
    alive,
    legacy_gold' = legacy_gold + amount,
    gold' = gold - amount,
    hp' = hp,
    alive' = alive,
    generation' = generation,
    legacy_bonus_atk' = legacy_bonus_atk,
    total_deaths' = total_deaths,
  }

  action step: bool = {
    nondet dmg = 1.to(30).oneOf()
    nondet earn = 1.to(50).oneOf()
    nondet dep = 1.to(20).oneOf()
    any {
      take_damage(dmg),
      die_and_inherit,
      earn_gold(earn),
      deposit_legacy(dep),
    }
  }

  // Invariants
  val generation_positive: bool = generation >= 1
  val bonus_bounded: bool = legacy_bonus_atk >= 0 and legacy_bonus_atk <= 5
  val alive_hp_consistent: bool = alive implies hp > 0
  val gold_non_negative: bool = gold >= 0
  val legacy_gold_non_negative: bool = legacy_gold >= 0
  val deaths_non_negative: bool = total_deaths >= 0
}

module permadeath_run {
  import permadeath.*
}
