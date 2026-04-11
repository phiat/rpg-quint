// Quint specification for an Elemental Affinity system
// Rock-paper-scissors damage modifiers with 4 elements:
// Fire > Ice > Lightning > Earth > Fire (circular)
module elemental {
  const INIT_PLAYER_HP: int
  const INIT_ENEMY_HP: int
  const INIT_BASE_DAMAGE: int

  // Element codes: 0=none, 1=fire, 2=ice, 3=lightning, 4=earth
  var player_element: int
  var enemy_element: int
  var player_hp: int
  var enemy_hp: int
  var base_damage: int
  var in_combat: bool

  // --- Pure functions ---

  // True if attacker element beats defender element in the cycle:
  // Fire(1) > Ice(2) > Lightning(3) > Earth(4) > Fire(1)
  pure def is_strong(a: int, d: int): bool = {
    if (a == 1 and d == 2) true
    else if (a == 2 and d == 3) true
    else if (a == 3 and d == 4) true
    else if (a == 4 and d == 1) true
    else false
  }

  // Returns 200 (2x), 50 (0.5x), or 100 (1x)
  pure def damage_multiplier(attacker_elem: int, defender_elem: int): int = {
    if (attacker_elem == 0 or defender_elem == 0) 100
    else if (is_strong(attacker_elem, defender_elem)) 200
    else if (is_strong(defender_elem, attacker_elem)) 50
    else 100
  }

  // Compute effective damage: base * mult / 100, minimum 1
  pure def effective_damage(base: int, mult: int): int = {
    val raw = base * mult / 100
    if (raw < 1) 1 else raw
  }

  // Zone element deterministic by position (simple hash)
  pure def zone_element(pos: int): int = {
    (pos % 4) + 1
  }

  // --- Actions ---

  action init = all {
    player_element' = 0,
    enemy_element' = 0,
    player_hp' = INIT_PLAYER_HP,
    enemy_hp' = INIT_ENEMY_HP,
    base_damage' = INIT_BASE_DAMAGE,
    in_combat' = false,
  }

  // Change player element affinity (e.g. equipping elemental weapon)
  action set_player_element(e: int): bool = all {
    e >= 0,
    e <= 4,
    player_element' = e,
    enemy_element' = enemy_element,
    player_hp' = player_hp,
    enemy_hp' = enemy_hp,
    base_damage' = base_damage,
    in_combat' = in_combat,
  }

  // Enter combat: spawn enemy with zone-appropriate element
  action enter_combat(pos: int): bool = all {
    not(in_combat),
    in_combat' = true,
    enemy_element' = zone_element(pos),
    enemy_hp' = INIT_ENEMY_HP,
    player_element' = player_element,
    player_hp' = player_hp,
    base_damage' = base_damage,
  }

  // Player attacks enemy
  action attack = all {
    in_combat,
    enemy_hp > 0,
    val mult = damage_multiplier(player_element, enemy_element)
    val dmg = effective_damage(base_damage, mult)
    all {
      enemy_hp' = if (enemy_hp - dmg < 0) 0 else enemy_hp - dmg,
      in_combat' = if (enemy_hp - dmg <= 0) false else true,
      player_hp' = player_hp,
      player_element' = player_element,
      enemy_element' = enemy_element,
      base_damage' = base_damage,
    }
  }

  // Enemy attacks player
  action enemy_attack = all {
    in_combat,
    player_hp > 0,
    val mult = damage_multiplier(enemy_element, player_element)
    val dmg = effective_damage(base_damage, mult)
    all {
      player_hp' = if (player_hp - dmg < 0) 0 else player_hp - dmg,
      in_combat' = if (player_hp - dmg <= 0) false else true,
      enemy_hp' = enemy_hp,
      player_element' = player_element,
      enemy_element' = enemy_element,
      base_damage' = base_damage,
    }
  }

  action step = {
    nondet e = 0.to(4).oneOf()
    nondet pos = 0.to(7).oneOf()
    any {
      set_player_element(e),
      enter_combat(pos),
      attack,
      enemy_attack,
    }
  }

  // --- Invariants ---

  val elements_bounded = and {
    player_element >= 0,
    player_element <= 4,
    enemy_element >= 0,
    enemy_element <= 4,
  }

  val hp_non_negative = and {
    player_hp >= 0,
    enemy_hp >= 0,
  }

  // Multiplier always returns 50, 100, or 200
  val multiplier_bounded = {
    val m = damage_multiplier(player_element, enemy_element)
    m == 50 or m == 100 or m == 200
  }

  // If A strong vs B, then B weak vs A (damage_multiplier(B, A) == 50)
  val damage_symmetric = and {
    is_strong(1, 2).implies(damage_multiplier(2, 1) == 50),
    is_strong(2, 3).implies(damage_multiplier(3, 2) == 50),
    is_strong(3, 4).implies(damage_multiplier(4, 3) == 50),
    is_strong(4, 1).implies(damage_multiplier(1, 4) == 50),
  }
}

module elemental_run {
  import elemental(INIT_PLAYER_HP = 100, INIT_ENEMY_HP = 80, INIT_BASE_DAMAGE = 10).*
}
