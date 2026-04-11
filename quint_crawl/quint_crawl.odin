package quint_crawl

ZONE_NAMES := [3][3]string{
	{"Village", "Plains", "Ruins"},
	{"Forest", "Cave", "Shrine"},
	{"Swamp", "Mountain", "Castle"},
}

ZONE_LEVEL_REQ := [3][3]int{
	{1, 1, 2},
	{1, 2, 2},
	{1, 2, 3},
}

ZONE_ENEMY_HP := [3]int{15, 30, 50}     // indexed by (zone_level - 1)
ZONE_ENEMY_ATK := [3]int{5, 8, 12}
ZONE_XP_REWARD := [3]int{5, 8, 15}
ZONE_GOLD_REWARD := [3]int{10, 15, 25}

XP_THRESHOLDS := [4]int{0, 0, 10, 25}   // index by level: threshold for level 2 = 10, level 3 = 25

SWORD_MAX_DUR :: 10
REPAIR_COST :: 5
POISON_DMG :: 3
ATK_BUFF_BONUS :: 5
DEF_BUFF_REDUCTION :: 3
STATUS_DURATION :: 3
WEATHER_CYCLE :: 5
STORM_MOVE_DMG :: 2
FOG_ATK_PENALTY :: 2
RAIN_GATHER_BONUS :: 1
COMBO_WINDOW :: 3

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
	combo_timer:         int,
	// World state
	turn_count:          int,
	// Save/Load
	saved_exists:        bool,
	save_data:           Save_Data,
}

zone_name :: proc(x, y: int) -> string {
	if x < 0 || x > 2 || y < 0 || y > 2 do return "Unknown"
	return ZONE_NAMES[x][y]
}

zone_level_req :: proc(x, y: int) -> int {
	if x < 0 || x > 2 || y < 0 || y > 2 do return 99
	return ZONE_LEVEL_REQ[x][y]
}

// Weather: 0=Clear, 1=Rain, 2=Fog, 3=Storm
zone_weather :: proc(x, y, turn: int) -> int {
	return (x * 3 + y * 7 + turn / WEATHER_CYCLE) % 4
}

attack_power :: proc(g: ^Game_State) -> int {
	sword_bonus := 5 if (g.has_sword && g.sword_dur > 0) else 0
	atk_buff := ATK_BUFF_BONUS if g.player_atk_buff_dur > 0 else 0
	return g.base_attack + sword_bonus + atk_buff
}

init_game :: proc(g: ^Game_State) {
	g.hp = 50
	g.max_hp = 50
	g.base_attack = 10
	g.xp = 0
	g.level = 1
	g.gold = 0
	g.pos_x = 0
	g.pos_y = 0
	g.qty_potion = 2
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
	g.combo_timer = 0
	g.turn_count = 0
	g.saved_exists = false
}

move :: proc(g: ^Game_State, dx, dy: int) -> bool {
	nx, ny := g.pos_x + dx, g.pos_y + dy
	if nx < 0 || nx > 2 || ny < 0 || ny > 2 do return false
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	if zone_level_req(nx, ny) > g.level do return false
	g.pos_x = nx
	g.pos_y = ny
	g.turn_count += 1
	// Storm damage (can't kill — floor at 1)
	if zone_weather(nx, ny, g.turn_count) == 3 {
		g.hp = max(g.hp - STORM_MOVE_DMG, 1)
	}
	return true
}

enter_combat :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	zlvl := zone_level_req(g.pos_x, g.pos_y) - 1
	g.turn_count += 1
	g.in_combat = true
	g.enemy_hp = ZONE_ENEMY_HP[zlvl]
	// Fog reduces enemy attack
	weather := zone_weather(g.pos_x, g.pos_y, g.turn_count)
	fog_penalty := FOG_ATK_PENALTY if weather == 2 else 0
	raw_atk := ZONE_ENEMY_ATK[zlvl] - fog_penalty
	g.enemy_attack = max(raw_atk, 1)
	g.combo_count = 0
	g.combo_timer = 0
	return true
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
	} else {
		zone_tier := zone_level_req(g.pos_x, g.pos_y)
		if zone_tier >= 2 && g.player_poison_dur == 0 {
			g.player_poison_dur = STATUS_DURATION
		} else if g.player_poison_dur > 0 {
			g.player_poison_dur -= 1
		}
		if g.player_atk_buff_dur > 0 do g.player_atk_buff_dur -= 1
		if g.player_def_buff_dur > 0 do g.player_def_buff_dur -= 1
		if g.enemy_poison_dur > 0 do g.enemy_poison_dur -= 1
	}

	// Player died — end combat
	if g.hp <= 0 {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		return true
	}

	if new_enemy_hp <= 0 {
		// Enemy defeated — rewards
		zlvl := zone_level_req(g.pos_x, g.pos_y) - 1
		g.xp += ZONE_XP_REWARD[zlvl]
		g.gold += ZONE_GOLD_REWARD[zlvl]
		g.in_combat = false
		g.enemy_attack = 0
		if g.level < 3 && g.xp >= XP_THRESHOLDS[g.level + 1] {
			g.level += 1
			g.max_hp += 20
			g.base_attack += 3
		}
		if g.level >= 3 {
			g.game_won = true
		}
	}
	return combat_ends
}

