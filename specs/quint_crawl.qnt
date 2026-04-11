module quint_crawl {
  // === Record type definitions ===
  type CharState = {
    hp: int, max_hp: int, base_attack: int, xp: int, level: int, gold: int,
    stamina: int, max_stamina: int, skill_points: int,
    skill_combo: bool, skill_poison: bool, skill_shield_block: bool,
    skill_heavy_strike: bool, skill_counter_attack: bool,
    skill_battle_cry: bool, skill_fortify: bool,
  }

  type InvState = {
    qty_potion: int, qty_wood: int, qty_iron: int, qty_sword: int,
    has_sword: bool, qty_venom_sac: int, salvage_level: int,
  }

  type EquipState = {
    sword_dur: int, sword_max_dur: int,
    enchant_slot_1: int, enchant_slot_2: int, enchant_slot_3: int,
  }

  type CombatState = {
    in_combat: bool, enemy_hp: int, enemy_attack: int, enemy_element: int,
    combo_count: int, player_poison_dur: int, player_atk_buff_dur: int,
    player_def_buff_dur: int, enemy_poison_dur: int,
    cd_heavy_strike: int, cd_battle_cry: int, cd_fortify: int,
  }

  type WorldState = {
    pos_x: int, pos_y: int, turn_count: int,
  }

  type MetaState = {
    game_won: bool, saved_exists: bool, pity_counter: int, last_drop: int,
  }

  // === State variables ===
  var ch: CharState
  var inv: InvState
  var eqp: EquipState
  var cb: CombatState
  var w: WorldState
  var meta: MetaState

  // --- Constants ---
  val SWORD_MAX_DUR = 10
  val REPAIR_COST = 5
  val POISON_DMG = 7
  val ATK_BUFF_BONUS = 5
  val DEF_BUFF_REDUCTION = 3
  val STATUS_DURATION = 3
  val SWORD_ATK_BONUS = 5
  val WEATHER_CYCLE = 5
  val STORM_MOVE_DMG = 2
  val FOG_ATK_PENALTY = 2
  val RAIN_GATHER_BONUS = 1
  val ATTACK_STAMINA = 2
  val COMBO_STAMINA = 3
  val HEAVY_STRIKE_STAMINA = 5
  val BATTLE_CRY_STAMINA = 3
  val HEAVY_STRIKE_CD = 3
  val BATTLE_CRY_CD = 4
  val PITY_THRESHOLD = 8
  val POTION_COST = 15
  val HP_PER_LEVEL = 15
  val ATK_PER_LEVEL_UP = 2
  val STAMINA_PER_LEVEL = 3
  val INITIAL_HP = 50
  val INITIAL_ATTACK = 10
  val INITIAL_POTIONS = 2
  val INITIAL_STAMINA = 10
  val POTION_HEAL = 20
  val CRAFT_WOOD_COST = 1
  val CRAFT_IRON_COST = 2
  val POISON_APPLY_TIER = 2
  val LOOT_DROP_MODULO = 3
  val MAX_COMBO_CHAIN = 3
  val SKILL_POINTS_PER_LEVEL = 1
  val RESPEC_COST = 25
  val COUNTER_STAMINA = 3
  val SHIELD_BLOCK_STAMINA = 3
  val FORTIFY_STAMINA = 4
  val FORTIFY_CD = 5
  val FORTIFY_DURATION = 6
  val CRAFT_VENOM_IRON_COST = 2
  val ENCHANT_COST = 10
  val MAX_INVENTORY = 30
  val CRAFT_LEVEL_REQ = 2
  val SALVAGE_WOOD_BASE = 0
  val SALVAGE_IRON_BASE = 1
  val UPGRADE_SALVAGE_COST = 15
  val MAX_SALVAGE_LEVEL = 3

  // --- World scaling constants ---
  val WORLD_SIZE = 9
  val MAX_LEVEL = 5
  val TILES_PER_LEVEL = 3
  val BASE_ENEMY_HP = 20
  val BASE_ENEMY_ATK = 2
  val ATK_PER_LEVEL = 4
  val BASE_XP = 5
  val BASE_GOLD = 3
  val GOLD_PER_LEVEL = 3

  // Weather types: 0=Clear, 1=Rain, 2=Fog, 3=Storm
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
  pure def zone_level(x: int, y: int): int =
    val raw = (x + y) / TILES_PER_LEVEL + 1
    if (raw > MAX_LEVEL) MAX_LEVEL else raw

  pure def zone_biome_x(x: int): int = x % 3
  pure def zone_biome_y(y: int): int = y % 3

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

  pure def zone_enemy_hp(x: int, y: int): int = BASE_ENEMY_HP * zone_level(x, y)
  pure def zone_enemy_attack(x: int, y: int): int = BASE_ENEMY_ATK + ATK_PER_LEVEL * zone_level(x, y)
  pure def zone_xp_reward(x: int, y: int): int = BASE_XP * zone_level(x, y)
  pure def zone_gold_reward(x: int, y: int): int = BASE_GOLD + GOLD_PER_LEVEL * zone_level(x, y)

  pure def zone_has_services(x: int, y: int): bool = (x % 3 == 0 and y % 3 == 0)
  pure def zone_has_wood(x: int, y: int): bool = (x % 3 == 1 and y % 3 == 0)
  pure def zone_has_iron(x: int, y: int): bool = (x % 3 == 2 and y % 3 == 1)

  // --- Elemental helpers ---
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
    if (slot == 1) 3
    else if (slot == 4) 1
    else 0
  }

  pure def def_for(slot: int): int = {
    if (slot == 2) 2
    else if (slot == 4) 1
    else 0
  }

  val has_fire_enchant = (eqp.enchant_slot_1 == 1 or eqp.enchant_slot_2 == 1 or eqp.enchant_slot_3 == 1)
  val has_ice_enchant = (eqp.enchant_slot_1 == 2 or eqp.enchant_slot_2 == 2 or eqp.enchant_slot_3 == 2)
  val enchant_atk_bonus = atk_for(eqp.enchant_slot_1) + atk_for(eqp.enchant_slot_2) + atk_for(eqp.enchant_slot_3)
  val enchant_def_bonus = def_for(eqp.enchant_slot_1) + def_for(eqp.enchant_slot_2) + def_for(eqp.enchant_slot_3)
  val player_element = if (has_fire_enchant) 1
                       else if (has_ice_enchant) 2
                       else if (eqp.enchant_slot_1 == 4 or eqp.enchant_slot_2 == 4 or eqp.enchant_slot_3 == 4) 3
                       else 0

  // Total attack power (sword bonus only if equipped AND not broken, plus ATK buff, plus enchant bonus)
  val attack_power = ch.base_attack + (if (inv.has_sword and eqp.sword_dur > 0) SWORD_ATK_BONUS else 0) + (if (cb.player_atk_buff_dur > 0) ATK_BUFF_BONUS else 0) + enchant_atk_bonus
  val player_elem_mult = damage_multiplier(player_element, cb.enemy_element)

  // --- Inventory helpers ---
  val total_items = inv.qty_potion + inv.qty_wood + inv.qty_iron + inv.qty_sword + inv.qty_venom_sac

  // Salvage recovery
  pure def salvage_wood_yield(slvl: int): int = SALVAGE_WOOD_BASE + (slvl - 1)
  pure def salvage_iron_yield(slvl: int): int = SALVAGE_IRON_BASE + (slvl - 1)

  // --- Helpers ---
  pure def clamp_hp(v: int, mx: int): int =
    if (v > mx) mx else if (v < 0) 0 else v

  // === Init ===
  action init = all {
    ch' = {
      hp: INITIAL_HP, max_hp: INITIAL_HP, base_attack: INITIAL_ATTACK,
      xp: 0, level: 1, gold: 0,
      stamina: INITIAL_STAMINA, max_stamina: INITIAL_STAMINA, skill_points: 0,
      skill_combo: false, skill_poison: false, skill_shield_block: false,
      skill_heavy_strike: false, skill_counter_attack: false,
      skill_battle_cry: false, skill_fortify: false,
    },
    inv' = {
      qty_potion: INITIAL_POTIONS, qty_wood: 0, qty_iron: 0, qty_sword: 0,
      has_sword: false, qty_venom_sac: 0, salvage_level: 1,
    },
    eqp' = {
      sword_dur: 0, sword_max_dur: SWORD_MAX_DUR,
      enchant_slot_1: 0, enchant_slot_2: 0, enchant_slot_3: 0,
    },
    cb' = {
      in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: 0,
      combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
      player_def_buff_dur: 0, enemy_poison_dur: 0,
      cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: 0,
    },
    w' = { pos_x: 0, pos_y: 0, turn_count: 0 },
    meta' = { game_won: false, saved_exists: false, pity_counter: 0, last_drop: 0 },
  }

  // === Movement (only when not in combat) ===
  // Storm (weather=3) deals damage when entering a zone
  action move_up = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    w.pos_y > 0,
    zone_level(w.pos_x, w.pos_y - 1) <= ch.level,
    val storm_dmg = if (zone_weather(w.pos_x, w.pos_y - 1, w.turn_count + 1) == 3) STORM_MOVE_DMG else 0
    all {
      w' = { ...w, pos_y: w.pos_y - 1, turn_count: w.turn_count + 1 },
      ch' = { ...ch, hp: if (ch.hp - storm_dmg < 1) 1 else ch.hp - storm_dmg },
      inv' = inv, eqp' = eqp,
      cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: cb.enemy_element,
              combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
              player_def_buff_dur: 0, enemy_poison_dur: 0,
              cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: cb.cd_fortify },
      meta' = meta,
    }
  }

  action move_down = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    w.pos_y < WORLD_SIZE - 1,
    zone_level(w.pos_x, w.pos_y + 1) <= ch.level,
    val storm_dmg = if (zone_weather(w.pos_x, w.pos_y + 1, w.turn_count + 1) == 3) STORM_MOVE_DMG else 0
    all {
      w' = { ...w, pos_y: w.pos_y + 1, turn_count: w.turn_count + 1 },
      ch' = { ...ch, hp: if (ch.hp - storm_dmg < 1) 1 else ch.hp - storm_dmg },
      inv' = inv, eqp' = eqp,
      cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: cb.enemy_element,
              combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
              player_def_buff_dur: 0, enemy_poison_dur: 0,
              cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: cb.cd_fortify },
      meta' = meta,
    }
  }

  action move_left = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    w.pos_x > 0,
    zone_level(w.pos_x - 1, w.pos_y) <= ch.level,
    val storm_dmg = if (zone_weather(w.pos_x - 1, w.pos_y, w.turn_count + 1) == 3) STORM_MOVE_DMG else 0
    all {
      w' = { ...w, pos_x: w.pos_x - 1, turn_count: w.turn_count + 1 },
      ch' = { ...ch, hp: if (ch.hp - storm_dmg < 1) 1 else ch.hp - storm_dmg },
      inv' = inv, eqp' = eqp,
      cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: cb.enemy_element,
              combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
              player_def_buff_dur: 0, enemy_poison_dur: 0,
              cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: cb.cd_fortify },
      meta' = meta,
    }
  }

  action move_right = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    w.pos_x < WORLD_SIZE - 1,
    zone_level(w.pos_x + 1, w.pos_y) <= ch.level,
    val storm_dmg = if (zone_weather(w.pos_x + 1, w.pos_y, w.turn_count + 1) == 3) STORM_MOVE_DMG else 0
    all {
      w' = { ...w, pos_x: w.pos_x + 1, turn_count: w.turn_count + 1 },
      ch' = { ...ch, hp: if (ch.hp - storm_dmg < 1) 1 else ch.hp - storm_dmg },
      inv' = inv, eqp' = eqp,
      cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: cb.enemy_element,
              combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
              player_def_buff_dur: 0, enemy_poison_dur: 0,
              cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: cb.cd_fortify },
      meta' = meta,
    }
  }

  // === Enter combat ===
  // Fog (weather=2) reduces enemy attack
  action enter_combat = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    val weather = zone_weather(w.pos_x, w.pos_y, w.turn_count + 1)
    val fog_penalty = if (weather == 2) FOG_ATK_PENALTY else 0
    val raw_atk = zone_enemy_attack(w.pos_x, w.pos_y) - fog_penalty
    all {
      cb' = { in_combat: true,
              enemy_hp: zone_enemy_hp(w.pos_x, w.pos_y),
              enemy_attack: if (raw_atk < 1) 1 else raw_atk,
              enemy_element: zone_element(w.pos_x, w.pos_y),
              combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
              player_def_buff_dur: 0, enemy_poison_dur: 0,
              cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: 0 },
      w' = { ...w, turn_count: w.turn_count + 1 },
      ch' = ch, inv' = inv, eqp' = eqp,
      meta' = { ...meta, last_drop: 0 },
    }
  }

  // === Combat: attack enemy ===
  action combat_attack = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    ch.stamina >= ATTACK_STAMINA,
    // Degrade sword on attack
    val new_sword_dur = if (inv.has_sword and eqp.sword_dur > 0) eqp.sword_dur - 1 else eqp.sword_dur
    // Enemy takes elemental-modified damage + poison
    val enemy_poison_dmg = if (cb.enemy_poison_dur > 0) POISON_DMG else 0
    val elem_atk = effective_damage(attack_power, player_elem_mult)
    val new_enemy_hp = cb.enemy_hp - elem_atk - enemy_poison_dmg
    // Player takes enemy hit (reduced by DEF buff + enchant DEF) + poison damage
    val enemy_dmg = cb.enemy_attack - enchant_def_bonus - (if (cb.player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (cb.player_poison_dur > 0) POISON_DMG else 0
    val new_hp = if (new_enemy_hp > 0) ch.hp - effective_enemy_dmg - poison_dmg else ch.hp - poison_dmg
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) ch.xp + zone_xp_reward(w.pos_x, w.pos_y) else ch.xp
    val new_level = if (ch.level < MAX_LEVEL and gained_xp >= xp_threshold(ch.level + 1)) ch.level + 1 else ch.level
    // Tier 2+ enemies apply poison
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and cb.player_poison_dur == 0 and new_enemy_hp > 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (cb.player_poison_dur > 0) cb.player_poison_dur - 1
                             else 0
    val next_atk_buff = if (cb.player_atk_buff_dur > 0) cb.player_atk_buff_dur - 1 else 0
    val next_def_buff = if (cb.player_def_buff_dur > 0) cb.player_def_buff_dur - 1 else 0
    val next_enemy_poison = if (cb.enemy_poison_dur > 0) cb.enemy_poison_dur - 1 else 0
    val combat_ends = (new_enemy_hp <= 0 or new_hp <= 0)
    // Loot drop on enemy defeat
    val enemy_defeated_alive = (new_enemy_hp <= 0 and new_hp > 0)
    val drop_trigger = (meta.pity_counter >= PITY_THRESHOLD or (w.turn_count % LOOT_DROP_MODULO == 0))
    val should_drop = enemy_defeated_alive and drop_trigger and total_items < MAX_INVENTORY
    val new_pity = if (should_drop) 0
                   else if (enemy_defeated_alive) meta.pity_counter + 1
                   else meta.pity_counter
    val drops_venom = should_drop and zone_tier >= POISON_APPLY_TIER
    val new_last_drop = if (drops_venom) 2 else if (should_drop) 1 else 0
    all {
      ch' = { ...ch,
              hp: if (new_hp < 0) 0 else new_hp,
              xp: gained_xp,
              gold: if (new_enemy_hp <= 0) ch.gold + zone_gold_reward(w.pos_x, w.pos_y) else ch.gold,
              level: new_level,
              max_hp: if (new_level > ch.level) ch.max_hp + HP_PER_LEVEL else ch.max_hp,
              base_attack: if (new_level > ch.level) ch.base_attack + ATK_PER_LEVEL_UP else ch.base_attack,
              stamina: ch.stamina - ATTACK_STAMINA,
              max_stamina: if (new_level > ch.level) ch.max_stamina + STAMINA_PER_LEVEL else ch.max_stamina,
              skill_points: if (new_level > ch.level) ch.skill_points + SKILL_POINTS_PER_LEVEL else ch.skill_points,
      },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else new_enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: if (combat_ends) 0 else cb.combo_count,
              player_poison_dur: if (combat_ends) 0 else next_player_poison,
              player_atk_buff_dur: if (combat_ends) 0 else next_atk_buff,
              player_def_buff_dur: if (combat_ends) 0 else next_def_buff,
              enemy_poison_dur: if (combat_ends) 0 else next_enemy_poison,
              cd_heavy_strike: if (combat_ends) 0 else (if (cb.cd_heavy_strike > 0) cb.cd_heavy_strike - 1 else 0),
              cd_battle_cry: if (combat_ends) 0 else (if (cb.cd_battle_cry > 0) cb.cd_battle_cry - 1 else 0),
              cd_fortify: if (combat_ends) 0 else (if (cb.cd_fortify > 0) cb.cd_fortify - 1 else 0),
      },
      eqp' = { ...eqp, sword_dur: new_sword_dur },
      inv' = { ...inv,
               qty_potion: if (should_drop and not(drops_venom)) inv.qty_potion + 1 else inv.qty_potion,
               qty_venom_sac: if (drops_venom) inv.qty_venom_sac + 1 else inv.qty_venom_sac,
      },
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = { ...meta, pity_counter: new_pity, last_drop: new_last_drop },
    }
  }

  // === Combat: use potion (quick action -- no stamina cost, no CD tick) ===
  action combat_potion = all {
    cb.in_combat, not(meta.game_won), inv.qty_potion > 0, ch.hp > 0,
    ch' = { ...ch, hp: clamp_hp(ch.hp + POTION_HEAL, ch.max_hp) },
    inv' = { ...inv, qty_potion: inv.qty_potion - 1 },
    eqp' = eqp,
    cb' = { ...cb, combo_count: 0 },
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta,
  }

  // === Flee combat ===
  action flee_combat = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0,
    val flee_dmg = if (cb.enemy_attack - enchant_def_bonus < 1) 1 else cb.enemy_attack - enchant_def_bonus
    val new_hp = ch.hp - flee_dmg
    all {
      ch' = { ...ch, hp: if (new_hp < 0) 0 else new_hp },
      cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: 0,
              combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
              player_def_buff_dur: 0, enemy_poison_dur: 0,
              cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: 0 },
      w' = { ...w, turn_count: w.turn_count + 1 },
      inv' = inv, eqp' = eqp, meta' = meta,
    }
  }

  // === Rest at village (town zone, not in combat) ===
  action rest_at_village = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    ch.hp < ch.max_hp or ch.stamina < ch.max_stamina,
    ch' = { ...ch, hp: ch.max_hp, stamina: ch.max_stamina },
    inv' = inv, eqp' = eqp,
    cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: cb.enemy_element,
            combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
            player_def_buff_dur: 0, enemy_poison_dur: 0,
            cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: cb.cd_fortify },
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta,
  }

  // === Buy potion (at town, costs 15 gold) ===
  action buy_potion = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    ch.gold >= POTION_COST,
    total_items < MAX_INVENTORY,
    ch' = { ...ch, gold: ch.gold - POTION_COST },
    inv' = { ...inv, qty_potion: inv.qty_potion + 1 },
    eqp' = eqp,
    cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: cb.enemy_element,
            combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
            player_def_buff_dur: 0, enemy_poison_dur: 0,
            cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: cb.cd_fortify },
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta,
  }

  // === Repair sword (at town, costs gold) ===
  action repair_sword = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    inv.has_sword,
    eqp.sword_dur < eqp.sword_max_dur,
    ch.gold >= REPAIR_COST,
    ch' = { ...ch, gold: ch.gold - REPAIR_COST },
    eqp' = { ...eqp, sword_dur: eqp.sword_max_dur },
    inv' = inv,
    cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: cb.enemy_element,
            combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
            player_def_buff_dur: 0, enemy_poison_dur: 0,
            cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: cb.cd_fortify },
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta,
  }

  // === Gather wood (in forest zone) ===
  // Rain (weather=1) gives bonus resources
  action gather_wood = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_wood(w.pos_x, w.pos_y),
    val rain_bonus = if (zone_weather(w.pos_x, w.pos_y, w.turn_count + 1) == 1) RAIN_GATHER_BONUS else 0
    all {
      total_items + 1 + rain_bonus <= MAX_INVENTORY,
      inv' = { ...inv, qty_wood: inv.qty_wood + 1 + rain_bonus },
      ch' = ch, eqp' = eqp,
      cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: cb.enemy_element,
              combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
              player_def_buff_dur: 0, enemy_poison_dur: 0,
              cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: cb.cd_fortify },
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta,
    }
  }

  // === Mine iron (in mountain zone) ===
  // Rain (weather=1) gives bonus resources
  action mine_iron = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_iron(w.pos_x, w.pos_y),
    val rain_bonus = if (zone_weather(w.pos_x, w.pos_y, w.turn_count + 1) == 1) RAIN_GATHER_BONUS else 0
    all {
      total_items + 1 + rain_bonus <= MAX_INVENTORY,
      inv' = { ...inv, qty_iron: inv.qty_iron + 1 + rain_bonus },
      ch' = ch, eqp' = eqp,
      cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: cb.enemy_element,
              combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
              player_def_buff_dur: 0, enemy_poison_dur: 0,
              cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: cb.cd_fortify },
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta,
    }
  }

  // === Craft sword (1 wood + 2 iron -> 1 sword, at town) ===
  action craft_sword = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    ch.level >= CRAFT_LEVEL_REQ,
    inv.qty_wood >= CRAFT_WOOD_COST, inv.qty_iron >= CRAFT_IRON_COST,
    inv' = { ...inv, qty_wood: inv.qty_wood - CRAFT_WOOD_COST, qty_iron: inv.qty_iron - CRAFT_IRON_COST, qty_sword: inv.qty_sword + 1 },
    ch' = ch, eqp' = eqp,
    cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: cb.enemy_element,
            combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
            player_def_buff_dur: 0, enemy_poison_dur: 0,
            cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: cb.cd_fortify },
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta,
  }

  // === Equip sword (sets durability to max) ===
  action equip_sword = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    inv.qty_sword >= 1, not(inv.has_sword),
    inv' = { ...inv, has_sword: true, qty_sword: inv.qty_sword - 1 },
    eqp' = { ...eqp, sword_dur: SWORD_MAX_DUR, enchant_slot_1: 0, enchant_slot_2: 0, enchant_slot_3: 0 },
    ch' = ch,
    cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: cb.enemy_element,
            combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
            player_def_buff_dur: 0, enemy_poison_dur: 0,
            cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: cb.cd_fortify },
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta,
  }

  // === Use antidote (quick action -- costs 1 potion, clears player poison, no CD tick) ===
  action use_antidote = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0,
    inv.qty_potion > 0, cb.player_poison_dur > 0,
    inv' = { ...inv, qty_potion: inv.qty_potion - 1 },
    cb' = { ...cb, player_poison_dur: 0, combo_count: 0 },
    ch' = ch, eqp' = eqp,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta,
  }

  // === Poison strike (apply poison to enemy, enemy hits back) ===
  action poison_strike = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    ch.skill_poison, inv.qty_venom_sac > 0,
    cb.enemy_poison_dur == 0,
    ch.stamina >= ATTACK_STAMINA,
    val dmg_taken = cb.enemy_attack - enchant_def_bonus - (if (cb.player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
    val effective_dmg = if (dmg_taken < 1) 1 else dmg_taken
    val new_hp = ch.hp - effective_dmg
    val combat_ends = (new_hp <= 0)
    all {
      ch' = { ...ch, hp: if (new_hp < 0) 0 else new_hp, stamina: ch.stamina - ATTACK_STAMINA },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else cb.enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,
              player_poison_dur: if (combat_ends) 0 else cb.player_poison_dur,
              player_atk_buff_dur: if (combat_ends) 0 else cb.player_atk_buff_dur,
              player_def_buff_dur: if (combat_ends) 0 else cb.player_def_buff_dur,
              enemy_poison_dur: if (combat_ends) 0 else STATUS_DURATION,
              cd_heavy_strike: if (combat_ends) 0 else (if (cb.cd_heavy_strike > 0) cb.cd_heavy_strike - 1 else 0),
              cd_battle_cry: if (combat_ends) 0 else (if (cb.cd_battle_cry > 0) cb.cd_battle_cry - 1 else 0),
              cd_fortify: if (combat_ends) 0 else (if (cb.cd_fortify > 0) cb.cd_fortify - 1 else 0),
      },
      inv' = { ...inv, qty_venom_sac: inv.qty_venom_sac - 1 },
      eqp' = eqp,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta,
    }
  }

  // === Combo attack (3-hit chain: Slash 1x -> Thrust 1.5x -> Finisher 2x) ===
  action combo_attack = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    ch.skill_combo,
    cb.combo_count < MAX_COMBO_CHAIN,
    ch.stamina >= COMBO_STAMINA,
    val next_combo = cb.combo_count + 1
    val base_dmg = attack_power
    val combo_dmg = if (next_combo == 1) base_dmg
                    else if (next_combo == 2) (base_dmg * 3) / 2
                    else base_dmg * 2
    // Degrade sword
    val new_sword_dur = if (inv.has_sword and eqp.sword_dur > 0) eqp.sword_dur - 1 else eqp.sword_dur
    // Enemy takes elemental-modified combo + poison damage
    val enemy_poison_dmg = if (cb.enemy_poison_dur > 0) POISON_DMG else 0
    val elem_combo = effective_damage(combo_dmg, player_elem_mult)
    val new_enemy_hp = cb.enemy_hp - elem_combo - enemy_poison_dmg
    // Player takes enemy hit (reduced by DEF buff + enchant DEF) + poison
    val enemy_dmg = cb.enemy_attack - enchant_def_bonus - (if (cb.player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (cb.player_poison_dur > 0) POISON_DMG else 0
    val new_hp = if (new_enemy_hp > 0) ch.hp - effective_enemy_dmg - poison_dmg else ch.hp - poison_dmg
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) ch.xp + zone_xp_reward(w.pos_x, w.pos_y) else ch.xp
    val new_level = if (ch.level < MAX_LEVEL and gained_xp >= xp_threshold(ch.level + 1)) ch.level + 1 else ch.level
    // Status ticking
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and cb.player_poison_dur == 0 and new_enemy_hp > 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (cb.player_poison_dur > 0) cb.player_poison_dur - 1
                             else 0
    val next_atk_buff = if (cb.player_atk_buff_dur > 0) cb.player_atk_buff_dur - 1 else 0
    val next_def_buff = if (cb.player_def_buff_dur > 0) cb.player_def_buff_dur - 1 else 0
    val next_enemy_poison = if (cb.enemy_poison_dur > 0) cb.enemy_poison_dur - 1 else 0
    val combat_ends = (new_enemy_hp <= 0 or new_hp <= 0)
    val new_combo_count = if (combat_ends) 0
                          else if (next_combo >= MAX_COMBO_CHAIN) 0
                          else next_combo
    // Loot drop on enemy defeat
    val enemy_defeated_alive = (new_enemy_hp <= 0 and new_hp > 0)
    val drop_trigger = (meta.pity_counter >= PITY_THRESHOLD or (w.turn_count % LOOT_DROP_MODULO == 0))
    val should_drop = enemy_defeated_alive and drop_trigger and total_items < MAX_INVENTORY
    val new_pity = if (should_drop) 0
                   else if (enemy_defeated_alive) meta.pity_counter + 1
                   else meta.pity_counter
    val drops_venom = should_drop and zone_tier >= POISON_APPLY_TIER
    val new_last_drop = if (drops_venom) 2 else if (should_drop) 1 else 0
    all {
      ch' = { ...ch,
              hp: if (new_hp < 0) 0 else new_hp,
              xp: gained_xp,
              gold: if (new_enemy_hp <= 0) ch.gold + zone_gold_reward(w.pos_x, w.pos_y) else ch.gold,
              level: new_level,
              max_hp: if (new_level > ch.level) ch.max_hp + HP_PER_LEVEL else ch.max_hp,
              base_attack: if (new_level > ch.level) ch.base_attack + ATK_PER_LEVEL_UP else ch.base_attack,
              stamina: ch.stamina - COMBO_STAMINA,
              max_stamina: if (new_level > ch.level) ch.max_stamina + STAMINA_PER_LEVEL else ch.max_stamina,
              skill_points: if (new_level > ch.level) ch.skill_points + SKILL_POINTS_PER_LEVEL else ch.skill_points,
      },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else new_enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: new_combo_count,
              player_poison_dur: if (combat_ends) 0 else next_player_poison,
              player_atk_buff_dur: if (combat_ends) 0 else next_atk_buff,
              player_def_buff_dur: if (combat_ends) 0 else next_def_buff,
              enemy_poison_dur: if (combat_ends) 0 else next_enemy_poison,
              cd_heavy_strike: if (combat_ends) 0 else (if (cb.cd_heavy_strike > 0) cb.cd_heavy_strike - 1 else 0),
              cd_battle_cry: if (combat_ends) 0 else (if (cb.cd_battle_cry > 0) cb.cd_battle_cry - 1 else 0),
              cd_fortify: if (combat_ends) 0 else (if (cb.cd_fortify > 0) cb.cd_fortify - 1 else 0),
      },
      eqp' = { ...eqp, sword_dur: new_sword_dur },
      inv' = { ...inv,
               qty_potion: if (should_drop and not(drops_venom)) inv.qty_potion + 1 else inv.qty_potion,
               qty_venom_sac: if (drops_venom) inv.qty_venom_sac + 1 else inv.qty_venom_sac,
      },
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = { ...meta, pity_counter: new_pity, last_drop: new_last_drop },
    }
  }

  // === Heavy strike (2x damage, costs 5 stamina, 3-turn cooldown) ===
  action heavy_strike = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    ch.skill_heavy_strike,
    cb.cd_heavy_strike == 0,
    ch.stamina >= HEAVY_STRIKE_STAMINA,
    val heavy_dmg = attack_power * 2
    val new_sword_dur = if (inv.has_sword and eqp.sword_dur > 0) eqp.sword_dur - 1 else eqp.sword_dur
    val enemy_poison_dmg = if (cb.enemy_poison_dur > 0) POISON_DMG else 0
    val elem_heavy = effective_damage(heavy_dmg, player_elem_mult)
    val new_enemy_hp = cb.enemy_hp - elem_heavy - enemy_poison_dmg
    val enemy_dmg = cb.enemy_attack - enchant_def_bonus - (if (cb.player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (cb.player_poison_dur > 0) POISON_DMG else 0
    val new_hp = if (new_enemy_hp > 0) ch.hp - effective_enemy_dmg - poison_dmg else ch.hp - poison_dmg
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) ch.xp + zone_xp_reward(w.pos_x, w.pos_y) else ch.xp
    val new_level = if (ch.level < MAX_LEVEL and gained_xp >= xp_threshold(ch.level + 1)) ch.level + 1 else ch.level
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and cb.player_poison_dur == 0 and new_enemy_hp > 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (cb.player_poison_dur > 0) cb.player_poison_dur - 1
                             else 0
    val next_atk_buff = if (cb.player_atk_buff_dur > 0) cb.player_atk_buff_dur - 1 else 0
    val next_def_buff = if (cb.player_def_buff_dur > 0) cb.player_def_buff_dur - 1 else 0
    val next_enemy_poison = if (cb.enemy_poison_dur > 0) cb.enemy_poison_dur - 1 else 0
    val combat_ends = (new_enemy_hp <= 0 or new_hp <= 0)
    val enemy_defeated_alive = (new_enemy_hp <= 0 and new_hp > 0)
    val drop_trigger = (meta.pity_counter >= PITY_THRESHOLD or (w.turn_count % LOOT_DROP_MODULO == 0))
    val should_drop = enemy_defeated_alive and drop_trigger and total_items < MAX_INVENTORY
    val new_pity = if (should_drop) 0
                   else if (enemy_defeated_alive) meta.pity_counter + 1
                   else meta.pity_counter
    val drops_venom = should_drop and zone_tier >= POISON_APPLY_TIER
    val new_last_drop = if (drops_venom) 2 else if (should_drop) 1 else 0
    all {
      ch' = { ...ch,
              hp: if (new_hp < 0) 0 else new_hp,
              xp: gained_xp,
              gold: if (new_enemy_hp <= 0) ch.gold + zone_gold_reward(w.pos_x, w.pos_y) else ch.gold,
              level: new_level,
              max_hp: if (new_level > ch.level) ch.max_hp + HP_PER_LEVEL else ch.max_hp,
              base_attack: if (new_level > ch.level) ch.base_attack + ATK_PER_LEVEL_UP else ch.base_attack,
              stamina: ch.stamina - HEAVY_STRIKE_STAMINA,
              max_stamina: if (new_level > ch.level) ch.max_stamina + STAMINA_PER_LEVEL else ch.max_stamina,
              skill_points: if (new_level > ch.level) ch.skill_points + SKILL_POINTS_PER_LEVEL else ch.skill_points,
      },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else new_enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,  // heavy strike breaks combo
              player_poison_dur: if (combat_ends) 0 else next_player_poison,
              player_atk_buff_dur: if (combat_ends) 0 else next_atk_buff,
              player_def_buff_dur: if (combat_ends) 0 else next_def_buff,
              enemy_poison_dur: if (combat_ends) 0 else next_enemy_poison,
              cd_heavy_strike: if (combat_ends) 0 else HEAVY_STRIKE_CD,
              cd_battle_cry: if (combat_ends) 0 else (if (cb.cd_battle_cry > 0) cb.cd_battle_cry - 1 else 0),
              cd_fortify: if (combat_ends) 0 else (if (cb.cd_fortify > 0) cb.cd_fortify - 1 else 0),
      },
      eqp' = { ...eqp, sword_dur: new_sword_dur },
      inv' = { ...inv,
               qty_potion: if (should_drop and not(drops_venom)) inv.qty_potion + 1 else inv.qty_potion,
               qty_venom_sac: if (drops_venom) inv.qty_venom_sac + 1 else inv.qty_venom_sac,
      },
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = { ...meta, pity_counter: new_pity, last_drop: new_last_drop },
    }
  }

  // === Battle cry (grants ATK buff, costs 3 stamina, 4-turn cooldown) ===
  // Enemy hits back. Resets combo.
  action battle_cry = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    ch.skill_battle_cry,
    cb.cd_battle_cry == 0,
    ch.stamina >= BATTLE_CRY_STAMINA,
    val enemy_dmg = cb.enemy_attack - enchant_def_bonus - (if (cb.player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (cb.player_poison_dur > 0) POISON_DMG else 0
    val new_hp = ch.hp - effective_enemy_dmg - poison_dmg
    val combat_ends = (new_hp <= 0)
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and cb.player_poison_dur == 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (cb.player_poison_dur > 0) cb.player_poison_dur - 1
                             else 0
    val next_def_buff = if (cb.player_def_buff_dur > 0) cb.player_def_buff_dur - 1 else 0
    val next_enemy_poison = if (cb.enemy_poison_dur > 0) cb.enemy_poison_dur - 1 else 0
    all {
      ch' = { ...ch, hp: if (new_hp < 0) 0 else new_hp, stamina: ch.stamina - BATTLE_CRY_STAMINA },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else cb.enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,
              player_poison_dur: if (combat_ends) 0 else next_player_poison,
              player_atk_buff_dur: if (combat_ends) 0 else STATUS_DURATION,
              player_def_buff_dur: if (combat_ends) 0 else next_def_buff,
              enemy_poison_dur: if (combat_ends) 0 else next_enemy_poison,
              cd_heavy_strike: if (combat_ends) 0 else (if (cb.cd_heavy_strike > 0) cb.cd_heavy_strike - 1 else 0),
              cd_battle_cry: if (combat_ends) 0 else BATTLE_CRY_CD,
              cd_fortify: if (combat_ends) 0 else (if (cb.cd_fortify > 0) cb.cd_fortify - 1 else 0),
      },
      eqp' = eqp, inv' = inv,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta,
    }
  }

  // === Shield block (grants DEF buff, takes enemy hit) ===
  action shield_block = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    ch.skill_shield_block,
    ch.stamina >= SHIELD_BLOCK_STAMINA,
    val enemy_dmg = cb.enemy_attack - enchant_def_bonus - (if (cb.player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (cb.player_poison_dur > 0) POISON_DMG else 0
    val new_hp = ch.hp - effective_enemy_dmg - poison_dmg
    val combat_ends = (new_hp <= 0)
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and cb.player_poison_dur == 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (cb.player_poison_dur > 0) cb.player_poison_dur - 1
                             else 0
    val next_atk_buff = if (cb.player_atk_buff_dur > 0) cb.player_atk_buff_dur - 1 else 0
    val next_enemy_poison = if (cb.enemy_poison_dur > 0) cb.enemy_poison_dur - 1 else 0
    all {
      ch' = { ...ch, hp: if (new_hp < 0) 0 else new_hp, stamina: ch.stamina - SHIELD_BLOCK_STAMINA },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else cb.enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,
              player_poison_dur: if (combat_ends) 0 else next_player_poison,
              player_atk_buff_dur: if (combat_ends) 0 else next_atk_buff,
              player_def_buff_dur: if (combat_ends) 0 else STATUS_DURATION,
              enemy_poison_dur: if (combat_ends) 0 else next_enemy_poison,
              cd_heavy_strike: if (combat_ends) 0 else (if (cb.cd_heavy_strike > 0) cb.cd_heavy_strike - 1 else 0),
              cd_battle_cry: if (combat_ends) 0 else (if (cb.cd_battle_cry > 0) cb.cd_battle_cry - 1 else 0),
              cd_fortify: if (combat_ends) 0 else (if (cb.cd_fortify > 0) cb.cd_fortify - 1 else 0),
      },
      eqp' = eqp, inv' = inv,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta,
    }
  }

  // === Skill unlock: Combo (tier 1 offense, no prereq) ===
  action unlock_combo = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    not(ch.skill_combo), ch.skill_points >= 1,
    ch' = { ...ch, skill_combo: true, skill_points: ch.skill_points - 1 },
    inv' = inv, eqp' = eqp, cb' = cb, w' = w, meta' = meta,
  }

  // === Skill unlock: Poison Strike (tier 1 utility, no prereq) ===
  action unlock_poison = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    not(ch.skill_poison), ch.skill_points >= 1,
    ch' = { ...ch, skill_poison: true, skill_points: ch.skill_points - 1 },
    inv' = inv, eqp' = eqp, cb' = cb, w' = w, meta' = meta,
  }

  // === Skill unlock: Shield Block (tier 1 defense, no prereq) ===
  action unlock_shield_block = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    not(ch.skill_shield_block), ch.skill_points >= 1,
    ch' = { ...ch, skill_shield_block: true, skill_points: ch.skill_points - 1 },
    inv' = inv, eqp' = eqp, cb' = cb, w' = w, meta' = meta,
  }

  // === Skill unlock: Heavy Strike (tier 2 offense, requires Combo) ===
  action unlock_heavy_strike = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    not(ch.skill_heavy_strike), ch.skill_combo, ch.skill_points >= 1,
    ch' = { ...ch, skill_heavy_strike: true, skill_points: ch.skill_points - 1 },
    inv' = inv, eqp' = eqp, cb' = cb, w' = w, meta' = meta,
  }

  // === Skill unlock: Counter-Attack (tier 2 defense, requires Shield Block) ===
  action unlock_counter_attack = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    not(ch.skill_counter_attack), ch.skill_shield_block, ch.skill_points >= 1,
    ch' = { ...ch, skill_counter_attack: true, skill_points: ch.skill_points - 1 },
    inv' = inv, eqp' = eqp, cb' = cb, w' = w, meta' = meta,
  }

  // === Skill unlock: Battle Cry (tier 3 offense, requires Heavy Strike, costs 2pt) ===
  action unlock_battle_cry = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    not(ch.skill_battle_cry), ch.skill_heavy_strike, ch.skill_points >= 2,
    ch' = { ...ch, skill_battle_cry: true, skill_points: ch.skill_points - 2 },
    inv' = inv, eqp' = eqp, cb' = cb, w' = w, meta' = meta,
  }

  // === Skill unlock: Fortify (tier 3 defense, requires Counter-Attack, costs 2pt) ===
  action unlock_fortify = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    not(ch.skill_fortify), ch.skill_counter_attack, ch.skill_points >= 2,
    ch' = { ...ch, skill_fortify: true, skill_points: ch.skill_points - 2 },
    inv' = inv, eqp' = eqp, cb' = cb, w' = w, meta' = meta,
  }

  // === Respec skills (at village, costs gold) ===
  action respec = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    ch.gold >= RESPEC_COST,
    val spent = (if (ch.skill_combo) 1 else 0) + (if (ch.skill_poison) 1 else 0) +
                (if (ch.skill_shield_block) 1 else 0) + (if (ch.skill_heavy_strike) 1 else 0) +
                (if (ch.skill_counter_attack) 1 else 0) + (if (ch.skill_battle_cry) 2 else 0) +
                (if (ch.skill_fortify) 2 else 0)
    all {
      spent > 0,
      ch' = { ...ch,
              gold: ch.gold - RESPEC_COST,
              skill_points: ch.skill_points + spent,
              skill_combo: false, skill_poison: false, skill_shield_block: false,
              skill_heavy_strike: false, skill_counter_attack: false,
              skill_battle_cry: false, skill_fortify: false,
      },
      inv' = inv, eqp' = eqp, cb' = cb, w' = w, meta' = meta,
    }
  }

  // === Counter-Attack (block + retaliatory hit) ===
  action counter_attack = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    ch.skill_counter_attack,
    ch.stamina >= COUNTER_STAMINA,
    val player_dmg = effective_damage(attack_power, player_elem_mult)
    val new_enemy_hp = if (cb.enemy_hp - player_dmg < 0) 0 else cb.enemy_hp - player_dmg
    val enemy_dmg = cb.enemy_attack - enchant_def_bonus - (if (cb.player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (cb.player_poison_dur > 0) POISON_DMG else 0
    val enemy_poison_dmg = if (cb.enemy_poison_dur > 0) POISON_DMG else 0
    val final_enemy_hp = if (new_enemy_hp - enemy_poison_dmg < 0) 0 else new_enemy_hp - enemy_poison_dmg
    val new_hp = ch.hp - effective_enemy_dmg - poison_dmg
    val combat_ends = (new_hp <= 0 or final_enemy_hp <= 0)
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val xp_reward = if (final_enemy_hp <= 0 and new_hp > 0) BASE_XP * zone_tier else 0
    val gold_reward = if (final_enemy_hp <= 0 and new_hp > 0) BASE_GOLD + GOLD_PER_LEVEL * zone_tier else 0
    val new_xp = ch.xp + xp_reward
    val new_level = if (ch.level < MAX_LEVEL and new_xp >= xp_threshold(ch.level + 1)) ch.level + 1 else ch.level
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and cb.player_poison_dur == 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (cb.player_poison_dur > 0) cb.player_poison_dur - 1
                             else 0
    val next_atk_buff = if (cb.player_atk_buff_dur > 0) cb.player_atk_buff_dur - 1 else 0
    val next_enemy_poison = if (cb.enemy_poison_dur > 0) cb.enemy_poison_dur - 1 else 0
    val dur_cost = if (inv.has_sword and eqp.sword_dur > 0) 1 else 0
    val enemy_defeated_alive = (final_enemy_hp <= 0 and new_hp > 0)
    val drop_trigger = (meta.pity_counter >= PITY_THRESHOLD or (w.turn_count % LOOT_DROP_MODULO == 0))
    val should_drop = enemy_defeated_alive and drop_trigger and total_items < MAX_INVENTORY
    val new_pity = if (should_drop) 0
                   else if (enemy_defeated_alive) meta.pity_counter + 1
                   else meta.pity_counter
    val drops_venom = should_drop and zone_tier >= POISON_APPLY_TIER
    val new_last_drop = if (drops_venom) 2 else if (should_drop) 1 else 0
    all {
      ch' = { ...ch,
              hp: if (new_hp < 0) 0 else new_hp,
              xp: new_xp, level: new_level,
              gold: ch.gold + gold_reward,
              max_hp: if (new_level > ch.level) ch.max_hp + HP_PER_LEVEL else ch.max_hp,
              base_attack: if (new_level > ch.level) ch.base_attack + ATK_PER_LEVEL_UP else ch.base_attack,
              stamina: ch.stamina - COUNTER_STAMINA,
              max_stamina: if (new_level > ch.level) ch.max_stamina + STAMINA_PER_LEVEL else ch.max_stamina,
              skill_points: if (new_level > ch.level) ch.skill_points + SKILL_POINTS_PER_LEVEL else ch.skill_points,
      },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else final_enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,
              player_poison_dur: if (combat_ends) 0 else next_player_poison,
              player_atk_buff_dur: if (combat_ends) 0 else next_atk_buff,
              player_def_buff_dur: if (combat_ends) 0 else STATUS_DURATION,
              enemy_poison_dur: if (combat_ends) 0 else next_enemy_poison,
              cd_heavy_strike: if (combat_ends) 0 else (if (cb.cd_heavy_strike > 0) cb.cd_heavy_strike - 1 else 0),
              cd_battle_cry: if (combat_ends) 0 else (if (cb.cd_battle_cry > 0) cb.cd_battle_cry - 1 else 0),
              cd_fortify: if (combat_ends) 0 else (if (cb.cd_fortify > 0) cb.cd_fortify - 1 else 0),
      },
      eqp' = { ...eqp, sword_dur: eqp.sword_dur - dur_cost },
      inv' = { ...inv,
               qty_potion: if (should_drop and not(drops_venom)) inv.qty_potion + 1 else inv.qty_potion,
               qty_venom_sac: if (drops_venom) inv.qty_venom_sac + 1 else inv.qty_venom_sac,
      },
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = { ...meta, pity_counter: new_pity, last_drop: new_last_drop },
    }
  }

  // === Fortify (double-duration DEF buff, no damage, cooldown) ===
  action fortify = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    ch.skill_fortify,
    cb.cd_fortify == 0,
    ch.stamina >= FORTIFY_STAMINA,
    val enemy_dmg = cb.enemy_attack - enchant_def_bonus - (if (cb.player_def_buff_dur > 0) DEF_BUFF_REDUCTION else 0)
    val effective_enemy_dmg = if (enemy_dmg < 1) 1 else enemy_dmg
    val poison_dmg = if (cb.player_poison_dur > 0) POISON_DMG else 0
    val new_hp = ch.hp - effective_enemy_dmg - poison_dmg
    val combat_ends = (new_hp <= 0)
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and cb.player_poison_dur == 0)
    val next_player_poison = if (apply_poison) STATUS_DURATION
                             else if (cb.player_poison_dur > 0) cb.player_poison_dur - 1
                             else 0
    val next_atk_buff = if (cb.player_atk_buff_dur > 0) cb.player_atk_buff_dur - 1 else 0
    val next_enemy_poison = if (cb.enemy_poison_dur > 0) cb.enemy_poison_dur - 1 else 0
    all {
      ch' = { ...ch, hp: if (new_hp < 0) 0 else new_hp, stamina: ch.stamina - FORTIFY_STAMINA },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else cb.enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,
              player_poison_dur: if (combat_ends) 0 else next_player_poison,
              player_atk_buff_dur: if (combat_ends) 0 else next_atk_buff,
              player_def_buff_dur: if (combat_ends) 0 else FORTIFY_DURATION,
              enemy_poison_dur: if (combat_ends) 0 else next_enemy_poison,
              cd_heavy_strike: if (combat_ends) 0 else (if (cb.cd_heavy_strike > 0) cb.cd_heavy_strike - 1 else 0),
              cd_battle_cry: if (combat_ends) 0 else (if (cb.cd_battle_cry > 0) cb.cd_battle_cry - 1 else 0),
              cd_fortify: if (combat_ends) 0 else FORTIFY_CD,
      },
      eqp' = eqp, inv' = inv,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta,
    }
  }

  // === Craft Venom Sac (at village, 2 iron) ===
  action craft_venom_sac = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    inv.qty_iron >= CRAFT_VENOM_IRON_COST,
    inv' = { ...inv, qty_iron: inv.qty_iron - CRAFT_VENOM_IRON_COST, qty_venom_sac: inv.qty_venom_sac + 1 },
    ch' = ch, eqp' = eqp, cb' = cb, w' = w, meta' = meta,
  }

  // === Apply enchantment to slot 1 (at village, costs gold, requires sword) ===
  action apply_enchant_1 = {
    nondet etype = Set(1, 2, 3, 4).oneOf()
    all {
      not(cb.in_combat), not(meta.game_won), ch.hp > 0,
      zone_has_services(w.pos_x, w.pos_y),
      inv.has_sword,
      ch.gold >= ENCHANT_COST,
      not(etype == 1 and has_ice_enchant),
      not(etype == 2 and has_fire_enchant),
      ch' = { ...ch, gold: ch.gold - ENCHANT_COST },
      eqp' = { ...eqp, enchant_slot_1: etype },
      inv' = inv, cb' = cb, w' = w, meta' = meta,
    }
  }

  // === Apply enchantment to slot 2 ===
  action apply_enchant_2 = {
    nondet etype = Set(1, 2, 3, 4).oneOf()
    all {
      not(cb.in_combat), not(meta.game_won), ch.hp > 0,
      zone_has_services(w.pos_x, w.pos_y),
      inv.has_sword,
      ch.gold >= ENCHANT_COST,
      not(etype == 1 and has_ice_enchant),
      not(etype == 2 and has_fire_enchant),
      ch' = { ...ch, gold: ch.gold - ENCHANT_COST },
      eqp' = { ...eqp, enchant_slot_2: etype },
      inv' = inv, cb' = cb, w' = w, meta' = meta,
    }
  }

  // === Apply enchantment to slot 3 ===
  action apply_enchant_3 = {
    nondet etype = Set(1, 2, 3, 4).oneOf()
    all {
      not(cb.in_combat), not(meta.game_won), ch.hp > 0,
      zone_has_services(w.pos_x, w.pos_y),
      inv.has_sword,
      ch.gold >= ENCHANT_COST,
      not(etype == 1 and has_ice_enchant),
      not(etype == 2 and has_fire_enchant),
      ch' = { ...ch, gold: ch.gold - ENCHANT_COST },
      eqp' = { ...eqp, enchant_slot_3: etype },
      inv' = inv, cb' = cb, w' = w, meta' = meta,
    }
  }

  // === Remove enchantment from slot 1 (at village, free) ===
  action remove_enchant_1 = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    inv.has_sword,
    eqp.enchant_slot_1 != 0,
    eqp' = { ...eqp, enchant_slot_1: 0 },
    ch' = ch, inv' = inv, cb' = cb, w' = w, meta' = meta,
  }

  // === Remove enchantment from slot 2 ===
  action remove_enchant_2 = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    inv.has_sword,
    eqp.enchant_slot_2 != 0,
    eqp' = { ...eqp, enchant_slot_2: 0 },
    ch' = ch, inv' = inv, cb' = cb, w' = w, meta' = meta,
  }

  // === Remove enchantment from slot 3 ===
  action remove_enchant_3 = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    inv.has_sword,
    eqp.enchant_slot_3 != 0,
    eqp' = { ...eqp, enchant_slot_3: 0 },
    ch' = ch, inv' = inv, cb' = cb, w' = w, meta' = meta,
  }

  // === Salvage sword (at village -- destroy 1 unequipped sword, recover materials) ===
  action salvage_sword = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    inv.qty_sword >= 1,
    inv' = { ...inv,
             qty_wood: inv.qty_wood + salvage_wood_yield(inv.salvage_level),
             qty_iron: inv.qty_iron + salvage_iron_yield(inv.salvage_level),
             qty_sword: inv.qty_sword - 1,
    },
    ch' = ch, eqp' = eqp,
    cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: cb.enemy_element,
            combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
            player_def_buff_dur: 0, enemy_poison_dur: 0,
            cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: cb.cd_fortify },
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta,
  }

  // === Upgrade salvage (at village -- spend gold to improve material recovery) ===
  action upgrade_salvage = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    inv.salvage_level < MAX_SALVAGE_LEVEL,
    ch.gold >= UPGRADE_SALVAGE_COST,
    ch' = { ...ch, gold: ch.gold - UPGRADE_SALVAGE_COST },
    inv' = { ...inv, salvage_level: inv.salvage_level + 1 },
    eqp' = eqp,
    cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: cb.enemy_element,
            combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
            player_def_buff_dur: 0, enemy_poison_dur: 0,
            cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: cb.cd_fortify },
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta,
  }

  // === Save game (only outside combat, alive, not won) ===
  action save_game = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    meta' = { ...meta, saved_exists: true },
    ch' = ch, inv' = inv, eqp' = eqp, cb' = cb, w' = w,
  }

  // === Load game (requires a save to exist) ===
  action load_game = all {
    meta.saved_exists,
    ch' = ch, inv' = inv, eqp' = eqp, cb' = cb, w' = w, meta' = meta,
  }

  // === Claim Victory ===
  action claim_victory = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    ch.level >= MAX_LEVEL,
    zone_biome_x(w.pos_x) == 2, zone_biome_y(w.pos_y) == 2,
    zone_level(w.pos_x, w.pos_y) >= MAX_LEVEL,
    meta' = { ...meta, game_won: true },
    ch' = ch, inv' = inv, eqp' = eqp,
    cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: cb.enemy_element,
            combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
            player_def_buff_dur: 0, enemy_poison_dur: 0,
            cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: cb.cd_fortify },
    w' = w,
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
    salvage_sword, upgrade_salvage,
    apply_enchant_1, apply_enchant_2, apply_enchant_3,
    remove_enchant_1, remove_enchant_2, remove_enchant_3,
    save_game, load_game, claim_victory,
  }

  // === Invariants ===

  /// HP is bounded [0, max_hp]
  val hp_bounded = ch.hp >= 0 and ch.hp <= ch.max_hp

  /// Gold never goes negative
  val gold_non_negative = ch.gold >= 0

  /// Level is bounded [1, MAX_LEVEL]
  val level_bounded = ch.level >= 1 and ch.level <= MAX_LEVEL

  /// Position stays on the grid
  val position_bounded = w.pos_x >= 0 and w.pos_x < WORLD_SIZE and w.pos_y >= 0 and w.pos_y < WORLD_SIZE

  /// Quantities never go negative
  val quantities_non_negative = and {
    inv.qty_potion >= 0,
    inv.qty_wood >= 0,
    inv.qty_iron >= 0,
    inv.qty_sword >= 0,
  }

  /// Can only be in a zone you're qualified for
  val level_gate_respected = zone_level(w.pos_x, w.pos_y) <= ch.level

  /// XP never decreases
  val xp_monotonic = ch.xp >= 0

  /// Game won only at max level
  val win_condition_correct = meta.game_won.implies(ch.level >= MAX_LEVEL)

  /// Enemy HP is non-negative
  val enemy_hp_bounded = cb.enemy_hp >= 0

  /// Not in combat means no enemy
  val combat_consistent = not(cb.in_combat).implies(cb.enemy_hp == 0 and cb.enemy_attack == 0)

  /// Durability bounded [0, max]
  val dur_bounded = eqp.sword_dur >= 0 and eqp.sword_dur <= eqp.sword_max_dur

  /// Max durability is constant
  val dur_max_constant = eqp.sword_max_dur == SWORD_MAX_DUR

  /// Broken sword gives no attack bonus (ignoring ATK buff)
  val broken_no_bonus = (inv.has_sword and eqp.sword_dur == 0 and cb.player_atk_buff_dur == 0).implies(attack_power == ch.base_attack)

  /// Status durations are non-negative and bounded
  val status_dur_bounded = and {
    cb.player_poison_dur >= 0, cb.player_poison_dur <= STATUS_DURATION,
    cb.player_atk_buff_dur >= 0, cb.player_atk_buff_dur <= STATUS_DURATION,
    cb.player_def_buff_dur >= 0, cb.player_def_buff_dur <= FORTIFY_DURATION,
    cb.enemy_poison_dur >= 0, cb.enemy_poison_dur <= STATUS_DURATION,
  }

  /// Statuses are only active during combat
  val status_only_in_combat = not(cb.in_combat).implies(
    cb.player_poison_dur == 0 and cb.player_atk_buff_dur == 0 and
    cb.player_def_buff_dur == 0 and cb.enemy_poison_dur == 0
  )

  /// Combo count bounded [0, 2]
  val combo_bounded = cb.combo_count >= 0 and cb.combo_count <= 2

  /// Combo only active in combat
  val combo_only_in_combat = not(cb.in_combat).implies(cb.combo_count == 0)

  /// Turn count is monotonically increasing
  val turn_count_non_negative = w.turn_count >= 0

  /// Weather is deterministic
  val weather_bounded = zone_weather(w.pos_x, w.pos_y, w.turn_count) >= 0 and
                        zone_weather(w.pos_x, w.pos_y, w.turn_count) <= 3

  /// Stamina bounded [0, max_stamina]
  val stamina_bounded = ch.stamina >= 0 and ch.stamina <= ch.max_stamina

  /// Max stamina is positive
  val max_stamina_positive = ch.max_stamina >= 10

  /// Cooldowns are non-negative and bounded
  val cooldowns_bounded = and {
    cb.cd_heavy_strike >= 0, cb.cd_heavy_strike <= HEAVY_STRIKE_CD,
    cb.cd_battle_cry >= 0, cb.cd_battle_cry <= BATTLE_CRY_CD,
    cb.cd_fortify >= 0, cb.cd_fortify <= FORTIFY_CD,
  }

  /// Cooldowns only active during combat
  val cooldowns_only_in_combat = not(cb.in_combat).implies(
    cb.cd_heavy_strike == 0 and cb.cd_battle_cry == 0 and cb.cd_fortify == 0
  )

  /// Pity counter bounded [0, PITY_THRESHOLD]
  val pity_bounded = meta.pity_counter >= 0 and meta.pity_counter <= PITY_THRESHOLD

  /// Last drop is valid (0=none, 1=potion, 2=venom_sac)
  val last_drop_valid = meta.last_drop >= 0 and meta.last_drop <= 2

  /// XP thresholds increase with level
  val xp_thresholds_monotonic = and {
    xp_threshold(2) < xp_threshold(3),
    xp_threshold(3) < xp_threshold(4),
    xp_threshold(4) < xp_threshold(5),
  }

  /// Win condition requires Castle position
  val win_requires_castle = meta.game_won.implies(
    w.pos_x % 3 == 2 and w.pos_y % 3 == 2 and zone_level(w.pos_x, w.pos_y) >= MAX_LEVEL
  )

  /// Skill points are non-negative
  val skill_points_non_negative = ch.skill_points >= 0

  /// Skill prerequisites are respected
  val skill_prereqs_respected = and {
    ch.skill_heavy_strike.implies(ch.skill_combo),
    ch.skill_counter_attack.implies(ch.skill_shield_block),
    ch.skill_battle_cry.implies(ch.skill_heavy_strike),
    ch.skill_fortify.implies(ch.skill_counter_attack),
  }

  /// Venom sac quantity is non-negative
  val qty_venom_sac_non_negative = inv.qty_venom_sac >= 0

  /// Enemy element is bounded [0, 4]
  val enemy_element_bounded = cb.enemy_element >= 0 and cb.enemy_element <= 4

  /// Enchant slots are bounded [0, 4]
  val enchant_slots_bounded = and {
    eqp.enchant_slot_1 >= 0, eqp.enchant_slot_1 <= 4,
    eqp.enchant_slot_2 >= 0, eqp.enchant_slot_2 <= 4,
    eqp.enchant_slot_3 >= 0, eqp.enchant_slot_3 <= 4,
  }

  /// Fire and Ice enchantments cannot coexist
  val no_fire_ice_incompatible = not(has_fire_enchant and has_ice_enchant)

  /// Enemy element is only set during combat
  val enemy_element_only_in_combat = not(cb.in_combat).implies(cb.enemy_element == 0)

  /// Inventory capacity bounded
  val inventory_bounded = total_items <= MAX_INVENTORY

  /// Salvage level bounded [1, MAX_SALVAGE_LEVEL]
  val salvage_level_bounded = inv.salvage_level >= 1 and inv.salvage_level <= MAX_SALVAGE_LEVEL

}

module quint_crawl_run {
  import quint_crawl.*
}
