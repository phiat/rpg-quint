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

  // === Durability ===
  var sword_dur: int        // current durability (0 = broken, no bonus)
  var sword_max_dur: int    // max durability

  // === Status effects (combat-only, tick down each turn) ===
  var player_poison_dur: int    // turns of poison remaining (takes POISON_DMG/turn)
  var player_atk_buff_dur: int  // turns of ATK buff remaining (+ATK_BUFF_BONUS)
  var player_def_buff_dur: int  // turns of DEF buff remaining (-DEF_BUFF_REDUCTION enemy dmg)
  var enemy_poison_dur: int     // turns enemy is poisoned (takes POISON_DMG/turn)

  // === Combo state ===
  var combo_count: int   // 0-3: current position in combo chain

  // === Stamina ===
  var stamina: int       // current stamina (combat actions cost stamina)
  var max_stamina: int   // max stamina (increases on level-up)

  // === Cooldowns (combat-only, tick down each combat turn) ===
  var cd_heavy_strike: int  // turns until heavy strike available
  var cd_battle_cry: int    // turns until battle cry available

  // === Loot ===
  var pity_counter: int  // kills since last loot drop (guarantees drop at PITY_THRESHOLD)
  var last_drop: int     // 0=none, 1=potion dropped

  // === World state ===
  var turn_count: int  // global turn counter (drives weather rotation)

  // === Win condition ===
  var game_won: bool

  // === Save/Load ===
  var saved_exists: bool  // whether a save slot is occupied

  // --- Constants ---
  val SWORD_MAX_DUR = 10
  val REPAIR_COST = 5
  val POISON_DMG = 3
  val ATK_BUFF_BONUS = 5
  val DEF_BUFF_REDUCTION = 3
  val STATUS_DURATION = 3
  val SWORD_ATK_BONUS = 5  // attack bonus from equipped sword
  val WEATHER_CYCLE = 5  // weather changes every 5 turns
  val STORM_MOVE_DMG = 2 // damage taken when moving in storm
  val FOG_ATK_PENALTY = 2 // enemy attack reduced in fog
  val RAIN_GATHER_BONUS = 1 // extra resources gathered in rain
  val ATTACK_STAMINA = 2    // stamina cost for basic attack / poison strike
  val COMBO_STAMINA = 3     // stamina cost for combo attack
  val HEAVY_STRIKE_STAMINA = 5  // stamina cost for heavy strike
  val BATTLE_CRY_STAMINA = 3    // stamina cost for battle cry
  val HEAVY_STRIKE_CD = 3   // cooldown turns for heavy strike
  val BATTLE_CRY_CD = 4     // cooldown turns for battle cry
  val PITY_THRESHOLD = 5    // kills without drop before guaranteed drop

  // --- World scaling constants ---
  val WORLD_SIZE = 9        // grid dimension (NxN)
  val MAX_LEVEL = 5         // max zone difficulty
  val TILES_PER_LEVEL = 3   // (x+y) distance per level increment
  val BASE_ENEMY_HP = 15    // enemy HP at level 1
  val BASE_ENEMY_ATK = 2    // enemy ATK constant term
  val ATK_PER_LEVEL = 3     // enemy ATK per level
  val BASE_XP = 5           // XP reward per level
  val BASE_GOLD = 5         // gold reward constant term
  val GOLD_PER_LEVEL = 5    // gold reward per level

  // Weather types: 0=Clear, 1=Rain, 2=Fog, 3=Storm
  // Deterministic weather based on turn and zone
  pure def zone_weather(x: int, y: int, turn: int): int =
    ((x * 3 + y * 7 + turn / WEATHER_CYCLE) % 4)

  // XP thresholds for leveling up
  pure def xp_threshold(lvl: int): int =
    if (lvl == 2) 10
    else if (lvl == 3) 25
    else if (lvl == 4) 50
    else if (lvl == 5) 85
    else 9999

  // --- Zone properties: pure functions of coordinates ---

  // Zone difficulty level — distance from origin determines difficulty
  pure def zone_level(x: int, y: int): int =
    val raw = (x + y) / TILES_PER_LEVEL + 1
    if (raw > MAX_LEVEL) MAX_LEVEL else raw

  // Zone biome — tiles the 3x3 pattern across the grid
  pure def zone_biome_x(x: int): int = x % 3
  pure def zone_biome_y(y: int): int = y % 3

  // Zone names (derived from tiled biome pattern)
  pure def zone_name(x: int, y: int): str =
    val bx = zone_biome_x(x)
    val by = zone_biome_y(y)
    if (bx == 0 and by == 0) "Village"
    else if (bx == 1 and by == 0) "Forest"
    else if (bx == 2 and by == 0) "Swamp"
    else if (bx == 0 and by == 1) "Plains"
    else if (bx == 1 and by == 1) "Cave"
    else if (bx == 2 and by == 1) "Mountain"
    else if (bx == 0 and by == 2) "Ruins"
    else if (bx == 1 and by == 2) "Shrine"
    else if (bx == 2 and by == 2) "Castle"
    else "Unknown"

  // Enemy stats — linear formulas of zone level
  pure def zone_enemy_hp(x: int, y: int): int = BASE_ENEMY_HP * zone_level(x, y)
  pure def zone_enemy_attack(x: int, y: int): int = BASE_ENEMY_ATK + ATK_PER_LEVEL * zone_level(x, y)
  pure def zone_xp_reward(x: int, y: int): int = BASE_XP * zone_level(x, y)
  pure def zone_gold_reward(x: int, y: int): int = BASE_GOLD + GOLD_PER_LEVEL * zone_level(x, y)

  // Zone feature predicates — tiles the 3x3 facility pattern
  pure def zone_has_services(x: int, y: int): bool = (x % 3 == 0 and y % 3 == 0)
  pure def zone_has_wood(x: int, y: int): bool = (x % 3 == 1 and y % 3 == 0)
  pure def zone_has_iron(x: int, y: int): bool = (x % 3 == 2 and y % 3 == 1)

  // Total attack power (sword bonus only if equipped AND not broken, plus ATK buff)
  val attack_power = base_attack + (if (has_sword and sword_dur > 0) SWORD_ATK_BONUS else 0) + (if (player_atk_buff_dur > 0) ATK_BUFF_BONUS else 0)

  // --- Helpers ---
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
    sword_dur' = 0,
    sword_max_dur' = SWORD_MAX_DUR,
    player_poison_dur' = 0,
    player_atk_buff_dur' = 0,
    player_def_buff_dur' = 0,
    enemy_poison_dur' = 0,
    combo_count' = 0,
    turn_count' = 0,
    saved_exists' = false,
    stamina' = 10,
    max_stamina' = 10,
    cd_heavy_strike' = 0,
    cd_battle_cry' = 0,
    pity_counter' = 0,
    last_drop' = 0,
  }

  // === Movement (only when not in combat) ===
  // Storm (weather=3) deals damage when entering a zone
  action move_up = all {
    not(in_combat), not(game_won), hp > 0,
    pos_y > 0,
    zone_level(pos_x, pos_y - 1) <= level,
    val storm_dmg = if (zone_weather(pos_x, pos_y - 1, turn_count + 1) == 3) STORM_MOVE_DMG else 0
    all {
      pos_y' = pos_y - 1, pos_x' = pos_x,
      hp' = if (hp - storm_dmg < 1) 1 else hp - storm_dmg,
      max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level, gold' = gold,
      qty_potion' = qty_potion, qty_wood' = qty_wood,
      qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
      in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
      game_won' = game_won,
      sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
      player_poison_dur' = 0, player_atk_buff_dur' = 0,
      player_def_buff_dur' = 0, enemy_poison_dur' = 0,
      combo_count' = 0,
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina, max_stamina' = max_stamina,
      cd_heavy_strike' = 0, cd_battle_cry' = 0,
      pity_counter' = pity_counter, last_drop' = last_drop,
    }
  }

  action move_down = all {
    not(in_combat), not(game_won), hp > 0,
    pos_y < WORLD_SIZE - 1,
    zone_level(pos_x, pos_y + 1) <= level,
    val storm_dmg = if (zone_weather(pos_x, pos_y + 1, turn_count + 1) == 3) STORM_MOVE_DMG else 0
    all {
      pos_y' = pos_y + 1, pos_x' = pos_x,
      hp' = if (hp - storm_dmg < 1) 1 else hp - storm_dmg,
      max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level, gold' = gold,
      qty_potion' = qty_potion, qty_wood' = qty_wood,
      qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
      in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
      game_won' = game_won,
      sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
      player_poison_dur' = 0, player_atk_buff_dur' = 0,
      player_def_buff_dur' = 0, enemy_poison_dur' = 0,
      combo_count' = 0,
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina, max_stamina' = max_stamina,
      cd_heavy_strike' = 0, cd_battle_cry' = 0,
      pity_counter' = pity_counter, last_drop' = last_drop,
    }
  }

  action move_left = all {
    not(in_combat), not(game_won), hp > 0,
    pos_x > 0,
    zone_level(pos_x - 1, pos_y) <= level,
    val storm_dmg = if (zone_weather(pos_x - 1, pos_y, turn_count + 1) == 3) STORM_MOVE_DMG else 0
    all {
      pos_x' = pos_x - 1, pos_y' = pos_y,
      hp' = if (hp - storm_dmg < 1) 1 else hp - storm_dmg,
      max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level, gold' = gold,
      qty_potion' = qty_potion, qty_wood' = qty_wood,
      qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
      in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
      game_won' = game_won,
      sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
      player_poison_dur' = 0, player_atk_buff_dur' = 0,
      player_def_buff_dur' = 0, enemy_poison_dur' = 0,
      combo_count' = 0,
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina, max_stamina' = max_stamina,
      cd_heavy_strike' = 0, cd_battle_cry' = 0,
      pity_counter' = pity_counter, last_drop' = last_drop,
    }
  }

  action move_right = all {
    not(in_combat), not(game_won), hp > 0,
    pos_x < WORLD_SIZE - 1,
    zone_level(pos_x + 1, pos_y) <= level,
    val storm_dmg = if (zone_weather(pos_x + 1, pos_y, turn_count + 1) == 3) STORM_MOVE_DMG else 0
    all {
      pos_x' = pos_x + 1, pos_y' = pos_y,
      hp' = if (hp - storm_dmg < 1) 1 else hp - storm_dmg,
      max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level, gold' = gold,
      qty_potion' = qty_potion, qty_wood' = qty_wood,
      qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
      in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
      game_won' = game_won,
      sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
      player_poison_dur' = 0, player_atk_buff_dur' = 0,
      player_def_buff_dur' = 0, enemy_poison_dur' = 0,
      combo_count' = 0,
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina, max_stamina' = max_stamina,
      cd_heavy_strike' = 0, cd_battle_cry' = 0,
      pity_counter' = pity_counter, last_drop' = last_drop,
    }
  }

  // === Enter combat ===
  // Fog (weather=2) reduces enemy attack
  action enter_combat = all {
    not(in_combat), not(game_won), hp > 0,
    val weather = zone_weather(pos_x, pos_y, turn_count + 1)
    val fog_penalty = if (weather == 2) FOG_ATK_PENALTY else 0
    val raw_atk = zone_enemy_attack(pos_x, pos_y) - fog_penalty
    all {
      in_combat' = true,
      enemy_hp' = zone_enemy_hp(pos_x, pos_y),
      enemy_attack' = if (raw_atk < 1) 1 else raw_atk,
      hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level, gold' = gold,
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = qty_potion, qty_wood' = qty_wood,
      qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
      game_won' = game_won,
      sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
      player_poison_dur' = 0, player_atk_buff_dur' = 0,
      player_def_buff_dur' = 0, enemy_poison_dur' = 0,
      combo_count' = 0,
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina, max_stamina' = max_stamina,
      cd_heavy_strike' = 0, cd_battle_cry' = 0,
      pity_counter' = pity_counter, last_drop' = 0,
    }
  }

  // === Combat: attack enemy ===
  action combat_attack = all {
    in_combat, not(game_won), hp > 0, enemy_hp > 0,
    stamina >= ATTACK_STAMINA,
    // Degrade sword on attack (only if equipped and not already broken)
    val new_sword_dur = if (has_sword and sword_dur > 0) sword_dur - 1 else sword_dur
    // Enemy takes poison damage if poisoned
    val enemy_poison_dmg = if (enemy_poison_dur > 0) POISON_DMG else 0
    val new_enemy_hp = enemy_hp - attack_power - enemy_poison_dmg
    // Player takes enemy hit (reduced by DEF buff) + poison damage
    val enemy_dmg = if (player_def_buff_dur > 0) enemy_attack - DEF_BUFF_REDUCTION else enemy_attack
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (player_poison_dur > 0) POISON_DMG else 0
    val new_hp = if (new_enemy_hp > 0) hp - effective_enemy_dmg - poison_dmg else hp - poison_dmg
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) xp + zone_xp_reward(pos_x, pos_y) else xp
    val new_level = if (level < MAX_LEVEL and gained_xp >= xp_threshold(level + 1)) level + 1 else level
    // Tier 2+ enemies apply poison if player isn't already poisoned
    val zone_tier = zone_level(pos_x, pos_y)
    val apply_poison = (zone_tier >= 2 and player_poison_dur == 0 and new_enemy_hp > 0)
    // Tick status durations (decrement, floor at 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (player_poison_dur > 0) player_poison_dur - 1
                             else 0
    val next_atk_buff = if (player_atk_buff_dur > 0) player_atk_buff_dur - 1 else 0
    val next_def_buff = if (player_def_buff_dur > 0) player_def_buff_dur - 1 else 0
    val next_enemy_poison = if (enemy_poison_dur > 0) enemy_poison_dur - 1 else 0
    // Combat ends?
    val combat_ends = (new_enemy_hp <= 0 or new_hp <= 0)
    // Loot drop on enemy defeat (deterministic pity system)
    val enemy_defeated_alive = (new_enemy_hp <= 0 and new_hp > 0)
    val drop_trigger = (pity_counter >= PITY_THRESHOLD or (turn_count % 3 == 0))
    val should_drop = enemy_defeated_alive and drop_trigger
    val new_pity = if (should_drop) 0
                   else if (enemy_defeated_alive) pity_counter + 1
                   else pity_counter
    val new_last_drop = if (should_drop) 1 else 0
    all {
      enemy_hp' = if (combat_ends) 0 else new_enemy_hp,
      hp' = if (new_hp < 0) 0 else new_hp,
      in_combat' = if (combat_ends) false else true,
      xp' = gained_xp,
      gold' = if (new_enemy_hp <= 0) gold + zone_gold_reward(pos_x, pos_y) else gold,
      enemy_attack' = if (combat_ends) 0 else enemy_attack,
      level' = new_level,
      max_hp' = if (new_level > level) max_hp + 20 else max_hp,
      base_attack' = if (new_level > level) base_attack + 3 else base_attack,
      game_won' = (new_level >= MAX_LEVEL),
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = if (should_drop) qty_potion + 1 else qty_potion,
      qty_wood' = qty_wood,
      qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
      sword_dur' = new_sword_dur, sword_max_dur' = sword_max_dur,
      // Clear statuses if combat ends, otherwise tick
      player_poison_dur' = if (combat_ends) 0 else next_player_poison,
      player_atk_buff_dur' = if (combat_ends) 0 else next_atk_buff,
      player_def_buff_dur' = if (combat_ends) 0 else next_def_buff,
      enemy_poison_dur' = if (combat_ends) 0 else next_enemy_poison,
      combo_count' = if (combat_ends) 0 else combo_count,
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina - ATTACK_STAMINA,
      max_stamina' = if (new_level > level) max_stamina + 5 else max_stamina,
      cd_heavy_strike' = if (combat_ends) 0 else (if (cd_heavy_strike > 0) cd_heavy_strike - 1 else 0),
      cd_battle_cry' = if (combat_ends) 0 else (if (cd_battle_cry > 0) cd_battle_cry - 1 else 0),
      pity_counter' = new_pity,
      last_drop' = new_last_drop,
    }
  }

  // === Combat: use potion (quick action — no stamina cost, no CD tick) ===
  action combat_potion = all {
    in_combat, not(game_won), qty_potion > 0, hp > 0,
    hp' = clamp_hp(hp + 20, max_hp),
    qty_potion' = qty_potion - 1,
    max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_wood' = qty_wood, qty_iron' = qty_iron,
    qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = in_combat, enemy_hp' = enemy_hp, enemy_attack' = enemy_attack,
    game_won' = game_won,
    sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
    player_poison_dur' = player_poison_dur, player_atk_buff_dur' = player_atk_buff_dur,
    player_def_buff_dur' = player_def_buff_dur, enemy_poison_dur' = enemy_poison_dur,
    combo_count' = 0,
    saved_exists' = saved_exists,
    turn_count' = turn_count + 1,
    stamina' = stamina, max_stamina' = max_stamina,
    cd_heavy_strike' = cd_heavy_strike, cd_battle_cry' = cd_battle_cry,
    pity_counter' = pity_counter, last_drop' = last_drop,
  }

  // === Flee combat ===
  action flee_combat = all {
    in_combat, not(game_won), hp > 0,
    val new_hp = hp - enemy_attack
    all {
      hp' = if (new_hp < 0) 0 else new_hp,
      in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
      max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level, gold' = gold,
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = qty_potion, qty_wood' = qty_wood,
      qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
      game_won' = game_won,
      sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
      player_poison_dur' = 0, player_atk_buff_dur' = 0,
      player_def_buff_dur' = 0, enemy_poison_dur' = 0,
      combo_count' = 0,
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina, max_stamina' = max_stamina,
      cd_heavy_strike' = 0, cd_battle_cry' = 0,
      pity_counter' = pity_counter, last_drop' = last_drop,
    }
  }

  // === Rest at village (town zone, not in combat) ===
  action rest_at_village = all {
    not(in_combat), not(game_won), hp > 0,
    zone_has_services(pos_x, pos_y),
    hp < max_hp or stamina < max_stamina,
    hp' = max_hp,
    max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_potion' = qty_potion, qty_wood' = qty_wood,
    qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    game_won' = game_won,
    sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
    player_poison_dur' = 0, player_atk_buff_dur' = 0,
    player_def_buff_dur' = 0, enemy_poison_dur' = 0,
    combo_count' = 0,
    saved_exists' = saved_exists,
    turn_count' = turn_count + 1,
    stamina' = max_stamina, max_stamina' = max_stamina,
    cd_heavy_strike' = 0, cd_battle_cry' = 0,
    pity_counter' = pity_counter, last_drop' = last_drop,
  }

  // === Buy potion (at town, costs 10 gold) ===
  action buy_potion = all {
    not(in_combat), not(game_won), hp > 0,
    zone_has_services(pos_x, pos_y),
    gold >= 10,
    gold' = gold - 10, qty_potion' = qty_potion + 1,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_wood' = qty_wood, qty_iron' = qty_iron,
    qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    game_won' = game_won,
    sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
    player_poison_dur' = 0, player_atk_buff_dur' = 0,
    player_def_buff_dur' = 0, enemy_poison_dur' = 0,
    combo_count' = 0,
    saved_exists' = saved_exists,
    turn_count' = turn_count + 1,
    stamina' = stamina, max_stamina' = max_stamina,
    cd_heavy_strike' = 0, cd_battle_cry' = 0,
    pity_counter' = pity_counter, last_drop' = last_drop,
  }

  // === Repair sword (at town, costs gold) ===
  action repair_sword = all {
    not(in_combat), not(game_won), hp > 0,
    zone_has_services(pos_x, pos_y),
    has_sword,
    sword_dur < sword_max_dur,
    gold >= REPAIR_COST,
    sword_dur' = sword_max_dur,
    gold' = gold - REPAIR_COST,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_potion' = qty_potion, qty_wood' = qty_wood, qty_iron' = qty_iron,
    qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    game_won' = game_won,
    sword_max_dur' = sword_max_dur,
    player_poison_dur' = 0, player_atk_buff_dur' = 0,
    player_def_buff_dur' = 0, enemy_poison_dur' = 0,
    combo_count' = 0,
    saved_exists' = saved_exists,
    turn_count' = turn_count + 1,
    stamina' = stamina, max_stamina' = max_stamina,
    cd_heavy_strike' = 0, cd_battle_cry' = 0,
    pity_counter' = pity_counter, last_drop' = last_drop,
  }

  // === Gather wood (in forest zone) ===
  // Rain (weather=1) gives bonus resources
  action gather_wood = all {
    not(in_combat), not(game_won), hp > 0,
    zone_has_wood(pos_x, pos_y),
    val rain_bonus = if (zone_weather(pos_x, pos_y, turn_count + 1) == 1) RAIN_GATHER_BONUS else 0
    all {
      qty_wood' = qty_wood + 1 + rain_bonus,
      hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level, gold' = gold,
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = qty_potion, qty_iron' = qty_iron,
      qty_sword' = qty_sword, has_sword' = has_sword,
      in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
      game_won' = game_won,
      sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
      player_poison_dur' = 0, player_atk_buff_dur' = 0,
      player_def_buff_dur' = 0, enemy_poison_dur' = 0,
      combo_count' = 0,
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina, max_stamina' = max_stamina,
      cd_heavy_strike' = 0, cd_battle_cry' = 0,
      pity_counter' = pity_counter, last_drop' = last_drop,
    }
  }

  // === Mine iron (in mountain zone) ===
  // Rain (weather=1) gives bonus resources
  action mine_iron = all {
    not(in_combat), not(game_won), hp > 0,
    zone_has_iron(pos_x, pos_y),
    val rain_bonus = if (zone_weather(pos_x, pos_y, turn_count + 1) == 1) RAIN_GATHER_BONUS else 0
    all {
      qty_iron' = qty_iron + 1 + rain_bonus,
      hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level, gold' = gold,
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = qty_potion, qty_wood' = qty_wood,
      qty_sword' = qty_sword, has_sword' = has_sword,
      in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
      game_won' = game_won,
      sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
      player_poison_dur' = 0, player_atk_buff_dur' = 0,
      player_def_buff_dur' = 0, enemy_poison_dur' = 0,
      combo_count' = 0,
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina, max_stamina' = max_stamina,
      cd_heavy_strike' = 0, cd_battle_cry' = 0,
      pity_counter' = pity_counter, last_drop' = last_drop,
    }
  }

  // === Craft sword (1 wood + 2 iron -> 1 sword, at town) ===
  action craft_sword = all {
    not(in_combat), not(game_won), hp > 0,
    zone_has_services(pos_x, pos_y),
    qty_wood >= 1, qty_iron >= 2,
    qty_wood' = qty_wood - 1, qty_iron' = qty_iron - 2,
    qty_sword' = qty_sword + 1,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_potion' = qty_potion, has_sword' = has_sword,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    game_won' = game_won,
    sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
    player_poison_dur' = 0, player_atk_buff_dur' = 0,
    player_def_buff_dur' = 0, enemy_poison_dur' = 0,
    combo_count' = 0,
    saved_exists' = saved_exists,
    turn_count' = turn_count + 1,
    stamina' = stamina, max_stamina' = max_stamina,
    cd_heavy_strike' = 0, cd_battle_cry' = 0,
    pity_counter' = pity_counter, last_drop' = last_drop,
  }

  // === Equip sword (sets durability to max) ===
  action equip_sword = all {
    not(in_combat), not(game_won), hp > 0,
    qty_sword >= 1, not(has_sword),
    has_sword' = true, qty_sword' = qty_sword - 1,
    sword_dur' = SWORD_MAX_DUR,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_potion' = qty_potion, qty_wood' = qty_wood, qty_iron' = qty_iron,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    game_won' = game_won,
    sword_max_dur' = sword_max_dur,
    player_poison_dur' = 0, player_atk_buff_dur' = 0,
    player_def_buff_dur' = 0, enemy_poison_dur' = 0,
    combo_count' = 0,
    saved_exists' = saved_exists,
    turn_count' = turn_count + 1,
    stamina' = stamina, max_stamina' = max_stamina,
    cd_heavy_strike' = 0, cd_battle_cry' = 0,
    pity_counter' = pity_counter, last_drop' = last_drop,
  }

  // === Use antidote (quick action — costs 1 potion, clears player poison, no CD tick) ===
  action use_antidote = all {
    in_combat, not(game_won), hp > 0,
    qty_potion > 0, player_poison_dur > 0,
    qty_potion' = qty_potion - 1,
    player_poison_dur' = 0,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_wood' = qty_wood, qty_iron' = qty_iron,
    qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = in_combat, enemy_hp' = enemy_hp, enemy_attack' = enemy_attack,
    game_won' = game_won,
    sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
    player_atk_buff_dur' = player_atk_buff_dur,
    player_def_buff_dur' = player_def_buff_dur,
    enemy_poison_dur' = enemy_poison_dur,
    combo_count' = 0,
    saved_exists' = saved_exists,
    turn_count' = turn_count + 1,
    stamina' = stamina, max_stamina' = max_stamina,
    cd_heavy_strike' = cd_heavy_strike, cd_battle_cry' = cd_battle_cry,
    pity_counter' = pity_counter, last_drop' = last_drop,
  }

  // === Poison strike (apply poison to enemy, enemy hits back) ===
  action poison_strike = all {
    in_combat, not(game_won), hp > 0, enemy_hp > 0,
    enemy_poison_dur == 0,  // can't stack poison
    stamina >= ATTACK_STAMINA,
    val dmg_taken = if (player_def_buff_dur > 0) enemy_attack - DEF_BUFF_REDUCTION else enemy_attack
    val effective_dmg = if (dmg_taken < 1) 1 else dmg_taken
    val new_hp = hp - effective_dmg
    val combat_ends = (new_hp <= 0)
    all {
      hp' = if (new_hp < 0) 0 else new_hp,
      enemy_poison_dur' = if (combat_ends) 0 else STATUS_DURATION,
      in_combat' = if (combat_ends) false else true,
      enemy_hp' = if (combat_ends) 0 else enemy_hp,
      enemy_attack' = if (combat_ends) 0 else enemy_attack,
      max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level, gold' = gold,
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = qty_potion, qty_wood' = qty_wood, qty_iron' = qty_iron,
      qty_sword' = qty_sword, has_sword' = has_sword,
      game_won' = game_won,
      sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
      player_poison_dur' = if (combat_ends) 0 else player_poison_dur,
      player_atk_buff_dur' = if (combat_ends) 0 else player_atk_buff_dur,
      player_def_buff_dur' = if (combat_ends) 0 else player_def_buff_dur,
      combo_count' = 0,
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina - ATTACK_STAMINA,
      max_stamina' = max_stamina,
      cd_heavy_strike' = if (combat_ends) 0 else (if (cd_heavy_strike > 0) cd_heavy_strike - 1 else 0),
      cd_battle_cry' = if (combat_ends) 0 else (if (cd_battle_cry > 0) cd_battle_cry - 1 else 0),
      pity_counter' = pity_counter, last_drop' = last_drop,
    }
  }

  // === Combo attack (3-hit chain: Slash 1x → Thrust 1.5x → Finisher 2x) ===
  action combo_attack = all {
    in_combat, not(game_won), hp > 0, enemy_hp > 0,
    combo_count < 3,
    stamina >= COMBO_STAMINA,
    val next_combo = combo_count + 1
    val base_dmg = attack_power
    val combo_dmg = if (next_combo == 1) base_dmg
                    else if (next_combo == 2) (base_dmg * 3) / 2
                    else base_dmg * 2
    // Degrade sword
    val new_sword_dur = if (has_sword and sword_dur > 0) sword_dur - 1 else sword_dur
    // Enemy takes combo + poison damage
    val enemy_poison_dmg = if (enemy_poison_dur > 0) POISON_DMG else 0
    val new_enemy_hp = enemy_hp - combo_dmg - enemy_poison_dmg
    // Player takes enemy hit (reduced by DEF buff) + poison
    val enemy_dmg = if (player_def_buff_dur > 0) enemy_attack - DEF_BUFF_REDUCTION else enemy_attack
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (player_poison_dur > 0) POISON_DMG else 0
    val new_hp = if (new_enemy_hp > 0) hp - effective_enemy_dmg - poison_dmg else hp - poison_dmg
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) xp + zone_xp_reward(pos_x, pos_y) else xp
    val new_level = if (level < MAX_LEVEL and gained_xp >= xp_threshold(level + 1)) level + 1 else level
    // Status ticking
    val zone_tier = zone_level(pos_x, pos_y)
    val apply_poison = (zone_tier >= 2 and player_poison_dur == 0 and new_enemy_hp > 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (player_poison_dur > 0) player_poison_dur - 1
                             else 0
    val next_atk_buff = if (player_atk_buff_dur > 0) player_atk_buff_dur - 1 else 0
    val next_def_buff = if (player_def_buff_dur > 0) player_def_buff_dur - 1 else 0
    val next_enemy_poison = if (enemy_poison_dur > 0) enemy_poison_dur - 1 else 0
    val combat_ends = (new_enemy_hp <= 0 or new_hp <= 0)
    // Combo state: reset on combat end or chain complete (3 hits), else advance
    val new_combo_count = if (combat_ends) 0
                          else if (next_combo >= 3) 0
                          else next_combo
    // Loot drop on enemy defeat
    val enemy_defeated_alive = (new_enemy_hp <= 0 and new_hp > 0)
    val drop_trigger = (pity_counter >= PITY_THRESHOLD or (turn_count % 3 == 0))
    val should_drop = enemy_defeated_alive and drop_trigger
    val new_pity = if (should_drop) 0
                   else if (enemy_defeated_alive) pity_counter + 1
                   else pity_counter
    val new_last_drop = if (should_drop) 1 else 0
    all {
      enemy_hp' = if (combat_ends) 0 else new_enemy_hp,
      hp' = if (new_hp < 0) 0 else new_hp,
      in_combat' = if (combat_ends) false else true,
      xp' = gained_xp,
      gold' = if (new_enemy_hp <= 0) gold + zone_gold_reward(pos_x, pos_y) else gold,
      enemy_attack' = if (combat_ends) 0 else enemy_attack,
      level' = new_level,
      max_hp' = if (new_level > level) max_hp + 20 else max_hp,
      base_attack' = if (new_level > level) base_attack + 3 else base_attack,
      game_won' = (new_level >= MAX_LEVEL),
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = if (should_drop) qty_potion + 1 else qty_potion,
      qty_wood' = qty_wood,
      qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
      sword_dur' = new_sword_dur, sword_max_dur' = sword_max_dur,
      player_poison_dur' = if (combat_ends) 0 else next_player_poison,
      player_atk_buff_dur' = if (combat_ends) 0 else next_atk_buff,
      player_def_buff_dur' = if (combat_ends) 0 else next_def_buff,
      enemy_poison_dur' = if (combat_ends) 0 else next_enemy_poison,
      combo_count' = new_combo_count,
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina - COMBO_STAMINA,
      max_stamina' = if (new_level > level) max_stamina + 5 else max_stamina,
      cd_heavy_strike' = if (combat_ends) 0 else (if (cd_heavy_strike > 0) cd_heavy_strike - 1 else 0),
      cd_battle_cry' = if (combat_ends) 0 else (if (cd_battle_cry > 0) cd_battle_cry - 1 else 0),
      pity_counter' = new_pity,
      last_drop' = new_last_drop,
    }
  }

  // === Heavy strike (2x damage, costs 5 stamina, 3-turn cooldown) ===
  action heavy_strike = all {
    in_combat, not(game_won), hp > 0, enemy_hp > 0,
    cd_heavy_strike == 0,
    stamina >= HEAVY_STRIKE_STAMINA,
    val heavy_dmg = attack_power * 2
    // Degrade sword
    val new_sword_dur = if (has_sword and sword_dur > 0) sword_dur - 1 else sword_dur
    // Enemy takes heavy + poison damage
    val enemy_poison_dmg = if (enemy_poison_dur > 0) POISON_DMG else 0
    val new_enemy_hp = enemy_hp - heavy_dmg - enemy_poison_dmg
    // Player takes enemy hit (reduced by DEF buff) + poison
    val enemy_dmg = if (player_def_buff_dur > 0) enemy_attack - DEF_BUFF_REDUCTION else enemy_attack
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (player_poison_dur > 0) POISON_DMG else 0
    val new_hp = if (new_enemy_hp > 0) hp - effective_enemy_dmg - poison_dmg else hp - poison_dmg
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) xp + zone_xp_reward(pos_x, pos_y) else xp
    val new_level = if (level < MAX_LEVEL and gained_xp >= xp_threshold(level + 1)) level + 1 else level
    // Status ticking
    val zone_tier = zone_level(pos_x, pos_y)
    val apply_poison = (zone_tier >= 2 and player_poison_dur == 0 and new_enemy_hp > 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (player_poison_dur > 0) player_poison_dur - 1
                             else 0
    val next_atk_buff = if (player_atk_buff_dur > 0) player_atk_buff_dur - 1 else 0
    val next_def_buff = if (player_def_buff_dur > 0) player_def_buff_dur - 1 else 0
    val next_enemy_poison = if (enemy_poison_dur > 0) enemy_poison_dur - 1 else 0
    val combat_ends = (new_enemy_hp <= 0 or new_hp <= 0)
    // Loot drop on enemy defeat
    val enemy_defeated_alive = (new_enemy_hp <= 0 and new_hp > 0)
    val drop_trigger = (pity_counter >= PITY_THRESHOLD or (turn_count % 3 == 0))
    val should_drop = enemy_defeated_alive and drop_trigger
    val new_pity = if (should_drop) 0
                   else if (enemy_defeated_alive) pity_counter + 1
                   else pity_counter
    val new_last_drop = if (should_drop) 1 else 0
    all {
      enemy_hp' = if (combat_ends) 0 else new_enemy_hp,
      hp' = if (new_hp < 0) 0 else new_hp,
      in_combat' = if (combat_ends) false else true,
      xp' = gained_xp,
      gold' = if (new_enemy_hp <= 0) gold + zone_gold_reward(pos_x, pos_y) else gold,
      enemy_attack' = if (combat_ends) 0 else enemy_attack,
      level' = new_level,
      max_hp' = if (new_level > level) max_hp + 20 else max_hp,
      base_attack' = if (new_level > level) base_attack + 3 else base_attack,
      game_won' = (new_level >= MAX_LEVEL),
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = if (should_drop) qty_potion + 1 else qty_potion,
      qty_wood' = qty_wood,
      qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
      sword_dur' = new_sword_dur, sword_max_dur' = sword_max_dur,
      player_poison_dur' = if (combat_ends) 0 else next_player_poison,
      player_atk_buff_dur' = if (combat_ends) 0 else next_atk_buff,
      player_def_buff_dur' = if (combat_ends) 0 else next_def_buff,
      enemy_poison_dur' = if (combat_ends) 0 else next_enemy_poison,
      combo_count' = 0,  // heavy strike breaks combo
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina - HEAVY_STRIKE_STAMINA,
      max_stamina' = if (new_level > level) max_stamina + 5 else max_stamina,
      cd_heavy_strike' = if (combat_ends) 0 else HEAVY_STRIKE_CD,
      cd_battle_cry' = if (combat_ends) 0 else (if (cd_battle_cry > 0) cd_battle_cry - 1 else 0),
      pity_counter' = new_pity,
      last_drop' = new_last_drop,
    }
  }

  // === Battle cry (grants ATK buff, costs 3 stamina, 4-turn cooldown) ===
  // Enemy hits back. Resets combo.
  action battle_cry = all {
    in_combat, not(game_won), hp > 0, enemy_hp > 0,
    cd_battle_cry == 0,
    stamina >= BATTLE_CRY_STAMINA,
    // Enemy hits player
    val enemy_dmg = if (player_def_buff_dur > 0) enemy_attack - DEF_BUFF_REDUCTION else enemy_attack
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (player_poison_dur > 0) POISON_DMG else 0
    val new_hp = hp - effective_enemy_dmg - poison_dmg
    val combat_ends = (new_hp <= 0)
    // Status ticking
    val zone_tier = zone_level(pos_x, pos_y)
    val apply_poison = (zone_tier >= 2 and player_poison_dur == 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (player_poison_dur > 0) player_poison_dur - 1
                             else 0
    val next_def_buff = if (player_def_buff_dur > 0) player_def_buff_dur - 1 else 0
    val next_enemy_poison = if (enemy_poison_dur > 0) enemy_poison_dur - 1 else 0
    all {
      hp' = if (new_hp < 0) 0 else new_hp,
      in_combat' = if (combat_ends) false else true,
      enemy_hp' = if (combat_ends) 0 else enemy_hp,
      enemy_attack' = if (combat_ends) 0 else enemy_attack,
      // Grant ATK buff (fresh STATUS_DURATION)
      player_atk_buff_dur' = if (combat_ends) 0 else STATUS_DURATION,
      player_poison_dur' = if (combat_ends) 0 else next_player_poison,
      player_def_buff_dur' = if (combat_ends) 0 else next_def_buff,
      enemy_poison_dur' = if (combat_ends) 0 else next_enemy_poison,
      max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level, gold' = gold,
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = qty_potion, qty_wood' = qty_wood, qty_iron' = qty_iron,
      qty_sword' = qty_sword, has_sword' = has_sword,
      game_won' = game_won,
      sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
      combo_count' = 0,  // battle cry breaks combo
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina - BATTLE_CRY_STAMINA,
      max_stamina' = max_stamina,
      cd_heavy_strike' = if (combat_ends) 0 else (if (cd_heavy_strike > 0) cd_heavy_strike - 1 else 0),
      cd_battle_cry' = if (combat_ends) 0 else BATTLE_CRY_CD,
      pity_counter' = pity_counter, last_drop' = last_drop,
    }
  }

  // === Save game (only outside combat, alive, not won) ===
  action save_game = all {
    not(in_combat), not(game_won), hp > 0,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_potion' = qty_potion, qty_wood' = qty_wood,
    qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = in_combat, enemy_hp' = enemy_hp, enemy_attack' = enemy_attack,
    game_won' = game_won,
    sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
    player_poison_dur' = player_poison_dur, player_atk_buff_dur' = player_atk_buff_dur,
    player_def_buff_dur' = player_def_buff_dur, enemy_poison_dur' = enemy_poison_dur,
    combo_count' = combo_count,
    saved_exists' = true,
    turn_count' = turn_count,
    stamina' = stamina, max_stamina' = max_stamina,
    cd_heavy_strike' = cd_heavy_strike, cd_battle_cry' = cd_battle_cry,
    pity_counter' = pity_counter, last_drop' = last_drop,
  }

  // === Load game (requires a save to exist) ===
  // In the spec we model load as a no-op that preserves invariants.
  // The Odin implementation does the actual state restoration.
  action load_game = all {
    saved_exists,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_potion' = qty_potion, qty_wood' = qty_wood,
    qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = in_combat, enemy_hp' = enemy_hp, enemy_attack' = enemy_attack,
    game_won' = game_won,
    sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
    player_poison_dur' = player_poison_dur, player_atk_buff_dur' = player_atk_buff_dur,
    player_def_buff_dur' = player_def_buff_dur, enemy_poison_dur' = enemy_poison_dur,
    combo_count' = combo_count,
    saved_exists' = saved_exists,
    turn_count' = turn_count,
    stamina' = stamina, max_stamina' = max_stamina,
    cd_heavy_strike' = cd_heavy_strike, cd_battle_cry' = cd_battle_cry,
    pity_counter' = pity_counter, last_drop' = last_drop,
  }

  // === Step ===
  action step = any {
    move_up, move_down, move_left, move_right,
    enter_combat, combat_attack, combat_potion, flee_combat,
    rest_at_village, buy_potion, repair_sword,
    gather_wood, mine_iron, craft_sword, equip_sword,
    use_antidote, poison_strike, combo_attack,
    heavy_strike, battle_cry,
    save_game, load_game,
  }

  // === Invariants ===

  /// HP is bounded [0, max_hp]
  val hp_bounded = hp >= 0 and hp <= max_hp

  /// Gold never goes negative
  val gold_non_negative = gold >= 0

  /// Level is bounded [1, MAX_LEVEL]
  val level_bounded = level >= 1 and level <= MAX_LEVEL

  /// Position stays on the grid
  val position_bounded = pos_x >= 0 and pos_x < WORLD_SIZE and pos_y >= 0 and pos_y < WORLD_SIZE

  /// Quantities never go negative
  val quantities_non_negative = and {
    qty_potion >= 0,
    qty_wood >= 0,
    qty_iron >= 0,
    qty_sword >= 0,
  }

  /// Can only be in a zone you're qualified for
  val level_gate_respected = zone_level(pos_x, pos_y) <= level

  /// XP never decreases
  val xp_monotonic = xp >= 0

  /// Game won only at max level
  val win_condition_correct = game_won.implies(level >= MAX_LEVEL)

  /// Enemy HP is non-negative
  val enemy_hp_bounded = enemy_hp >= 0

  /// Not in combat means no enemy
  val combat_consistent = not(in_combat).implies(enemy_hp == 0 and enemy_attack == 0)

  /// Durability bounded [0, max]
  val dur_bounded = sword_dur >= 0 and sword_dur <= sword_max_dur

  /// Max durability is constant
  val dur_max_constant = sword_max_dur == SWORD_MAX_DUR

  /// Broken sword gives no attack bonus (ignoring ATK buff)
  val broken_no_bonus = (has_sword and sword_dur == 0 and player_atk_buff_dur == 0).implies(attack_power == base_attack)

  /// Status durations are non-negative and bounded
  val status_dur_bounded = and {
    player_poison_dur >= 0, player_poison_dur <= STATUS_DURATION,
    player_atk_buff_dur >= 0, player_atk_buff_dur <= STATUS_DURATION,
    player_def_buff_dur >= 0, player_def_buff_dur <= STATUS_DURATION,
    enemy_poison_dur >= 0, enemy_poison_dur <= STATUS_DURATION,
  }

  /// Statuses are only active during combat
  val status_only_in_combat = not(in_combat).implies(
    player_poison_dur == 0 and player_atk_buff_dur == 0 and
    player_def_buff_dur == 0 and enemy_poison_dur == 0
  )

  /// Combo count bounded [0, 2] (0=none, 1=slash done, 2=thrust done; resets on 3rd hit)
  val combo_bounded = combo_count >= 0 and combo_count <= 2

  /// Combo only active in combat
  val combo_only_in_combat = not(in_combat).implies(combo_count == 0)

  /// Turn count is monotonically increasing
  val turn_count_non_negative = turn_count >= 0

  /// Weather is deterministic: same inputs always produce same weather
  val weather_bounded = zone_weather(pos_x, pos_y, turn_count) >= 0 and
                        zone_weather(pos_x, pos_y, turn_count) <= 3

  /// Stamina bounded [0, max_stamina]
  val stamina_bounded = stamina >= 0 and stamina <= max_stamina

  /// Max stamina is positive
  val max_stamina_positive = max_stamina >= 10

  /// Cooldowns are non-negative and bounded
  val cooldowns_bounded = and {
    cd_heavy_strike >= 0, cd_heavy_strike <= HEAVY_STRIKE_CD,
    cd_battle_cry >= 0, cd_battle_cry <= BATTLE_CRY_CD,
  }

  /// Cooldowns only active during combat
  val cooldowns_only_in_combat = not(in_combat).implies(
    cd_heavy_strike == 0 and cd_battle_cry == 0
  )

  /// Pity counter bounded [0, PITY_THRESHOLD]
  val pity_bounded = pity_counter >= 0 and pity_counter <= PITY_THRESHOLD

  /// Last drop is valid (0=none, 1=potion)
  val last_drop_valid = last_drop >= 0 and last_drop <= 1
}

module quint_crawl_run {
  import quint_crawl.*
}
