package quint_crawl

// Zone names by biome (indexed as [x%3][y%3])
ZONE_NAMES := [3][3]string{
	{"Village", "Plains", "Ruins"},
	{"Forest", "Cave", "Shrine"},
	{"Swamp", "Mountain", "Castle"},
}

XP_THRESHOLDS := [MAX_LEVEL + 1]int{0, 0, 15, 50, 110, 200}   // index by level

// --- World scaling constants ---
WORLD_SIZE :: 9        // grid dimension (NxN)
MAX_LEVEL :: 5         // max zone difficulty
TILES_PER_LEVEL :: 3   // (x+y) distance per level increment
BASE_ENEMY_HP :: 20    // enemy HP at level 1
BASE_ENEMY_ATK :: 2    // enemy ATK constant term
ATK_PER_LEVEL :: 4     // enemy ATK per level
BASE_XP :: 5           // XP reward per level
BASE_GOLD :: 8         // gold reward constant term
GOLD_PER_LEVEL :: 2    // gold reward per level

SWORD_MAX_DUR :: 10
REPAIR_COST :: 5
POISON_DMG :: 7
ATK_BUFF_BONUS :: 8
DEF_BUFF_REDUCTION :: 3
FORTIFY_DEF_REDUCTION :: 5
STATUS_DURATION :: 3
WEATHER_CYCLE :: 5
STORM_MOVE_DMG :: 4
FOG_ATK_PENALTY :: 2
RAIN_GATHER_BONUS :: 1
ATTACK_STAMINA :: 2
COMBO_STAMINA :: 3
HEAVY_STRIKE_STAMINA :: 5
BATTLE_CRY_STAMINA :: 3
HEAVY_STRIKE_CD :: 3
BATTLE_CRY_CD :: 2
PITY_THRESHOLD :: 8
// Quest targets
Q1_TARGET :: 2  // slime kills
Q2_TARGET :: 3  // ZL2+ zone entries after Q1 complete
Q3_TARGET :: 2  // dragon kills
// Companion quest targets
CQ1_TARGET :: 1
CQ2_TARGET :: 1
CQ3_TARGET :: 5
QUEST_REWARD_GOLD :: 30
// Companion constants
MAX_LOYALTY :: 100
INITIAL_LOYALTY :: 50
LOYALTY_GAIN :: 10
LOYALTY_COMBAT_COST :: 5
HIGH_LOYALTY :: 75
LOW_LOYALTY :: 25
TRAIN_COST :: 3
// Companion trait base effects (scaled by rarity tier+1)
COMP_ATK_BASE_ATTACKER :: 2
COMP_ATK_BASE_SCOUT    :: 1
COMP_DEF_BASE_DEFENDER :: 1
COMP_DEF_BASE_SUPPORT  :: 1
COMP_TRAIT_COUNT       :: 4
COMP_RARITY_COUNT      :: 3
ADOPT_BASE_COST        :: 1   // wood cost baseline; scales with rarity
SWORD_ATK_BONUS :: 5
POTION_COST :: 15
HP_PER_LEVEL :: 15
ATK_PER_LEVEL_UP :: 2
STAMINA_PER_LEVEL :: 2
STAMINA_REGEN_PER_MOVE :: 1
MANA_PER_LEVEL :: 3
MANA_REGEN_PER_MOVE :: 1
SPELLBOOK_COST :: 40
FIREBALL_COST :: 5
FIREBALL_DMG :: 14
HEAL_COST :: 4
HEAL_AMOUNT :: 20
INITIAL_MAX_MANA :: 10
SPELL_HEAL :: 0
SPELL_FIRE :: 1
SCROLL_FIRE_COST :: 25
CRAFT_HOLY_WATER_WOOD :: 2
INITIAL_HP :: 50
INITIAL_ATTACK :: 10
INITIAL_POTIONS :: 2
INITIAL_STAMINA :: 10
POTION_HEAL :: 20
CRAFT_WOOD_COST :: 1
CRAFT_IRON_COST :: 2
POISON_APPLY_TIER :: 2
LOOT_DROP_MODULO :: 3
MAX_COMBO_CHAIN :: 3
SKILL_POINTS_PER_LEVEL :: 1
RESPEC_BASE_COST :: 25
COUNTER_STAMINA :: 3
SHIELD_BLOCK_STAMINA :: 3
FORTIFY_STAMINA :: 4
FORTIFY_CD :: 5
FORTIFY_DURATION :: 8
CRAFT_VENOM_IRON_COST :: 2
ENCHANT_COST :: 25
ENCHANT_IRON_COST :: 1
ENCHANT_VENOM_COST :: 1
MAX_INVENTORY :: 30
BATTERY_CAP :: 20
PISTOL_UNLOCK_COST :: 50
STAFF_UNLOCK_COST :: 40
STAFF_MAX_MANA_BONUS :: 5
STAFF_SPELL_BONUS :: 5
STAFF_HEAL_BONUS :: 5
TRINKET_COST :: 25
TRINKET_VITALITY_HP :: 5
SHIELD_COST :: 30
SHIELD_MAX_DUR :: 5
SHIELD_DEF :: 2
ARMOR_COST :: 40
ARMOR_MAX_DUR :: 8
ARMOR_DEF :: 1
PISTOL_STAMINA :: 2
PISTOL_BASE_BONUS :: 4
CRAFT_LEVEL_REQ :: 2
SALVAGE_WOOD_BASE :: 0
SALVAGE_IRON_BASE :: 1
UPGRADE_SALVAGE_COST :: 15
MAX_SALVAGE_LEVEL :: 3
RESPAWN_TURNS :: 3
// Castle boss — replaces the tier-5 Castle-zone enemy until defeated
BOSS_HP :: 80
BOSS_ATK :: 12
BOSS_ELEMENT :: 1

