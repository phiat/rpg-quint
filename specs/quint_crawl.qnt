module quint_crawl {
  // === Record type definitions ===
  type CharState = {
    hp: int, max_hp: int, base_attack: int, xp: int, level: int, gold: int,
    stamina: int, max_stamina: int, skill_points: int,
    skill_combo: bool, skill_poison: bool, skill_shield_block: bool,
    skill_heavy_strike: bool, skill_counter_attack: bool,
    skill_battle_cry: bool, skill_fortify: bool,
    respec_count: int,
    skill_magic: bool, mana: int, max_mana: int,
  }

  type InvState = {
    qty_potion: int, qty_wood: int, qty_iron: int, qty_sword: int,
    has_sword: bool, qty_venom_sac: int, salvage_level: int,
    qty_battery: int,
    qty_scroll_fire: int,
    qty_holy_dust: int, qty_holy_water: int,
  }

  type EquipState = {
    sword_dur: int, sword_max_dur: int,
    enchant_slot_1: int, enchant_slot_2: int, enchant_slot_3: int,
    weapon_type: int, // 0=sword, 1=pistol, 2=staff
    trinket: int,     // 0=none, 1=vitality(+max_hp)
    has_shield: bool, shield_dur: int,
    has_armor: bool, armor_dur: int,
  }

  type CombatState = {
    in_combat: bool, enemy_hp: int, enemy_attack: int, enemy_element: int,
    combo_count: int, player_poison_dur: int, player_atk_buff_dur: int,
    player_def_buff_dur: int, enemy_poison_dur: int,
    cd_heavy_strike: int, cd_battle_cry: int, cd_fortify: int,
  }

  type WorldState = {
    pos_x: int, pos_y: int, turn_count: int,
    visited: Set[(int, int)],
    waypoints: Set[(int, int)],
  }

  type MetaState = {
    game_won: bool, saved_exists: bool, pity_counter: int, last_drop: int,
    last_kill_turn: int,
    q1_kills: int, q2_zones: int, q3_kills: int,
    cq1_adopted: int, cq2_maxed: int, cq3_wins: int,
    quest_rewards_claimed: int,
    boss_defeated: bool,
  }

  // Companion is represented abstractly by its trait + rarity.
  // Species is flavor (lives in the game catalog); the spec only sees effects.
  // active = true when a companion is bound; false = no companion.
  //   trait:  0=Attacker, 1=Defender, 2=Scout, 3=Support
  //   rarity: 0=Common,   1=Rare,     2=Legendary
  type CompState = {
    active: bool,
    trait: int,
    rarity: int,
    loyalty: int,
    command_used: bool, // resets on enter_combat
  }

  // Result of the shared loot-drop helper (see compute_loot). Callers
  // add potion_inc / venom_inc to inv and store new_pity / new_last_drop
  // in meta directly.
  type LootDrop = {
    potion_inc: int,
    venom_inc: int,
    holy_dust_inc: int,
    new_pity: int,
    new_last_drop: int,
  }

  // === State variables ===
  var ch: CharState
  var inv: InvState
  var eqp: EquipState
  var cb: CombatState
  var w: WorldState
  var meta: MetaState
  var comp: CompState

  // --- Constants ---
  val SWORD_MAX_DUR = 10
  val REPAIR_COST = 5
  val POISON_DMG = 7
  val ATK_BUFF_BONUS = 8
  val DEF_BUFF_REDUCTION = 3
  val FORTIFY_DEF_REDUCTION = 5
  val STATUS_DURATION = 3
  val SWORD_ATK_BONUS = 5
  val WEATHER_CYCLE = 5
  val STORM_MOVE_DMG = 4
  val FOG_ATK_PENALTY = 2
  val RAIN_GATHER_BONUS = 1
  val ATTACK_STAMINA = 2
  val COMBO_STAMINA = 3
  val HEAVY_STRIKE_STAMINA = 5
  val BATTLE_CRY_STAMINA = 3
  val HEAVY_STRIKE_CD = 3
  val BATTLE_CRY_CD = 2
  val PITY_THRESHOLD = 8
  // Quest targets (Q1: slime slayer, Q2: venture forth, Q3: castle conqueror)
  val Q1_TARGET = 2
  val Q2_TARGET = 3
  val Q3_TARGET = 2
  // Companion quest targets (CQ1: adopt, CQ2: loyalty max, CQ3: win combats)
  val CQ1_TARGET = 1
  val CQ2_TARGET = 1
  val CQ3_TARGET = 5
  val QUEST_REWARD_GOLD = 30
  // Companion constants
  val MAX_LOYALTY = 100
  val INITIAL_LOYALTY = 50
  val LOYALTY_GAIN = 10
  val LOYALTY_COMBAT_COST = 5
  val HIGH_LOYALTY = 75
  // Minimum loyalty for a companion to contribute combat bonuses at all.
  // Below this, the pet is present but too dispirited to help.
  val LOW_LOYALTY = 25
  // Training cost (wood) per target rarity: (new_rarity + 1) * TRAIN_COST
  val TRAIN_COST = 3
  // Companion trait effect multipliers (scaled by rarity tier)
  //   Attacker(0): atk bonus    | Defender(1): dmg reduction
  //   Scout(2):    small atk    | Support(3):  small dmg reduction
  val COMP_ATK_BASE_ATTACKER = 2
  val COMP_ATK_BASE_SCOUT    = 1
  val COMP_DEF_BASE_DEFENDER = 1
  val COMP_DEF_BASE_SUPPORT  = 1
  val COMP_TRAIT_COUNT  = 4
  val COMP_RARITY_COUNT = 3
  // Rarity scales (common=1, rare=2, legendary=3) — applied to the base trait effect
  // Adoption material cost is abstracted to a single "material cost" of rarity+1 in spec
  val ADOPT_BASE_COST = 1
  val POTION_COST = 15
  val HP_PER_LEVEL = 15
  val ATK_PER_LEVEL_UP = 2
  val STAMINA_PER_LEVEL = 2
  val STAMINA_REGEN_PER_MOVE = 1 // passive out-of-combat regen on every move
  // Mana is inert until skill_magic is unlocked. Once unlocked, spellbook/scroll
  // purchases raise max_mana and mana regens on move like stamina.
  val MANA_PER_LEVEL = 3
  val MANA_REGEN_PER_MOVE = 1
  val SPELLBOOK_COST = 40
  val INITIAL_MAX_MANA = 10
  val FIREBALL_COST = 5
  val FIREBALL_DMG = 14
  val HEAL_COST = 4
  val HEAL_AMOUNT = 20
  // Spell IDs for cast_spell dispatch
  val SPELL_HEAL = 0
  val SPELL_FIRE = 1
  // Fire scroll: consumable that deals fireball damage without skill_magic/mana
  val SCROLL_FIRE_COST = 25
  // Holy water: crafted at village from holy_dust + wood; out-of-combat full heal.
  val CRAFT_HOLY_WATER_WOOD = 2
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
  val RESPEC_BASE_COST = 25
  val COUNTER_STAMINA = 3
  val SHIELD_BLOCK_STAMINA = 3
  val FORTIFY_STAMINA = 4
  val FORTIFY_CD = 5
  val FORTIFY_DURATION = 8
  val CRAFT_VENOM_IRON_COST = 2
  val ENCHANT_COST = 25
  val ENCHANT_IRON_COST = 1
  val ENCHANT_VENOM_COST = 1
  val MAX_INVENTORY = 30
  val BATTERY_CAP = 20
  val PISTOL_UNLOCK_COST = 50
  // Staff: caster weapon (weapon_type=2). Village unlock, requires skill_magic.
  // Grants +max_mana on equip and boosts spell output; no melee combat action.
  val STAFF_UNLOCK_COST = 40
  val STAFF_MAX_MANA_BONUS = 5
  val STAFF_SPELL_BONUS = 5
  val STAFF_HEAL_BONUS = 5
  // Trinket slot: single passive modifier. Vitality (1) grants +max_hp on
  // equip. Bought at village; removable at village for no refund.
  val TRINKET_COST = 25
  val TRINKET_VITALITY_HP = 5
  // Shield: passive DEF reduction while equipped. Durability degrades only
  // via active shield_block skill usage (follow-up beads can extend wear).
  val SHIELD_COST = 30
  val SHIELD_MAX_DUR = 5
  val SHIELD_DEF = 2
  // Armor: passive flat DEF, durability ticks at enter_combat (lasts N fights).
  val ARMOR_COST = 40
  val ARMOR_MAX_DUR = 8
  val ARMOR_DEF = 1
  val PISTOL_STAMINA = 2
  val PISTOL_BASE_BONUS = 4
  val CRAFT_LEVEL_REQ = 2
  val SALVAGE_WOOD_BASE = 0
  val SALVAGE_IRON_BASE = 1
  val UPGRADE_SALVAGE_COST = 15
  val MAX_SALVAGE_LEVEL = 3
  val RESPAWN_TURNS = 3           // turns after kill before combat available again
  // Castle boss encounter — replaces the generic tier-5 enemy at the Castle
  // zone until it's killed. Roughly 2x a top-tier mob so the fight has weight.
  val BOSS_HP = 80
  val BOSS_ATK = 12
  val BOSS_ELEMENT = 1

  // --- World scaling constants ---
  val WORLD_SIZE = 9
  val MAX_LEVEL = 5
  val TILES_PER_LEVEL = 3
  val BASE_ENEMY_HP = 20
  val BASE_ENEMY_ATK = 2
  val ATK_PER_LEVEL = 4
  val BASE_XP = 5
  val BASE_GOLD = 8
  val GOLD_PER_LEVEL = 2

  // Weather types: 0=Clear, 1=Rain, 2=Fog, 3=Storm
  pure def zone_weather(x: int, y: int, turn: int): int =
    ((x * 3 + y * 7 + turn / WEATHER_CYCLE) % 4)

  // XP thresholds for leveling up
  pure def xp_threshold(lvl: int): int =
    if (lvl == 2) 15
    else if (lvl == 3) 50
    else if (lvl == 4) 110
    else if (lvl == 5) 200
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
  pure def is_castle_zone(x: int, y: int): bool =
    zone_biome_x(x) == 2 and zone_biome_y(y) == 2 and zone_level(x, y) >= MAX_LEVEL
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
  // Helpers to get/set enchant slot by index (1, 2, 3)
  pure def get_enchant_slot(e: EquipState, slot: int): int =
    if (slot == 1) e.enchant_slot_1
    else if (slot == 2) e.enchant_slot_2
    else e.enchant_slot_3

  pure def set_enchant_slot(e: EquipState, slot: int, value: int): EquipState =
    if (slot == 1) { ...e, enchant_slot_1: value }
    else if (slot == 2) { ...e, enchant_slot_2: value }
    else { ...e, enchant_slot_3: value }

  // Enchants are sword-bound: a broken (or absent) sword zeroes enchant bonuses.
  val enchant_sword_ok = inv.has_sword and eqp.sword_dur > 0
  val enchant_atk_bonus =
    if (enchant_sword_ok)
      atk_for(eqp.enchant_slot_1) + atk_for(eqp.enchant_slot_2) + atk_for(eqp.enchant_slot_3)
    else 0
  val enchant_def_bonus =
    if (enchant_sword_ok)
      def_for(eqp.enchant_slot_1) + def_for(eqp.enchant_slot_2) + def_for(eqp.enchant_slot_3)
    else 0
  // Companion passives
  val comp_active = comp.active and comp.loyalty >= LOW_LOYALTY
  // Rarity scale: common=1, rare=2, legendary=3
  val comp_rarity_scale = comp.rarity + 1
  // Attacker(0)/Scout(2) contribute to atk; Defender(1)/Support(3) contribute to dmg reduction
  val comp_atk_bonus =
    if (not(comp_active)) 0
    else if (comp.trait == 0) COMP_ATK_BASE_ATTACKER * comp_rarity_scale
    else if (comp.trait == 2) COMP_ATK_BASE_SCOUT    * comp_rarity_scale
    else 0
  val comp_dmg_reduction =
    if (not(comp_active)) 0
    else if (comp.trait == 1) COMP_DEF_BASE_DEFENDER * comp_rarity_scale
    else if (comp.trait == 3) COMP_DEF_BASE_SUPPORT  * comp_rarity_scale
    else 0

  // Damage-taken helpers (used across all combat actions)
  // Fortify grants a stronger reduction than shield_block; disambiguated by
  // buff duration (shield_block sets STATUS_DURATION=3, fortify sets
  // FORTIFY_DURATION=8, so any duration > STATUS_DURATION implies fortify).
  val def_reduction_active =
    if (cb.player_def_buff_dur > STATUS_DURATION) FORTIFY_DEF_REDUCTION
    else if (cb.player_def_buff_dur > 0) DEF_BUFF_REDUCTION
    else 0
  val shield_def_bonus = if (eqp.has_shield) SHIELD_DEF else 0
  val armor_def_bonus = if (eqp.has_armor) ARMOR_DEF else 0
  val incoming_enemy_dmg = {
    val raw = cb.enemy_attack - enchant_def_bonus - def_reduction_active - comp_dmg_reduction - shield_def_bonus - armor_def_bonus
    if (raw < 1) 1 else raw
  }
  val player_poison_tick = if (cb.player_poison_dur > 0) POISON_DMG else 0

  // Shared loot-drop + pity logic used by every killing combat action.
  // Returns inventory increments (potion vs venom sac) and updated pity
  // counter / last_drop marker. Kill-on-hit actions simply add the
  // increments to inv' and copy new_pity / new_last_drop into meta'.
  pure def compute_loot(m: MetaState, tot: int, defeated_alive: bool, turn_count: int, zone_tier: int, nonce: int): LootDrop = {
    // Nonce (caller passes ch.xp) desyncs the periodic drop pattern from
    // turn_count alone so players can't kill-sync to turn_count % N == 0.
    val drop_trigger = (m.pity_counter >= PITY_THRESHOLD or ((turn_count + nonce) % LOOT_DROP_MODULO == 0))
    val should_drop = defeated_alive and drop_trigger and tot < MAX_INVENTORY
    val drops_venom = should_drop and zone_tier >= POISON_APPLY_TIER
    // Holy dust is a bonus drop alongside the primary at tier 2+,
    // mirroring the Odin-side trait drop that formerly keyed on .Undead.
    // Gates on the same drop_trigger so MBT traces can exercise it.
    // Holy dust stacks on the primary drop, so it only fires when there's
    // room for both items under the inventory cap.
    val drops_holy = should_drop and zone_tier >= POISON_APPLY_TIER and tot + 1 < MAX_INVENTORY
    {
      potion_inc: if (should_drop and not(drops_venom)) 1 else 0,
      venom_inc: if (drops_venom) 1 else 0,
      holy_dust_inc: if (drops_holy) 1 else 0,
      new_pity: if (should_drop) 0
                else if (defeated_alive) m.pity_counter + 1
                else m.pity_counter,
      new_last_drop: if (drops_venom) 2 else if (should_drop) 1 else 0,
    }
  }

  // Tick per-turn combat decay in one pass: 4 status durations + 3
  // ability cooldowns. Returns a CombatState with those 7 fields
  // advanced one step; other fields pass through unchanged. Callers
  // that need to override a field (battle_cry sets atk_buff and
  // battle_cry CD, shield_block/counter_attack/fortify set def_buff,
  // heavy_strike sets heavy CD) simply assign over the ticked value
  // in their cb' record.
  pure def tick_statuses(c: CombatState, apply_poison_now: bool): CombatState = {
    ...c,
    player_poison_dur: if (apply_poison_now) STATUS_DURATION
                       else if (c.player_poison_dur > 0) c.player_poison_dur - 1
                       else 0,
    player_atk_buff_dur: if (c.player_atk_buff_dur > 0) c.player_atk_buff_dur - 1 else 0,
    player_def_buff_dur: if (c.player_def_buff_dur > 0) c.player_def_buff_dur - 1 else 0,
    enemy_poison_dur: if (c.enemy_poison_dur > 0) c.enemy_poison_dur - 1 else 0,
    cd_heavy_strike: if (c.cd_heavy_strike > 0) c.cd_heavy_strike - 1 else 0,
    cd_battle_cry: if (c.cd_battle_cry > 0) c.cd_battle_cry - 1 else 0,
    cd_fortify: if (c.cd_fortify > 0) c.cd_fortify - 1 else 0,
  }

  // Quest completion predicates
  val quest1_complete = meta.q1_kills >= Q1_TARGET
  val quest2_complete = quest1_complete and meta.q2_zones >= Q2_TARGET
  val quest3_complete = quest2_complete and meta.q3_kills >= Q3_TARGET
  val quest2_unlocked = quest1_complete
  val quest3_unlocked = quest2_complete
  val cquest1_complete = meta.cq1_adopted >= CQ1_TARGET
  val cquest2_complete = cquest1_complete and meta.cq2_maxed >= CQ2_TARGET
  val cquest3_complete = cquest2_complete and meta.cq3_wins >= CQ3_TARGET
  val player_element = if (has_fire_enchant) 1
                       else if (has_ice_enchant) 2
                       else if (eqp.enchant_slot_1 == 4 or eqp.enchant_slot_2 == 4 or eqp.enchant_slot_3 == 4) 3
                       else 0

  // Total attack power (sword bonus only if equipped AND not broken, plus ATK buff, plus enchant bonus).
  // Fog reduces player visibility — the same FOG_ATK_PENALTY that was already cutting the enemy now
  // also bites the player's offense, so fog becomes a real trade rather than a free upside.
  val fog_penalty_now = if (zone_weather(w.pos_x, w.pos_y, w.turn_count + 1) == 2) FOG_ATK_PENALTY else 0
  val attack_power_raw = ch.base_attack + (if (inv.has_sword and eqp.sword_dur > 0) SWORD_ATK_BONUS else 0) + (if (cb.player_atk_buff_dur > 0) ATK_BUFF_BONUS else 0) + enchant_atk_bonus + comp_atk_bonus - fog_penalty_now
  val attack_power = if (attack_power_raw < 1) 1 else attack_power_raw
  val player_elem_mult = damage_multiplier(player_element, cb.enemy_element)

  // --- Inventory helpers ---
  val total_items = inv.qty_potion + inv.qty_wood + inv.qty_iron + inv.qty_sword + inv.qty_venom_sac + inv.qty_battery + inv.qty_scroll_fire + inv.qty_holy_dust + inv.qty_holy_water

  // Salvage recovery
  pure def salvage_wood_yield(slvl: int): int = SALVAGE_WOOD_BASE + (slvl - 1)
  pure def salvage_iron_yield(slvl: int): int = SALVAGE_IRON_BASE + (slvl - 1)

  // --- Helpers ---
  // HP clamp convention:
  //   - Death paths (combat damage, poison ticks) clamp to 0 so HP <= 0 ends combat.
  //   - Survival paths (storm on move, flee_combat) floor at 1 so the player
  //     never dies from an escape-hatch action or from entering a zone.
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
      respec_count: 0,
      skill_magic: false, mana: 0, max_mana: 0,
    },
    inv' = {
      qty_potion: INITIAL_POTIONS, qty_wood: 0, qty_iron: 0, qty_sword: 0, qty_scroll_fire: 0,
      has_sword: false, qty_venom_sac: 0, salvage_level: 1,
      qty_battery: 0,
      qty_holy_dust: 0, qty_holy_water: 0,
    },
    eqp' = {
      sword_dur: 0, sword_max_dur: SWORD_MAX_DUR,
      enchant_slot_1: 0, enchant_slot_2: 0, enchant_slot_3: 0,
      weapon_type: 0,
      trinket: 0,
      has_shield: false, shield_dur: 0,
      has_armor: false, armor_dur: 0,
    },
    cb' = {
      in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: 0,
      combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
      player_def_buff_dur: 0, enemy_poison_dur: 0,
      cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: 0,
    },
    w' = { pos_x: 0, pos_y: 0, turn_count: 0,
           visited: Set((0, 0)), waypoints: Set((0, 0)) },
    meta' = { game_won: false, saved_exists: false, pity_counter: 0, last_drop: 0, last_kill_turn: 0,
              q1_kills: 0, q2_zones: 0, q3_kills: 0,
              cq1_adopted: 0, cq2_maxed: 0, cq3_wins: 0,
              quest_rewards_claimed: 0,
              boss_defeated: false },
    comp' = { active: false, trait: 0, rarity: 0, loyalty: 0, command_used: false },
  }

  // === Movement (only when not in combat) ===
  // Storm (weather=3) deals damage when entering a zone
  action move_up = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    w.pos_y > 0,
    zone_level(w.pos_x, w.pos_y - 1) <= ch.level,
    val storm_dmg = if (zone_weather(w.pos_x, w.pos_y - 1, w.turn_count + 1) == 3) STORM_MOVE_DMG else 0
    all {
      w' = { ...w, pos_y: w.pos_y - 1, turn_count: w.turn_count + 1,
             visited: w.visited.union(Set((w.pos_x, w.pos_y - 1))),
             waypoints: if (zone_has_services(w.pos_x, w.pos_y - 1)) w.waypoints.union(Set((w.pos_x, w.pos_y - 1))) else w.waypoints },
      ch' = { ...ch,
              hp: if (ch.hp - storm_dmg < 1) 1 else ch.hp - storm_dmg,
              stamina: if (ch.stamina + STAMINA_REGEN_PER_MOVE > ch.max_stamina) ch.max_stamina else ch.stamina + STAMINA_REGEN_PER_MOVE,
              mana: if (ch.max_mana == 0) ch.mana else if (ch.mana + MANA_REGEN_PER_MOVE > ch.max_mana) ch.max_mana else ch.mana + MANA_REGEN_PER_MOVE },
      inv' = inv, eqp' = eqp,
      cb' = cb,
      meta' = { ...meta, q2_zones: if (quest1_complete and zone_level(w.pos_x, w.pos_y - 1) >= 2 and not(w.visited.contains((w.pos_x, w.pos_y - 1))) and meta.q2_zones < Q2_TARGET) meta.q2_zones + 1 else meta.q2_zones },
      comp' = comp,
    }
  }

  action move_down = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    w.pos_y < WORLD_SIZE - 1,
    zone_level(w.pos_x, w.pos_y + 1) <= ch.level,
    val storm_dmg = if (zone_weather(w.pos_x, w.pos_y + 1, w.turn_count + 1) == 3) STORM_MOVE_DMG else 0
    all {
      w' = { ...w, pos_y: w.pos_y + 1, turn_count: w.turn_count + 1,
             visited: w.visited.union(Set((w.pos_x, w.pos_y + 1))),
             waypoints: if (zone_has_services(w.pos_x, w.pos_y + 1)) w.waypoints.union(Set((w.pos_x, w.pos_y + 1))) else w.waypoints },
      ch' = { ...ch,
              hp: if (ch.hp - storm_dmg < 1) 1 else ch.hp - storm_dmg,
              stamina: if (ch.stamina + STAMINA_REGEN_PER_MOVE > ch.max_stamina) ch.max_stamina else ch.stamina + STAMINA_REGEN_PER_MOVE,
              mana: if (ch.max_mana == 0) ch.mana else if (ch.mana + MANA_REGEN_PER_MOVE > ch.max_mana) ch.max_mana else ch.mana + MANA_REGEN_PER_MOVE },
      inv' = inv, eqp' = eqp,
      cb' = cb,
      meta' = { ...meta, q2_zones: if (quest1_complete and zone_level(w.pos_x, w.pos_y + 1) >= 2 and not(w.visited.contains((w.pos_x, w.pos_y + 1))) and meta.q2_zones < Q2_TARGET) meta.q2_zones + 1 else meta.q2_zones },
      comp' = comp,
    }
  }

  action move_left = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    w.pos_x > 0,
    zone_level(w.pos_x - 1, w.pos_y) <= ch.level,
    val storm_dmg = if (zone_weather(w.pos_x - 1, w.pos_y, w.turn_count + 1) == 3) STORM_MOVE_DMG else 0
    all {
      w' = { ...w, pos_x: w.pos_x - 1, turn_count: w.turn_count + 1,
             visited: w.visited.union(Set((w.pos_x - 1, w.pos_y))),
             waypoints: if (zone_has_services(w.pos_x - 1, w.pos_y)) w.waypoints.union(Set((w.pos_x - 1, w.pos_y))) else w.waypoints },
      ch' = { ...ch,
              hp: if (ch.hp - storm_dmg < 1) 1 else ch.hp - storm_dmg,
              stamina: if (ch.stamina + STAMINA_REGEN_PER_MOVE > ch.max_stamina) ch.max_stamina else ch.stamina + STAMINA_REGEN_PER_MOVE,
              mana: if (ch.max_mana == 0) ch.mana else if (ch.mana + MANA_REGEN_PER_MOVE > ch.max_mana) ch.max_mana else ch.mana + MANA_REGEN_PER_MOVE },
      inv' = inv, eqp' = eqp,
      cb' = cb,
      meta' = { ...meta, q2_zones: if (quest1_complete and zone_level(w.pos_x - 1, w.pos_y) >= 2 and not(w.visited.contains((w.pos_x - 1, w.pos_y))) and meta.q2_zones < Q2_TARGET) meta.q2_zones + 1 else meta.q2_zones },
      comp' = comp,
    }
  }

  action move_right = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    w.pos_x < WORLD_SIZE - 1,
    zone_level(w.pos_x + 1, w.pos_y) <= ch.level,
    val storm_dmg = if (zone_weather(w.pos_x + 1, w.pos_y, w.turn_count + 1) == 3) STORM_MOVE_DMG else 0
    all {
      w' = { ...w, pos_x: w.pos_x + 1, turn_count: w.turn_count + 1,
             visited: w.visited.union(Set((w.pos_x + 1, w.pos_y))),
             waypoints: if (zone_has_services(w.pos_x + 1, w.pos_y)) w.waypoints.union(Set((w.pos_x + 1, w.pos_y))) else w.waypoints },
      ch' = { ...ch,
              hp: if (ch.hp - storm_dmg < 1) 1 else ch.hp - storm_dmg,
              stamina: if (ch.stamina + STAMINA_REGEN_PER_MOVE > ch.max_stamina) ch.max_stamina else ch.stamina + STAMINA_REGEN_PER_MOVE,
              mana: if (ch.max_mana == 0) ch.mana else if (ch.mana + MANA_REGEN_PER_MOVE > ch.max_mana) ch.max_mana else ch.mana + MANA_REGEN_PER_MOVE },
      inv' = inv, eqp' = eqp,
      cb' = cb,
      meta' = { ...meta, q2_zones: if (quest1_complete and zone_level(w.pos_x + 1, w.pos_y) >= 2 and not(w.visited.contains((w.pos_x + 1, w.pos_y))) and meta.q2_zones < Q2_TARGET) meta.q2_zones + 1 else meta.q2_zones },
      comp' = comp,
    }
  }

  // === Enter combat ===
  // Fog (weather=2) reduces enemy attack
  action enter_combat = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    (meta.last_kill_turn == 0 or w.turn_count - meta.last_kill_turn >= RESPAWN_TURNS),
    val weather = zone_weather(w.pos_x, w.pos_y, w.turn_count + 1)
    val fog_penalty = if (weather == 2) FOG_ATK_PENALTY else 0
    val is_boss = is_castle_zone(w.pos_x, w.pos_y) and not(meta.boss_defeated)
    val base_hp = if (is_boss) BOSS_HP else zone_enemy_hp(w.pos_x, w.pos_y)
    val base_atk = if (is_boss) BOSS_ATK else zone_enemy_attack(w.pos_x, w.pos_y)
    val base_elem = if (is_boss) BOSS_ELEMENT else zone_element(w.pos_x, w.pos_y)
    val raw_atk = base_atk - fog_penalty
    val new_armor_dur = if (eqp.has_armor) eqp.armor_dur - 1 else 0
    val armor_broken = eqp.has_armor and new_armor_dur <= 0
    all {
      cb' = { in_combat: true,
              enemy_hp: base_hp,
              enemy_attack: if (raw_atk < 1) 1 else raw_atk,
              enemy_element: base_elem,
              combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
              player_def_buff_dur: 0, enemy_poison_dur: 0,
              cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: 0 },
      w' = { ...w, turn_count: w.turn_count + 1 },
      ch' = ch, inv' = inv,
      eqp' = { ...eqp,
               has_armor: if (armor_broken) false else eqp.has_armor,
               armor_dur: if (armor_broken) 0 else new_armor_dur },
      meta' = { ...meta, last_drop: 0 },
      // Loyalty tick: departure zeroes trait/rarity to match dismiss_companion
      // (keeps comp_inactive_zeroed invariant tight).
      comp' = if (comp.active and comp.loyalty - LOYALTY_COMBAT_COST <= 0)
                { active: false, trait: 0, rarity: 0, loyalty: 0, command_used: false }
              else
                { ...comp,
                  loyalty: if (comp.loyalty - LOYALTY_COMBAT_COST < 0) 0 else comp.loyalty - LOYALTY_COMBAT_COST,
                  command_used: false },
    }
  }

  // === Combat: attack enemy ===
  action combat_attack = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    eqp.weapon_type == 0,
    ch.stamina >= ATTACK_STAMINA,
    // Degrade sword on attack
    val new_sword_dur = if (inv.has_sword and eqp.sword_dur > 0) eqp.sword_dur - 1 else eqp.sword_dur
    // Enemy takes elemental-modified damage + poison
    val enemy_poison_dmg = if (cb.enemy_poison_dur > 0) POISON_DMG else 0
    val elem_atk = effective_damage(attack_power, player_elem_mult)
    val new_enemy_hp = cb.enemy_hp - elem_atk - enemy_poison_dmg
    // Player takes enemy hit (reduced by DEF buff + enchant DEF) + poison damage
    val new_hp = if (new_enemy_hp > 0) ch.hp - incoming_enemy_dmg - player_poison_tick else ch.hp - player_poison_tick
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) ch.xp + zone_xp_reward(w.pos_x, w.pos_y) else ch.xp
    val new_level = if (ch.level < MAX_LEVEL and gained_xp >= xp_threshold(ch.level + 1)) ch.level + 1 else ch.level
    // Tier 2+ enemies apply poison
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and cb.player_poison_dur == 0 and new_enemy_hp > 0)
    val ticked = tick_statuses(cb, apply_poison)
    val combat_ends = (new_enemy_hp <= 0 or new_hp <= 0)
    // Loot drop on enemy defeat
    val enemy_defeated_alive = (new_enemy_hp <= 0 and new_hp > 0)
    val loot = compute_loot(meta, total_items, enemy_defeated_alive, w.turn_count, zone_tier, ch.xp)
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
              max_mana: if (new_level > ch.level and ch.skill_magic) ch.max_mana + MANA_PER_LEVEL else ch.max_mana,
              skill_points: if (new_level > ch.level) ch.skill_points + SKILL_POINTS_PER_LEVEL else ch.skill_points,
      },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else new_enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: if (combat_ends) 0 else cb.combo_count,
              player_poison_dur: if (combat_ends) 0 else ticked.player_poison_dur,
              player_atk_buff_dur: if (combat_ends) 0 else ticked.player_atk_buff_dur,
              player_def_buff_dur: if (combat_ends) 0 else ticked.player_def_buff_dur,
              enemy_poison_dur: if (combat_ends) 0 else ticked.enemy_poison_dur,
              cd_heavy_strike: if (combat_ends) 0 else ticked.cd_heavy_strike,
              cd_battle_cry: if (combat_ends) 0 else ticked.cd_battle_cry,
              cd_fortify: if (combat_ends) 0 else ticked.cd_fortify,
      },
      // If durability hits 0 this strike, enchants are lost with the broken sword.
      eqp' = if (eqp.sword_dur > 0 and new_sword_dur == 0)
               { ...eqp, sword_dur: 0, enchant_slot_1: 0, enchant_slot_2: 0, enchant_slot_3: 0 }
             else { ...eqp, sword_dur: new_sword_dur },
      inv' = { ...inv,
               qty_potion: inv.qty_potion + loot.potion_inc,
               qty_venom_sac: inv.qty_venom_sac + loot.venom_inc,
               qty_holy_dust: inv.qty_holy_dust + loot.holy_dust_inc,
      },
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = { ...meta, pity_counter: loot.new_pity, last_drop: loot.new_last_drop,
               last_kill_turn: if (enemy_defeated_alive) w.turn_count else meta.last_kill_turn,
               q1_kills: if (enemy_defeated_alive and zone_tier == 1 and meta.q1_kills < Q1_TARGET) meta.q1_kills + 1 else meta.q1_kills,
               q3_kills: if (enemy_defeated_alive and zone_tier == MAX_LEVEL and meta.q3_kills < Q3_TARGET) meta.q3_kills + 1 else meta.q3_kills,
               cq3_wins: if (enemy_defeated_alive and comp_active and meta.cq3_wins < CQ3_TARGET) meta.cq3_wins + 1 else meta.cq3_wins,
               boss_defeated: if (enemy_defeated_alive and is_castle_zone(w.pos_x, w.pos_y)) true else meta.boss_defeated },
      comp' = comp,
    }
  }

  // === Combat: use potion (quick action -- heals then enemy gets a free hit) ===
  action combat_potion = all {
    cb.in_combat, not(meta.game_won), inv.qty_potion > 0, ch.hp > 0,
    val healed = clamp_hp(ch.hp + POTION_HEAL, ch.max_hp)
    val new_hp = healed - incoming_enemy_dmg - player_poison_tick
    val combat_ends = (new_hp <= 0)
    val ticked = tick_statuses(cb, false)
    all {
      ch' = { ...ch, hp: if (new_hp < 0) 0 else new_hp },
      inv' = { ...inv, qty_potion: inv.qty_potion - 1 },
      eqp' = eqp,
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else cb.enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,
              player_poison_dur: if (combat_ends) 0 else ticked.player_poison_dur,
              player_atk_buff_dur: if (combat_ends) 0 else ticked.player_atk_buff_dur,
              player_def_buff_dur: if (combat_ends) 0 else ticked.player_def_buff_dur,
              enemy_poison_dur: if (combat_ends) 0 else ticked.enemy_poison_dur,
              cd_heavy_strike: if (combat_ends) 0 else ticked.cd_heavy_strike,
              cd_battle_cry: if (combat_ends) 0 else ticked.cd_battle_cry,
              cd_fortify: if (combat_ends) 0 else ticked.cd_fortify,
      },
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta, comp' = comp,
    }
  }

  // === Flee combat ===
  action flee_combat = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0,
    val flee_dmg = if (cb.enemy_attack - enchant_def_bonus < 1) 1 else cb.enemy_attack - enchant_def_bonus
    val poison_dmg = if (cb.player_poison_dur > 0) POISON_DMG else 0
    // Flee should not kill — clamp HP to 1 minimum so the escape hatch remains.
    val raw_hp = ch.hp - flee_dmg - poison_dmg
    val new_hp = if (raw_hp < 1) 1 else raw_hp
    all {
      ch' = { ...ch, hp: new_hp },
      cb' = { in_combat: false, enemy_hp: 0, enemy_attack: 0, enemy_element: 0,
              combo_count: 0, player_poison_dur: 0, player_atk_buff_dur: 0,
              player_def_buff_dur: 0, enemy_poison_dur: 0,
              cd_heavy_strike: 0, cd_battle_cry: 0, cd_fortify: 0 },
      w' = { ...w, turn_count: w.turn_count + 1 },
      inv' = inv, eqp' = eqp, meta' = meta, comp' = comp,
    }
  }

  // === Rest at village (town zone, not in combat) ===
  action rest_at_village = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    ch.hp < ch.max_hp or ch.stamina < ch.max_stamina,
    val new_loyalty = if (comp.active and comp.loyalty + LOYALTY_GAIN > MAX_LOYALTY) MAX_LOYALTY
                      else if (comp.active) comp.loyalty + LOYALTY_GAIN
                      else comp.loyalty
    all {
      ch' = { ...ch, hp: ch.max_hp, stamina: ch.max_stamina, mana: ch.max_mana },
      inv' = inv, eqp' = eqp,
      cb' = cb,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = { ...meta, cq2_maxed: if (new_loyalty == MAX_LOYALTY and meta.cq2_maxed < CQ2_TARGET) meta.cq2_maxed + 1 else meta.cq2_maxed },
      comp' = { ...comp, loyalty: new_loyalty },
    }
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
    cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Buy armor (village; passive flat DEF, durability decrements per fight) ===
  action buy_armor = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    not(eqp.has_armor),
    ch.gold >= ARMOR_COST,
    ch' = { ...ch, gold: ch.gold - ARMOR_COST },
    inv' = inv,
    eqp' = { ...eqp, has_armor: true, armor_dur: ARMOR_MAX_DUR },
    cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Buy shield (village; passive flat DEF, breaks via shield_block wear) ===
  action buy_shield = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    not(eqp.has_shield),
    ch.gold >= SHIELD_COST,
    ch' = { ...ch, gold: ch.gold - SHIELD_COST },
    inv' = inv,
    eqp' = { ...eqp, has_shield: true, shield_dur: SHIELD_MAX_DUR },
    cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Buy spellbook (village one-time purchase that unlocks magic) ===
  // Flips skill_magic, grants starter mana pool. Level-ups from here on
  // grow max_mana (see level-up branches). Spells themselves are added in
  // a later slice; this action just switches mana from inert to active.
  action buy_spellbook = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    not(ch.skill_magic),
    ch.gold >= SPELLBOOK_COST,
    ch' = { ...ch,
            gold: ch.gold - SPELLBOOK_COST,
            skill_magic: true,
            max_mana: INITIAL_MAX_MANA,
            mana: INITIAL_MAX_MANA,
    },
    inv' = inv, eqp' = eqp, cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Cast heal (out-of-combat self-heal, costs mana) ===
  action cast_heal = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    ch.skill_magic,
    ch.mana >= HEAL_COST,
    ch.hp < ch.max_hp,
    val heal_amt = HEAL_AMOUNT + (if (eqp.weapon_type == 2) STAFF_HEAL_BONUS else 0)
    val healed = clamp_hp(ch.hp + heal_amt, ch.max_hp)
    all {
      ch' = { ...ch, hp: healed, mana: ch.mana - HEAL_COST },
      inv' = inv, eqp' = eqp, cb' = cb,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta, comp' = comp,
    }
  }

  // === Cast fireball (combat spell, costs mana, pure magic damage) ===
  // Deals flat FIREBALL_DMG bypassing elements and sword; enemy counter-hits
  // like combat_attack. Meant as a stamina-free alternative to melee.
  action cast_fireball = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    ch.skill_magic,
    ch.mana >= FIREBALL_COST,
    val fire_dmg = FIREBALL_DMG + (if (eqp.weapon_type == 2) STAFF_SPELL_BONUS else 0)
    val enemy_poison_dmg = if (cb.enemy_poison_dur > 0) POISON_DMG else 0
    val new_enemy_hp = cb.enemy_hp - fire_dmg - enemy_poison_dmg
    val new_hp = if (new_enemy_hp > 0) ch.hp - incoming_enemy_dmg - player_poison_tick else ch.hp - player_poison_tick
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) ch.xp + zone_xp_reward(w.pos_x, w.pos_y) else ch.xp
    val new_level = if (ch.level < MAX_LEVEL and gained_xp >= xp_threshold(ch.level + 1)) ch.level + 1 else ch.level
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val ticked = tick_statuses(cb, false)
    val combat_ends = (new_enemy_hp <= 0 or new_hp <= 0)
    val enemy_defeated_alive = (new_enemy_hp <= 0 and new_hp > 0)
    val loot = compute_loot(meta, total_items, enemy_defeated_alive, w.turn_count, zone_tier, ch.xp)
    all {
      ch' = { ...ch,
              hp: if (new_hp < 0) 0 else new_hp,
              mana: ch.mana - FIREBALL_COST,
              xp: gained_xp,
              gold: if (new_enemy_hp <= 0) ch.gold + zone_gold_reward(w.pos_x, w.pos_y) else ch.gold,
              level: new_level,
              max_hp: if (new_level > ch.level) ch.max_hp + HP_PER_LEVEL else ch.max_hp,
              base_attack: if (new_level > ch.level) ch.base_attack + ATK_PER_LEVEL_UP else ch.base_attack,
              max_stamina: if (new_level > ch.level) ch.max_stamina + STAMINA_PER_LEVEL else ch.max_stamina,
              max_mana: if (new_level > ch.level and ch.skill_magic) ch.max_mana + MANA_PER_LEVEL else ch.max_mana,
              skill_points: if (new_level > ch.level) ch.skill_points + SKILL_POINTS_PER_LEVEL else ch.skill_points,
      },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else new_enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,
              player_poison_dur: if (combat_ends) 0 else ticked.player_poison_dur,
              player_atk_buff_dur: if (combat_ends) 0 else ticked.player_atk_buff_dur,
              player_def_buff_dur: if (combat_ends) 0 else ticked.player_def_buff_dur,
              enemy_poison_dur: if (combat_ends) 0 else ticked.enemy_poison_dur,
              cd_heavy_strike: if (combat_ends) 0 else ticked.cd_heavy_strike,
              cd_battle_cry: if (combat_ends) 0 else ticked.cd_battle_cry,
              cd_fortify: if (combat_ends) 0 else ticked.cd_fortify,
      },
      inv' = { ...inv,
               qty_potion: inv.qty_potion + loot.potion_inc,
               qty_venom_sac: inv.qty_venom_sac + loot.venom_inc,
               qty_holy_dust: inv.qty_holy_dust + loot.holy_dust_inc,
      },
      eqp' = eqp,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = { ...meta, pity_counter: loot.new_pity, last_drop: loot.new_last_drop,
               last_kill_turn: if (enemy_defeated_alive) w.turn_count else meta.last_kill_turn,
               q1_kills: if (enemy_defeated_alive and zone_tier == 1 and meta.q1_kills < Q1_TARGET) meta.q1_kills + 1 else meta.q1_kills,
               q3_kills: if (enemy_defeated_alive and zone_tier == MAX_LEVEL and meta.q3_kills < Q3_TARGET) meta.q3_kills + 1 else meta.q3_kills,
               cq3_wins: if (enemy_defeated_alive and comp.active and meta.cq3_wins < CQ3_TARGET) meta.cq3_wins + 1 else meta.cq3_wins,
               boss_defeated: if (enemy_defeated_alive and is_castle_zone(w.pos_x, w.pos_y)) true else meta.boss_defeated },
      comp' = comp,
    }
  }

  // === Cast spell (dispatch) ===
  // Unified entry point — picks one of the concrete spell actions by id.
  // MBT picks `id` nondeterministically; UI code passes a concrete value.
  action cast_spell(id: int): bool = any {
    all { id == SPELL_HEAL, cast_heal },
    all { id == SPELL_FIRE, cast_fireball },
  }

  // === Buy fire scroll (village) ===
  // Consumable alternative to cast_fireball — works without skill_magic/mana,
  // but inventory-bound and not infinitely renewable.
  action buy_scroll_fire = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    ch.gold >= SCROLL_FIRE_COST,
    total_items < MAX_INVENTORY,
    ch' = { ...ch, gold: ch.gold - SCROLL_FIRE_COST },
    inv' = { ...inv, qty_scroll_fire: inv.qty_scroll_fire + 1 },
    eqp' = eqp, cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Use fire scroll (combat consumable, no mana/magic gate) ===
  // Mirrors cast_fireball body except mana→scroll and no skill_magic check.
  action use_scroll_fire = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    inv.qty_scroll_fire > 0,
    val enemy_poison_dmg = if (cb.enemy_poison_dur > 0) POISON_DMG else 0
    val new_enemy_hp = cb.enemy_hp - FIREBALL_DMG - enemy_poison_dmg
    val new_hp = if (new_enemy_hp > 0) ch.hp - incoming_enemy_dmg - player_poison_tick else ch.hp - player_poison_tick
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) ch.xp + zone_xp_reward(w.pos_x, w.pos_y) else ch.xp
    val new_level = if (ch.level < MAX_LEVEL and gained_xp >= xp_threshold(ch.level + 1)) ch.level + 1 else ch.level
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val ticked = tick_statuses(cb, false)
    val combat_ends = (new_enemy_hp <= 0 or new_hp <= 0)
    val enemy_defeated_alive = (new_enemy_hp <= 0 and new_hp > 0)
    val loot = compute_loot(meta, total_items, enemy_defeated_alive, w.turn_count, zone_tier, ch.xp)
    all {
      ch' = { ...ch,
              hp: if (new_hp < 0) 0 else new_hp,
              xp: gained_xp,
              gold: if (new_enemy_hp <= 0) ch.gold + zone_gold_reward(w.pos_x, w.pos_y) else ch.gold,
              level: new_level,
              max_hp: if (new_level > ch.level) ch.max_hp + HP_PER_LEVEL else ch.max_hp,
              base_attack: if (new_level > ch.level) ch.base_attack + ATK_PER_LEVEL_UP else ch.base_attack,
              max_stamina: if (new_level > ch.level) ch.max_stamina + STAMINA_PER_LEVEL else ch.max_stamina,
              max_mana: if (new_level > ch.level and ch.skill_magic) ch.max_mana + MANA_PER_LEVEL else ch.max_mana,
              skill_points: if (new_level > ch.level) ch.skill_points + SKILL_POINTS_PER_LEVEL else ch.skill_points,
      },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else new_enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,
              player_poison_dur: if (combat_ends) 0 else ticked.player_poison_dur,
              player_atk_buff_dur: if (combat_ends) 0 else ticked.player_atk_buff_dur,
              player_def_buff_dur: if (combat_ends) 0 else ticked.player_def_buff_dur,
              enemy_poison_dur: if (combat_ends) 0 else ticked.enemy_poison_dur,
              cd_heavy_strike: if (combat_ends) 0 else ticked.cd_heavy_strike,
              cd_battle_cry: if (combat_ends) 0 else ticked.cd_battle_cry,
              cd_fortify: if (combat_ends) 0 else ticked.cd_fortify,
      },
      inv' = { ...inv,
               qty_scroll_fire: inv.qty_scroll_fire - 1,
               qty_potion: inv.qty_potion + loot.potion_inc,
               qty_venom_sac: inv.qty_venom_sac + loot.venom_inc,
               qty_holy_dust: inv.qty_holy_dust + loot.holy_dust_inc,
      },
      eqp' = eqp,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = { ...meta, pity_counter: loot.new_pity, last_drop: loot.new_last_drop,
               last_kill_turn: if (enemy_defeated_alive) w.turn_count else meta.last_kill_turn,
               q1_kills: if (enemy_defeated_alive and zone_tier == 1 and meta.q1_kills < Q1_TARGET) meta.q1_kills + 1 else meta.q1_kills,
               q3_kills: if (enemy_defeated_alive and zone_tier == MAX_LEVEL and meta.q3_kills < Q3_TARGET) meta.q3_kills + 1 else meta.q3_kills,
               cq3_wins: if (enemy_defeated_alive and comp.active and meta.cq3_wins < CQ3_TARGET) meta.cq3_wins + 1 else meta.cq3_wins,
               boss_defeated: if (enemy_defeated_alive and is_castle_zone(w.pos_x, w.pos_y)) true else meta.boss_defeated },
      comp' = comp,
    }
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
    cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
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
      cb' = cb,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta, comp' = comp,
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
      cb' = cb,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta, comp' = comp,
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
    cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Equip sword (sets durability to max) ===
  action equip_sword = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    inv.qty_sword >= 1, not(inv.has_sword),
    inv' = { ...inv, has_sword: true, qty_sword: inv.qty_sword - 1 },
    eqp' = { ...eqp, sword_dur: SWORD_MAX_DUR, enchant_slot_1: 0, enchant_slot_2: 0, enchant_slot_3: 0 },
    ch' = ch,
    cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Equip pistol (village, trades in sword for future-tech weapon) ===
  // Converts the equipped sword into a Service Pistol: the sword is consumed
  // (with its enchantments), weapon_type flips to 1, and the player now uses
  // battery-powered pistol shots instead of blade attacks.
  action equip_pistol = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    inv.has_sword, eqp.weapon_type == 0,
    ch.gold >= PISTOL_UNLOCK_COST,
    ch' = { ...ch, gold: ch.gold - PISTOL_UNLOCK_COST },
    inv' = { ...inv, has_sword: false },
    eqp' = { ...eqp, weapon_type: 1, sword_dur: 0,
             enchant_slot_1: 0, enchant_slot_2: 0, enchant_slot_3: 0 },
    cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Equip staff (village, trades in sword for a caster weapon) ===
  // Requires spellbook (skill_magic). Converts equipped sword into a Staff:
  // weapon_type flips to 2, +max_mana, mana restored to full, enchants
  // cleared. No melee attack — staff users rely on spells/scrolls/flee.
  action equip_staff = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    inv.has_sword, eqp.weapon_type == 0,
    ch.skill_magic,
    ch.gold >= STAFF_UNLOCK_COST,
    ch' = { ...ch,
            gold: ch.gold - STAFF_UNLOCK_COST,
            max_mana: ch.max_mana + STAFF_MAX_MANA_BONUS,
            mana: ch.max_mana + STAFF_MAX_MANA_BONUS },
    inv' = { ...inv, has_sword: false },
    eqp' = { ...eqp, weapon_type: 2, sword_dur: 0,
             enchant_slot_1: 0, enchant_slot_2: 0, enchant_slot_3: 0 },
    cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Buy trinket (vitality, +max_hp) at village ===
  action buy_trinket = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    eqp.trinket == 0,
    ch.gold >= TRINKET_COST,
    ch' = { ...ch,
            gold: ch.gold - TRINKET_COST,
            max_hp: ch.max_hp + TRINKET_VITALITY_HP,
            hp: ch.hp + TRINKET_VITALITY_HP },
    inv' = inv,
    eqp' = { ...eqp, trinket: 1 },
    cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Remove trinket (village, no refund) ===
  action remove_trinket = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    eqp.trinket == 1,
    val new_max_hp = ch.max_hp - TRINKET_VITALITY_HP
    val new_hp = if (ch.hp > new_max_hp) new_max_hp else ch.hp
    all {
      ch' = { ...ch, max_hp: new_max_hp, hp: new_hp },
      inv' = inv,
      eqp' = { ...eqp, trinket: 0 },
      cb' = cb,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta, comp' = comp,
    }
  }

  // === Use antidote (quick action -- clears player poison, enemy gets a free hit) ===
  action use_antidote = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0,
    inv.qty_potion > 0, cb.player_poison_dur > 0,
    // Poison cleared this turn, so no player_poison_tick this action.
    val new_hp = ch.hp - incoming_enemy_dmg
    val combat_ends = (new_hp <= 0)
    val ticked = tick_statuses(cb, false)
    all {
      ch' = { ...ch, hp: if (new_hp < 0) 0 else new_hp },
      inv' = { ...inv, qty_potion: inv.qty_potion - 1 },
      eqp' = eqp,
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else cb.enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,
              player_poison_dur: 0,
              player_atk_buff_dur: if (combat_ends) 0 else ticked.player_atk_buff_dur,
              player_def_buff_dur: if (combat_ends) 0 else ticked.player_def_buff_dur,
              enemy_poison_dur: if (combat_ends) 0 else ticked.enemy_poison_dur,
              cd_heavy_strike: if (combat_ends) 0 else ticked.cd_heavy_strike,
              cd_battle_cry: if (combat_ends) 0 else ticked.cd_battle_cry,
              cd_fortify: if (combat_ends) 0 else ticked.cd_fortify,
      },
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta, comp' = comp,
    }
  }

  // === Poison strike (apply poison to enemy, enemy hits back) ===
  action poison_strike = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    eqp.weapon_type == 0,
    ch.skill_poison, inv.qty_venom_sac > 0,
    ch.stamina >= ATTACK_STAMINA,
    val new_hp = ch.hp - incoming_enemy_dmg
    val combat_ends = (new_hp <= 0)
    val ticked = tick_statuses(cb, false)
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
              // Refresh (not overwrite): allows re-cast on already-poisoned enemy.
              enemy_poison_dur: if (combat_ends) 0 else (if (cb.enemy_poison_dur > STATUS_DURATION) cb.enemy_poison_dur else STATUS_DURATION),
              cd_heavy_strike: if (combat_ends) 0 else ticked.cd_heavy_strike,
              cd_battle_cry: if (combat_ends) 0 else ticked.cd_battle_cry,
              cd_fortify: if (combat_ends) 0 else ticked.cd_fortify,
      },
      inv' = { ...inv, qty_venom_sac: inv.qty_venom_sac - 1 },
      eqp' = eqp,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta, comp' = comp,
    }
  }

  // === Combo attack (3-hit chain: Slash 1x -> Thrust 1.5x -> Finisher 2x) ===
  action combo_attack = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    eqp.weapon_type == 0,
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
    val new_hp = if (new_enemy_hp > 0) ch.hp - incoming_enemy_dmg - player_poison_tick else ch.hp - player_poison_tick
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) ch.xp + zone_xp_reward(w.pos_x, w.pos_y) else ch.xp
    val new_level = if (ch.level < MAX_LEVEL and gained_xp >= xp_threshold(ch.level + 1)) ch.level + 1 else ch.level
    // Status ticking
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and cb.player_poison_dur == 0 and new_enemy_hp > 0)
    val ticked = tick_statuses(cb, apply_poison)
    val combat_ends = (new_enemy_hp <= 0 or new_hp <= 0)
    val new_combo_count = if (combat_ends) 0
                          else if (next_combo >= MAX_COMBO_CHAIN) 0
                          else next_combo
    // Loot drop on enemy defeat
    val enemy_defeated_alive = (new_enemy_hp <= 0 and new_hp > 0)
    val loot = compute_loot(meta, total_items, enemy_defeated_alive, w.turn_count, zone_tier, ch.xp)
    // Passive venom infusion: skill_poison turns your combo into a venom carrier.
    val auto_poison = ch.skill_poison and inv.qty_venom_sac > 0 and new_enemy_hp > 0
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
              max_mana: if (new_level > ch.level and ch.skill_magic) ch.max_mana + MANA_PER_LEVEL else ch.max_mana,
              skill_points: if (new_level > ch.level) ch.skill_points + SKILL_POINTS_PER_LEVEL else ch.skill_points,
      },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else new_enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: new_combo_count,
              player_poison_dur: if (combat_ends) 0 else ticked.player_poison_dur,
              player_atk_buff_dur: if (combat_ends) 0 else ticked.player_atk_buff_dur,
              player_def_buff_dur: if (combat_ends) 0 else ticked.player_def_buff_dur,
              enemy_poison_dur: if (combat_ends) 0 else if (auto_poison) STATUS_DURATION else ticked.enemy_poison_dur,
              cd_heavy_strike: if (combat_ends) 0 else ticked.cd_heavy_strike,
              cd_battle_cry: if (combat_ends) 0 else ticked.cd_battle_cry,
              cd_fortify: if (combat_ends) 0 else ticked.cd_fortify,
      },
      // If durability hits 0 this strike, enchants are lost with the broken sword.
      eqp' = if (eqp.sword_dur > 0 and new_sword_dur == 0)
               { ...eqp, sword_dur: 0, enchant_slot_1: 0, enchant_slot_2: 0, enchant_slot_3: 0 }
             else { ...eqp, sword_dur: new_sword_dur },
      inv' = { ...inv,
               qty_potion: inv.qty_potion + loot.potion_inc,
               qty_venom_sac: inv.qty_venom_sac + loot.venom_inc - (if (auto_poison) 1 else 0),
               qty_holy_dust: inv.qty_holy_dust + loot.holy_dust_inc,
      },
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = { ...meta, pity_counter: loot.new_pity, last_drop: loot.new_last_drop,
               last_kill_turn: if (enemy_defeated_alive) w.turn_count else meta.last_kill_turn,
               q1_kills: if (enemy_defeated_alive and zone_tier == 1 and meta.q1_kills < Q1_TARGET) meta.q1_kills + 1 else meta.q1_kills,
               q3_kills: if (enemy_defeated_alive and zone_tier == MAX_LEVEL and meta.q3_kills < Q3_TARGET) meta.q3_kills + 1 else meta.q3_kills,
               cq3_wins: if (enemy_defeated_alive and comp_active and meta.cq3_wins < CQ3_TARGET) meta.cq3_wins + 1 else meta.cq3_wins,
               boss_defeated: if (enemy_defeated_alive and is_castle_zone(w.pos_x, w.pos_y)) true else meta.boss_defeated },
      comp' = comp,
    }
  }

  // === Heavy strike (2x damage, costs 5 stamina, 3-turn cooldown) ===
  action heavy_strike = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    eqp.weapon_type == 0,
    ch.skill_heavy_strike,
    cb.cd_heavy_strike == 0,
    ch.stamina >= HEAVY_STRIKE_STAMINA,
    val heavy_dmg = attack_power * 2
    val new_sword_dur = if (inv.has_sword and eqp.sword_dur > 0) eqp.sword_dur - 1 else eqp.sword_dur
    val enemy_poison_dmg = if (cb.enemy_poison_dur > 0) POISON_DMG else 0
    val elem_heavy = effective_damage(heavy_dmg, player_elem_mult)
    val new_enemy_hp = cb.enemy_hp - elem_heavy - enemy_poison_dmg
    val new_hp = if (new_enemy_hp > 0) ch.hp - incoming_enemy_dmg - player_poison_tick else ch.hp - player_poison_tick
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) ch.xp + zone_xp_reward(w.pos_x, w.pos_y) else ch.xp
    val new_level = if (ch.level < MAX_LEVEL and gained_xp >= xp_threshold(ch.level + 1)) ch.level + 1 else ch.level
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and cb.player_poison_dur == 0 and new_enemy_hp > 0)
    val ticked = tick_statuses(cb, apply_poison)
    val combat_ends = (new_enemy_hp <= 0 or new_hp <= 0)
    val enemy_defeated_alive = (new_enemy_hp <= 0 and new_hp > 0)
    val loot = compute_loot(meta, total_items, enemy_defeated_alive, w.turn_count, zone_tier, ch.xp)
    // Passive venom infusion: skill_poison turns your heavy into a venom carrier.
    val auto_poison = ch.skill_poison and inv.qty_venom_sac > 0 and new_enemy_hp > 0
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
              max_mana: if (new_level > ch.level and ch.skill_magic) ch.max_mana + MANA_PER_LEVEL else ch.max_mana,
              skill_points: if (new_level > ch.level) ch.skill_points + SKILL_POINTS_PER_LEVEL else ch.skill_points,
      },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else new_enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,  // heavy strike breaks combo
              player_poison_dur: if (combat_ends) 0 else ticked.player_poison_dur,
              player_atk_buff_dur: if (combat_ends) 0 else ticked.player_atk_buff_dur,
              player_def_buff_dur: if (combat_ends) 0 else ticked.player_def_buff_dur,
              enemy_poison_dur: if (combat_ends) 0 else if (auto_poison) STATUS_DURATION else ticked.enemy_poison_dur,
              cd_heavy_strike: if (combat_ends) 0 else HEAVY_STRIKE_CD,
              cd_battle_cry: if (combat_ends) 0 else ticked.cd_battle_cry,
              cd_fortify: if (combat_ends) 0 else ticked.cd_fortify,
      },
      // If durability hits 0 this strike, enchants are lost with the broken sword.
      eqp' = if (eqp.sword_dur > 0 and new_sword_dur == 0)
               { ...eqp, sword_dur: 0, enchant_slot_1: 0, enchant_slot_2: 0, enchant_slot_3: 0 }
             else { ...eqp, sword_dur: new_sword_dur },
      inv' = { ...inv,
               qty_potion: inv.qty_potion + loot.potion_inc,
               qty_venom_sac: inv.qty_venom_sac + loot.venom_inc - (if (auto_poison) 1 else 0),
               qty_holy_dust: inv.qty_holy_dust + loot.holy_dust_inc,
      },
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = { ...meta, pity_counter: loot.new_pity, last_drop: loot.new_last_drop,
               last_kill_turn: if (enemy_defeated_alive) w.turn_count else meta.last_kill_turn,
               q1_kills: if (enemy_defeated_alive and zone_tier == 1 and meta.q1_kills < Q1_TARGET) meta.q1_kills + 1 else meta.q1_kills,
               q3_kills: if (enemy_defeated_alive and zone_tier == MAX_LEVEL and meta.q3_kills < Q3_TARGET) meta.q3_kills + 1 else meta.q3_kills,
               cq3_wins: if (enemy_defeated_alive and comp_active and meta.cq3_wins < CQ3_TARGET) meta.cq3_wins + 1 else meta.cq3_wins,
               boss_defeated: if (enemy_defeated_alive and is_castle_zone(w.pos_x, w.pos_y)) true else meta.boss_defeated },
      comp' = comp,
    }
  }

  // === Battle cry (grants ATK buff, costs 3 stamina, 4-turn cooldown) ===
  // Enemy hits back. Resets combo.
  action battle_cry = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    eqp.weapon_type == 0,
    ch.skill_battle_cry,
    cb.cd_battle_cry == 0,
    ch.stamina >= BATTLE_CRY_STAMINA,
    // Battle cry is a pure setup move — enemy does NOT retaliate. Only poison ticks.
    val new_hp = ch.hp - player_poison_tick
    val combat_ends = (new_hp <= 0)
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and cb.player_poison_dur == 0)
    val ticked = tick_statuses(cb, apply_poison)
    all {
      ch' = { ...ch, hp: if (new_hp < 0) 0 else new_hp, stamina: ch.stamina - BATTLE_CRY_STAMINA },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else cb.enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,
              player_poison_dur: if (combat_ends) 0 else ticked.player_poison_dur,
              player_atk_buff_dur: if (combat_ends) 0 else STATUS_DURATION,
              player_def_buff_dur: if (combat_ends) 0 else ticked.player_def_buff_dur,
              enemy_poison_dur: if (combat_ends) 0 else ticked.enemy_poison_dur,
              cd_heavy_strike: if (combat_ends) 0 else ticked.cd_heavy_strike,
              cd_battle_cry: if (combat_ends) 0 else BATTLE_CRY_CD,
              cd_fortify: if (combat_ends) 0 else ticked.cd_fortify,
      },
      eqp' = eqp, inv' = inv,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta, comp' = comp,
    }
  }

  // === Shield block (grants DEF buff, takes enemy hit) ===
  action shield_block = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    eqp.weapon_type == 0,
    ch.skill_shield_block,
    ch.stamina >= SHIELD_BLOCK_STAMINA,
    val new_hp = ch.hp - incoming_enemy_dmg - player_poison_tick
    val combat_ends = (new_hp <= 0)
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and cb.player_poison_dur == 0)
    val ticked = tick_statuses(cb, apply_poison)
    val new_shield_dur = if (eqp.has_shield) eqp.shield_dur - 1 else 0
    val shield_broken = eqp.has_shield and new_shield_dur <= 0
    all {
      ch' = { ...ch, hp: if (new_hp < 0) 0 else new_hp, stamina: ch.stamina - SHIELD_BLOCK_STAMINA },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else cb.enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,
              player_poison_dur: if (combat_ends) 0 else ticked.player_poison_dur,
              player_atk_buff_dur: if (combat_ends) 0 else ticked.player_atk_buff_dur,
              player_def_buff_dur: if (combat_ends) 0 else STATUS_DURATION,
              enemy_poison_dur: if (combat_ends) 0 else ticked.enemy_poison_dur,
              cd_heavy_strike: if (combat_ends) 0 else ticked.cd_heavy_strike,
              cd_battle_cry: if (combat_ends) 0 else ticked.cd_battle_cry,
              cd_fortify: if (combat_ends) 0 else ticked.cd_fortify,
      },
      eqp' = { ...eqp,
               has_shield: if (shield_broken) false else eqp.has_shield,
               shield_dur: if (shield_broken) 0 else new_shield_dur },
      inv' = inv,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta, comp' = comp,
    }
  }

  // === Skill unlock: Combo (tier 1 offense, no prereq) ===
  action unlock_combo = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    not(ch.skill_combo), ch.skill_points >= 1,
    ch' = { ...ch, skill_combo: true, skill_points: ch.skill_points - 1 },
    inv' = inv, eqp' = eqp, cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Skill unlock: Poison Strike (tier 1 utility, no prereq) ===
  action unlock_poison = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    not(ch.skill_poison), ch.skill_points >= 1,
    ch' = { ...ch, skill_poison: true, skill_points: ch.skill_points - 1 },
    inv' = inv, eqp' = eqp, cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Skill unlock: Shield Block (tier 1 defense, no prereq) ===
  action unlock_shield_block = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    not(ch.skill_shield_block), ch.skill_points >= 1,
    ch' = { ...ch, skill_shield_block: true, skill_points: ch.skill_points - 1 },
    inv' = inv, eqp' = eqp, cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Skill unlock: Heavy Strike (tier 2 offense, requires Combo) ===
  action unlock_heavy_strike = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    not(ch.skill_heavy_strike), ch.skill_combo, ch.skill_points >= 1,
    ch' = { ...ch, skill_heavy_strike: true, skill_points: ch.skill_points - 1 },
    inv' = inv, eqp' = eqp, cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Skill unlock: Counter-Attack (tier 2 defense, requires Shield Block) ===
  action unlock_counter_attack = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    not(ch.skill_counter_attack), ch.skill_shield_block, ch.skill_points >= 1,
    ch' = { ...ch, skill_counter_attack: true, skill_points: ch.skill_points - 1 },
    inv' = inv, eqp' = eqp, cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Skill unlock: Battle Cry (tier 3 offense, requires Heavy Strike, costs 2pt) ===
  action unlock_battle_cry = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    not(ch.skill_battle_cry), ch.skill_heavy_strike, ch.skill_points >= 2,
    ch' = { ...ch, skill_battle_cry: true, skill_points: ch.skill_points - 2 },
    inv' = inv, eqp' = eqp, cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Skill unlock: Fortify (tier 3 defense, requires Counter-Attack, costs 2pt) ===
  action unlock_fortify = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    not(ch.skill_fortify), ch.skill_counter_attack, ch.skill_points >= 2,
    ch' = { ...ch, skill_fortify: true, skill_points: ch.skill_points - 2 },
    inv' = inv, eqp' = eqp, cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Respec skills (at village, costs gold) ===
  action respec = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    val respec_cost = RESPEC_BASE_COST * (ch.respec_count + 1)
    val spent = (if (ch.skill_combo) 1 else 0) + (if (ch.skill_poison) 1 else 0) +
                (if (ch.skill_shield_block) 1 else 0) + (if (ch.skill_heavy_strike) 1 else 0) +
                (if (ch.skill_counter_attack) 1 else 0) + (if (ch.skill_battle_cry) 2 else 0) +
                (if (ch.skill_fortify) 2 else 0)
    all {
      spent > 0,
      ch.gold >= respec_cost,
      ch' = { ...ch,
              gold: ch.gold - respec_cost,
              skill_points: ch.skill_points + spent,
              skill_combo: false, skill_poison: false, skill_shield_block: false,
              skill_heavy_strike: false, skill_counter_attack: false,
              skill_battle_cry: false, skill_fortify: false,
              respec_count: ch.respec_count + 1,
      },
      inv' = inv, eqp' = eqp, cb' = cb,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta, comp' = comp,
    }
  }

  // === Counter-Attack (block + retaliatory hit) ===
  action counter_attack = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    eqp.weapon_type == 0,
    ch.skill_counter_attack,
    ch.stamina >= COUNTER_STAMINA,
    // Counter-attack is a retaliatory strike — deals HALF attack power (rounded down, min 1).
    // No longer a strict upgrade to combat_attack.
    val counter_base = if (attack_power / 2 < 1) 1 else attack_power / 2
    val player_dmg = effective_damage(counter_base, player_elem_mult)
    val new_enemy_hp = if (cb.enemy_hp - player_dmg < 0) 0 else cb.enemy_hp - player_dmg
    val enemy_poison_dmg = if (cb.enemy_poison_dur > 0) POISON_DMG else 0
    val final_enemy_hp = if (new_enemy_hp - enemy_poison_dmg < 0) 0 else new_enemy_hp - enemy_poison_dmg
    val new_hp = ch.hp - incoming_enemy_dmg - player_poison_tick
    val combat_ends = (new_hp <= 0 or final_enemy_hp <= 0)
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val xp_reward = if (final_enemy_hp <= 0 and new_hp > 0) zone_xp_reward(w.pos_x, w.pos_y) else 0
    val gold_reward = if (final_enemy_hp <= 0 and new_hp > 0) zone_gold_reward(w.pos_x, w.pos_y) else 0
    val new_xp = ch.xp + xp_reward
    val new_level = if (ch.level < MAX_LEVEL and new_xp >= xp_threshold(ch.level + 1)) ch.level + 1 else ch.level
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and cb.player_poison_dur == 0)
    val ticked = tick_statuses(cb, apply_poison)
    val dur_cost = if (inv.has_sword and eqp.sword_dur > 0) 1 else 0
    val enemy_defeated_alive = (final_enemy_hp <= 0 and new_hp > 0)
    val loot = compute_loot(meta, total_items, enemy_defeated_alive, w.turn_count, zone_tier, ch.xp)
    all {
      ch' = { ...ch,
              hp: if (new_hp < 0) 0 else new_hp,
              xp: new_xp, level: new_level,
              gold: ch.gold + gold_reward,
              max_hp: if (new_level > ch.level) ch.max_hp + HP_PER_LEVEL else ch.max_hp,
              base_attack: if (new_level > ch.level) ch.base_attack + ATK_PER_LEVEL_UP else ch.base_attack,
              stamina: ch.stamina - COUNTER_STAMINA,
              max_stamina: if (new_level > ch.level) ch.max_stamina + STAMINA_PER_LEVEL else ch.max_stamina,
              max_mana: if (new_level > ch.level and ch.skill_magic) ch.max_mana + MANA_PER_LEVEL else ch.max_mana,
              skill_points: if (new_level > ch.level) ch.skill_points + SKILL_POINTS_PER_LEVEL else ch.skill_points,
      },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else final_enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,
              player_poison_dur: if (combat_ends) 0 else ticked.player_poison_dur,
              player_atk_buff_dur: if (combat_ends) 0 else STATUS_DURATION,
              player_def_buff_dur: if (combat_ends) 0 else STATUS_DURATION,
              enemy_poison_dur: if (combat_ends) 0 else ticked.enemy_poison_dur,
              cd_heavy_strike: if (combat_ends) 0 else ticked.cd_heavy_strike,
              cd_battle_cry: if (combat_ends) 0 else ticked.cd_battle_cry,
              cd_fortify: if (combat_ends) 0 else ticked.cd_fortify,
      },
      // If this counter breaks the sword, enchants go with it.
      eqp' = if (eqp.sword_dur > 0 and eqp.sword_dur - dur_cost == 0)
               { ...eqp, sword_dur: 0, enchant_slot_1: 0, enchant_slot_2: 0, enchant_slot_3: 0 }
             else { ...eqp, sword_dur: eqp.sword_dur - dur_cost },
      inv' = { ...inv,
               qty_potion: inv.qty_potion + loot.potion_inc,
               qty_venom_sac: inv.qty_venom_sac + loot.venom_inc,
               qty_holy_dust: inv.qty_holy_dust + loot.holy_dust_inc,
      },
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = { ...meta, pity_counter: loot.new_pity, last_drop: loot.new_last_drop,
               last_kill_turn: if (enemy_defeated_alive) w.turn_count else meta.last_kill_turn,
               q1_kills: if (enemy_defeated_alive and zone_tier == 1 and meta.q1_kills < Q1_TARGET) meta.q1_kills + 1 else meta.q1_kills,
               q3_kills: if (enemy_defeated_alive and zone_tier == MAX_LEVEL and meta.q3_kills < Q3_TARGET) meta.q3_kills + 1 else meta.q3_kills,
               cq3_wins: if (enemy_defeated_alive and comp_active and meta.cq3_wins < CQ3_TARGET) meta.cq3_wins + 1 else meta.cq3_wins,
               boss_defeated: if (enemy_defeated_alive and is_castle_zone(w.pos_x, w.pos_y)) true else meta.boss_defeated },
      comp' = comp,
    }
  }

  // === Fortify (double-duration DEF buff, no damage, cooldown) ===
  action fortify = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    eqp.weapon_type == 0,
    ch.skill_fortify,
    cb.cd_fortify == 0,
    ch.stamina >= FORTIFY_STAMINA,
    val new_hp = ch.hp - incoming_enemy_dmg - player_poison_tick
    val combat_ends = (new_hp <= 0)
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and cb.player_poison_dur == 0)
    val ticked = tick_statuses(cb, apply_poison)
    all {
      ch' = { ...ch, hp: if (new_hp < 0) 0 else new_hp, stamina: ch.stamina - FORTIFY_STAMINA },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else cb.enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,
              player_poison_dur: if (combat_ends) 0 else ticked.player_poison_dur,
              player_atk_buff_dur: if (combat_ends) 0 else ticked.player_atk_buff_dur,
              player_def_buff_dur: if (combat_ends) 0 else FORTIFY_DURATION,
              enemy_poison_dur: if (combat_ends) 0 else ticked.enemy_poison_dur,
              cd_heavy_strike: if (combat_ends) 0 else ticked.cd_heavy_strike,
              cd_battle_cry: if (combat_ends) 0 else ticked.cd_battle_cry,
              cd_fortify: if (combat_ends) 0 else FORTIFY_CD,
      },
      eqp' = eqp, inv' = inv,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta, comp' = comp,
    }
  }

  // === Pistol shot (future-tech weapon: no elemental, no enchants, consumes battery) ===
  action pistol_shot = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    eqp.weapon_type == 1,
    inv.qty_battery >= 1,
    ch.stamina >= PISTOL_STAMINA,
    val pistol_dmg = ch.base_attack + PISTOL_BASE_BONUS + (if (cb.player_atk_buff_dur > 0) ATK_BUFF_BONUS else 0) + comp_atk_bonus
    val enemy_poison_dmg = if (cb.enemy_poison_dur > 0) POISON_DMG else 0
    val new_enemy_hp = cb.enemy_hp - pistol_dmg - enemy_poison_dmg
    val new_hp = if (new_enemy_hp > 0) ch.hp - incoming_enemy_dmg - player_poison_tick else ch.hp - player_poison_tick
    val gained_xp = if (new_enemy_hp <= 0 and new_hp > 0) ch.xp + zone_xp_reward(w.pos_x, w.pos_y) else ch.xp
    val new_level = if (ch.level < MAX_LEVEL and gained_xp >= xp_threshold(ch.level + 1)) ch.level + 1 else ch.level
    val zone_tier = zone_level(w.pos_x, w.pos_y)
    val apply_poison = (zone_tier >= POISON_APPLY_TIER and cb.player_poison_dur == 0 and new_enemy_hp > 0)
    val ticked = tick_statuses(cb, apply_poison)
    val combat_ends = (new_enemy_hp <= 0 or new_hp <= 0)
    val enemy_defeated_alive = (new_enemy_hp <= 0 and new_hp > 0)
    val loot = compute_loot(meta, total_items, enemy_defeated_alive, w.turn_count, zone_tier, ch.xp)
    all {
      ch' = { ...ch,
              hp: if (new_hp < 0) 0 else new_hp,
              xp: gained_xp,
              gold: if (new_enemy_hp <= 0) ch.gold + zone_gold_reward(w.pos_x, w.pos_y) else ch.gold,
              level: new_level,
              max_hp: if (new_level > ch.level) ch.max_hp + HP_PER_LEVEL else ch.max_hp,
              base_attack: if (new_level > ch.level) ch.base_attack + ATK_PER_LEVEL_UP else ch.base_attack,
              stamina: ch.stamina - PISTOL_STAMINA,
              max_stamina: if (new_level > ch.level) ch.max_stamina + STAMINA_PER_LEVEL else ch.max_stamina,
              max_mana: if (new_level > ch.level and ch.skill_magic) ch.max_mana + MANA_PER_LEVEL else ch.max_mana,
              skill_points: if (new_level > ch.level) ch.skill_points + SKILL_POINTS_PER_LEVEL else ch.skill_points,
      },
      cb' = { in_combat: if (combat_ends) false else true,
              enemy_hp: if (combat_ends) 0 else new_enemy_hp,
              enemy_attack: if (combat_ends) 0 else cb.enemy_attack,
              enemy_element: if (combat_ends) 0 else cb.enemy_element,
              combo_count: 0,
              player_poison_dur: if (combat_ends) 0 else ticked.player_poison_dur,
              player_atk_buff_dur: if (combat_ends) 0 else ticked.player_atk_buff_dur,
              player_def_buff_dur: if (combat_ends) 0 else ticked.player_def_buff_dur,
              enemy_poison_dur: if (combat_ends) 0 else ticked.enemy_poison_dur,
              cd_heavy_strike: if (combat_ends) 0 else ticked.cd_heavy_strike,
              cd_battle_cry: if (combat_ends) 0 else ticked.cd_battle_cry,
              cd_fortify: if (combat_ends) 0 else ticked.cd_fortify,
      },
      eqp' = eqp,
      inv' = { ...inv,
               qty_battery: inv.qty_battery - 1,
               qty_potion: inv.qty_potion + loot.potion_inc,
               qty_venom_sac: inv.qty_venom_sac + loot.venom_inc,
               qty_holy_dust: inv.qty_holy_dust + loot.holy_dust_inc,
      },
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = { ...meta, pity_counter: loot.new_pity, last_drop: loot.new_last_drop,
               last_kill_turn: if (enemy_defeated_alive) w.turn_count else meta.last_kill_turn,
               q1_kills: if (enemy_defeated_alive and zone_tier == 1 and meta.q1_kills < Q1_TARGET) meta.q1_kills + 1 else meta.q1_kills,
               q3_kills: if (enemy_defeated_alive and zone_tier == MAX_LEVEL and meta.q3_kills < Q3_TARGET) meta.q3_kills + 1 else meta.q3_kills,
               cq3_wins: if (enemy_defeated_alive and comp_active and meta.cq3_wins < CQ3_TARGET) meta.cq3_wins + 1 else meta.cq3_wins,
               boss_defeated: if (enemy_defeated_alive and is_castle_zone(w.pos_x, w.pos_y)) true else meta.boss_defeated },
      comp' = comp,
    }
  }

  // === Craft Venom Sac (at village, 2 iron) ===
  action craft_venom_sac = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    inv.qty_iron >= CRAFT_VENOM_IRON_COST,
    inv' = { ...inv, qty_iron: inv.qty_iron - CRAFT_VENOM_IRON_COST, qty_venom_sac: inv.qty_venom_sac + 1 },
    ch' = ch, eqp' = eqp, cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Craft holy water (village; holy_dust + wood -> holy_water consumable) ===
  action craft_holy_water = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    inv.qty_holy_dust >= 1,
    inv.qty_wood >= CRAFT_HOLY_WATER_WOOD,
    // Net delta: -1 holy_dust -W wood +1 holy_water => -W items net; guard anyway.
    total_items - 1 - CRAFT_HOLY_WATER_WOOD + 1 <= MAX_INVENTORY,
    inv' = { ...inv,
             qty_holy_dust: inv.qty_holy_dust - 1,
             qty_wood: inv.qty_wood - CRAFT_HOLY_WATER_WOOD,
             qty_holy_water: inv.qty_holy_water + 1 },
    ch' = ch, eqp' = eqp, cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Use holy water (out-of-combat full heal) ===
  action use_holy_water = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    inv.qty_holy_water >= 1,
    ch.hp < ch.max_hp,
    inv' = { ...inv, qty_holy_water: inv.qty_holy_water - 1 },
    ch' = { ...ch, hp: ch.max_hp },
    eqp' = eqp, cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Apply enchantment to slot 1 (at village, costs gold, requires sword) ===
  // === Apply enchantment to any slot (village, costs gold) ===
  action apply_enchant = {
    nondet slot = Set(1, 2, 3).oneOf()
    nondet etype = Set(1, 2, 3, 4).oneOf()
    // Vampiric (etype=3) costs 1 venom_sac; other elements cost 1 iron.
    val needs_venom = (etype == 3)
    all {
      not(cb.in_combat), not(meta.game_won), ch.hp > 0,
      zone_has_services(w.pos_x, w.pos_y),
      inv.has_sword,
      eqp.weapon_type == 0,
      ch.gold >= ENCHANT_COST,
      if (needs_venom) inv.qty_venom_sac >= ENCHANT_VENOM_COST
      else inv.qty_iron >= ENCHANT_IRON_COST,
      not(etype == 1 and has_ice_enchant),
      not(etype == 2 and has_fire_enchant),
      ch' = { ...ch, gold: ch.gold - ENCHANT_COST },
      eqp' = set_enchant_slot(eqp, slot, etype),
      inv' = { ...inv,
               qty_iron: if (needs_venom) inv.qty_iron else inv.qty_iron - ENCHANT_IRON_COST,
               qty_venom_sac: if (needs_venom) inv.qty_venom_sac - ENCHANT_VENOM_COST else inv.qty_venom_sac,
      },
      cb' = cb,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta, comp' = comp,
    }
  }

  // === Remove enchantment from any slot (at village, free) ===
  action remove_enchant = {
    nondet slot = Set(1, 2, 3).oneOf()
    all {
      not(cb.in_combat), not(meta.game_won), ch.hp > 0,
      zone_has_services(w.pos_x, w.pos_y),
      inv.has_sword,
      get_enchant_slot(eqp, slot) != 0,
      eqp' = set_enchant_slot(eqp, slot, 0),
      ch' = ch, inv' = inv, cb' = cb,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta, comp' = comp,
    }
  }

  // === Salvage sword (at village -- destroy 1 unequipped sword, recover materials) ===
  action salvage_sword = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    inv.qty_sword >= 1,
    // Capacity guard: net delta is (wood + iron yield) - 1 sword; must fit.
    total_items - 1 + salvage_wood_yield(inv.salvage_level) + salvage_iron_yield(inv.salvage_level) <= MAX_INVENTORY,
    inv' = { ...inv,
             qty_wood: inv.qty_wood + salvage_wood_yield(inv.salvage_level),
             qty_iron: inv.qty_iron + salvage_iron_yield(inv.salvage_level),
             qty_sword: inv.qty_sword - 1,
    },
    ch' = ch,
    // Salvage destroys an inventory sword; the equipped sword (and its enchants)
    // is untouched.
    eqp' = eqp,
    cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
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
    cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    meta' = meta, comp' = comp,
  }

  // === Save game (only outside combat, alive, not won) ===
  action save_game = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    meta' = { ...meta, saved_exists: true },
    comp' = comp,
    ch' = ch, inv' = inv, eqp' = eqp, cb' = cb, w' = w,
  }

  // === Load game (requires a save to exist) ===
  // NOTE: The spec models load_game as a no-op identity transition — it only
  // checks that a save exists. Modeling a real restore would require snapshotting
  // all 6 record state vars into meta, which is invasive for marginal value. The
  // Odin implementation performs the actual restore, and the MBT harness skips
  // replaying load_game (it returns true when saved_exists is set). Save/load
  // correctness is tested independently in the game runtime.
  action load_game = all {
    meta.saved_exists,
    ch' = ch, inv' = inv, eqp' = eqp, cb' = cb, w' = w, meta' = meta, comp' = comp,
  }

  // === Claim quest reward (stackable; unlocks as quests complete) ===
  action claim_quest_reward = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    meta.quest_rewards_claimed < 3,
    // Next reward requires the corresponding quest complete.
    (meta.quest_rewards_claimed == 0).implies(quest1_complete),
    (meta.quest_rewards_claimed == 1).implies(quest2_complete),
    (meta.quest_rewards_claimed == 2).implies(quest3_complete),
    ch' = { ...ch, gold: ch.gold + QUEST_REWARD_GOLD, skill_points: ch.skill_points + 1 },
    meta' = { ...meta, quest_rewards_claimed: meta.quest_rewards_claimed + 1 },
    inv' = inv, eqp' = eqp, cb' = cb,
    w' = { ...w, turn_count: w.turn_count + 1 },
    comp' = comp,
  }

  // === Claim Victory ===
  action claim_victory = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    ch.level >= MAX_LEVEL,
    zone_biome_x(w.pos_x) == 2, zone_biome_y(w.pos_y) == 2,
    zone_level(w.pos_x, w.pos_y) >= MAX_LEVEL,
    meta.boss_defeated,
    meta' = { ...meta, game_won: true },
    comp' = comp,
    ch' = ch, inv' = inv, eqp' = eqp,
    cb' = cb,
    w' = w,
  }

  // === Fast travel to an unlocked waypoint ===
  action fast_travel = {
    nondet target = w.waypoints.oneOf()
    all {
      not(cb.in_combat), not(meta.game_won), ch.hp > 0,
      target._1 != w.pos_x or target._2 != w.pos_y,
      zone_level(target._1, target._2) <= ch.level,
      w' = { ...w, pos_x: target._1, pos_y: target._2, turn_count: w.turn_count + 1,
             visited: w.visited.union(Set((target._1, target._2))) },
      ch' = ch, inv' = inv, eqp' = eqp, cb' = cb,
      meta' = { ...meta, q2_zones: if (quest1_complete and zone_level(target._1, target._2) >= 2 and not(w.visited.contains(target)) and meta.q2_zones < Q2_TARGET) meta.q2_zones + 1 else meta.q2_zones },
      comp' = comp,
    }
  }

  // === Companion actions ===
  //
  // Abstract model: companion is a (trait, rarity) tuple.
  // Species (wolf/hawk/fox/owl/...) is flavor the game catalog handles — the
  // spec does not enumerate species. Adoption nondeterministically picks any
  // trait+rarity the player can afford (bounded search: 4 * 3 = 12 classes).
  // Material cost abstracts to a "wood-or-iron" test of (rarity+1)*ADOPT_BASE_COST.
  //
  // The MBT harness maps each abstract (trait, rarity) onto a concrete species
  // from the Odin-side SPECIES_DEFS catalog with matching affinity.

  action adopt_companion = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    not(comp.active),
    nondet t = oneOf(Set(0, 1, 2, 3))
    nondet r = oneOf(Set(0, 1, 2))
    val cost = (r + 1) * ADOPT_BASE_COST
    all {
      // Any service zone gates adoption (sanctuary/village abstraction)
      zone_has_services(w.pos_x, w.pos_y),
      inv.qty_wood >= cost,
      inv' = { ...inv, qty_wood: inv.qty_wood - cost },
      comp' = { active: true, trait: t, rarity: r, loyalty: INITIAL_LOYALTY, command_used: false },
      meta' = { ...meta, cq1_adopted: if (meta.cq1_adopted < CQ1_TARGET) meta.cq1_adopted + 1 else meta.cq1_adopted },
      ch' = ch, eqp' = eqp, cb' = cb, w' = w,
    }
  }

  // Feed companion at village: 1 potion -> +LOYALTY_GAIN
  action feed_companion = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    comp.active, comp.loyalty < MAX_LOYALTY,
    inv.qty_potion >= 1,
    val new_loyalty = if (comp.loyalty + LOYALTY_GAIN > MAX_LOYALTY) MAX_LOYALTY else comp.loyalty + LOYALTY_GAIN
    all {
      inv' = { ...inv, qty_potion: inv.qty_potion - 1 },
      comp' = { ...comp, loyalty: new_loyalty },
      meta' = { ...meta, cq2_maxed: if (new_loyalty == MAX_LOYALTY and meta.cq2_maxed < CQ2_TARGET) meta.cq2_maxed + 1 else meta.cq2_maxed },
      ch' = ch, eqp' = eqp, cb' = cb, w' = w,
    }
  }

  // Train companion — at a village, consume wood to raise rarity by 1.
  // Cost scales with target rarity: (new_rarity + 1) * TRAIN_COST.
  // Legendary is the cap.
  action train_companion = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    comp.active,
    comp.rarity < COMP_RARITY_COUNT - 1,
    val new_rarity = comp.rarity + 1
    val cost = (new_rarity + 1) * TRAIN_COST
    all {
      inv.qty_wood >= cost,
      inv' = { ...inv, qty_wood: inv.qty_wood - cost },
      comp' = { ...comp, rarity: new_rarity },
      ch' = ch, eqp' = eqp, cb' = cb,
      w' = { ...w, turn_count: w.turn_count + 1 },
      meta' = meta,
    }
  }

  // Dismiss companion at village. Refunds (rarity+1)*ADOPT_BASE_COST in wood
  // — scales with current rarity so trained companions yield more on release.
  action dismiss_companion = all {
    not(cb.in_combat), not(meta.game_won), ch.hp > 0,
    zone_has_services(w.pos_x, w.pos_y),
    comp.active,
    val refund = (comp.rarity + 1) * ADOPT_BASE_COST
    all {
      comp' = { active: false, trait: 0, rarity: 0, loyalty: 0, command_used: false },
      inv' = { ...inv, qty_wood: inv.qty_wood + refund },
      ch' = ch, eqp' = eqp, cb' = cb, w' = w, meta' = meta,
    }
  }

  // Companion command (in-combat, high loyalty, one per combat)
  // Trait 0 (Attacker)/2 (Scout): ATK buff
  // Trait 1 (Defender):           DEF buff
  // Trait 3 (Support):            enemy poison (debuff)
  action companion_command = all {
    cb.in_combat, not(meta.game_won), ch.hp > 0, cb.enemy_hp > 0,
    comp.active, comp.loyalty >= HIGH_LOYALTY,
    not(comp.command_used),
    cb' = { ...cb,
      player_atk_buff_dur: if (comp.trait == 0 or comp.trait == 2) STATUS_DURATION else cb.player_atk_buff_dur,
      player_def_buff_dur: if (comp.trait == 1) STATUS_DURATION else cb.player_def_buff_dur,
      enemy_poison_dur:    if (comp.trait == 3) STATUS_DURATION else cb.enemy_poison_dur,
    },
    comp' = { ...comp, command_used: true },
    ch' = ch, inv' = inv, eqp' = eqp, meta' = meta,
    w' = { ...w, turn_count: w.turn_count + 1 },
  }

  // === Step ===
  action step = any {
    move_up, move_down, move_left, move_right, fast_travel,
    enter_combat, combat_attack, combat_potion, flee_combat,
    rest_at_village, buy_potion, buy_shield, buy_armor, repair_sword, buy_spellbook,
    gather_wood, mine_iron, craft_sword, equip_sword, equip_pistol, equip_staff,
    buy_trinket, remove_trinket,
    use_antidote, poison_strike, combo_attack,
    heavy_strike, battle_cry, shield_block,
    counter_attack, fortify, pistol_shot,
    unlock_combo, unlock_poison, unlock_shield_block,
    unlock_heavy_strike, unlock_counter_attack,
    unlock_battle_cry, unlock_fortify,
    respec, craft_venom_sac,
    salvage_sword, upgrade_salvage,
    apply_enchant, remove_enchant,
    adopt_companion,
    feed_companion, dismiss_companion, companion_command, train_companion,
    save_game, load_game, claim_victory,
    claim_quest_reward,
    cast_heal, cast_fireball,
    nondet sid = oneOf(Set(SPELL_HEAL, SPELL_FIRE)) cast_spell(sid),
    buy_scroll_fire, use_scroll_fire,
    craft_holy_water, use_holy_water,
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
  val current_pos_visited = w.visited.contains((w.pos_x, w.pos_y))
  val start_is_waypoint = w.waypoints.contains((0, 0))
  val waypoints_are_visited = w.waypoints.forall(p => w.visited.contains(p))
  /// All visited cells are on the grid
  val visited_in_bounds = w.visited.forall(p =>
    p._1 >= 0 and p._1 < WORLD_SIZE and p._2 >= 0 and p._2 < WORLD_SIZE)
  /// Every waypoint is a service zone (fast travel assumes this)
  val waypoint_is_service_zone = w.waypoints.forall(p => zone_has_services(p._1, p._2))

  /// Quantities never go negative
  val quantities_non_negative = and {
    inv.qty_potion >= 0,
    inv.qty_wood >= 0,
    inv.qty_iron >= 0,
    inv.qty_sword >= 0,
    inv.qty_venom_sac >= 0,
    inv.qty_battery >= 0,
    inv.qty_scroll_fire >= 0,
    inv.qty_holy_dust >= 0,
    inv.qty_holy_water >= 0,
  }

  /// Can only be in a zone you're qualified for
  val level_gate_respected = zone_level(w.pos_x, w.pos_y) <= ch.level

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

  /// Broken sword gives no attack bonus: neither SWORD_ATK_BONUS nor enchant atk.
  /// (ATK buff and companion atk bonuses are independent and may still apply.
  /// Fog penalty and min-1 clamp from attack_power are also accounted for.)
  val atk_buff_bonus_val = if (cb.player_atk_buff_dur > 0) ATK_BUFF_BONUS else 0
  val broken_no_bonus_raw = ch.base_attack + atk_buff_bonus_val + comp_atk_bonus - fog_penalty_now
  val broken_no_bonus = (inv.has_sword and eqp.sword_dur == 0).implies(
    attack_power == (if (broken_no_bonus_raw < 1) 1 else broken_no_bonus_raw)
  )

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

  /// Stamina bounded [0, max_stamina]
  val stamina_bounded = ch.stamina >= 0 and ch.stamina <= ch.max_stamina

  /// Mana bounded [0, max_mana]; inert until skill_magic unlocks.
  val mana_bounded = ch.mana >= 0 and ch.mana <= ch.max_mana and ch.max_mana >= 0
  val mana_requires_magic = not(ch.skill_magic).implies(ch.mana == 0 and ch.max_mana == 0)

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

  /// Active combat always has an enemy with positive attack
  val combat_enemy_has_attack = cb.in_combat.implies(cb.enemy_attack > 0)

  /// Last kill turn is non-negative and bounded by turn count
  val last_kill_turn_bounded = meta.last_kill_turn >= 0 and meta.last_kill_turn <= w.turn_count

  /// Base attack grows correctly with level
  val base_attack_scales_with_level =
    ch.base_attack >= INITIAL_ATTACK + (ch.level - 1) * ATK_PER_LEVEL_UP

  /// Victory only set under valid claim_victory guards (safety form of liveness)
  val victory_preconditions = meta.game_won.implies(
    ch.level >= MAX_LEVEL and zone_level(w.pos_x, w.pos_y) >= MAX_LEVEL and meta.boss_defeated)

  /// Victory requires the castle boss has been defeated
  val win_requires_boss_defeated = meta.game_won.implies(meta.boss_defeated)

  /// Win condition requires Castle position
  val win_requires_castle = meta.game_won.implies(
    w.pos_x % 3 == 2 and w.pos_y % 3 == 2 and zone_level(w.pos_x, w.pos_y) >= MAX_LEVEL
  )

  /// Skill points are non-negative
  val skill_points_non_negative = ch.skill_points >= 0

  /// Respec count is non-negative
  val respec_count_non_negative = ch.respec_count >= 0

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

  /// Weapon type bounded (0=sword, 1=pistol)
  val weapon_type_bounded = eqp.weapon_type >= 0 and eqp.weapon_type <= 2
  val trinket_bounded = eqp.trinket >= 0 and eqp.trinket <= 1
  val shield_dur_bounded = eqp.shield_dur >= 0 and eqp.shield_dur <= SHIELD_MAX_DUR
  val shield_consistent = eqp.has_shield.implies(eqp.shield_dur > 0)
  val armor_dur_bounded = eqp.armor_dur >= 0 and eqp.armor_dur <= ARMOR_MAX_DUR
  val armor_consistent = eqp.has_armor.implies(eqp.armor_dur > 0)

  /// Battery quantity bounded [0, BATTERY_CAP]
  val qty_battery_bounded = inv.qty_battery >= 0 and inv.qty_battery <= BATTERY_CAP

  /// Pistols cannot hold enchantments (energy weapons ignore arcane runes)
  val pistol_no_enchants = (eqp.weapon_type == 1).implies(
    eqp.enchant_slot_1 == 0 and eqp.enchant_slot_2 == 0 and eqp.enchant_slot_3 == 0
  )

  /// Enemy element is only set during combat
  val enemy_element_only_in_combat = not(cb.in_combat).implies(cb.enemy_element == 0)

  /// Inventory capacity bounded
  val inventory_bounded = total_items <= MAX_INVENTORY

  /// Salvage level bounded [1, MAX_SALVAGE_LEVEL]
  val salvage_level_bounded = inv.salvage_level >= 1 and inv.salvage_level <= MAX_SALVAGE_LEVEL

  /// Quest counters bounded by their targets
  val quest_counters_bounded = and {
    meta.q1_kills >= 0, meta.q1_kills <= Q1_TARGET,
    meta.q2_zones >= 0, meta.q2_zones <= Q2_TARGET,
    meta.q3_kills >= 0, meta.q3_kills <= Q3_TARGET,
    meta.quest_rewards_claimed >= 0, meta.quest_rewards_claimed <= 3,
  }

  /// Quest prerequisites: q2 progress requires q1 complete, q3 progress requires q2 complete
  val quest_prereqs_respected = and {
    (meta.q2_zones > 0) implies quest1_complete,
    (meta.q3_kills > 0) implies quest2_complete,
    (meta.quest_rewards_claimed >= 1) implies quest1_complete,
    (meta.quest_rewards_claimed >= 2) implies quest2_complete,
    (meta.quest_rewards_claimed >= 3) implies quest3_complete,
  }

  /// Companion trait is in [0, COMP_TRAIT_COUNT)
  val comp_trait_bounded = comp.trait >= 0 and comp.trait < COMP_TRAIT_COUNT

  /// Companion rarity is in [0, COMP_RARITY_COUNT)
  val comp_rarity_bounded = comp.rarity >= 0 and comp.rarity < COMP_RARITY_COUNT

  /// Companion loyalty bounded [0, MAX_LOYALTY]
  val comp_loyalty_bounded = comp.loyalty >= 0 and comp.loyalty <= MAX_LOYALTY

  /// Inactive companion implies no loyalty
  val comp_inactive_no_loyalty = (not(comp.active)) implies (comp.loyalty == 0)

  /// Derived atk bonus stays within each trait's tight ceiling.
  /// Non-attacking traits contribute zero; attacking traits scale with rarity.
  val comp_atk_bonus_bounded = and {
    comp_atk_bonus >= 0,
    (comp.trait == 0).implies(comp_atk_bonus <= COMP_ATK_BASE_ATTACKER * COMP_RARITY_COUNT),
    (comp.trait == 2).implies(comp_atk_bonus <= COMP_ATK_BASE_SCOUT * COMP_RARITY_COUNT),
    (comp.trait == 1 or comp.trait == 3).implies(comp_atk_bonus == 0),
  }

  /// Derived dmg reduction stays within each trait's tight ceiling.
  val comp_dmg_reduction_bounded = and {
    comp_dmg_reduction >= 0,
    (comp.trait == 1).implies(comp_dmg_reduction <= COMP_DEF_BASE_DEFENDER * COMP_RARITY_COUNT),
    (comp.trait == 3).implies(comp_dmg_reduction <= COMP_DEF_BASE_SUPPORT * COMP_RARITY_COUNT),
    (comp.trait == 0 or comp.trait == 2).implies(comp_dmg_reduction == 0),
  }

  /// Inactive companion has fully zeroed effect tuple (no ghost trait/rarity).
  val comp_inactive_zeroed = (not(comp.active)).implies(
    comp.trait == 0 and comp.rarity == 0 and comp.loyalty == 0
  )

  /// Companion quest counters bounded
  val companion_quest_counters_bounded = and {
    meta.cq1_adopted >= 0, meta.cq1_adopted <= CQ1_TARGET,
    meta.cq2_maxed >= 0, meta.cq2_maxed <= CQ2_TARGET,
    meta.cq3_wins >= 0, meta.cq3_wins <= CQ3_TARGET,
  }

  /// Companion quest prerequisites respected
  val companion_quest_prereqs_respected = and {
    (meta.cq2_maxed > 0) implies cquest1_complete,
    (meta.cq3_wins > 0) implies cquest2_complete,
  }

}

module quint_crawl_run {
  import quint_crawl.*
}
