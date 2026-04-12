package quint_crawl

// Zone names by biome (indexed as [x%3][y%3])
ZONE_NAMES := [3][3]string{
	{"Village", "Plains", "Ruins"},
	{"Forest", "Cave", "Shrine"},
	{"Swamp", "Mountain", "Castle"},
}

XP_THRESHOLDS := [MAX_LEVEL + 1]int{0, 0, 15, 45, 90, 150}   // index by level

// --- World scaling constants ---
WORLD_SIZE :: 9        // grid dimension (NxN)
MAX_LEVEL :: 5         // max zone difficulty
TILES_PER_LEVEL :: 3   // (x+y) distance per level increment
BASE_ENEMY_HP :: 20    // enemy HP at level 1
BASE_ENEMY_ATK :: 2    // enemy ATK constant term
ATK_PER_LEVEL :: 4     // enemy ATK per level
BASE_XP :: 5           // XP reward per level
BASE_GOLD :: 3         // gold reward constant term
GOLD_PER_LEVEL :: 3    // gold reward per level

SWORD_MAX_DUR :: 10
REPAIR_COST :: 5
POISON_DMG :: 7
ATK_BUFF_BONUS :: 8
DEF_BUFF_REDUCTION :: 3
FORTIFY_DEF_REDUCTION :: 5
STATUS_DURATION :: 3
WEATHER_CYCLE :: 5
STORM_MOVE_DMG :: 2
FOG_ATK_PENALTY :: 2
RAIN_GATHER_BONUS :: 1
ATTACK_STAMINA :: 2
COMBO_STAMINA :: 3
HEAVY_STRIKE_STAMINA :: 5
BATTLE_CRY_STAMINA :: 3
HEAVY_STRIKE_CD :: 3
BATTLE_CRY_CD :: 4
PITY_THRESHOLD :: 8
// Quest targets
Q1_TARGET :: 2  // slime kills
Q2_TARGET :: 3  // ZL2+ zone entries after Q1 complete
Q3_TARGET :: 2  // dragon kills
// Companion quest targets
CQ1_TARGET :: 1
CQ2_TARGET :: 1
CQ3_TARGET :: 5
// Companion constants
MAX_LOYALTY :: 100
INITIAL_LOYALTY :: 50
LOYALTY_GAIN :: 10
LOYALTY_COMBAT_COST :: 5
HIGH_LOYALTY :: 75
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
STAMINA_PER_LEVEL :: 3
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
CRAFT_LEVEL_REQ :: 2
SALVAGE_WOOD_BASE :: 0
SALVAGE_IRON_BASE :: 1
UPGRADE_SALVAGE_COST :: 15
MAX_SALVAGE_LEVEL :: 3
RESPAWN_TURNS :: 5

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
	qty_holy_dust: int,
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
	// Trait-keyed archetype loot (Odin-only, not in MBT spec contract).
	// All six fields are invisible to the getter so the spec contract
	// stays untouched. Humanoid and Aberration intentionally do NOT reuse
	// gold / qty_venom_sac because those are spec-tracked.
	qty_holy_dust:       int,  // Undead
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
	return g.comp_active && g.comp_loyalty > 0
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
	return g.base_attack + sword_bonus + atk_buff + enchant_atk_bonus(g) + comp_atk_bonus(g)
}

total_items :: proc(g: ^Game_State) -> int {
	return g.qty_potion + g.qty_wood + g.qty_iron + g.qty_sword + g.qty_venom_sac +
		g.qty_holy_dust + g.qty_pelt + g.qty_core + g.qty_essence + g.qty_coin + g.qty_ichor
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
	g.qty_holy_dust = 0
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

// Fog of war: a zone is revealed if visited or orthogonally adjacent to a visited zone
is_revealed :: proc(g: ^Game_State, x, y: int) -> bool {
	if x < 0 || x >= WORLD_SIZE || y < 0 || y >= WORLD_SIZE do return false
	if g.visited[x][y] do return true
	if x > 0 && g.visited[x - 1][y] do return true
	if x < WORLD_SIZE - 1 && g.visited[x + 1][y] do return true
	if y > 0 && g.visited[x][y - 1] do return true
	if y < WORLD_SIZE - 1 && g.visited[x][y + 1] do return true
	return false
}

// Update revealed state (call after any move)
update_revealed :: proc(g: ^Game_State) {
	// revealed is derived from visited — no separate storage needed
	// We use is_revealed() as a pure function instead
}

// Fast travel to a waypoint
fast_travel :: proc(g: ^Game_State, tx, ty: int) -> bool {
	if !can_act_map(g) do return false
	if tx < 0 || tx >= WORLD_SIZE || ty < 0 || ty >= WORLD_SIZE do return false
	if !g.waypoints[tx][ty] do return false
	if tx == g.pos_x && ty == g.pos_y do return false  // already there
	if zone_level(tx, ty) > g.level do return false
	g.pos_x = tx
	g.pos_y = ty
	g.turn_count += 1
	g.visited[tx][ty] = true
	// Quest 2: count ZL2+ zone entries after Q1 complete
	if g.q1_kills >= Q1_TARGET && zone_level(tx, ty) >= 2 && g.q2_zones < Q2_TARGET {
		g.q2_zones += 1
	}
	return true
}

move :: proc(g: ^Game_State, dx, dy: int) -> bool {
	nx, ny := g.pos_x + dx, g.pos_y + dy
	if nx < 0 || nx >= WORLD_SIZE || ny < 0 || ny >= WORLD_SIZE do return false
	if !can_act_map(g) do return false
	if zone_level(nx, ny) > g.level do return false
	g.pos_x = nx
	g.pos_y = ny
	g.turn_count += 1
	// Mark visited + unlock waypoint at villages
	g.visited[nx][ny] = true
	if zone_has_services(nx, ny) {
		g.waypoints[nx][ny] = true
	}
	// Quest 2: count ZL2+ zone entries after Q1 complete
	if g.q1_kills >= Q1_TARGET && zone_level(nx, ny) >= 2 && g.q2_zones < Q2_TARGET {
		g.q2_zones += 1
	}
	// Storm damage (can't kill — floor at 1)
	if zone_weather(nx, ny, g.turn_count) == 3 {
		g.hp = max(g.hp - STORM_MOVE_DMG, 1)
	}
	return true
}

enter_combat :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.last_kill_turn != 0 && g.turn_count - g.last_kill_turn < RESPAWN_TURNS do return false
	g.turn_count += 1
	g.in_combat = true
	g.enemy_hp = zone_enemy_hp(g.pos_x, g.pos_y)
	// Fog reduces enemy attack
	weather := zone_weather(g.pos_x, g.pos_y, g.turn_count)
	fog_penalty := FOG_ATK_PENALTY if weather == 2 else 0
	raw_atk := zone_enemy_atk(g.pos_x, g.pos_y) - fog_penalty
	g.enemy_attack = max(raw_atk, 1)
	g.combo_count = 0

	g.cd_heavy_strike = 0
	g.cd_battle_cry = 0
	g.cd_fortify = 0
	g.last_drop = 0
	g.enemy_element = zone_element(g.pos_x, g.pos_y)
	// Companion loyalty tick: pays to be brought into combat
	if g.comp_active {
		g.comp_loyalty -= LOYALTY_COMBAT_COST
		if g.comp_loyalty <= 0 {
			g.comp_active = false
			g.comp_species = -1
			g.comp_trait = 0
			g.comp_rarity = 0
			g.comp_loyalty = 0
		}
		g.comp_command_used = false
	}
	return true
}