// Common guard checks
can_act_map :: proc(g: ^Game_State) -> bool {
	return !g.in_combat && !g.game_won && g.hp > 0
}

can_act_combat :: proc(g: ^Game_State) -> bool {
	return g.in_combat && !g.game_won && g.hp > 0 && g.enemy_hp > 0
}

Save_Data :: struct {
	hp:           int,
	max_hp:       int,
	base_attack:  int,
	xp:           int,
	level:        int,
	gold:         int,
	pos_x:        int,
	pos_y:        int,
	qty_potion:   int,
	qty_wood:     int,
	qty_iron:     int,
	qty_sword:    int,
	has_sword:    bool,
	sword_dur:    int,
	sword_max_dur: int,
	weapon_type:  int,
	trinket:      int,
	has_shield:   bool,
	shield_dur:   int,
	has_armor:    bool,
	armor_dur:    int,
	turn_count:   int,
	stamina:      int,
	max_stamina:  int,
	pity_counter: int,
	skill_points: int,
	skill_combo:  bool,
	skill_poison: bool,
	skill_shield_block: bool,
	skill_heavy_strike: bool,
	skill_counter_attack: bool,
	skill_battle_cry: bool,
	skill_fortify: bool,
	respec_count: int,
	qty_venom_sac: int,
	qty_battery:   int,
	qty_scroll_fire: int,
	qty_holy_dust: int,
	qty_holy_water: int,
	qty_pelt:      int,
	qty_core:      int,
	qty_essence:   int,
	qty_coin:      int,
	qty_ichor:     int,
	enemy_element: int,
	enchant_slot_1: int,
	enchant_slot_2: int,
	enchant_slot_3: int,
	salvage_level: int,
	last_kill_turn: int,
	q1_kills:     int,
	q2_zones:     int,
	q3_kills:     int,
	comp_active:  bool,
	comp_species: int,   // index into SPECIES_DEFS (-1 if none)
	comp_trait:   int,   // 0=Attacker, 1=Defender, 2=Scout, 3=Support
	comp_rarity:  int,   // 0=Common, 1=Rare, 2=Legendary
	comp_loyalty: int,
	cq1_adopted:  int,
	cq2_maxed:    int,
	cq3_wins:     int,
	quest_rewards_claimed: int,
	boss_defeated: bool,
	visited:      [WORLD_SIZE][WORLD_SIZE]bool,
	waypoints:    [WORLD_SIZE][WORLD_SIZE]bool,
	skill_magic:  bool,
	mana:         int,
	max_mana:     int,
}

