module companion {
  // Constants
  pure val LOYALTY_GAIN = 5
  pure val LOYALTY_LOSS = 10
  pure val COMPANION_REVIVE_COST = 20
  pure val WOLF_BONUS = 3
  pure val HAWK_DODGE = 1
  pure val TURTLE_ABSORB = 2

  // State vars
  var player_hp: int
  var companion_hp: int
  var companion_max_hp: int
  var companion_alive: bool
  var loyalty: int
  var companion_type: int
  var in_combat: bool
  var enemy_hp: int
  var enemy_attack: int
  var turn_count: int

  action init = all {
    player_hp' = 50,
    companion_hp' = 0,
    companion_max_hp' = 30,
    companion_alive' = false,
    loyalty' = 0,
    companion_type' = 0,
    in_combat' = false,
    enemy_hp' = 0,
    enemy_attack' = 5,
    turn_count' = 0,
  }

  action adopt_companion(ctype: int): bool = all {
    companion_type == 0,
    ctype >= 1,
    ctype <= 3,
    companion_type' = ctype,
    companion_alive' = true,
    companion_hp' = 30,
    companion_max_hp' = 30,
    loyalty' = 50,
    player_hp' = player_hp,
    in_combat' = in_combat,
    enemy_hp' = enemy_hp,
    enemy_attack' = enemy_attack,
    turn_count' = turn_count,
  }

  action feed_companion: bool = all {
    companion_alive,
    loyalty' = if (loyalty + LOYALTY_GAIN > 100) 100 else loyalty + LOYALTY_GAIN,
    player_hp' = player_hp,
    companion_hp' = companion_hp,
    companion_max_hp' = companion_max_hp,
    companion_alive' = companion_alive,
    companion_type' = companion_type,
    in_combat' = in_combat,
    enemy_hp' = enemy_hp,
    enemy_attack' = enemy_attack,
    turn_count' = turn_count,
  }

  action enter_combat: bool = all {
    not(in_combat),
    companion_alive,
    in_combat' = true,
    enemy_hp' = 20,
    enemy_attack' = 5,
    turn_count' = 0,
    player_hp' = player_hp,
    companion_hp' = companion_hp,
    companion_max_hp' = companion_max_hp,
    companion_alive' = companion_alive,
    loyalty' = loyalty,
    companion_type' = companion_type,
  }

  action attack: bool = all {
    in_combat,
    enemy_hp > 0,
    player_hp > 0,
    // Player deals 10 base damage + wolf bonus
    val player_damage = if (companion_alive and companion_type == 1) 10 + WOLF_BONUS else 10
    // Enemy damage to player (hawk dodges some)
    val raw_enemy_dmg = enemy_attack
    val hawk_reduction = if (companion_alive and companion_type == 2) HAWK_DODGE else 0
    val turtle_reduction = if (companion_alive and companion_type == 3) TURTLE_ABSORB else 0
    val damage_to_player = raw_enemy_dmg - hawk_reduction - turtle_reduction
    // Turtle companion takes damage
    val damage_to_companion = if (companion_alive and companion_type == 3) TURTLE_ABSORB else 0
    val new_companion_hp = if (companion_hp - damage_to_companion <= 0) 0 else companion_hp - damage_to_companion
    val companion_dies = companion_alive and new_companion_hp == 0 and damage_to_companion > 0
    val new_enemy_hp = if (enemy_hp - player_damage <= 0) 0 else enemy_hp - player_damage
    all {
      enemy_hp' = new_enemy_hp,
      player_hp' = if (player_hp - damage_to_player <= 0) 0 else player_hp - damage_to_player,
      companion_hp' = new_companion_hp,
      companion_alive' = if (companion_dies) false else companion_alive,
      loyalty' = if (companion_dies) (if (loyalty - LOYALTY_LOSS < 0) 0 else loyalty - LOYALTY_LOSS) else loyalty,
      in_combat' = if (new_enemy_hp == 0) false else in_combat,
      turn_count' = turn_count + 1,
      companion_type' = companion_type,
      companion_max_hp' = companion_max_hp,
      enemy_attack' = enemy_attack,
    }
  }

  action rest: bool = all {
    not(in_combat),
    companion_alive,
    player_hp' = 50,
    companion_hp' = companion_max_hp,
    loyalty' = if (loyalty + LOYALTY_GAIN > 100) 100 else loyalty + LOYALTY_GAIN,
    companion_alive' = companion_alive,
    companion_type' = companion_type,
    companion_max_hp' = companion_max_hp,
    in_combat' = in_combat,
    enemy_hp' = enemy_hp,
    enemy_attack' = enemy_attack,
    turn_count' = turn_count,
  }

  action revive_companion: bool = all {
    not(companion_alive),
    companion_type > 0,
    loyalty >= COMPANION_REVIVE_COST,
    companion_alive' = true,
    companion_hp' = companion_max_hp / 2,
    loyalty' = loyalty - COMPANION_REVIVE_COST,
    player_hp' = player_hp,
    companion_type' = companion_type,
    companion_max_hp' = companion_max_hp,
    in_combat' = in_combat,
    enemy_hp' = enemy_hp,
    enemy_attack' = enemy_attack,
    turn_count' = turn_count,
  }

  action step: bool = {
    nondet ctype = 1.to(3).oneOf()
    any {
      adopt_companion(ctype),
      feed_companion,
      enter_combat,
      attack,
      rest,
      revive_companion,
    }
  }

  // Invariants
  val loyalty_bounded: bool = loyalty >= 0 and loyalty <= 100
  val companion_hp_bounded: bool = companion_hp >= 0 and companion_hp <= companion_max_hp
  val alive_consistent: bool = not(companion_alive) implies (companion_hp == 0)
  val type_bounded: bool = companion_type >= 0 and companion_type <= 3
  val no_companion_no_loyalty: bool = (companion_type == 0) implies (loyalty == 0)
}

module companion_run {
  import companion.*
}