// Tick cooldowns (decrement by 1, min 0). Call on full combat turns.
tick_cooldowns :: proc(g: ^Game_State) {
	if g.cd_heavy_strike > 0 do g.cd_heavy_strike -= 1
	if g.cd_battle_cry > 0 do g.cd_battle_cry -= 1
	if g.cd_fortify > 0 do g.cd_fortify -= 1
}

// Reset cooldowns when leaving combat
reset_cooldowns :: proc(g: ^Game_State) {
	g.cd_heavy_strike = 0
	g.cd_battle_cry = 0
	g.cd_fortify = 0
}

// Resolve loot drop on enemy defeat. Uses pre-increment turn for determinism (matches spec).
// Primary drop follows the zone-tier table (potion / venom sac). A secondary
// trait-keyed drop fires on ~25% of kills, flavored by the archetype trait
// cached on g.enemy_trait (set in input.enter_combat). The trait drop is
// Odin-only — no spec fields are touched — so the MBT contract is preserved.
resolve_loot :: proc(g: ^Game_State) {
	// turn_count was already incremented before resolve_combat_hit, so use -1 to match spec
	pre_turn := g.turn_count - 1
	should_drop := (g.pity_counter >= PITY_THRESHOLD || (pre_turn % LOOT_DROP_MODULO == 0)) && total_items(g) < MAX_INVENTORY
	if should_drop {
		zlvl := zone_level(g.pos_x, g.pos_y)
		if zlvl >= POISON_APPLY_TIER {
			g.qty_venom_sac += 1
			g.last_drop = 2
		} else {
			g.qty_potion += 1
			g.last_drop = 1
		}
		g.pity_counter = 0
	} else {
		g.pity_counter += 1
		g.last_drop = 0
	}

	// Trait-keyed secondary drop (~25%). Deterministic hash of position +
	// turn, same style used elsewhere in the catalog. Aberration reuses the
	// existing venom sac field; Humanoid bleeds out as bonus gold.
	h := enemy_hash3(g.pos_x, g.pos_y, pre_turn + 911)
	if h % 4 == 0 {
		switch g.enemy_trait {
		case .Undead:
			g.qty_holy_dust += 1
		case .Beast:
			g.qty_pelt += 1
		case .Construct:
			g.qty_core += 1
		case .Elemental:
			g.qty_essence += 1
		case .Humanoid:
			g.qty_coin += 1
		case .Aberration:
			g.qty_ichor += 1
		}
	}
}

