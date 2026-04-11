module status {
  const INIT_HP: int
  const ATK: int

  var hp: int
  var base_atk: int
  var poison_turns: int
  var buff_turns: int
  var poison_dmg: int
  var buff_amount: int

  action init = all {
    hp' = INIT_HP,
    base_atk' = ATK,
    poison_turns' = 0,
    buff_turns' = 0,
    poison_dmg' = 0,
    buff_amount' = 0,
  }

  action apply_poison(dmg: int, dur: int): bool = all {
    poison_turns == 0,
    hp' = hp,
    base_atk' = base_atk,
    poison_turns' = dur,
    buff_turns' = buff_turns,
    poison_dmg' = dmg,
    buff_amount' = buff_amount,
  }

  action apply_buff(amt: int, dur: int): bool = all {
    buff_turns == 0,
    hp' = hp,
    base_atk' = base_atk,
    poison_turns' = poison_turns,
    buff_turns' = dur,
    poison_dmg' = poison_dmg,
    buff_amount' = amt,
  }

  action tick = all {
    (poison_turns > 0 or buff_turns > 0),
    hp' = if (poison_turns > 0) hp - poison_dmg else hp,
    base_atk' = base_atk,
    poison_turns' = if (poison_turns > 0) poison_turns - 1 else 0,
    buff_turns' = if (buff_turns > 0) buff_turns - 1 else 0,
    poison_dmg' = if (poison_turns > 0) (if (poison_turns - 1 == 0) 0 else poison_dmg) else 0,
    buff_amount' = if (buff_turns > 0) (if (buff_turns - 1 == 0) 0 else buff_amount) else 0,
  }

  action tick_no_effects = all {
    poison_turns == 0,
    buff_turns == 0,
    hp' = hp,
    base_atk' = base_atk,
    poison_turns' = poison_turns,
    buff_turns' = buff_turns,
    poison_dmg' = poison_dmg,
    buff_amount' = buff_amount,
  }

  action step = any {
    tick,
    tick_no_effects,
    nondet dmg = 1.to(10).oneOf()
    nondet dur = 1.to(5).oneOf()
    apply_poison(dmg, dur),
    nondet amt = 1.to(10).oneOf()
    nondet dur = 1.to(5).oneOf()
    apply_buff(amt, dur),
  }

  val durations_non_negative: bool = poison_turns >= 0 and buff_turns >= 0

  val effects_consistent: bool =
    (if (poison_turns == 0) poison_dmg == 0 else true) and
    (if (buff_turns == 0) buff_amount == 0 else true)

  val hp_capped: bool = hp <= INIT_HP
}

module status_run {
  import status(INIT_HP = 100, ATK = 25).*
}