Game_State :: struct {
	hp:           int,
	max_hp:       int,
	base_attack:  int,
	xp:           int,
	level:        int,
	gold:         int,
	pos_x:        int,
	pos_y:        int,
	qty_potion:   int,
	qty_wood:     int,
	qty_iron:     int,
	qty_sword:    int,
	has_sword:    bool,
	sword_dur:    int,
	sword_max_dur: int,
	weapon_type:  int, // 0=sword, 1=pistol, 2=staff
	trinket:      int,
	has_shield:   bool,
	shield_dur:   int,
	has_armor:    bool,
	armor_dur:    int,
	in_combat:    bool,
	enemy_hp:     int,
	enemy_attack: int,
	game_won:     bool,
	// Status effects
	player_poison_dur:   int,
	player_atk_buff_dur: int,
	player_def_buff_dur: int,
	enemy_poison_dur:    int,
	// Combo state
	combo_count:         int,
	// Stamina
	stamina:             int,
	max_stamina:         int,
	// Magic / Mana (inert until skill_magic = true)
	skill_magic:         bool,
	mana:                int,
	max_mana:            int,
	// Cooldowns
	cd_heavy_strike:     int,
	cd_battle_cry:       int,
	cd_fortify:          int,
	// Loot
	pity_counter:        int,
	last_drop:           int,
	// World state
	turn_count:          int,
	// Fog of war
	visited:             [WORLD_SIZE][WORLD_SIZE]bool,
	// Fast travel
	waypoints:           [WORLD_SIZE][WORLD_SIZE]bool,
	// Skill tree
	skill_points:        int,
	skill_combo:         bool,
	skill_poison:        bool,
	skill_shield_block:  bool,
	skill_heavy_strike:  bool,
	skill_counter_attack: bool,
	skill_battle_cry:    bool,
	skill_fortify:       bool,
	// Respec escalation (scales cost with uses)
	respec_count:        int,
	// Venom sac
	qty_venom_sac:       int,
	// Battery (future-tech power cell for pistols / oracle shards)
	qty_battery:         int,
	// Fire scroll (combat consumable that deals fireball damage)
	qty_scroll_fire:     int,
	// Trait-keyed archetype loot (Odin-only, not in MBT spec contract).
	// All six fields are invisible to the getter so the spec contract
	// stays untouched. Humanoid and Aberration intentionally do NOT reuse
	// gold / qty_venom_sac because those are spec-tracked.
	qty_holy_dust:       int,  // Undead
	qty_holy_water:      int,  // Crafted from holy_dust (spec-visible)
	qty_pelt:            int,  // Beast
	qty_core:            int,  // Construct
	qty_essence:         int,  // Elemental
	qty_coin:            int,  // Humanoid (bonus trophy coins, not treasury gold)
	qty_ichor:           int,  // Aberration
	// Active enemy archetype trait (set at enter_combat; drives resolve_loot branch)
	enemy_trait:         Enemy_Trait,
	// Elemental & Enchantment
	enemy_element:       int,  // 0=none, 1=fire, 2=ice, 3=lightning, 4=earth
	enchant_slot_1:      int,  // 0=empty, 1=fire, 2=ice, 3=vampiric, 4=lightning
	enchant_slot_2:      int,
	enchant_slot_3:      int,
	// Salvage
	salvage_level:       int,  // 1-3, determines material recovery
	// Respawn timer
	last_kill_turn:      int,
	// Quests
	q1_kills:            int,  // slime slayer (ZL1 kills, capped Q1_TARGET)
	q2_zones:            int,  // venture forth (ZL2+ zone entries after Q1, capped Q2_TARGET)
	q3_kills:            int,  // castle conqueror (dragon kills, capped Q3_TARGET)
	// Companion (data-driven: species is catalog index, mechanics come from trait+rarity)
	comp_active:         bool,
	comp_species:        int,  // index into SPECIES_DEFS, -1 if none
	comp_trait:          int,  // 0=Attacker, 1=Defender, 2=Scout, 3=Support
	comp_rarity:         int,  // 0=Common, 1=Rare, 2=Legendary
	comp_loyalty:        int,  // [0, MAX_LOYALTY]
	comp_command_used:   bool, // per-combat flag
	// Companion quests
	cq1_adopted:         int,  // 0..CQ1_TARGET
	cq2_maxed:           int,  // 0..CQ2_TARGET
	cq3_wins:            int,  // 0..CQ3_TARGET
	quest_rewards_claimed: int, // 0..3, stackable claim counter
	// Castle boss kill flag — gates claim_victory
	boss_defeated:       bool,
	// Save/Load
	saved_exists:        bool,
	save_data:           Save_Data,
}

zone_name :: proc(x, y: int) -> string {
	if x < 0 || x >= WORLD_SIZE || y < 0 || y >= WORLD_SIZE do return "Unknown"
	return ZONE_NAMES[x % 3][y % 3]
}