// Shared combat hit resolution: applies damage, ticks statuses, resolves combat end.
// Returns true if combat ended.
resolve_combat_hit :: proc(g: ^Game_State, dmg: int) -> bool {
	// Capture pre-state enchant-derived values before any sword-break zeroing.
	pre_elem_mult := damage_multiplier(player_element(g), g.enemy_element)
	pre_enchant_def := enchant_def_bonus(g)
	// Degrade sword on attack. If it breaks (dur hits 0), lose enchants.
	if g.has_sword && g.sword_dur > 0 {
		g.sword_dur -= 1
		if g.sword_dur == 0 {
			g.enchant_slot_1 = 0
			g.enchant_slot_2 = 0
			g.enchant_slot_3 = 0
		}
	}
	// Enemy takes elemental-modified hit + poison damage
	enemy_poison_dmg := POISON_DMG if g.enemy_poison_dur > 0 else 0
	elem_dmg := effective_damage(dmg, pre_elem_mult)
	new_enemy_hp := g.enemy_hp - elem_dmg - enemy_poison_dmg

	// Player takes enemy hit (reduced by enchant DEF + DEF buff) + poison damage
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	new_hp := g.hp - poison_dmg
	if new_enemy_hp > 0 {
		enemy_dmg := g.enemy_attack - pre_enchant_def - def_reduction_active(g) - comp_dmg_reduction(g)
		if enemy_dmg < 1 do enemy_dmg = 1
		new_hp -= enemy_dmg
	}
	g.enemy_hp = max(new_enemy_hp, 0)
	g.hp = max(new_hp, 0)

	combat_ends := (new_enemy_hp <= 0 || g.hp <= 0)

	// Tick status durations
	if combat_ends {
		g.player_poison_dur = 0
		g.player_atk_buff_dur = 0
		g.player_def_buff_dur = 0
		g.enemy_poison_dur = 0
		reset_cooldowns(g)
	} else {
		zlvl := zone_level(g.pos_x, g.pos_y)
		if zlvl >= POISON_APPLY_TIER && g.player_poison_dur == 0 {
			g.player_poison_dur = STATUS_DURATION
		} else if g.player_poison_dur > 0 {
			g.player_poison_dur -= 1
		}
		if g.player_atk_buff_dur > 0 do g.player_atk_buff_dur -= 1
		if g.player_def_buff_dur > 0 do g.player_def_buff_dur -= 1
		if g.enemy_poison_dur > 0 do g.enemy_poison_dur -= 1
		tick_cooldowns(g)
	}

	// Enemy defeated — gold is granted even on mutual kill (matches spec)
	if new_enemy_hp <= 0 {
		g.gold += zone_gold_reward(g.pos_x, g.pos_y)
	}

	// Player died — end combat (no XP, no loot, no level-up)
	if g.hp <= 0 {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		g.enemy_element = 0
		return true
	}

	if new_enemy_hp <= 0 {
		// Enemy defeated, player alive — XP, loot, level-up, respawn timer
		g.last_kill_turn = g.turn_count - 1
		g.xp += zone_xp_reward(g.pos_x, g.pos_y)
		// Quest 1 / 3: count slime / dragon kills
		zone_tier := zone_level(g.pos_x, g.pos_y)
		if zone_tier == 1 && g.q1_kills < Q1_TARGET do g.q1_kills += 1
		if zone_tier == MAX_LEVEL && g.q3_kills < Q3_TARGET do g.q3_kills += 1
		// Companion Quest 3: count wins with active companion
		if comp_active(g) && g.cq3_wins < CQ3_TARGET do g.cq3_wins += 1
		g.in_combat = false
		g.enemy_attack = 0
		g.enemy_element = 0
		resolve_loot(g)
		if g.level < MAX_LEVEL && g.xp >= XP_THRESHOLDS[g.level + 1] {
			g.level += 1
			g.max_hp += HP_PER_LEVEL
			g.base_attack += ATK_PER_LEVEL_UP
			g.max_stamina += STAMINA_PER_LEVEL
			g.skill_points += SKILL_POINTS_PER_LEVEL
		}
	}
	return combat_ends
}

combat_attack :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if g.stamina < ATTACK_STAMINA do return false
	g.turn_count += 1
	g.stamina -= ATTACK_STAMINA
	combat_ends := resolve_combat_hit(g, attack_power(g))
	// Plain attack preserves combo (spec: combo_count' = combo_count)
	if combat_ends {
		g.combo_count = 0
	
	}
	return true
}

combat_potion :: proc(g: ^Game_State) -> bool {
	if !g.in_combat || g.game_won || g.qty_potion <= 0 || g.hp <= 0 do return false
	g.turn_count += 1
	g.hp = min(g.hp + POTION_HEAL, g.max_hp)
	g.qty_potion -= 1
	g.combo_count = 0

	// Quick action: no stamina cost, no CD tick
	return true
}

flee_combat :: proc(g: ^Game_State) -> bool {
	if !g.in_combat || g.game_won || g.hp <= 0 do return false
	g.turn_count += 1
	flee_dmg := g.enemy_attack - enchant_def_bonus(g)
	if flee_dmg < 1 do flee_dmg = 1
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	// Flee should not kill — clamp HP to 1 minimum so escape hatch remains.
	new_hp := g.hp - flee_dmg - poison_dmg
	if new_hp < 1 do new_hp = 1
	g.hp = new_hp
	g.in_combat = false
	g.enemy_hp = 0
	g.enemy_attack = 0
	g.enemy_element = 0
	g.player_poison_dur = 0
	g.player_atk_buff_dur = 0
	g.player_def_buff_dur = 0
	g.enemy_poison_dur = 0
	g.combo_count = 0

	reset_cooldowns(g)
	return true
}

rest_at_village :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if g.hp >= g.max_hp && g.stamina >= g.max_stamina do return false
	g.turn_count += 1
	g.hp = g.max_hp
	g.stamina = g.max_stamina
	if g.comp_active {
		g.comp_loyalty = min(g.comp_loyalty + LOYALTY_GAIN, MAX_LOYALTY)
		if g.comp_loyalty == MAX_LOYALTY && g.cq2_maxed < CQ2_TARGET do g.cq2_maxed += 1
	}
	return true
}

buy_potion :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if g.gold < POTION_COST do return false
	if total_items(g) >= MAX_INVENTORY do return false
	g.turn_count += 1
	g.gold -= POTION_COST
	g.qty_potion += 1
	return true
}

gather_wood :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_wood(g.pos_x, g.pos_y) do return false
	rain_bonus := RAIN_GATHER_BONUS if zone_weather(g.pos_x, g.pos_y, g.turn_count + 1) == 1 else 0
	if total_items(g) + 1 + rain_bonus > MAX_INVENTORY do return false
	g.turn_count += 1
	g.qty_wood += 1 + rain_bonus
	return true
}

