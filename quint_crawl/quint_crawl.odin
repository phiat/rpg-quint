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
ATK_BUFF_BONUS :: 5
DEF_BUFF_REDUCTION :: 3
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
RESPEC_COST :: 25
COUNTER_STAMINA :: 3
SHIELD_BLOCK_STAMINA :: 3
FORTIFY_STAMINA :: 4
FORTIFY_CD :: 5
FORTIFY_DURATION :: 6
CRAFT_VENOM_IRON_COST :: 2

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
	qty_venom_sac: int,
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
	// Venom sac
	qty_venom_sac:       int,
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

attack_power :: proc(g: ^Game_State) -> int {
	sword_bonus := SWORD_ATK_BONUS if (g.has_sword && g.sword_dur > 0) else 0
	atk_buff := ATK_BUFF_BONUS if g.player_atk_buff_dur > 0 else 0
	return g.base_attack + sword_bonus + atk_buff
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
	g.qty_venom_sac = 0
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
	// Storm damage (can't kill — floor at 1)
	if zone_weather(nx, ny, g.turn_count) == 3 {
		g.hp = max(g.hp - STORM_MOVE_DMG, 1)
	}
	return true
}

enter_combat :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
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
resolve_loot :: proc(g: ^Game_State) {
	// turn_count was already incremented before resolve_combat_hit, so use -1 to match spec
	pre_turn := g.turn_count - 1
	should_drop := g.pity_counter >= PITY_THRESHOLD || (pre_turn % LOOT_DROP_MODULO == 0)
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
}

// Shared combat hit resolution: applies damage, ticks statuses, resolves combat end.
// Returns true if combat ended.
resolve_combat_hit :: proc(g: ^Game_State, dmg: int) -> bool {
	// Degrade sword on attack
	if g.has_sword && g.sword_dur > 0 {
		g.sword_dur -= 1
	}
	// Enemy takes hit + poison damage
	enemy_poison_dmg := POISON_DMG if g.enemy_poison_dur > 0 else 0
	new_enemy_hp := g.enemy_hp - dmg - enemy_poison_dmg

	// Player takes enemy hit (reduced by DEF buff) + poison damage
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	new_hp := g.hp - poison_dmg
	if new_enemy_hp > 0 {
		enemy_dmg := g.enemy_attack - (DEF_BUFF_REDUCTION if g.player_def_buff_dur > 0 else 0)
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
		return true
	}

	if new_enemy_hp <= 0 {
		// Enemy defeated, player alive — XP, loot, level-up
		g.xp += zone_xp_reward(g.pos_x, g.pos_y)
		g.in_combat = false
		g.enemy_attack = 0
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
	g.hp = max(g.hp - g.enemy_attack, 0)
	g.in_combat = false
	g.enemy_hp = 0
	g.enemy_attack = 0
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
	return true
}

buy_potion :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if g.gold < POTION_COST do return false
	g.turn_count += 1
	g.gold -= POTION_COST
	g.qty_potion += 1
	return true
}

gather_wood :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_wood(g.pos_x, g.pos_y) do return false
	g.turn_count += 1
	rain_bonus := RAIN_GATHER_BONUS if zone_weather(g.pos_x, g.pos_y, g.turn_count) == 1 else 0
	g.qty_wood += 1 + rain_bonus
	return true
}

mine_iron :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_iron(g.pos_x, g.pos_y) do return false
	g.turn_count += 1
	rain_bonus := RAIN_GATHER_BONUS if zone_weather(g.pos_x, g.pos_y, g.turn_count) == 1 else 0
	g.qty_iron += 1 + rain_bonus
	return true
}

