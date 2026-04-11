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

  // === Skill tree ===
  var skill_points: int        // unspent skill points
  var skill_combo: bool        // combo attack unlocked
  var skill_poison: bool       // poison strike unlocked
  var skill_shield_block: bool // shield block unlocked
  var skill_heavy_strike: bool // heavy strike unlocked
  var skill_counter_attack: bool // counter-attack unlocked
  var skill_battle_cry: bool   // battle cry unlocked
  var skill_fortify: bool      // fortify unlocked

  // === Venom sac (consumable for poison strike) ===
  var qty_venom_sac: int

  // === Fortify cooldown ===
  var cd_fortify: int

  // === Elemental & Enchantment ===
  var enemy_element: int      // 0=none, 1=fire, 2=ice, 3=lightning, 4=earth
  var enchant_slot_1: int     // weapon enchant slot 1 (0=empty, 1=fire, 2=ice, 3=vampiric, 4=lightning)
  var enchant_slot_2: int     // weapon enchant slot 2
  var enchant_slot_3: int     // weapon enchant slot 3

  // === Save/Load ===
  var saved_exists: bool  // whether a save slot is occupied

  // --- Constants ---
  val SWORD_MAX_DUR = 10
  val REPAIR_COST = 5
  val POISON_DMG = 7
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
  val PITY_THRESHOLD = 8    // kills without drop before guaranteed drop
  val POTION_COST = 15      // gold cost to buy a potion
  val HP_PER_LEVEL = 15     // max HP gained per level-up
  val ATK_PER_LEVEL_UP = 2  // base attack gained per level-up
  val STAMINA_PER_LEVEL = 3 // max stamina gained per level-up
  val INITIAL_HP = 50       // starting HP and max HP
  val INITIAL_ATTACK = 10   // starting base attack
  val INITIAL_POTIONS = 2   // starting potion count
  val INITIAL_STAMINA = 10  // starting stamina and max stamina
  val POTION_HEAL = 20      // HP restored per potion
  val CRAFT_WOOD_COST = 1   // wood required to craft a sword
  val CRAFT_IRON_COST = 2   // iron required to craft a sword
  val POISON_APPLY_TIER = 2 // minimum zone tier for auto-poison
  val LOOT_DROP_MODULO = 3  // turn modulo for guaranteed loot drops
  val MAX_COMBO_CHAIN = 3   // max combo hits before reset
  val SKILL_POINTS_PER_LEVEL = 1  // skill points earned per level-up
  val RESPEC_COST = 25            // gold cost to respec skills
  val COUNTER_STAMINA = 3         // stamina cost for counter-attack
  val SHIELD_BLOCK_STAMINA = 3    // stamina cost for shield block
  val FORTIFY_STAMINA = 4         // stamina cost for fortify
  val FORTIFY_CD = 5              // cooldown turns for fortify
  val FORTIFY_DURATION = 6        // DEF buff duration from fortify (double STATUS_DURATION)
  val CRAFT_VENOM_IRON_COST = 2   // iron cost to craft venom sac
  val ENCHANT_COST = 10             // gold cost per enchantment

  // --- World scaling constants ---
  val WORLD_SIZE = 9        // grid dimension (NxN)
  val MAX_LEVEL = 5         // max zone difficulty
  val TILES_PER_LEVEL = 3   // (x+y) distance per level increment
  val BASE_ENEMY_HP = 20    // enemy HP at level 1
  val BASE_ENEMY_ATK = 2    // enemy ATK constant term
  val ATK_PER_LEVEL = 4     // enemy ATK per level
  val BASE_XP = 5           // XP reward per level
  val BASE_GOLD = 3         // gold reward constant term
  val GOLD_PER_LEVEL = 3    // gold reward per level

  // Weather types: 0=Clear, 1=Rain, 2=Fog, 3=Storm
  // Deterministic weather based on turn and zone
  pure def zone_weather(x: int, y: int, turn: int): int =
    ((x * 3 + y * 7 + turn / WEATHER_CYCLE) % 4)

  // XP thresholds for leveling up
  pure def xp_threshold(lvl: int): int =
    if (lvl == 2) 15
    else if (lvl == 3) 45
    else if (lvl == 4) 90
    else if (lvl == 5) 150
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

  // --- Elemental helpers ---
  // Fire(1) > Ice(2) > Lightning(3) > Earth(4) > Fire(1)
  pure def is_strong(a: int, d: int): bool = {
    if (a == 1 and d == 2) true
    else if (a == 2 and d == 3) true
    else if (a == 3 and d == 4) true
    else if (a == 4 and d == 1) true
    else false
  }

  pure def damage_multiplier(attacker_elem: int, defender_elem: int): int = {
    if (attacker_elem == 0 or defender_elem == 0) 100
    else if (is_strong(attacker_elem, defender_elem)) 200
    else if (is_strong(defender_elem, attacker_elem)) 50
    else 100
  }

  pure def effective_damage(base_dmg: int, mult: int): int = {
    val raw = base_dmg * mult / 100
    if (raw < 1) 1 else raw
  }

  pure def zone_element(x: int, y: int): int =
    ((x * 3 + y * 7) % 4) + 1

  // --- Enchantment helpers ---
  pure def atk_for(slot: int): int = {
    if (slot == 1) 3       // Fire: +3 atk
    else if (slot == 4) 1  // Lightning: +1 atk
    else 0
  }

  pure def def_for(slot: int): int = {
    if (slot == 2) 2       // Ice: +2 def
    else if (slot == 4) 1  // Lightning: +1 def
    else 0
  }

  val has_fire_enchant = (enchant_slot_1 == 1 or enchant_slot_2 == 1 or enchant_slot_3 == 1)
  val has_ice_enchant = (enchant_slot_1 == 2 or enchant_slot_2 == 2 or enchant_slot_3 == 2)
  val enchant_atk_bonus = atk_for(enchant_slot_1) + atk_for(enchant_slot_2) + atk_for(enchant_slot_3)
  val enchant_def_bonus = def_for(enchant_slot_1) + def_for(enchant_slot_2) + def_for(enchant_slot_3)
  val player_element = if (has_fire_enchant) 1
                       else if (has_ice_enchant) 2
                       else if (enchant_slot_1 == 4 or enchant_slot_2 == 4 or enchant_slot_3 == 4) 3
                       else 0

  // Total attack power (sword bonus only if equipped AND not broken, plus ATK buff, plus enchant bonus)
  val attack_power = base_attack + (if (has_sword and sword_dur > 0) SWORD_ATK_BONUS else 0) + (if (player_atk_buff_dur > 0) ATK_BUFF_BONUS else 0) + enchant_atk_bonus
  val player_elem_mult = damage_multiplier(player_element, enemy_element)

  // --- Helpers ---
  pure def clamp_hp(v: int, mx: int): int =
    if (v > mx) mx else if (v < 0) 0 else v

  // === Init ===
  action init = all {
    hp' = INITIAL_HP,
    max_hp' = INITIAL_HP,
    base_attack' = INITIAL_ATTACK,
    xp' = 0,
    level' = 1,
    gold' = 0,
    pos_x' = 0,
    pos_y' = 0,
    qty_potion' = INITIAL_POTIONS,
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
    stamina' = INITIAL_STAMINA,
    max_stamina' = INITIAL_STAMINA,
    cd_heavy_strike' = 0,
    cd_battle_cry' = 0,
    pity_counter' = 0,
    last_drop' = 0,
    skill_points' = 0,
    skill_combo' = false,
    skill_poison' = false,
    skill_shield_block' = false,
    skill_heavy_strike' = false,
    skill_counter_attack' = false,
    skill_battle_cry' = false,
    skill_fortify' = false,
    qty_venom_sac' = 0,
    cd_fortify' = 0,
    enemy_element' = 0,
    enchant_slot_1' = 0,
    enchant_slot_2' = 0,
    enchant_slot_3' = 0,
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
      skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
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
      skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
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
      skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
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
      skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
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
      skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = 0,
      enemy_element' = zone_element(pos_x, pos_y),
      enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
    }
  }

  // === Combat: attack enemy ===
  action combat_attack = all {
    in_combat, not(game_won), hp > 0, enemy_hp > 0,
    stamina >= ATTACK_STAMINA,
    // Degrade sword on attack (only if equipped and not already broken)
    val new_sword_dur = if (has_sword and sword_dur > 0) sword_dur - 1 else sword_dur
    // Enemy takes elemental-modified damage + poison
    val enemy_poison_dmg = if (enemy_poison_dur > 0) POISON_DMG else 0
    val elem_atk = effective_damage(attack_power, player_elem_mult)
    val new_enemy_hp = enemy_hp - elem_atk - enemy_poison_dmg
    // Player takes enemy hit (reduced by DEF buff + enchant DEF) + poison damage
    val enemy_dmg = enemy_attack - enchant_def_bonus - (if (player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (player_poison_dur > 0) POISON_DMG else 0
    val new_hp = if (new_enemy_hp > 0) hp - effective_enemy_dmg - poison_dmg else hp - poison_dmg
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) xp + zone_xp_reward(pos_x, pos_y) else xp
    val new_level = if (level < MAX_LEVEL and gained_xp >= xp_threshold(level + 1)) level + 1 else level
    // Tier 2+ enemies apply poison if player isn't already poisoned
    val zone_tier = zone_level(pos_x, pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and player_poison_dur == 0 and new_enemy_hp > 0)
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
    val drop_trigger = (pity_counter >= PITY_THRESHOLD or (turn_count % LOOT_DROP_MODULO == 0))
    val should_drop = enemy_defeated_alive and drop_trigger
    val new_pity = if (should_drop) 0
                   else if (enemy_defeated_alive) pity_counter + 1
                   else pity_counter
    val drops_venom = should_drop and zone_tier >= POISON_APPLY_TIER
    val new_last_drop = if (drops_venom) 2 else if (should_drop) 1 else 0
    all {
      enemy_hp' = if (combat_ends) 0 else new_enemy_hp,
      hp' = if (new_hp < 0) 0 else new_hp,
      in_combat' = if (combat_ends) false else true,
      xp' = gained_xp,
      gold' = if (new_enemy_hp <= 0) gold + zone_gold_reward(pos_x, pos_y) else gold,
      enemy_attack' = if (combat_ends) 0 else enemy_attack,
      level' = new_level,
      max_hp' = if (new_level > level) max_hp + HP_PER_LEVEL else max_hp,
      base_attack' = if (new_level > level) base_attack + ATK_PER_LEVEL_UP else base_attack,
      game_won' = game_won,  // win requires claim_victory at Castle
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = if (should_drop and not(drops_venom)) qty_potion + 1 else qty_potion,
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
      max_stamina' = if (new_level > level) max_stamina + STAMINA_PER_LEVEL else max_stamina,
      cd_heavy_strike' = if (combat_ends) 0 else (if (cd_heavy_strike > 0) cd_heavy_strike - 1 else 0),
      cd_battle_cry' = if (combat_ends) 0 else (if (cd_battle_cry > 0) cd_battle_cry - 1 else 0),
      pity_counter' = new_pity,
      last_drop' = new_last_drop,
      skill_points' = if (new_level > level) skill_points + SKILL_POINTS_PER_LEVEL else skill_points,
      skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify,
      qty_venom_sac' = if (drops_venom) qty_venom_sac + 1 else qty_venom_sac,
      cd_fortify' = if (combat_ends) 0 else (if (cd_fortify > 0) cd_fortify - 1 else 0),
      enemy_element' = if (combat_ends) 0 else enemy_element,
      enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
    }
  }

  // === Combat: use potion (quick action — no stamina cost, no CD tick) ===
  action combat_potion = all {
    in_combat, not(game_won), qty_potion > 0, hp > 0,
    hp' = clamp_hp(hp + POTION_HEAL, max_hp),
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
    skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
  }

  // === Flee combat ===
  action flee_combat = all {
    in_combat, not(game_won), hp > 0,
    val flee_dmg = if (enemy_attack - enchant_def_bonus < 1) 1 else enemy_attack - enchant_def_bonus
    val new_hp = hp - flee_dmg
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
      skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = 0,
      enemy_element' = 0,
      enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
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
    skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
  }

  // === Buy potion (at town, costs 10 gold) ===
  action buy_potion = all {
    not(in_combat), not(game_won), hp > 0,
    zone_has_services(pos_x, pos_y),
    gold >= POTION_COST,
    gold' = gold - POTION_COST, qty_potion' = qty_potion + 1,
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
    skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
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
    skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
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
      skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
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
      skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
    }
  }

  // === Craft sword (1 wood + 2 iron -> 1 sword, at town) ===
  action craft_sword = all {
    not(in_combat), not(game_won), hp > 0,
    zone_has_services(pos_x, pos_y),
    qty_wood >= CRAFT_WOOD_COST, qty_iron >= CRAFT_IRON_COST,
    qty_wood' = qty_wood - CRAFT_WOOD_COST, qty_iron' = qty_iron - CRAFT_IRON_COST,
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
    skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
  }

  // === Equip sword (sets durability to max) ===
  action equip_sword = all {
    not(in_combat), not(game_won), hp > 0,
    qty_sword >= 1, not(has_sword),
    has_sword' = true, qty_sword' = qty_sword - 1,
    sword_dur' = SWORD_MAX_DUR,
    enchant_slot_1' = 0, enchant_slot_2' = 0, enchant_slot_3' = 0,
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
    skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element,
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
    skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
  }

  // === Poison strike (apply poison to enemy, enemy hits back) ===
  action poison_strike = all {
    in_combat, not(game_won), hp > 0, enemy_hp > 0,
    skill_poison, qty_venom_sac > 0,
    enemy_poison_dur == 0,  // can't stack poison
    stamina >= ATTACK_STAMINA,
    val dmg_taken = enemy_attack - enchant_def_bonus - (if (player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
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
      skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac - 1,
      cd_fortify' = if (combat_ends) 0 else (if (cd_fortify > 0) cd_fortify - 1 else 0),
      enemy_element' = if (combat_ends) 0 else enemy_element,
      enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
    }
  }

  // === Combo attack (3-hit chain: Slash 1x → Thrust 1.5x → Finisher 2x) ===
  action combo_attack = all {
    in_combat, not(game_won), hp > 0, enemy_hp > 0,
    skill_combo,
    combo_count < MAX_COMBO_CHAIN,
    stamina >= COMBO_STAMINA,
    val next_combo = combo_count + 1
    val base_dmg = attack_power
    val combo_dmg = if (next_combo == 1) base_dmg
                    else if (next_combo == 2) (base_dmg * 3) / 2
                    else base_dmg * 2
    // Degrade sword
    val new_sword_dur = if (has_sword and sword_dur > 0) sword_dur - 1 else sword_dur
    // Enemy takes elemental-modified combo + poison damage
    val enemy_poison_dmg = if (enemy_poison_dur > 0) POISON_DMG else 0
    val elem_combo = effective_damage(combo_dmg, player_elem_mult)
    val new_enemy_hp = enemy_hp - elem_combo - enemy_poison_dmg
    // Player takes enemy hit (reduced by DEF buff + enchant DEF) + poison
    val enemy_dmg = enemy_attack - enchant_def_bonus - (if (player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (player_poison_dur > 0) POISON_DMG else 0
    val new_hp = if (new_enemy_hp > 0) hp - effective_enemy_dmg - poison_dmg else hp - poison_dmg
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) xp + zone_xp_reward(pos_x, pos_y) else xp
    val new_level = if (level < MAX_LEVEL and gained_xp >= xp_threshold(level + 1)) level + 1 else level
    // Status ticking
    val zone_tier = zone_level(pos_x, pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and player_poison_dur == 0 and new_enemy_hp > 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (player_poison_dur > 0) player_poison_dur - 1
                             else 0
    val next_atk_buff = if (player_atk_buff_dur > 0) player_atk_buff_dur - 1 else 0
    val next_def_buff = if (player_def_buff_dur > 0) player_def_buff_dur - 1 else 0
    val next_enemy_poison = if (enemy_poison_dur > 0) enemy_poison_dur - 1 else 0
    val combat_ends = (new_enemy_hp <= 0 or new_hp <= 0)
    // Combo state: reset on combat end or chain complete (3 hits), else advance
    val new_combo_count = if (combat_ends) 0
                          else if (next_combo >= MAX_COMBO_CHAIN) 0
                          else next_combo
    // Loot drop on enemy defeat
    val enemy_defeated_alive = (new_enemy_hp <= 0 and new_hp > 0)
    val drop_trigger = (pity_counter >= PITY_THRESHOLD or (turn_count % LOOT_DROP_MODULO == 0))
    val should_drop = enemy_defeated_alive and drop_trigger
    val new_pity = if (should_drop) 0
                   else if (enemy_defeated_alive) pity_counter + 1
                   else pity_counter
    val drops_venom = should_drop and zone_tier >= POISON_APPLY_TIER
    val new_last_drop = if (drops_venom) 2 else if (should_drop) 1 else 0
    all {
      enemy_hp' = if (combat_ends) 0 else new_enemy_hp,
      hp' = if (new_hp < 0) 0 else new_hp,
      in_combat' = if (combat_ends) false else true,
      xp' = gained_xp,
      gold' = if (new_enemy_hp <= 0) gold + zone_gold_reward(pos_x, pos_y) else gold,
      enemy_attack' = if (combat_ends) 0 else enemy_attack,
      level' = new_level,
      max_hp' = if (new_level > level) max_hp + HP_PER_LEVEL else max_hp,
      base_attack' = if (new_level > level) base_attack + ATK_PER_LEVEL_UP else base_attack,
      game_won' = game_won,  // win requires claim_victory at Castle
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = if (should_drop and not(drops_venom)) qty_potion + 1 else qty_potion,
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
      max_stamina' = if (new_level > level) max_stamina + STAMINA_PER_LEVEL else max_stamina,
      cd_heavy_strike' = if (combat_ends) 0 else (if (cd_heavy_strike > 0) cd_heavy_strike - 1 else 0),
      cd_battle_cry' = if (combat_ends) 0 else (if (cd_battle_cry > 0) cd_battle_cry - 1 else 0),
      pity_counter' = new_pity,
      last_drop' = new_last_drop,
      skill_points' = if (new_level > level) skill_points + SKILL_POINTS_PER_LEVEL else skill_points,
      skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify,
      qty_venom_sac' = if (drops_venom) qty_venom_sac + 1 else qty_venom_sac,
      cd_fortify' = if (combat_ends) 0 else (if (cd_fortify > 0) cd_fortify - 1 else 0),
      enemy_element' = if (combat_ends) 0 else enemy_element,
      enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
    }
  }

  // === Heavy strike (2x damage, costs 5 stamina, 3-turn cooldown) ===
  action heavy_strike = all {
    in_combat, not(game_won), hp > 0, enemy_hp > 0,
    skill_heavy_strike,
    cd_heavy_strike == 0,
    stamina >= HEAVY_STRIKE_STAMINA,
    val heavy_dmg = attack_power * 2
    // Degrade sword
    val new_sword_dur = if (has_sword and sword_dur > 0) sword_dur - 1 else sword_dur
    // Enemy takes elemental-modified heavy + poison damage
    val enemy_poison_dmg = if (enemy_poison_dur > 0) POISON_DMG else 0
    val elem_heavy = effective_damage(heavy_dmg, player_elem_mult)
    val new_enemy_hp = enemy_hp - elem_heavy - enemy_poison_dmg
    // Player takes enemy hit (reduced by DEF buff + enchant DEF) + poison
    val enemy_dmg = enemy_attack - enchant_def_bonus - (if (player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (player_poison_dur > 0) POISON_DMG else 0
    val new_hp = if (new_enemy_hp > 0) hp - effective_enemy_dmg - poison_dmg else hp - poison_dmg
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) xp + zone_xp_reward(pos_x, pos_y) else xp
    val new_level = if (level < MAX_LEVEL and gained_xp >= xp_threshold(level + 1)) level + 1 else level
    // Status ticking
    val zone_tier = zone_level(pos_x, pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and player_poison_dur == 0 and new_enemy_hp > 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (player_poison_dur > 0) player_poison_dur - 1
                             else 0
    val next_atk_buff = if (player_atk_buff_dur > 0) player_atk_buff_dur - 1 else 0
    val next_def_buff = if (player_def_buff_dur > 0) player_def_buff_dur - 1 else 0
    val next_enemy_poison = if (enemy_poison_dur > 0) enemy_poison_dur - 1 else 0
    val combat_ends = (new_enemy_hp <= 0 or new_hp <= 0)
    // Loot drop on enemy defeat
    val enemy_defeated_alive = (new_enemy_hp <= 0 and new_hp > 0)
    val drop_trigger = (pity_counter >= PITY_THRESHOLD or (turn_count % LOOT_DROP_MODULO == 0))
    val should_drop = enemy_defeated_alive and drop_trigger
    val new_pity = if (should_drop) 0
                   else if (enemy_defeated_alive) pity_counter + 1
                   else pity_counter
    val drops_venom = should_drop and zone_tier >= POISON_APPLY_TIER
    val new_last_drop = if (drops_venom) 2 else if (should_drop) 1 else 0
    all {
      enemy_hp' = if (combat_ends) 0 else new_enemy_hp,
      hp' = if (new_hp < 0) 0 else new_hp,
      in_combat' = if (combat_ends) false else true,
      xp' = gained_xp,
      gold' = if (new_enemy_hp <= 0) gold + zone_gold_reward(pos_x, pos_y) else gold,
      enemy_attack' = if (combat_ends) 0 else enemy_attack,
      level' = new_level,
      max_hp' = if (new_level > level) max_hp + HP_PER_LEVEL else max_hp,
      base_attack' = if (new_level > level) base_attack + ATK_PER_LEVEL_UP else base_attack,
      game_won' = game_won,  // win requires claim_victory at Castle
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = if (should_drop and not(drops_venom)) qty_potion + 1 else qty_potion,
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
      max_stamina' = if (new_level > level) max_stamina + STAMINA_PER_LEVEL else max_stamina,
      cd_heavy_strike' = if (combat_ends) 0 else HEAVY_STRIKE_CD,
      cd_battle_cry' = if (combat_ends) 0 else (if (cd_battle_cry > 0) cd_battle_cry - 1 else 0),
      pity_counter' = new_pity,
      last_drop' = new_last_drop,
      skill_points' = if (new_level > level) skill_points + SKILL_POINTS_PER_LEVEL else skill_points,
      skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify,
      qty_venom_sac' = if (drops_venom) qty_venom_sac + 1 else qty_venom_sac,
      cd_fortify' = if (combat_ends) 0 else (if (cd_fortify > 0) cd_fortify - 1 else 0),
      enemy_element' = if (combat_ends) 0 else enemy_element,
      enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
    }
  }

  // === Battle cry (grants ATK buff, costs 3 stamina, 4-turn cooldown) ===
  // Enemy hits back. Resets combo.
  action battle_cry = all {
    in_combat, not(game_won), hp > 0, enemy_hp > 0,
    skill_battle_cry,
    cd_battle_cry == 0,
    stamina >= BATTLE_CRY_STAMINA,
    // Enemy hits player (reduced by enchant DEF + DEF buff)
    val enemy_dmg = enemy_attack - enchant_def_bonus - (if (player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (player_poison_dur > 0) POISON_DMG else 0
    val new_hp = hp - effective_enemy_dmg - poison_dmg
    val combat_ends = (new_hp <= 0)
    // Status ticking
    val zone_tier = zone_level(pos_x, pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and player_poison_dur == 0)
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
      skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac,
      cd_fortify' = if (combat_ends) 0 else (if (cd_fortify > 0) cd_fortify - 1 else 0),
      enemy_element' = if (combat_ends) 0 else enemy_element,
      enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
    }
  }

  // === Shield block (grants DEF buff, takes enemy hit) ===
  action shield_block = all {
    in_combat, not(game_won), hp > 0, enemy_hp > 0,
    skill_shield_block,
    stamina >= SHIELD_BLOCK_STAMINA,
    // Enemy hits player (reduced by enchant DEF + DEF buff)
    val enemy_dmg = enemy_attack - enchant_def_bonus - (if (player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (player_poison_dur > 0) POISON_DMG else 0
    val new_hp = hp - effective_enemy_dmg - poison_dmg
    val combat_ends = (new_hp <= 0)
    // Status ticking
    val zone_tier = zone_level(pos_x, pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and player_poison_dur == 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (player_poison_dur > 0) player_poison_dur - 1
                             else 0
    val next_atk_buff = if (player_atk_buff_dur > 0) player_atk_buff_dur - 1 else 0
    val next_enemy_poison = if (enemy_poison_dur > 0) enemy_poison_dur - 1 else 0
    all {
      hp' = if (new_hp < 0) 0 else new_hp,
      in_combat' = if (combat_ends) false else true,
      enemy_hp' = if (combat_ends) 0 else enemy_hp,
      enemy_attack' = if (combat_ends) 0 else enemy_attack,
      // Grant DEF buff (fresh STATUS_DURATION)
      player_def_buff_dur' = if (combat_ends) 0 else STATUS_DURATION,
      player_poison_dur' = if (combat_ends) 0 else next_player_poison,
      player_atk_buff_dur' = if (combat_ends) 0 else next_atk_buff,
      enemy_poison_dur' = if (combat_ends) 0 else next_enemy_poison,
      max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level, gold' = gold,
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = qty_potion, qty_wood' = qty_wood, qty_iron' = qty_iron,
      qty_sword' = qty_sword, has_sword' = has_sword,
      game_won' = game_won,
      sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
      combo_count' = 0,  // shield block breaks combo
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina - SHIELD_BLOCK_STAMINA,
      max_stamina' = max_stamina,
      cd_heavy_strike' = if (combat_ends) 0 else (if (cd_heavy_strike > 0) cd_heavy_strike - 1 else 0),
      cd_battle_cry' = if (combat_ends) 0 else (if (cd_battle_cry > 0) cd_battle_cry - 1 else 0),
      pity_counter' = pity_counter, last_drop' = last_drop,
      skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac,
      cd_fortify' = if (combat_ends) 0 else (if (cd_fortify > 0) cd_fortify - 1 else 0),
      enemy_element' = if (combat_ends) 0 else enemy_element,
      enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
    }
  }

  // === Skill unlock: Combo (tier 1 offense, no prereq) ===
  action unlock_combo = all {
    not(in_combat), not(game_won), hp > 0,
    not(skill_combo), skill_points >= 1,
    skill_combo' = true, skill_points' = skill_points - 1,
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
    skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
  }

  // === Skill unlock: Poison Strike (tier 1 utility, no prereq) ===
  action unlock_poison = all {
    not(in_combat), not(game_won), hp > 0,
    not(skill_poison), skill_points >= 1,
    skill_poison' = true, skill_points' = skill_points - 1,
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
    skill_combo' = skill_combo,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
  }

  // === Skill unlock: Shield Block (tier 1 defense, no prereq) ===
  action unlock_shield_block = all {
    not(in_combat), not(game_won), hp > 0,
    not(skill_shield_block), skill_points >= 1,
    skill_shield_block' = true, skill_points' = skill_points - 1,
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
    skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
  }

  // === Skill unlock: Heavy Strike (tier 2 offense, requires Combo) ===
  action unlock_heavy_strike = all {
    not(in_combat), not(game_won), hp > 0,
    not(skill_heavy_strike), skill_combo, skill_points >= 1,
    skill_heavy_strike' = true, skill_points' = skill_points - 1,
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
    skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
  }

  // === Skill unlock: Counter-Attack (tier 2 defense, requires Shield Block) ===
  action unlock_counter_attack = all {
    not(in_combat), not(game_won), hp > 0,
    not(skill_counter_attack), skill_shield_block, skill_points >= 1,
    skill_counter_attack' = true, skill_points' = skill_points - 1,
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
    skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
  }

  // === Skill unlock: Battle Cry (tier 3 offense, requires Heavy Strike, costs 2pt) ===
  action unlock_battle_cry = all {
    not(in_combat), not(game_won), hp > 0,
    not(skill_battle_cry), skill_heavy_strike, skill_points >= 2,
    skill_battle_cry' = true, skill_points' = skill_points - 2,
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
    skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
  }

  // === Skill unlock: Fortify (tier 3 defense, requires Counter-Attack, costs 2pt) ===
  action unlock_fortify = all {
    not(in_combat), not(game_won), hp > 0,
    not(skill_fortify), skill_counter_attack, skill_points >= 2,
    skill_fortify' = true, skill_points' = skill_points - 2,
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
    skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
  }

  // === Respec skills (at village, costs gold) ===
  action respec = all {
    not(in_combat), not(game_won), hp > 0,
    zone_has_services(pos_x, pos_y),
    gold >= RESPEC_COST,
    // Count spent points
    val spent = (if (skill_combo) 1 else 0) + (if (skill_poison) 1 else 0) +
                (if (skill_shield_block) 1 else 0) + (if (skill_heavy_strike) 1 else 0) +
                (if (skill_counter_attack) 1 else 0) + (if (skill_battle_cry) 2 else 0) +
                (if (skill_fortify) 2 else 0)
    all {
      spent > 0,
      gold' = gold - RESPEC_COST,
      skill_points' = skill_points + spent,
      skill_combo' = false, skill_poison' = false, skill_shield_block' = false,
      skill_heavy_strike' = false, skill_counter_attack' = false,
      skill_battle_cry' = false, skill_fortify' = false,
      hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level,
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
      qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
    }
  }

  // === Counter-Attack (block + retaliatory hit) ===
  action counter_attack = all {
    in_combat, not(game_won), hp > 0, enemy_hp > 0,
    skill_counter_attack,
    stamina >= COUNTER_STAMINA,
    // Player deals elemental-modified damage to enemy
    val player_dmg = effective_damage(attack_power, player_elem_mult)
    val new_enemy_hp = if (enemy_hp - player_dmg < 0) 0 else enemy_hp - player_dmg
    // Enemy hits player (reduced by enchant DEF + DEF buff)
    val enemy_dmg = enemy_attack - enchant_def_bonus - (if (player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (player_poison_dur > 0) POISON_DMG else 0
    val enemy_poison_dmg = if (enemy_poison_dur > 0) POISON_DMG else 0
    val final_enemy_hp = if (new_enemy_hp - enemy_poison_dmg < 0) 0 else new_enemy_hp - enemy_poison_dmg
    val new_hp = hp - effective_enemy_dmg - poison_dmg
    val combat_ends = (new_hp <= 0 or final_enemy_hp <= 0)
    // XP and gold on kill
    val zone_tier = zone_level(pos_x, pos_y)
    val xp_reward = if (final_enemy_hp <= 0 and new_hp > 0) BASE_XP * zone_tier else 0
    val gold_reward = if (final_enemy_hp <= 0 and new_hp > 0) BASE_GOLD + GOLD_PER_LEVEL * zone_tier else 0
    val new_xp = xp + xp_reward
    val new_level = if (level < MAX_LEVEL and new_xp >= xp_threshold(level + 1)) level + 1 else level
    // Status ticking
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and player_poison_dur == 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (player_poison_dur > 0) player_poison_dur - 1
                             else 0
    val next_atk_buff = if (player_atk_buff_dur > 0) player_atk_buff_dur - 1 else 0
    val next_enemy_poison = if (enemy_poison_dur > 0) enemy_poison_dur - 1 else 0
    // Sword durability (counter-attack uses sword)
    val dur_cost = if (has_sword and sword_dur > 0) 1 else 0
    // Loot drop on enemy defeat
    val enemy_defeated_alive = (final_enemy_hp <= 0 and new_hp > 0)
    val drop_trigger = (pity_counter >= PITY_THRESHOLD or (turn_count % LOOT_DROP_MODULO == 0))
    val should_drop = enemy_defeated_alive and drop_trigger
    val new_pity = if (should_drop) 0
                   else if (enemy_defeated_alive) pity_counter + 1
                   else pity_counter
    val drops_venom = should_drop and zone_tier >= POISON_APPLY_TIER
    val new_last_drop = if (drops_venom) 2 else if (should_drop) 1 else 0
    all {
      hp' = if (new_hp < 0) 0 else new_hp,
      enemy_hp' = if (combat_ends) 0 else final_enemy_hp,
      in_combat' = if (combat_ends) false else true,
      enemy_attack' = if (combat_ends) 0 else enemy_attack,
      xp' = new_xp, level' = new_level,
      gold' = gold + gold_reward,
      // Grant DEF buff on counter
      player_def_buff_dur' = if (combat_ends) 0 else STATUS_DURATION,
      player_poison_dur' = if (combat_ends) 0 else next_player_poison,
      player_atk_buff_dur' = if (combat_ends) 0 else next_atk_buff,
      enemy_poison_dur' = if (combat_ends) 0 else next_enemy_poison,
      max_hp' = if (new_level > level) max_hp + HP_PER_LEVEL else max_hp,
      base_attack' = if (new_level > level) base_attack + ATK_PER_LEVEL_UP else base_attack,
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = if (should_drop and not(drops_venom)) qty_potion + 1 else qty_potion,
      qty_wood' = qty_wood, qty_iron' = qty_iron,
      qty_sword' = qty_sword, has_sword' = has_sword,
      game_won' = game_won,
      sword_dur' = sword_dur - dur_cost, sword_max_dur' = sword_max_dur,
      combo_count' = 0,  // counter-attack breaks combo
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina - COUNTER_STAMINA,
      max_stamina' = if (new_level > level) max_stamina + STAMINA_PER_LEVEL else max_stamina,
      cd_heavy_strike' = if (combat_ends) 0 else (if (cd_heavy_strike > 0) cd_heavy_strike - 1 else 0),
      cd_battle_cry' = if (combat_ends) 0 else (if (cd_battle_cry > 0) cd_battle_cry - 1 else 0),
      pity_counter' = new_pity,
      last_drop' = new_last_drop,
      skill_points' = if (new_level > level) skill_points + SKILL_POINTS_PER_LEVEL else skill_points,
      skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify,
      qty_venom_sac' = if (drops_venom) qty_venom_sac + 1 else qty_venom_sac,
      cd_fortify' = if (combat_ends) 0 else (if (cd_fortify > 0) cd_fortify - 1 else 0),
      enemy_element' = if (combat_ends) 0 else enemy_element,
      enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
    }
  }

  // === Fortify (double-duration DEF buff, no damage, cooldown) ===
  action fortify = all {
    in_combat, not(game_won), hp > 0, enemy_hp > 0,
    skill_fortify,
    cd_fortify == 0,
    stamina >= FORTIFY_STAMINA,
    // Enemy hits player (reduced by enchant DEF + DEF buff)
    val enemy_dmg = enemy_attack - enchant_def_bonus - (if (player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (player_poison_dur > 0) POISON_DMG else 0
    val new_hp = hp - effective_enemy_dmg - poison_dmg
    val combat_ends = (new_hp <= 0)
    // Status ticking
    val zone_tier = zone_level(pos_x, pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and player_poison_dur == 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (player_poison_dur > 0) player_poison_dur - 1
                             else 0
    val next_atk_buff = if (player_atk_buff_dur > 0) player_atk_buff_dur - 1 else 0
    val next_enemy_poison = if (enemy_poison_dur > 0) enemy_poison_dur - 1 else 0
    all {
      hp' = if (new_hp < 0) 0 else new_hp,
      in_combat' = if (combat_ends) false else true,
      enemy_hp' = if (combat_ends) 0 else enemy_hp,
      enemy_attack' = if (combat_ends) 0 else enemy_attack,
      // Grant extended DEF buff
      player_def_buff_dur' = if (combat_ends) 0 else FORTIFY_DURATION,
      player_poison_dur' = if (combat_ends) 0 else next_player_poison,
      player_atk_buff_dur' = if (combat_ends) 0 else next_atk_buff,
      enemy_poison_dur' = if (combat_ends) 0 else next_enemy_poison,
      max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level, gold' = gold,
      pos_x' = pos_x, pos_y' = pos_y,
      qty_potion' = qty_potion, qty_wood' = qty_wood, qty_iron' = qty_iron,
      qty_sword' = qty_sword, has_sword' = has_sword,
      game_won' = game_won,
      sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
      combo_count' = 0,  // fortify breaks combo
      saved_exists' = saved_exists,
      turn_count' = turn_count + 1,
      stamina' = stamina - FORTIFY_STAMINA,
      max_stamina' = max_stamina,
      cd_heavy_strike' = if (combat_ends) 0 else (if (cd_heavy_strike > 0) cd_heavy_strike - 1 else 0),
      cd_battle_cry' = if (combat_ends) 0 else (if (cd_battle_cry > 0) cd_battle_cry - 1 else 0),
      pity_counter' = pity_counter, last_drop' = last_drop,
      skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac,
      cd_fortify' = if (combat_ends) 0 else FORTIFY_CD,
      enemy_element' = if (combat_ends) 0 else enemy_element,
      enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
    }
  }

  // === Craft Venom Sac (at village, 2 iron) ===
  action craft_venom_sac = all {
    not(in_combat), not(game_won), hp > 0,
    zone_has_services(pos_x, pos_y),
    qty_iron >= CRAFT_VENOM_IRON_COST,
    qty_iron' = qty_iron - CRAFT_VENOM_IRON_COST,
    qty_venom_sac' = qty_venom_sac + 1,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_potion' = qty_potion, qty_wood' = qty_wood,
    qty_sword' = qty_sword, has_sword' = has_sword,
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
    skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, cd_fortify' = cd_fortify,
    enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
  }

  // === Apply enchantment to slot 1 (at village, costs gold, requires sword) ===
  action apply_enchant_1 = {
    nondet etype = Set(1, 2, 3, 4).oneOf()
    all {
      not(in_combat), not(game_won), hp > 0,
      zone_has_services(pos_x, pos_y),
      has_sword,
      gold >= ENCHANT_COST,
      not(etype == 1 and has_ice_enchant),
      not(etype == 2 and has_fire_enchant),
      enchant_slot_1' = etype,
      enchant_slot_2' = enchant_slot_2,
      enchant_slot_3' = enchant_slot_3,
      gold' = gold - ENCHANT_COST,
      hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level,
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
      skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element,
    }
  }

  // === Apply enchantment to slot 2 ===
  action apply_enchant_2 = {
    nondet etype = Set(1, 2, 3, 4).oneOf()
    all {
      not(in_combat), not(game_won), hp > 0,
      zone_has_services(pos_x, pos_y),
      has_sword,
      gold >= ENCHANT_COST,
      not(etype == 1 and has_ice_enchant),
      not(etype == 2 and has_fire_enchant),
      enchant_slot_1' = enchant_slot_1,
      enchant_slot_2' = etype,
      enchant_slot_3' = enchant_slot_3,
      gold' = gold - ENCHANT_COST,
      hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level,
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
      skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element,
    }
  }

  // === Apply enchantment to slot 3 ===
  action apply_enchant_3 = {
    nondet etype = Set(1, 2, 3, 4).oneOf()
    all {
      not(in_combat), not(game_won), hp > 0,
      zone_has_services(pos_x, pos_y),
      has_sword,
      gold >= ENCHANT_COST,
      not(etype == 1 and has_ice_enchant),
      not(etype == 2 and has_fire_enchant),
      enchant_slot_1' = enchant_slot_1,
      enchant_slot_2' = enchant_slot_2,
      enchant_slot_3' = etype,
      gold' = gold - ENCHANT_COST,
      hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
      xp' = xp, level' = level,
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
      skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
      skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
      skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
      skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element,
    }
  }

  // === Remove enchantment from slot 1 (at village, free) ===
  action remove_enchant_1 = all {
    not(in_combat), not(game_won), hp > 0,
    zone_has_services(pos_x, pos_y),
    has_sword,
    enchant_slot_1 != 0,
    enchant_slot_1' = 0,
    enchant_slot_2' = enchant_slot_2,
    enchant_slot_3' = enchant_slot_3,
    gold' = gold,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level,
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
    skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
    enemy_element' = enemy_element,
  }

  // === Remove enchantment from slot 2 ===
  action remove_enchant_2 = all {
    not(in_combat), not(game_won), hp > 0,
    zone_has_services(pos_x, pos_y),
    has_sword,
    enchant_slot_2 != 0,
    enchant_slot_1' = enchant_slot_1,
    enchant_slot_2' = 0,
    enchant_slot_3' = enchant_slot_3,
    gold' = gold,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level,
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
    skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
    enemy_element' = enemy_element,
  }

  // === Remove enchantment from slot 3 ===
  action remove_enchant_3 = all {
    not(in_combat), not(game_won), hp > 0,
    zone_has_services(pos_x, pos_y),
    has_sword,
    enchant_slot_3 != 0,
    enchant_slot_1' = enchant_slot_1,
    enchant_slot_2' = enchant_slot_2,
    enchant_slot_3' = 0,
    gold' = gold,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level,
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
    skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
    enemy_element' = enemy_element,
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
    skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
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
    skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
  }

  // === Claim Victory ===
  // Player must be at max level AND standing on a level-5 Castle tile
  action claim_victory = all {
    not(in_combat), not(game_won), hp > 0,
    level >= MAX_LEVEL,
    zone_biome_x(pos_x) == 2, zone_biome_y(pos_y) == 2,
    zone_level(pos_x, pos_y) >= MAX_LEVEL,
    game_won' = true,
    hp' = hp, max_hp' = max_hp, base_attack' = base_attack,
    xp' = xp, level' = level, gold' = gold,
    pos_x' = pos_x, pos_y' = pos_y,
    qty_potion' = qty_potion, qty_wood' = qty_wood,
    qty_iron' = qty_iron, qty_sword' = qty_sword, has_sword' = has_sword,
    in_combat' = false, enemy_hp' = 0, enemy_attack' = 0,
    sword_dur' = sword_dur, sword_max_dur' = sword_max_dur,
    player_poison_dur' = 0, player_atk_buff_dur' = 0,
    player_def_buff_dur' = 0, enemy_poison_dur' = 0,
    combo_count' = 0,
    saved_exists' = saved_exists,
    turn_count' = turn_count,
    stamina' = stamina, max_stamina' = max_stamina,
    cd_heavy_strike' = 0, cd_battle_cry' = 0,
    pity_counter' = pity_counter, last_drop' = last_drop,
    skill_points' = skill_points, skill_combo' = skill_combo, skill_poison' = skill_poison,
    skill_shield_block' = skill_shield_block, skill_heavy_strike' = skill_heavy_strike,
    skill_counter_attack' = skill_counter_attack, skill_battle_cry' = skill_battle_cry,
    skill_fortify' = skill_fortify, qty_venom_sac' = qty_venom_sac, cd_fortify' = cd_fortify,
      enemy_element' = enemy_element, enchant_slot_1' = enchant_slot_1, enchant_slot_2' = enchant_slot_2, enchant_slot_3' = enchant_slot_3,
  }

  // === Step ===
  action step = any {
    move_up, move_down, move_left, move_right,
    enter_combat, combat_attack, combat_potion, flee_combat,
    rest_at_village, buy_potion, repair_sword,
    gather_wood, mine_iron, craft_sword, equip_sword,
    use_antidote, poison_strike, combo_attack,
    heavy_strike, battle_cry, shield_block,
    counter_attack, fortify,
    unlock_combo, unlock_poison, unlock_shield_block,
    unlock_heavy_strike, unlock_counter_attack,
    unlock_battle_cry, unlock_fortify,
    respec, craft_venom_sac,
    apply_enchant_1, apply_enchant_2, apply_enchant_3,
    remove_enchant_1, remove_enchant_2, remove_enchant_3,
    save_game, load_game, claim_victory,
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
    player_def_buff_dur >= 0, player_def_buff_dur <= FORTIFY_DURATION,
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
    cd_fortify >= 0, cd_fortify <= FORTIFY_CD,
  }

  /// Cooldowns only active during combat
  val cooldowns_only_in_combat = not(in_combat).implies(
    cd_heavy_strike == 0 and cd_battle_cry == 0 and cd_fortify == 0
  )

  /// Pity counter bounded [0, PITY_THRESHOLD]
  val pity_bounded = pity_counter >= 0 and pity_counter <= PITY_THRESHOLD

  /// Last drop is valid (0=none, 1=potion, 2=venom_sac)
  val last_drop_valid = last_drop >= 0 and last_drop <= 2

  /// XP thresholds increase with level (progression is monotonic)
  val xp_thresholds_monotonic = and {
    xp_threshold(2) < xp_threshold(3),
    xp_threshold(3) < xp_threshold(4),
    xp_threshold(4) < xp_threshold(5),
  }

  /// Win condition requires Castle position
  val win_requires_castle = game_won.implies(
    pos_x % 3 == 2 and pos_y % 3 == 2 and zone_level(pos_x, pos_y) >= MAX_LEVEL
  )

  /// Skill points are non-negative
  val skill_points_non_negative = skill_points >= 0

  /// Skill prerequisites are respected
  val skill_prereqs_respected = and {
    skill_heavy_strike.implies(skill_combo),
    skill_counter_attack.implies(skill_shield_block),
    skill_battle_cry.implies(skill_heavy_strike),
    skill_fortify.implies(skill_counter_attack),
  }

  /// Venom sac quantity is non-negative
  val qty_venom_sac_non_negative = qty_venom_sac >= 0

  /// Enemy element is bounded [0, 4]
  val enemy_element_bounded = enemy_element >= 0 and enemy_element <= 4

  /// Enchant slots are bounded [0, 4]
  val enchant_slots_bounded = and {
    enchant_slot_1 >= 0, enchant_slot_1 <= 4,
    enchant_slot_2 >= 0, enchant_slot_2 <= 4,
    enchant_slot_3 >= 0, enchant_slot_3 <= 4,
  }

  /// Fire and Ice enchantments cannot coexist
  val no_fire_ice_incompatible = not(has_fire_enchant and has_ice_enchant)

  /// Enemy element is only set during combat
  val enemy_element_only_in_combat = not(in_combat).implies(enemy_element == 0)
}

module quint_crawl_run {
  import quint_crawl.*
}