mine_iron :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_iron(g.pos_x, g.pos_y) do return false
	rain_bonus := RAIN_GATHER_BONUS if zone_weather(g.pos_x, g.pos_y, g.turn_count + 1) == 1 else 0
	if total_items(g) + 1 + rain_bonus > MAX_INVENTORY do return false
	g.turn_count += 1
	g.qty_iron += 1 + rain_bonus
	return true
}

craft_sword :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if g.level < CRAFT_LEVEL_REQ do return false
	if g.qty_wood < CRAFT_WOOD_COST || g.qty_iron < CRAFT_IRON_COST do return false
	g.turn_count += 1
	g.qty_wood -= CRAFT_WOOD_COST
	g.qty_iron -= CRAFT_IRON_COST
	g.qty_sword += 1
	return true
}

equip_sword :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.qty_sword < 1 || g.has_sword do return false
	g.turn_count += 1
	g.has_sword = true
	g.qty_sword -= 1
	g.sword_dur = SWORD_MAX_DUR
	g.enchant_slot_1 = 0
	g.enchant_slot_2 = 0
	g.enchant_slot_3 = 0
	return true
}

repair_sword :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if !g.has_sword do return false
	if g.sword_dur >= g.sword_max_dur do return false
	if g.gold < REPAIR_COST do return false
	g.turn_count += 1
	g.sword_dur = g.sword_max_dur
	g.gold -= REPAIR_COST
	return true
}

claim_victory :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.level < MAX_LEVEL do return false
	// Must be on a Castle biome (x%3==2, y%3==2) at zone level >= MAX_LEVEL
	if g.pos_x % 3 != 2 || g.pos_y % 3 != 2 do return false
	if zone_level(g.pos_x, g.pos_y) < MAX_LEVEL do return false
	g.game_won = true
	return true
}

use_antidote :: proc(g: ^Game_State) -> bool {
	if !g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.qty_potion <= 0 || g.player_poison_dur <= 0 do return false
	g.turn_count += 1
	g.qty_potion -= 1
	g.player_poison_dur = 0
	g.combo_count = 0

	// Quick action: no stamina cost, no CD tick
	return true
}

poison_strike :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !g.skill_poison do return false
	if g.qty_venom_sac <= 0 do return false
	if g.stamina < ATTACK_STAMINA do return false
	g.turn_count += 1
	g.stamina -= ATTACK_STAMINA
	g.qty_venom_sac -= 1
	// Enemy hits back (reduced by enchant DEF + DEF buff)
	enemy_dmg := g.enemy_attack - enchant_def_bonus(g) - def_reduction_active(g)
	if enemy_dmg < 1 do enemy_dmg = 1
	g.hp = max(g.hp - enemy_dmg, 0)
	if g.hp <= 0 {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		g.enemy_element = 0
		g.player_poison_dur = 0
		g.player_atk_buff_dur = 0
		g.player_def_buff_dur = 0
		g.enemy_poison_dur = 0
		reset_cooldowns(g)
	} else {
		// Refresh (not overwrite): allows re-cast on already-poisoned enemy.
		if g.enemy_poison_dur < STATUS_DURATION do g.enemy_poison_dur = STATUS_DURATION
		tick_cooldowns(g)
	}
	g.combo_count = 0

	return true
}

combo_attack :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !g.skill_combo do return false
	if g.combo_count >= MAX_COMBO_CHAIN do return false
	if g.stamina < COMBO_STAMINA do return false
	g.turn_count += 1
	g.stamina -= COMBO_STAMINA

	next_combo := g.combo_count + 1
	base_dmg := attack_power(g)
	combo_dmg: int
	switch next_combo {
	case 1:
		combo_dmg = base_dmg
	case 2:
		combo_dmg = (base_dmg * 3) / 2
	case:
		combo_dmg = base_dmg * 2
	}

	combat_ends := resolve_combat_hit(g, combo_dmg)

	// Combo state: reset on combat end or chain complete, else advance
	if combat_ends || next_combo >= MAX_COMBO_CHAIN {
		g.combo_count = 0
	
	} else {
		g.combo_count = next_combo
	}
	return true
}

heavy_strike :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !g.skill_heavy_strike do return false
	if g.cd_heavy_strike != 0 do return false
	if g.stamina < HEAVY_STRIKE_STAMINA do return false
	g.turn_count += 1
	g.stamina -= HEAVY_STRIKE_STAMINA

	heavy_dmg := attack_power(g) * 2

	// Set CD before resolve (resolve_combat_hit ticks CDs, but we set after)
	// Actually, resolve_combat_hit ticks CDs. We need to set AFTER tick.
	// But resolve resets CDs on combat end. So handle like spec:
	// - resolve_combat_hit handles normal ticking
	// - we override cd_heavy_strike after

	combat_ends := resolve_combat_hit(g, heavy_dmg)

	// Override CD: resolve already ticked/reset it, but we want to SET it
	if !combat_ends {
		g.cd_heavy_strike = HEAVY_STRIKE_CD
	}
	// Heavy strike breaks combo
	g.combo_count = 0

	return true
}