craft_sword :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
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
	if g.enemy_poison_dur != 0 do return false  // can't stack
	if g.stamina < ATTACK_STAMINA do return false
	g.turn_count += 1
	g.stamina -= ATTACK_STAMINA
	g.qty_venom_sac -= 1
	// Enemy hits back
	enemy_dmg := g.enemy_attack - (DEF_BUFF_REDUCTION if g.player_def_buff_dur > 0 else 0)
	if enemy_dmg < 1 do enemy_dmg = 1
	g.hp = max(g.hp - enemy_dmg, 0)
	if g.hp <= 0 {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		g.player_poison_dur = 0
		g.player_atk_buff_dur = 0
		g.player_def_buff_dur = 0
		g.enemy_poison_dur = 0
		reset_cooldowns(g)
	} else {
		g.enemy_poison_dur = STATUS_DURATION
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

	// Enemy hits back
	enemy_dmg := g.enemy_attack - (DEF_BUFF_REDUCTION if g.player_def_buff_dur > 0 else 0)
	if enemy_dmg < 1 do enemy_dmg = 1
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	g.hp = max(g.hp - enemy_dmg - poison_dmg, 0)

	combat_ends := (g.hp <= 0)

	if combat_ends {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
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

	// Enemy hits back
	enemy_dmg := g.enemy_attack - (DEF_BUFF_REDUCTION if g.player_def_buff_dur > 0 else 0)
	if enemy_dmg < 1 do enemy_dmg = 1
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	g.hp = max(g.hp - enemy_dmg - poison_dmg, 0)

	combat_ends := (g.hp <= 0)

	if combat_ends {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
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
	g.skill_combo = true
	g.skill_points -= 1
	return true
}

unlock_poison :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.skill_poison do return false
	if g.skill_points < 1 do return false
	g.skill_poison = true
	g.skill_points -= 1
	return true
}

unlock_shield_block :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.skill_shield_block do return false
	if g.skill_points < 1 do return false
	g.skill_shield_block = true
	g.skill_points -= 1
	return true
}

unlock_heavy_strike :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.skill_heavy_strike do return false
	if !g.skill_combo do return false  // prereq
	if g.skill_points < 1 do return false
	g.skill_heavy_strike = true
	g.skill_points -= 1
	return true
}

unlock_counter_attack :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.skill_counter_attack do return false
	if !g.skill_shield_block do return false  // prereq
	if g.skill_points < 1 do return false
	g.skill_counter_attack = true
	g.skill_points -= 1
	return true
}

unlock_battle_cry :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.skill_battle_cry do return false
	if !g.skill_heavy_strike do return false  // prereq
	if g.skill_points < 2 do return false
	g.skill_battle_cry = true
	g.skill_points -= 2
	return true
}

unlock_fortify :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.skill_fortify do return false
	if !g.skill_counter_attack do return false  // prereq
	if g.skill_points < 2 do return false
	g.skill_fortify = true
	g.skill_points -= 2
	return true
}

respec :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if g.gold < RESPEC_COST do return false
	spent := 0
	if g.skill_combo do spent += 1
	if g.skill_poison do spent += 1
	if g.skill_shield_block do spent += 1
	if g.skill_heavy_strike do spent += 1
	if g.skill_counter_attack do spent += 1
	if g.skill_battle_cry do spent += 2
	if g.skill_fortify do spent += 2
	if spent == 0 do return false
	g.gold -= RESPEC_COST
	g.skill_points += spent
	g.skill_combo = false
	g.skill_poison = false
	g.skill_shield_block = false
	g.skill_heavy_strike = false
	g.skill_counter_attack = false
	g.skill_battle_cry = false
	g.skill_fortify = false
	return true
}

counter_attack :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !g.skill_counter_attack do return false
	if g.stamina < COUNTER_STAMINA do return false
	g.turn_count += 1
	g.stamina -= COUNTER_STAMINA

	// Player deals base damage + sword durability cost
	dmg := attack_power(g)
	if g.has_sword && g.sword_dur > 0 {
		g.sword_dur -= 1
	}

	// Enemy takes hit + poison
	enemy_poison_dmg := POISON_DMG if g.enemy_poison_dur > 0 else 0
	new_enemy_hp := g.enemy_hp - dmg - enemy_poison_dmg
	g.enemy_hp = max(new_enemy_hp, 0)

	// Enemy hits player (with DEF buff reduction)
	enemy_dmg := g.enemy_attack - (DEF_BUFF_REDUCTION if g.player_def_buff_dur > 0 else 0)
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
			g.player_poison_dur = 0
			g.player_atk_buff_dur = 0
			g.player_def_buff_dur = 0
			g.enemy_poison_dur = 0
			reset_cooldowns(g)
		} else {
			// Enemy defeated, player alive
			g.xp += zone_xp_reward(g.pos_x, g.pos_y)
			g.in_combat = false
			g.enemy_attack = 0
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

	// Enemy hits back
	enemy_dmg := g.enemy_attack - (DEF_BUFF_REDUCTION if g.player_def_buff_dur > 0 else 0)
	if enemy_dmg < 1 do enemy_dmg = 1
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	g.hp = max(g.hp - enemy_dmg - poison_dmg, 0)

	combat_ends := (g.hp <= 0)

	if combat_ends {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
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
	g.qty_iron -= CRAFT_VENOM_IRON_COST
	g.qty_venom_sac += 1
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
		qty_venom_sac = g.qty_venom_sac,
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
	g.qty_venom_sac = s.qty_venom_sac
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
