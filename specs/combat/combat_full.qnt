module combat_full {
  var hp_a: int
  var hp_b: int
  var weapon_dmg_a: int
  var weapon_dmg_b: int
  var buff_a: int
  var buff_b: int
  var buff_turns_a: int
  var buff_turns_b: int
  var poison_a: int
  var poison_b: int
  var poison_turns_a: int
  var poison_turns_b: int
  var turn: str
  var game_over: bool

  /// Compute new poison damage, turns, and HP delta after ticking poison for one character.
  pure def tick_poison(p_dmg: int, p_turns: int): (int, int, int) =
    if (p_turns > 0)
      val new_turns = p_turns - 1
      val dmg_after = if (new_turns == 0) 0 else p_dmg
      (p_dmg, dmg_after, new_turns)
    else
      (0, 0, 0)

  /// Compute new buff amount and turns after ticking buff for one character.
  pure def tick_buff(b_amt: int, b_turns: int): (int, int) =
    if (b_turns > 0)
      val new_turns = b_turns - 1
      val amt_after = if (new_turns == 0) 0 else b_amt
      (amt_after, new_turns)
    else
      (0, 0)

  action init = all {
    hp_a' = 100,
    hp_b' = 100,
    weapon_dmg_a' = 25,
    weapon_dmg_b' = 20,
    buff_a' = 0,
    buff_b' = 0,
    buff_turns_a' = 0,
    buff_turns_b' = 0,
    poison_a' = 0,
    poison_b' = 0,
    poison_turns_a' = 0,
    poison_turns_b' = 0,
    turn' = "A",
    game_over' = false,
  }

  action attack_a = all {
    turn == "A",
    not(game_over),
    // A attacks B: B takes weapon + buff damage
    val atk_dmg = weapon_dmg_a + buff_a
    // Tick poisons for both
    val pa = tick_poison(poison_a, poison_turns_a)
    val pb = tick_poison(poison_b, poison_turns_b)
    // pa._1 = damage dealt to A this tick, pa._2 = new poison_a, pa._3 = new poison_turns_a
    val new_hp_a = hp_a - pa._1
    val new_hp_b = hp_b - atk_dmg - pb._1
    // Tick buffs for both
    val ba = tick_buff(buff_a, buff_turns_a)
    val bb = tick_buff(buff_b, buff_turns_b)
    all {
      hp_a' = new_hp_a,
      hp_b' = new_hp_b,
      weapon_dmg_a' = weapon_dmg_a,
      weapon_dmg_b' = weapon_dmg_b,
      poison_a' = pa._2,
      poison_turns_a' = pa._3,
      poison_b' = pb._2,
      poison_turns_b' = pb._3,
      buff_a' = ba._1,
      buff_turns_a' = ba._2,
      buff_b' = bb._1,
      buff_turns_b' = bb._2,
      game_over' = (new_hp_a <= 0 or new_hp_b <= 0),
      turn' = "B",
    }
  }

  action attack_b = all {
    turn == "B",
    not(game_over),
    // B attacks A: A takes weapon + buff damage
    val atk_dmg = weapon_dmg_b + buff_b
    // Tick poisons for both
    val pa = tick_poison(poison_a, poison_turns_a)
    val pb = tick_poison(poison_b, poison_turns_b)
    val new_hp_a = hp_a - atk_dmg - pa._1
    val new_hp_b = hp_b - pb._1
    // Tick buffs for both
    val ba = tick_buff(buff_a, buff_turns_a)
    val bb = tick_buff(buff_b, buff_turns_b)
    all {
      hp_a' = new_hp_a,
      hp_b' = new_hp_b,
      weapon_dmg_a' = weapon_dmg_a,
      weapon_dmg_b' = weapon_dmg_b,
      poison_a' = pa._2,
      poison_turns_a' = pa._3,
      poison_b' = pb._2,
      poison_turns_b' = pb._3,
      buff_a' = ba._1,
      buff_turns_a' = ba._2,
      buff_b' = bb._1,
      buff_turns_b' = bb._2,
      game_over' = (new_hp_a <= 0 or new_hp_b <= 0),
      turn' = "A",
    }
  }

  action apply_poison_a(dmg: int, dur: int): bool = all {
    poison_turns_a == 0,
    not(game_over),
    hp_a' = hp_a,
    hp_b' = hp_b,
    weapon_dmg_a' = weapon_dmg_a,
    weapon_dmg_b' = weapon_dmg_b,
    buff_a' = buff_a,
    buff_b' = buff_b,
    buff_turns_a' = buff_turns_a,
    buff_turns_b' = buff_turns_b,
    poison_a' = dmg,
    poison_turns_a' = dur,
    poison_b' = poison_b,
    poison_turns_b' = poison_turns_b,
    turn' = turn,
    game_over' = game_over,
  }

  action apply_poison_b(dmg: int, dur: int): bool = all {
    poison_turns_b == 0,
    not(game_over),
    hp_a' = hp_a,
    hp_b' = hp_b,
    weapon_dmg_a' = weapon_dmg_a,
    weapon_dmg_b' = weapon_dmg_b,
    buff_a' = buff_a,
    buff_b' = buff_b,
    buff_turns_a' = buff_turns_a,
    buff_turns_b' = buff_turns_b,
    poison_a' = poison_a,
    poison_turns_a' = poison_turns_a,
    poison_b' = dmg,
    poison_turns_b' = dur,
    turn' = turn,
    game_over' = game_over,
  }

  action apply_buff_a(amt: int, dur: int): bool = all {
    buff_turns_a == 0,
    not(game_over),
    hp_a' = hp_a,
    hp_b' = hp_b,
    weapon_dmg_a' = weapon_dmg_a,
    weapon_dmg_b' = weapon_dmg_b,
    buff_a' = amt,
    buff_turns_a' = dur,
    buff_b' = buff_b,
    buff_turns_b' = buff_turns_b,
    poison_a' = poison_a,
    poison_turns_a' = poison_turns_a,
    poison_b' = poison_b,
    poison_turns_b' = poison_turns_b,
    turn' = turn,
    game_over' = game_over,
  }

  action apply_buff_b(amt: int, dur: int): bool = all {
    buff_turns_b == 0,
    not(game_over),
    hp_a' = hp_a,
    hp_b' = hp_b,
    weapon_dmg_a' = weapon_dmg_a,
    weapon_dmg_b' = weapon_dmg_b,
    buff_a' = buff_a,
    buff_turns_a' = buff_turns_a,
    buff_b' = amt,
    buff_turns_b' = dur,
    poison_a' = poison_a,
    poison_turns_a' = poison_turns_a,
    poison_b' = poison_b,
    poison_turns_b' = poison_turns_b,
    turn' = turn,
    game_over' = game_over,
  }

  action step = any {
    attack_a,
    attack_b,
    nondet dmg = 1.to(5).oneOf()
    nondet dur = 1.to(3).oneOf()
    apply_poison_a(dmg, dur),
    nondet dmg = 1.to(5).oneOf()
    nondet dur = 1.to(3).oneOf()
    apply_poison_b(dmg, dur),
    nondet amt = 1.to(10).oneOf()
    nondet dur = 1.to(3).oneOf()
    apply_buff_a(amt, dur),
    nondet amt = 1.to(10).oneOf()
    nondet dur = 1.to(3).oneOf()
    apply_buff_b(amt, dur),
  }

  /// HP never exceeds initial value (no healing in this module).
  val hp_bounded_by_init: bool = hp_a <= 100 and hp_b <= 100

  /// When effect turns reach 0, the effect value must also be 0.
  val effects_consistent: bool =
    (if (poison_turns_a == 0) poison_a == 0 else true) and
    (if (poison_turns_b == 0) poison_b == 0 else true) and
    (if (buff_turns_a == 0) buff_a == 0 else true) and
    (if (buff_turns_b == 0) buff_b == 0 else true)

  /// Game over only when someone is dead.
  val game_over_correct: bool = game_over.implies(hp_a <= 0 or hp_b <= 0)

  /// Weapon damage never changes mid-combat.
  val weapon_constant: bool = weapon_dmg_a == 25 and weapon_dmg_b == 20
}

module combat_full_run {
  import combat_full.*
}