// Zone difficulty level — distance from origin determines difficulty
zone_level :: proc(x, y: int) -> int {
	if x < 0 || x >= WORLD_SIZE || y < 0 || y >= WORLD_SIZE do return 99
	raw := (x + y) / TILES_PER_LEVEL + 1
	return min(raw, MAX_LEVEL)
}

// Enemy stats — linear formulas of zone level
zone_enemy_hp :: proc(x, y: int) -> int {
	return BASE_ENEMY_HP * zone_level(x, y)
}

zone_enemy_atk :: proc(x, y: int) -> int {
	return BASE_ENEMY_ATK + ATK_PER_LEVEL * zone_level(x, y)
}

zone_xp_reward :: proc(x, y: int) -> int {
	return BASE_XP * zone_level(x, y)
}

zone_gold_reward :: proc(x, y: int) -> int {
	return BASE_GOLD + GOLD_PER_LEVEL * zone_level(x, y)
}

// Zone feature predicates — which zones have which facilities
zone_has_services :: proc(x, y: int) -> bool {
	return x % 3 == 0 && y % 3 == 0
}

is_castle_zone :: proc(x, y: int) -> bool {
	return x % 3 == 2 && y % 3 == 2 && zone_level(x, y) >= MAX_LEVEL
}

zone_has_wood :: proc(x, y: int) -> bool {
	return x % 3 == 1 && y % 3 == 0
}

zone_has_iron :: proc(x, y: int) -> bool {
	return x % 3 == 2 && y % 3 == 1
}

// Weather: 0=Clear, 1=Rain, 2=Fog, 3=Storm
zone_weather :: proc(x, y, turn: int) -> int {
	return (x * 3 + y * 7 + turn / WEATHER_CYCLE) % 4
}

// --- Elemental helpers ---
// Fire(1)>Ice(2)>Lightning(3)>Earth(4)>Fire(1)
is_strong :: proc(a, d: int) -> bool {
	return (a == 1 && d == 2) || (a == 2 && d == 3) || (a == 3 && d == 4) || (a == 4 && d == 1)
}

damage_multiplier :: proc(attacker_elem, defender_elem: int) -> int {
	if attacker_elem == 0 || defender_elem == 0 do return 100
	if is_strong(attacker_elem, defender_elem) do return 200
	if is_strong(defender_elem, attacker_elem) do return 50
	return 100
}

effective_damage :: proc(base_dmg, mult: int) -> int {
	raw := base_dmg * mult / 100
	return max(raw, 1)
}

zone_element :: proc(x, y: int) -> int {
	return ((x * 3 + y * 7) % 4) + 1
}

// --- Enchantment helpers ---
atk_for :: proc(slot: int) -> int {
	if slot == 1 do return 3       // Fire: +3 atk
	if slot == 4 do return 1       // Lightning: +1 atk
	return 0
}

def_for :: proc(slot: int) -> int {
	if slot == 2 do return 2       // Ice: +2 def
	if slot == 4 do return 1       // Lightning: +1 def
	return 0
}

// Enchants are sword-bound: a broken (or absent) sword zeroes enchant bonuses.
enchant_sword_ok :: proc(g: ^Game_State) -> bool {
	return g.has_sword && g.sword_dur > 0
}

enchant_atk_bonus :: proc(g: ^Game_State) -> int {
	if !enchant_sword_ok(g) do return 0
	return atk_for(g.enchant_slot_1) + atk_for(g.enchant_slot_2) + atk_for(g.enchant_slot_3)
}

enchant_def_bonus :: proc(g: ^Game_State) -> int {
	if !enchant_sword_ok(g) do return 0
	return def_for(g.enchant_slot_1) + def_for(g.enchant_slot_2) + def_for(g.enchant_slot_3)
}

has_fire_enchant :: proc(g: ^Game_State) -> bool {
	return g.enchant_slot_1 == 1 || g.enchant_slot_2 == 1 || g.enchant_slot_3 == 1
}

has_ice_enchant :: proc(g: ^Game_State) -> bool {
	return g.enchant_slot_1 == 2 || g.enchant_slot_2 == 2 || g.enchant_slot_3 == 2
}

player_element :: proc(g: ^Game_State) -> int {
	if has_fire_enchant(g) do return 1
	if has_ice_enchant(g) do return 2
	if g.enchant_slot_1 == 4 || g.enchant_slot_2 == 4 || g.enchant_slot_3 == 4 do return 3
	return 0
}