combat_attack :: proc(g: ^Game_State) -> bool {
	if !g.in_combat || g.game_won || g.hp <= 0 || g.enemy_hp <= 0 do return false
	g.turn_count += 1
	combat_ends := resolve_combat_hit(g, attack_power(g))
	// Plain attack preserves combo (spec: combo_count' = combo_count)
	if combat_ends {
		g.combo_count = 0
		g.combo_timer = 0
	}
	return true
}

combat_potion :: proc(g: ^Game_State) -> bool {
	if !g.in_combat || g.game_won || g.qty_potion <= 0 || g.hp <= 0 do return false
	g.turn_count += 1
	g.hp = min(g.hp + 20, g.max_hp)
	g.qty_potion -= 1
	g.combo_count = 0
	g.combo_timer = 0
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
	g.combo_timer = 0
	return true
}

rest_at_village :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.pos_x != 0 || g.pos_y != 0 do return false
	if g.hp >= g.max_hp do return false
	g.turn_count += 1
	g.hp = g.max_hp
	return true
}

buy_potion :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.pos_x != 0 || g.pos_y != 0 do return false
	if g.gold < 10 do return false
	g.turn_count += 1
	g.gold -= 10
	g.qty_potion += 1
	return true
}

gather_wood :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.pos_x != 1 || g.pos_y != 0 do return false
	g.turn_count += 1
	rain_bonus := RAIN_GATHER_BONUS if zone_weather(g.pos_x, g.pos_y, g.turn_count) == 1 else 0
	g.qty_wood += 1 + rain_bonus
	return true
}

mine_iron :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.pos_x != 2 || g.pos_y != 1 do return false
	g.turn_count += 1
	rain_bonus := RAIN_GATHER_BONUS if zone_weather(g.pos_x, g.pos_y, g.turn_count) == 1 else 0
	g.qty_iron += 1 + rain_bonus
	return true
}

craft_sword :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.pos_x != 0 || g.pos_y != 0 do return false
	if g.qty_wood < 1 || g.qty_iron < 2 do return false
	g.turn_count += 1
	g.qty_wood -= 1
	g.qty_iron -= 2
	g.qty_sword += 1
	return true
}

equip_sword :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.qty_sword < 1 || g.has_sword do return false
	g.turn_count += 1
	g.has_sword = true
	g.qty_sword -= 1
	g.sword_dur = SWORD_MAX_DUR
	return true
}

repair_sword :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.pos_x != 0 || g.pos_y != 0 do return false
	if !g.has_sword do return false
	if g.sword_dur >= g.sword_max_dur do return false
	if g.gold < REPAIR_COST do return false
	g.turn_count += 1
	g.sword_dur = g.sword_max_dur
	g.gold -= REPAIR_COST
	return true
}

use_antidote :: proc(g: ^Game_State) -> bool {
	if !g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.qty_potion <= 0 || g.player_poison_dur <= 0 do return false
	g.turn_count += 1
	g.qty_potion -= 1
	g.player_poison_dur = 0
	g.combo_count = 0
	g.combo_timer = 0
	return true
}

poison_strike :: proc(g: ^Game_State) -> bool {
	if !g.in_combat || g.game_won || g.hp <= 0 || g.enemy_hp <= 0 do return false
	if g.enemy_poison_dur != 0 do return false  // can't stack
	g.turn_count += 1
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
	} else {
		g.enemy_poison_dur = STATUS_DURATION
	}
	g.combo_count = 0
	g.combo_timer = 0
	return true
}

save_game :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
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
	g.combo_timer = 0
	return true
}

combo_attack :: proc(g: ^Game_State) -> bool {
	if !g.in_combat || g.game_won || g.hp <= 0 || g.enemy_hp <= 0 do return false
	if g.combo_count >= 3 do return false
	g.turn_count += 1

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
	if combat_ends || next_combo >= 3 {
		g.combo_count = 0
		g.combo_timer = 0
	} else {
		g.combo_count = next_combo
		g.combo_timer = COMBO_WINDOW
	}
	return true
}
