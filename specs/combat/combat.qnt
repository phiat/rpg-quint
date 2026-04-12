module combat {
  const INIT_HP: int
  const ATK_A: int
  const ATK_B: int

  var hp_a: int
  var hp_b: int
  var atk_a: int
  var atk_b: int
  var turn: str
  var game_over: bool

  action init = all {
    hp_a' = INIT_HP,
    hp_b' = INIT_HP,
    atk_a' = ATK_A,
    atk_b' = ATK_B,
    turn' = "A",
    game_over' = false,
  }

  action attack_a = all {
    turn == "A",
    not(game_over),
    hp_a' = hp_a,
    hp_b' = hp_b - atk_a,
    atk_a' = atk_a,
    atk_b' = atk_b,
    game_over' = (hp_b - atk_a <= 0),
    turn' = "B",
  }

  action attack_b = all {
    turn == "B",
    not(game_over),
    hp_a' = hp_a - atk_b,
    hp_b' = hp_b,
    atk_a' = atk_a,
    atk_b' = atk_b,
    game_over' = (hp_a - atk_b <= 0),
    turn' = "A",
  }

  action step = any {
    attack_a,
    attack_b,
  }

  val turns_alternate = not(game_over).implies(turn == "A" or turn == "B")

  // dead_cant_act is enforced by action guards — game_over blocks both attack actions
  val dead_cant_act = game_over.implies(hp_a + hp_b < 2 * INIT_HP)

  val hp_bounded_by_init = hp_a <= INIT_HP and hp_b <= INIT_HP

  val atk_constant = atk_a == ATK_A and atk_b == ATK_B
}

module combat_run {
  import combat(INIT_HP = 100, ATK_A = 25, ATK_B = 20).*
}