// --- Companion catalog ---
// Species is flavor; mechanics come from trait affinity + rarity.
// Adding a new companion = one row here, zero code changes elsewhere.

Comp_Trait :: enum { Attacker, Defender, Scout, Support }

Material_Kind :: enum { Wood, Iron, Venom_Sac }

Species_Def :: struct {
	name:           string,
	biome_x:        int,          // pos_x % 3 adoption biome (-1 = any)
	biome_y:        int,          // pos_y % 3 adoption biome (-1 = any)
	trait_affinity: Comp_Trait,
	material:       Material_Kind,
}

SPECIES_DEFS := [?]Species_Def{
	{ name = "Wolf",   biome_x =  1, biome_y =  0, trait_affinity = .Attacker, material = .Iron },
	{ name = "Hawk",   biome_x =  1, biome_y =  2, trait_affinity = .Scout,    material = .Venom_Sac },
	{ name = "Turtle", biome_x =  2, biome_y =  0, trait_affinity = .Defender, material = .Wood },
	{ name = "Fox",    biome_x =  0, biome_y =  1, trait_affinity = .Scout,    material = .Wood },
	{ name = "Bear",   biome_x =  2, biome_y =  2, trait_affinity = .Defender, material = .Iron },
	{ name = "Owl",    biome_x =  0, biome_y =  2, trait_affinity = .Support,  material = .Wood },
	{ name = "Lynx",   biome_x =  2, biome_y =  1, trait_affinity = .Attacker, material = .Wood },
	{ name = "Sprite", biome_x =  0, biome_y =  0, trait_affinity = .Support,  material = .Venom_Sac },
}

species_count :: proc() -> int { return len(SPECIES_DEFS) }

// Adoption cost scales with rarity: (rarity+1) * base
comp_adopt_cost :: proc(rarity: int) -> int {
	return (rarity + 1) * ADOPT_BASE_COST
}

// Derived effect table — any future tuning lives here
comp_atk_from :: proc(trait, rarity: int) -> int {
	scale := rarity + 1
	switch Comp_Trait(trait) {
	case .Attacker: return COMP_ATK_BASE_ATTACKER * scale
	case .Scout:    return COMP_ATK_BASE_SCOUT * scale
	case .Defender, .Support: return 0
	}
	return 0
}

comp_def_from :: proc(trait, rarity: int) -> int {
	scale := rarity + 1
	switch Comp_Trait(trait) {
	case .Defender: return COMP_DEF_BASE_DEFENDER * scale
	case .Support:  return COMP_DEF_BASE_SUPPORT * scale
	case .Attacker, .Scout: return 0
	}
	return 0
}

// Consume a material cost of the given kind from inventory; returns true if paid
consume_material :: proc(g: ^Game_State, kind: Material_Kind, cost: int) -> bool {
	switch kind {
	case .Wood:
		if g.qty_wood < cost do return false
		g.qty_wood -= cost
		return true
	case .Iron:
		if g.qty_iron < cost do return false
		g.qty_iron -= cost
		return true
	case .Venom_Sac:
		if g.qty_venom_sac < cost do return false
		g.qty_venom_sac -= cost
		return true
	}
	return false
}

species_def :: proc(idx: int) -> (Species_Def, bool) {
	if idx < 0 || idx >= len(SPECIES_DEFS) do return {}, false
	return SPECIES_DEFS[idx], true
}

comp_active :: proc(g: ^Game_State) -> bool {
	return g.comp_active && g.comp_loyalty >= LOW_LOYALTY
}

comp_atk_bonus :: proc(g: ^Game_State) -> int {
	if !comp_active(g) do return 0
	return comp_atk_from(g.comp_trait, g.comp_rarity)
}

comp_dmg_reduction :: proc(g: ^Game_State) -> int {
	if !comp_active(g) do return 0
	return comp_def_from(g.comp_trait, g.comp_rarity)
}

// Fortify grants a stronger DEF reduction than shield_block; disambiguated
// by buff duration (shield_block sets STATUS_DURATION=3, fortify sets
// FORTIFY_DURATION=8, so any duration > STATUS_DURATION implies fortify).
def_reduction_active :: proc(g: ^Game_State) -> int {
	if g.player_def_buff_dur > STATUS_DURATION do return FORTIFY_DEF_REDUCTION
	if g.player_def_buff_dur > 0 do return DEF_BUFF_REDUCTION
	return 0
}