battle_cry :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !g.skill_battle_cry do return false
	if g.cd_battle_cry != 0 do return false
	if g.stamina < BATTLE_CRY_STAMINA do return false
	g.turn_count += 1
	g.stamina -= BATTLE_CRY_STAMINA

	// Battle cry is a pure setup move — enemy does NOT retaliate (only poison ticks).
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	g.hp = max(g.hp - poison_dmg, 0)

	combat_ends := (g.hp <= 0)

	if combat_ends {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		g.enemy_element = 0
		g.player_poison_dur = 0
		g.player_atk_buff_dur = 0
		g.player_def_buff_dur = 0
		g.enemy_poison_dur = 0
		reset_cooldowns(g)
	} else {
		// Grant ATK buff
		g.player_atk_buff_dur = STATUS_DURATION
		// Tick statuses
		zone_tier := zone_level(g.pos_x, g.pos_y)
		if zone_tier >= POISON_APPLY_TIER && g.player_poison_dur == 0 {
			g.player_poison_dur = STATUS_DURATION
		} else if g.player_poison_dur > 0 {
			g.player_poison_dur -= 1
		}
		if g.player_def_buff_dur > 0 do g.player_def_buff_dur -= 1
		if g.enemy_poison_dur > 0 do g.enemy_poison_dur -= 1
		// Tick CDs, then set battle_cry CD
		tick_cooldowns(g)
		g.cd_battle_cry = BATTLE_CRY_CD
	}
	g.combo_count = 0

	return true
}

shield_block :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !g.skill_shield_block do return false
	if g.stamina < SHIELD_BLOCK_STAMINA do return false
	g.turn_count += 1
	g.stamina -= SHIELD_BLOCK_STAMINA

	// Enemy hits back (reduced by enchant DEF + DEF buff)
	enemy_dmg := g.enemy_attack - enchant_def_bonus(g) - def_reduction_active(g)
	if enemy_dmg < 1 do enemy_dmg = 1
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	g.hp = max(g.hp - enemy_dmg - poison_dmg, 0)

	combat_ends := (g.hp <= 0)

	if combat_ends {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		g.enemy_element = 0
		g.player_poison_dur = 0
		g.player_atk_buff_dur = 0
		g.player_def_buff_dur = 0
		g.enemy_poison_dur = 0
		reset_cooldowns(g)
	} else {
		// Grant DEF buff
		g.player_def_buff_dur = STATUS_DURATION
		// Tick statuses
		zone_tier := zone_level(g.pos_x, g.pos_y)
		if zone_tier >= POISON_APPLY_TIER && g.player_poison_dur == 0 {
			g.player_poison_dur = STATUS_DURATION
		} else if g.player_poison_dur > 0 {
			g.player_poison_dur -= 1
		}
		if g.player_atk_buff_dur > 0 do g.player_atk_buff_dur -= 1
		if g.enemy_poison_dur > 0 do g.enemy_poison_dur -= 1
		tick_cooldowns(g)
	}
	g.combo_count = 0

	return true
}

// --- Skill unlock procs ---

unlock_combo :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.skill_combo do return false
	if g.skill_points < 1 do return false
	g.turn_count += 1
	g.skill_combo = true
	g.skill_points -= 1
	return true
}

unlock_poison :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.skill_poison do return false
	if g.skill_points < 1 do return false
	g.turn_count += 1
	g.skill_poison = true
	g.skill_points -= 1
	return true
}

unlock_shield_block :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.skill_shield_block do return false
	if g.skill_points < 1 do return false
	g.turn_count += 1
	g.skill_shield_block = true
	g.skill_points -= 1
	return true
}

unlock_heavy_strike :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.skill_heavy_strike do return false
	if !g.skill_combo do return false  // prereq
	if g.skill_points < 1 do return false
	g.turn_count += 1
	g.skill_heavy_strike = true
	g.skill_points -= 1
	return true
}

unlock_counter_attack :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.skill_counter_attack do return false
	if !g.skill_shield_block do return false  // prereq
	if g.skill_points < 1 do return false
	g.turn_count += 1
	g.skill_counter_attack = true
	g.skill_points -= 1
	return true
}

unlock_battle_cry :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.skill_battle_cry do return false
	if !g.skill_heavy_strike do return false  // prereq
	if g.skill_points < 2 do return false
	g.turn_count += 1
	g.skill_battle_cry = true
	g.skill_points -= 2
	return true
}

unlock_fortify :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.skill_fortify do return false
	if !g.skill_counter_attack do return false  // prereq
	if g.skill_points < 2 do return false
	g.turn_count += 1
	g.skill_fortify = true
	g.skill_points -= 2
	return true
}

// Escalating respec cost: RESPEC_BASE_COST * (respec_count + 1)
respec_cost :: proc(g: ^Game_State) -> int {
	return RESPEC_BASE_COST * (g.respec_count + 1)
}

respec :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	cost := respec_cost(g)
	if g.gold < cost do return false
	spent := 0
	if g.skill_combo do spent += 1
	if g.skill_poison do spent += 1
	if g.skill_shield_block do spent += 1
	if g.skill_heavy_strike do spent += 1
	if g.skill_counter_attack do spent += 1
	if g.skill_battle_cry do spent += 2
	if g.skill_fortify do spent += 2
	if spent == 0 do return false
	g.turn_count += 1
	g.gold -= cost
	g.skill_points += spent
	g.skill_combo = false
	g.skill_poison = false
	g.skill_shield_block = false
	g.skill_heavy_strike = false
	g.skill_counter_attack = false
	g.skill_battle_cry = false
	g.skill_fortify = false
	g.respec_count += 1
	return true
}

