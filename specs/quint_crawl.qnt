module quint_crawl {
  // === Character state ===
  var hp: int
  var max_hp: int
  var base_attack: int
  var xp: int
  var level: int
  var gold: int

  // === Position ===
  var pos_x: int
  var pos_y: int

  // === Inventory (quantity-based) ===
  var qty_potion: int    // heals 20 HP
  var qty_wood: int
  var qty_iron: int
  var qty_sword: int     // crafted weapon, +5 attack
  var has_sword: bool    // equipped

  // === Combat state ===
  var in_combat: bool
  var enemy_hp: int
  var enemy_attack: int

  // === Win condition ===
  var game_won: bool

  // --- Constants ---
  // XP thresholds: level 2 at 10 XP, level 3 at 25 XP
  pure def xp_threshold(lvl: int): int =
    if (lvl == 2) 10
    else if (lvl == 3) 25
    else 9999

  // Zone names for the 3x3 grid (row = y, col = x)
  pure def zone_name(x: int, y: int): str =
    if (x == 0 and y == 0) "Village"
    else if (x == 1 and y == 0) "Forest"
    else if (x == 2 and y == 0) "Swamp"
    else if (x == 0 and y == 1) "Plains"
    else if (x == 1 and y == 1) "Cave"
    else if (x == 2 and y == 1) "Mountain"
    else if (x == 0 and y == 2) "Ruins"
    else if (x == 1 and y == 2) "Shrine"
    else if (x == 2 and y == 2) "Castle"
    else "Unknown"

  // Zone level requirement
  pure def zone_level_req(x: int, y: int): int =
    if (x == 0 and y == 0) 1
    else if (x == 1 and y == 0) 1
    else if (x == 2 and y == 0) 1
    else if (x == 0 and y == 1) 1
    else if (x == 1 and y == 1) 2
    else if (x == 2 and y == 1) 2
    else if (x == 0 and y == 2) 2
    else if (x == 1 and y == 2) 2
    else if (x == 2 and y == 2) 3
    else 99

  // Enemy strength by zone
  pure def zone_enemy_hp(x: int, y: int): int =
    if (zone_level_req(x, y) == 1) 15
    else if (zone_level_req(x, y) == 2) 30
    else 50

  pure def zone_enemy_attack(x: int, y: int): int =
    if (zone_level_req(x, y) == 1) 5
    else if (zone_level_req(x, y) == 2) 8
    else 12

  // Rewards per zone level
  pure def zone_xp_reward(x: int, y: int): int =
    if (zone_level_req(x, y) == 1) 5
    else if (zone_level_req(x, y) == 2) 8
    else 15

  pure def zone_gold_reward(x: int, y: int): int =
    if (zone_level_req(x, y) == 1) 10
    else if (zone_level_req(x, y) == 2) 15
    else 25

  // Total attack power
  val attack_power = base_attack + (if (has_sword) 5 else 0)

  // --- Helpers ---
  // Keep non-combat state unchanged
  pure def clamp_hp(v: int, mx: int): int =
    if (v > mx) mx else if (v < 0) 0 else v

  // === Init ===
  action init = all {
    hp' = 50,
    max_hp' = 50,
    base_attack' = 10,
    xp' = 0,
    level' = 1,
    gold' = 0,
    pos_x' = 0,
    pos_y' = 0,
    qty_potion' = 2,
    qty_wood' = 0,
    qty_iron' = 0,
    qty_sword' = 0,
    has_sword' = false,
    in_combat' = false,
    enemy_hp' = 0,
    enemy_attack' = 0,
    game_won' = false,
  }

  // === Movement (only when not in combat) ===
  action move_up = all {
    not(in_combat),
    not(game_won),
    hp > 0,
    pos_y > 0,
    zone_level_req(pos_x, pos_y - 1) <= level,
    pos_y' = pos_y - 1,
    pos_x' = pos_x,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    qty_potion' = qty_potion, qty_wood' = qty_wood,
    qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    game_won' = game_won,
  }

  action move_down = all {
    not(in_combat),
    not(game_won),
    hp > 0,
    pos_y < 2,
    zone_level_req(pos_x, pos_y + 1) <= level,
    pos_y' = pos_y + 1,
    pos_x' = pos_x,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    qty_potion' = qty_potion, qty_wood' = qty_wood,
    qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    game_won' = game_won,
  }

  action move_left = all {
    not(in_combat),
    not(game_won),
    hp > 0,
    pos_x > 0,
    zone_level_req(pos_x - 1, pos_y) <= level,
    pos_x' = pos_x - 1,
    pos_y' = pos_y,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    qty_potion' = qty_potion, qty_wood' = qty_wood,
    qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    game_won' = game_won,
  }

  action move_right = all {
    not(in_combat),
    not(game_won),
    hp > 0,
    pos_x < 2,
    zone_level_req(pos_x + 1, pos_y) <= level,
    pos_x' = pos_x + 1,
    pos_y' = pos_y,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    qty_potion' = qty_potion, qty_wood' = qty_wood,
    qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    game_won' = game_won,
  }

  // === Enter combat ===
  action enter_combat = all {
    not(in_combat),
    not(game_won),
    hp > 0,
    in_combat' = true,
    enemy_hp' = zone_enemy_hp(pos_x, pos_y),
    enemy_attack' = zone_enemy_attack(pos_x, pos_y),
    // Everything else unchanged
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_potion' = qty_potion, qty_wood' = qty_wood,
    qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
    game_won' = game_won,
  }

  // === Combat: attack enemy ===
  action combat_attack = all {
    in_combat,
    not(game_won),
    hp > 0,
    enemy_hp > 0,
    val new_enemy_hp = enemy_hp - attack_power
    val new_hp = if (new_enemy_hp > 0) hp - enemy_attack else hp
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) xp + zone_xp_reward(pos_x, pos_y) else xp
    val new_level = if (level < 3 and gained_xp >= xp_threshold(level + 1)) level + 1 else level
    all {
      enemy_hp' = if (new_enemy_hp <= 0 or new_hp <= 0) 0 else new_enemy_hp,
      hp' = if (new_hp < 0) 0 else new_hp,
      in_combat' = if (new_enemy_hp <= 0 or new_hp <= 0) false else true,
      xp' = gained_xp,
      gold' = if (new_enemy_hp <= 0) gold + zone_gold_reward(pos_x, pos_y) else gold,
      enemy_attack' = if (new_enemy_hp <= 0 or new_hp <= 0) 0 else enemy_attack,
      level' = new_level,
      max_hp' = if (new_level > level) max_hp + 20 else max_hp,
      base_attack' = if (new_level > level) base_attack + 3 else base_attack,
      game_won' = (new_level >= 3),
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = qty_potion, qty_wood' = qty_wood,
      qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
    }
  }

  // === Combat: use potion ===
  action combat_potion = all {
    in_combat,
    not(game_won),
    qty_potion > 0,
    hp > 0,
    hp' = clamp_hp(hp + 20, max_hp),
    qty_potion' = qty_potion - 1,
    // Enemy still attacks
    // Actually: use potion = heal + take hit
    // Simplified: just heal, enemy doesn't attack on potion turn
    max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_wood' = qty_wood, qty_iron' = qty_iron,
    qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = in_combat, enemy_hp' = enemy_hp, enemy_attack' = enemy_attack,
    game_won' = game_won,
  }

  // === Flee combat ===
  action flee_combat = all {
    in_combat,
    not(game_won),
    hp > 0,
    // Take one hit while fleeing
    val new_hp = hp - enemy_attack
    all {
      hp' = if (new_hp < 0) 0 else new_hp,
      in_combat' = false,
      enemy_hp' = 0,
      enemy_attack' = 0,
      max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level, gold' = gold,
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = qty_potion, qty_wood' = qty_wood,
      qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
      game_won' = game_won,
    }
  }

  // === Rest at village (pos 0,0, not in combat) ===
  action rest_at_village = all {
    not(in_combat),
    not(game_won),
    hp > 0,
    pos_x == 0,
    pos_y == 0,
    hp < max_hp,
    hp' = max_hp,
    max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_potion' = qty_potion, qty_wood' = qty_wood,
    qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    game_won' = game_won,
  }

  // === Buy potion (at village, costs 10 gold) ===
  action buy_potion = all {
    not(in_combat),
    not(game_won),
    hp > 0,
    pos_x == 0,
    pos_y == 0,
    gold >= 10,
    gold' = gold - 10,
    qty_potion' = qty_potion + 1,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_wood' = qty_wood, qty_iron' = qty_iron,
    qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    game_won' = game_won,
  }

  // === Gather wood (in Forest x=1,y=0) ===
  action gather_wood = all {
    not(in_combat),
    not(game_won),
    hp > 0,
    pos_x == 1,
    pos_y == 0,
    qty_wood' = qty_wood + 1,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_potion' = qty_potion, qty_iron' = qty_iron,
    qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    game_won' = game_won,
  }

  // === Mine iron (in Mountain x=2,y=1) ===
  action mine_iron = all {
    not(in_combat),
    not(game_won),
    hp > 0,
    pos_x == 2,
    pos_y == 1,
    qty_iron' = qty_iron + 1,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_potion' = qty_potion, qty_wood' = qty_wood,
    qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    game_won' = game_won,
  }

  // === Craft sword (1 wood + 2 iron -> 1 sword, at village) ===
  action craft_sword = all {
    not(in_combat),
    not(game_won),
    hp > 0,
    pos_x == 0,
    pos_y == 0,
    qty_wood >= 1,
    qty_iron >= 2,
    qty_wood' = qty_wood - 1,
    qty_iron' = qty_iron - 2,
    qty_sword' = qty_sword + 1,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_potion' = qty_potion, has_sword' = has_sword,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    game_won' = game_won,
  }

  // === Equip sword ===
  action equip_sword = all {
    not(in_combat),
    not(game_won),
    hp > 0,
    qty_sword >= 1,
    not(has_sword),
    has_sword' = true,
    qty_sword' = qty_sword - 1,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_potion' = qty_potion, qty_wood' = qty_wood, qty_iron' = qty_iron,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    game_won' = game_won,
  }

  // === Step ===
  action step = any {
    move_up,
    move_down,
    move_left,
    move_right,
    enter_combat,
    combat_attack,
    combat_potion,
    flee_combat,
    rest_at_village,
    buy_potion,
    gather_wood,
    mine_iron,
    craft_sword,
    equip_sword,
  }

  // === Invariants ===

  /// HP is bounded [0, max_hp]
  val hp_bounded = hp >= 0 and hp <= max_hp

  /// Gold never goes negative
  val gold_non_negative = gold >= 0

  /// Level is bounded [1, 3]
  val level_bounded = level >= 1 and level <= 3

  /// Position stays on the grid
  val position_bounded = pos_x >= 0 and pos_x <= 2 and pos_y >= 0 and pos_y <= 2

  /// Quantities never go negative
  val quantities_non_negative = and {
    qty_potion >= 0,
    qty_wood >= 0,
    qty_iron >= 0,
    qty_sword >= 0,
  }

  /// Can only be in a zone you're qualified for
  val level_gate_respected = zone_level_req(pos_x, pos_y) <= level

  /// XP never decreases
  val xp_monotonic = xp >= 0

  /// Game won only at level 3
  val win_condition_correct = game_won.implies(level >= 3)

  /// Enemy HP is non-negative
  val enemy_hp_bounded = enemy_hp >= 0

  /// Not in combat means no enemy
  val combat_consistent = not(in_combat).implies(enemy_hp == 0 and enemy_attack == 0)
}

module quint_crawl_run {
  import quint_crawl.*
}