attack_power :: proc(g: ^Game_State) -> int {
	sword_bonus := SWORD_ATK_BONUS if (g.has_sword && g.sword_dur > 0) else 0
	atk_buff := ATK_BUFF_BONUS if g.player_atk_buff_dur > 0 else 0
	// Fog cuts the player's visibility as much as the enemy's — offense takes a hit too.
	fog_penalty := FOG_ATK_PENALTY if zone_weather(g.pos_x, g.pos_y, g.turn_count) == 2 else 0
	raw := g.base_attack + sword_bonus + atk_buff + enchant_atk_bonus(g) + comp_atk_bonus(g) - fog_penalty
	return max(raw, 1)
}

total_items :: proc(g: ^Game_State) -> int {
	return g.qty_potion + g.qty_wood + g.qty_iron + g.qty_sword + g.qty_venom_sac + g.qty_battery +
		g.qty_scroll_fire +
		g.qty_holy_dust + g.qty_holy_water + g.qty_pelt + g.qty_core + g.qty_essence + g.qty_coin + g.qty_ichor
}

salvage_wood_yield :: proc(slvl: int) -> int {
	return SALVAGE_WOOD_BASE + (slvl - 1)
}

salvage_iron_yield :: proc(slvl: int) -> int {
	return SALVAGE_IRON_BASE + (slvl - 1)
}

init_game :: proc(g: ^Game_State) {
	g.hp = INITIAL_HP
	g.max_hp = INITIAL_HP
	g.base_attack = INITIAL_ATTACK
	g.xp = 0
	g.level = 1
	g.gold = 0
	g.pos_x = 0
	g.pos_y = 0
	g.qty_potion = INITIAL_POTIONS
	g.qty_wood = 0
	g.qty_iron = 0
	g.qty_sword = 0
	g.has_sword = false
	g.sword_dur = 0
	g.sword_max_dur = SWORD_MAX_DUR
	g.weapon_type = 0
	g.trinket = 0
	g.has_shield = false
	g.shield_dur = 0
	g.has_armor = false
	g.armor_dur = 0
	g.in_combat = false
	g.enemy_hp = 0
	g.enemy_attack = 0
	g.game_won = false
	g.player_poison_dur = 0
	g.player_atk_buff_dur = 0
	g.player_def_buff_dur = 0
	g.enemy_poison_dur = 0
	g.combo_count = 0

	g.turn_count = 0
	g.saved_exists = false
	g.stamina = INITIAL_STAMINA
	g.max_stamina = INITIAL_STAMINA
	g.skill_magic = false
	g.mana = 0
	g.max_mana = 0
	g.cd_heavy_strike = 0
	g.cd_battle_cry = 0
	g.pity_counter = 0
	g.last_drop = 0
	g.cd_fortify = 0
	g.skill_points = 0
	g.skill_combo = false
	g.skill_poison = false
	g.skill_shield_block = false
	g.skill_heavy_strike = false
	g.skill_counter_attack = false
	g.skill_battle_cry = false
	g.skill_fortify = false
	g.respec_count = 0
	g.qty_venom_sac = 0
	g.qty_battery = 0
	g.qty_scroll_fire = 0
	g.qty_holy_dust = 0
	g.qty_holy_water = 0
	g.qty_pelt = 0
	g.qty_core = 0
	g.qty_essence = 0
	g.qty_coin = 0
	g.qty_ichor = 0
	g.enemy_trait = .Aberration
	g.enemy_element = 0
	g.enchant_slot_1 = 0
	g.enchant_slot_2 = 0
	g.enchant_slot_3 = 0
	g.salvage_level = 1
	g.last_kill_turn = 0
	g.q1_kills = 0
	g.q2_zones = 0
	g.q3_kills = 0
	g.comp_active = false
	g.comp_species = -1
	g.comp_trait = 0
	g.comp_rarity = 0
	g.comp_loyalty = 0
	g.comp_command_used = false
	g.cq1_adopted = 0
	g.cq2_maxed = 0
	g.cq3_wins = 0
	g.quest_rewards_claimed = 0
	g.boss_defeated = false
	// Fog of war: clear all, mark starting zone + neighbors as revealed
	for x in 0 ..< WORLD_SIZE {
		for y in 0 ..< WORLD_SIZE {
			g.visited[x][y] = false
			g.waypoints[x][y] = false
		}
	}
	g.visited[0][0] = true
	g.waypoints[0][0] = true  // starting village is a waypoint
	update_revealed(g)
}