counter_attack :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !g.skill_counter_attack do return false
	if g.stamina < COUNTER_STAMINA do return false
	g.turn_count += 1
	g.stamina -= COUNTER_STAMINA

	// Counter-attack is a retaliatory strike — deals HALF attack power (min 1).
	// Compute elemental multiplier BEFORE sword break, matching spec's pre-state read.
	dmg := attack_power(g) / 2
	if dmg < 1 do dmg = 1
	elem_mult := damage_multiplier(player_element(g), g.enemy_element)
	pre_enchant_def := enchant_def_bonus(g)
	if g.has_sword && g.sword_dur > 0 {
		g.sword_dur -= 1
		if g.sword_dur == 0 {
			g.enchant_slot_1 = 0
			g.enchant_slot_2 = 0
			g.enchant_slot_3 = 0
		}
	}

	// Enemy takes elemental-modified hit + poison
	enemy_poison_dmg := POISON_DMG if g.enemy_poison_dur > 0 else 0
	elem_dmg := effective_damage(dmg, elem_mult)
	new_enemy_hp := g.enemy_hp - elem_dmg - enemy_poison_dmg
	g.enemy_hp = max(new_enemy_hp, 0)

	// Enemy hits player (reduced by enchant DEF + DEF buff)
	enemy_dmg := g.enemy_attack - pre_enchant_def - def_reduction_active(g)
	if enemy_dmg < 1 do enemy_dmg = 1
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	g.hp = max(g.hp - enemy_dmg - poison_dmg, 0)

	combat_ends := (g.hp <= 0 || g.enemy_hp <= 0)

	if combat_ends {
		// Gold on enemy kill (even mutual)
		if new_enemy_hp <= 0 {
			g.gold += zone_gold_reward(g.pos_x, g.pos_y)
		}
		if g.hp <= 0 {
			g.in_combat = false
			g.enemy_hp = 0
			g.enemy_attack = 0
			g.enemy_element = 0
			g.player_poison_dur = 0
			g.player_atk_buff_dur = 0
			g.player_def_buff_dur = 0
			g.enemy_poison_dur = 0
			reset_cooldowns(g)
		} else {
			// Enemy defeated, player alive
			g.last_kill_turn = g.turn_count - 1
			g.xp += zone_xp_reward(g.pos_x, g.pos_y)
			g.in_combat = false
			g.enemy_attack = 0
			g.enemy_element = 0
			g.player_poison_dur = 0
			g.player_atk_buff_dur = 0
			g.player_def_buff_dur = 0
			g.enemy_poison_dur = 0
			reset_cooldowns(g)
			resolve_loot(g)
			if g.level < MAX_LEVEL && g.xp >= XP_THRESHOLDS[g.level + 1] {
				g.level += 1
				g.max_hp += HP_PER_LEVEL
				g.base_attack += ATK_PER_LEVEL_UP
				g.max_stamina += STAMINA_PER_LEVEL
				g.skill_points += SKILL_POINTS_PER_LEVEL
			}
		}
	} else {
		// Grant DEF buff on counter
		g.player_def_buff_dur = STATUS_DURATION
		// Tick statuses
		zone_tier := zone_level(g.pos_x, g.pos_y)
		if zone_tier >= POISON_APPLY_TIER && g.player_poison_dur == 0 {
			g.player_poison_dur = STATUS_DURATION
		} else if g.player_poison_dur > 0 {
			g.player_poison_dur -= 1
		}
		if g.player_atk_buff_dur > 0 do g.player_atk_buff_dur -= 1
		if g.enemy_poison_dur > 0 do g.enemy_poison_dur -= 1
		tick_cooldowns(g)
	}
	g.combo_count = 0
	return true
}

fortify :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !g.skill_fortify do return false
	if g.cd_fortify != 0 do return false
	if g.stamina < FORTIFY_STAMINA do return false
	g.turn_count += 1
	g.stamina -= FORTIFY_STAMINA

	// Enemy hits back (reduced by enchant DEF + DEF buff)
	enemy_dmg := g.enemy_attack - enchant_def_bonus(g) - def_reduction_active(g)
	if enemy_dmg < 1 do enemy_dmg = 1
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	g.hp = max(g.hp - enemy_dmg - poison_dmg, 0)

	combat_ends := (g.hp <= 0)

	if combat_ends {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		g.enemy_element = 0
		g.player_poison_dur = 0
		g.player_atk_buff_dur = 0
		g.player_def_buff_dur = 0
		g.enemy_poison_dur = 0
		reset_cooldowns(g)
	} else {
		// Grant extended DEF buff
		g.player_def_buff_dur = FORTIFY_DURATION
		// Tick statuses
		zone_tier := zone_level(g.pos_x, g.pos_y)
		if zone_tier >= POISON_APPLY_TIER && g.player_poison_dur == 0 {
			g.player_poison_dur = STATUS_DURATION
		} else if g.player_poison_dur > 0 {
			g.player_poison_dur -= 1
		}
		if g.player_atk_buff_dur > 0 do g.player_atk_buff_dur -= 1
		if g.enemy_poison_dur > 0 do g.enemy_poison_dur -= 1
		tick_cooldowns(g)
		g.cd_fortify = FORTIFY_CD
	}
	g.combo_count = 0
	return true
}

craft_venom_sac :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if g.qty_iron < CRAFT_VENOM_IRON_COST do return false
	g.turn_count += 1
	g.qty_iron -= CRAFT_VENOM_IRON_COST
	g.qty_venom_sac += 1
	return true
}

// --- Companion procs ---
//
// Adoption is data-driven: pass a species catalog index + rarity.
// Biome gate and material cost are looked up from SPECIES_DEFS.
// The companion's trait is derived from the species's affinity; no branching
// on species elsewhere in the code — everything reads trait+rarity.

// Abstract adoption — mirrors the spec's adopt_companion exactly.
// Used by MBT harness and (optionally) by the game when species flavor
// is not relevant. Services-zone gate + wood cost scaling with rarity.
// The passed trait is recorded directly; species is left unset (-1).
adopt_companion_abstract :: proc(g: ^Game_State, trait, rarity: int) -> bool {
	if !can_act_map(g) do return false
	if g.comp_active do return false
	if trait < 0 || trait >= COMP_TRAIT_COUNT do return false
	if rarity < 0 || rarity >= COMP_RARITY_COUNT do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	cost := comp_adopt_cost(rarity)
	if g.qty_wood < cost do return false
	g.qty_wood -= cost
	g.comp_active = true
	g.comp_species = -1
	g.comp_trait = trait
	g.comp_rarity = rarity
	g.comp_loyalty = INITIAL_LOYALTY
	g.comp_command_used = false
	if g.cq1_adopted < CQ1_TARGET do g.cq1_adopted += 1
	return true
}

adopt_companion :: proc(g: ^Game_State, species_idx: int, rarity: int) -> bool {
	if !can_act_map(g) do return false
	if g.comp_active do return false
	if rarity < 0 || rarity >= COMP_RARITY_COUNT do return false
	def, ok := species_def(species_idx)
	if !ok do return false
	if def.biome_x >= 0 && g.pos_x % 3 != def.biome_x do return false
	if def.biome_y >= 0 && g.pos_y % 3 != def.biome_y do return false
	cost := comp_adopt_cost(rarity)
	if !consume_material(g, def.material, cost) do return false
	g.comp_active = true
	g.comp_species = species_idx
	g.comp_trait = int(def.trait_affinity)
	g.comp_rarity = rarity
	g.comp_loyalty = INITIAL_LOYALTY
	g.comp_command_used = false
	if g.cq1_adopted < CQ1_TARGET do g.cq1_adopted += 1
	return true
}

feed_companion :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if !g.comp_active do return false
	if g.comp_loyalty >= MAX_LOYALTY do return false
	if g.qty_potion < 1 do return false
	g.qty_potion -= 1
	g.comp_loyalty = min(g.comp_loyalty + LOYALTY_GAIN, MAX_LOYALTY)
	if g.comp_loyalty == MAX_LOYALTY && g.cq2_maxed < CQ2_TARGET do g.cq2_maxed += 1
	return true
}

dismiss_companion :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if !g.comp_active do return false
	g.comp_active = false
	g.comp_species = -1
	g.comp_trait = 0
	g.comp_rarity = 0
	g.comp_loyalty = 0
	g.comp_command_used = false
	return true
}

companion_command :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !g.comp_active do return false
	if g.comp_loyalty < HIGH_LOYALTY do return false
	if g.comp_command_used do return false
	// Trait dispatch: Attacker/Scout grant ATK buff, Defender grants DEF buff,
	// Support applies enemy poison. No species branching.
	switch Comp_Trait(g.comp_trait) {
	case .Attacker, .Scout: g.player_atk_buff_dur = STATUS_DURATION
	case .Defender:         g.player_def_buff_dur = STATUS_DURATION
	case .Support:          g.enemy_poison_dur    = STATUS_DURATION
	}
	g.comp_command_used = true
	return true
}

// --- Salvage procs ---

salvage_sword :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if g.qty_sword < 1 do return false
	// Capacity guard: net delta is (wood + iron yield) - 1 sword.
	if total_items(g) - 1 + salvage_wood_yield(g.salvage_level) + salvage_iron_yield(g.salvage_level) > MAX_INVENTORY do return false
	g.turn_count += 1
	g.qty_sword -= 1
	g.qty_wood += salvage_wood_yield(g.salvage_level)
	g.qty_iron += salvage_iron_yield(g.salvage_level)
	// Salvage destroys an inventory sword; equipped sword + its enchants untouched.
	return true
}

upgrade_salvage :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if g.salvage_level >= MAX_SALVAGE_LEVEL do return false
	if g.gold < UPGRADE_SALVAGE_COST do return false
	g.turn_count += 1
	g.salvage_level += 1
	g.gold -= UPGRADE_SALVAGE_COST
	return true
}

// --- Enchantment procs ---

apply_enchant :: proc(g: ^Game_State, slot: int, etype: int) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if !g.has_sword do return false
	if g.gold < ENCHANT_COST do return false
	if etype < 1 || etype > 4 do return false
	// Vampiric (etype=3) costs 1 venom_sac; other elements cost 1 iron.
	needs_venom := etype == 3
	if needs_venom {
		if g.qty_venom_sac < ENCHANT_VENOM_COST do return false
	} else {
		if g.qty_iron < ENCHANT_IRON_COST do return false
	}
	// Fire/Ice incompatibility
	if etype == 1 && has_ice_enchant(g) do return false
	if etype == 2 && has_fire_enchant(g) do return false
	// Validate slot before spending any resources
	if slot < 1 || slot > 3 do return false
	g.turn_count += 1
	g.gold -= ENCHANT_COST
	if needs_venom {
		g.qty_venom_sac -= ENCHANT_VENOM_COST
	} else {
		g.qty_iron -= ENCHANT_IRON_COST
	}
	switch slot {
	case 1: g.enchant_slot_1 = etype
	case 2: g.enchant_slot_2 = etype
	case 3: g.enchant_slot_3 = etype
	}
	return true
}

remove_enchant :: proc(g: ^Game_State, slot: int) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if !g.has_sword do return false
	switch slot {
	case 1:
		if g.enchant_slot_1 == 0 do return false
		g.turn_count += 1
		g.enchant_slot_1 = 0
	case 2:
		if g.enchant_slot_2 == 0 do return false
		g.turn_count += 1
		g.enchant_slot_2 = 0
	case 3:
		if g.enchant_slot_3 == 0 do return false
		g.turn_count += 1
		g.enchant_slot_3 = 0
	case:
		return false
	}
	return true
}

save_game :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	g.saved_exists = true
	g.save_data = Save_Data{
		hp           = g.hp,
		max_hp       = g.max_hp,
		base_attack  = g.base_attack,
		xp           = g.xp,
		level        = g.level,
		gold         = g.gold,
		pos_x        = g.pos_x,
		pos_y        = g.pos_y,
		qty_potion   = g.qty_potion,
		qty_wood     = g.qty_wood,
		qty_iron     = g.qty_iron,
		qty_sword    = g.qty_sword,
		has_sword    = g.has_sword,
		sword_dur    = g.sword_dur,
		sword_max_dur = g.sword_max_dur,
		turn_count   = g.turn_count,
		stamina      = g.stamina,
		max_stamina  = g.max_stamina,
		pity_counter = g.pity_counter,
		skill_points = g.skill_points,
		skill_combo = g.skill_combo,
		skill_poison = g.skill_poison,
		skill_shield_block = g.skill_shield_block,
		skill_heavy_strike = g.skill_heavy_strike,
		skill_counter_attack = g.skill_counter_attack,
		skill_battle_cry = g.skill_battle_cry,
		skill_fortify = g.skill_fortify,
		respec_count = g.respec_count,
		qty_venom_sac = g.qty_venom_sac,
		qty_holy_dust = g.qty_holy_dust,
		qty_pelt      = g.qty_pelt,
		qty_core      = g.qty_core,
		qty_essence   = g.qty_essence,
		qty_coin      = g.qty_coin,
		qty_ichor     = g.qty_ichor,
		enemy_element = g.enemy_element,
		enchant_slot_1 = g.enchant_slot_1,
		enchant_slot_2 = g.enchant_slot_2,
		enchant_slot_3 = g.enchant_slot_3,
		salvage_level = g.salvage_level,
		last_kill_turn = g.last_kill_turn,
		q1_kills = g.q1_kills,
		q2_zones = g.q2_zones,
		q3_kills = g.q3_kills,
		comp_active = g.comp_active,
		comp_species = g.comp_species,
		comp_trait = g.comp_trait,
		comp_rarity = g.comp_rarity,
		comp_loyalty = g.comp_loyalty,
		cq1_adopted = g.cq1_adopted,
		cq2_maxed = g.cq2_maxed,
		cq3_wins = g.cq3_wins,
	}
	return true
}

load_game :: proc(g: ^Game_State) -> bool {
	if !g.saved_exists do return false
	s := g.save_data
	g.hp = s.hp
	g.max_hp = s.max_hp
	g.base_attack = s.base_attack
	g.xp = s.xp
	g.level = s.level
	g.gold = s.gold
	g.pos_x = s.pos_x
	g.pos_y = s.pos_y
	g.qty_potion = s.qty_potion
	g.qty_wood = s.qty_wood
	g.qty_iron = s.qty_iron
	g.qty_sword = s.qty_sword
	g.has_sword = s.has_sword
	g.sword_dur = s.sword_dur
	g.sword_max_dur = s.sword_max_dur
	g.turn_count = s.turn_count
	g.stamina = s.stamina
	g.max_stamina = s.max_stamina
	g.pity_counter = s.pity_counter
	g.skill_points = s.skill_points
	g.skill_combo = s.skill_combo
	g.skill_poison = s.skill_poison
	g.skill_shield_block = s.skill_shield_block
	g.skill_heavy_strike = s.skill_heavy_strike
	g.skill_counter_attack = s.skill_counter_attack
	g.skill_battle_cry = s.skill_battle_cry
	g.skill_fortify = s.skill_fortify
	g.respec_count = s.respec_count
	g.qty_venom_sac = s.qty_venom_sac
	g.qty_holy_dust = s.qty_holy_dust
	g.qty_pelt      = s.qty_pelt
	g.qty_core      = s.qty_core
	g.qty_essence   = s.qty_essence
	g.qty_coin      = s.qty_coin
	g.qty_ichor     = s.qty_ichor
	g.enemy_element = s.enemy_element
	g.enchant_slot_1 = s.enchant_slot_1
	g.enchant_slot_2 = s.enchant_slot_2
	g.enchant_slot_3 = s.enchant_slot_3
	g.salvage_level = s.salvage_level
	g.last_kill_turn = s.last_kill_turn
	g.q1_kills = s.q1_kills
	g.q2_zones = s.q2_zones
	g.q3_kills = s.q3_kills
	g.comp_active = s.comp_active
	g.comp_species = s.comp_species
	g.comp_trait = s.comp_trait
	g.comp_rarity = s.comp_rarity
	g.comp_loyalty = s.comp_loyalty
	g.comp_command_used = false
	g.cq1_adopted = s.cq1_adopted
	g.cq2_maxed = s.cq2_maxed
	g.cq3_wins = s.cq3_wins
	// Clear combat/status state (save is only outside combat)
	g.in_combat = false
	g.enemy_hp = 0
	g.enemy_attack = 0
	g.game_won = false
	g.player_poison_dur = 0
	g.player_atk_buff_dur = 0
	g.player_def_buff_dur = 0
	g.enemy_poison_dur = 0
	g.combo_count = 0

	g.cd_heavy_strike = 0
	g.cd_battle_cry = 0
	g.cd_fortify = 0
	g.last_drop = 0
	return true
}
