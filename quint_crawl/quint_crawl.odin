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
}

zone_name :: proc(x, y: int) -> string {
	if x < 0 || x > 2 || y < 0 || y > 2 do return "Unknown"
	return ZONE_NAMES[x][y]
}

zone_level_req :: proc(x, y: int) -> int {
	if x < 0 || x > 2 || y < 0 || y > 2 do return 99
	return ZONE_LEVEL_REQ[x][y]
}

attack_power :: proc(g: ^Game_State) -> int {
	return g.base_attack + (5 if (g.has_sword && g.sword_dur > 0) else 0)
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
}

move :: proc(g: ^Game_State, dx, dy: int) -> bool {
	nx, ny := g.pos_x + dx, g.pos_y + dy
	if nx < 0 || nx > 2 || ny < 0 || ny > 2 do return false
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	if zone_level_req(nx, ny) > g.level do return false
	g.pos_x = nx
	g.pos_y = ny
	return true
}

enter_combat :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	zlvl := zone_level_req(g.pos_x, g.pos_y) - 1
	g.in_combat = true
	g.enemy_hp = ZONE_ENEMY_HP[zlvl]
	g.enemy_attack = ZONE_ENEMY_ATK[zlvl]
	return true
}

combat_attack :: proc(g: ^Game_State) -> bool {
	if !g.in_combat || g.game_won || g.hp <= 0 || g.enemy_hp <= 0 do return false
	atk := attack_power(g)
	// Degrade sword on attack
	if g.has_sword && g.sword_dur > 0 {
		g.sword_dur -= 1
	}
	new_enemy_hp := g.enemy_hp - atk
	new_hp := g.hp
	if new_enemy_hp > 0 {
		new_hp = g.hp - g.enemy_attack
	}
	g.enemy_hp = max(new_enemy_hp, 0)
	g.hp = max(new_hp, 0)

	// Player died during combat — end combat
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
		// Check level up
		if g.level < 3 && g.xp >= XP_THRESHOLDS[g.level + 1] {
			g.level += 1
			g.max_hp += 20
			g.base_attack += 3
		}
		if g.level >= 3 {
			g.game_won = true
		}
	}
	return true
}

combat_potion :: proc(g: ^Game_State) -> bool {
	if !g.in_combat || g.game_won || g.qty_potion <= 0 || g.hp <= 0 do return false
	g.hp = min(g.hp + 20, g.max_hp)
	g.qty_potion -= 1
	return true
}

flee_combat :: proc(g: ^Game_State) -> bool {
	if !g.in_combat || g.game_won || g.hp <= 0 do return false
	g.hp = max(g.hp - g.enemy_attack, 0)
	g.in_combat = false
	g.enemy_hp = 0
	g.enemy_attack = 0
	return true
}

rest_at_village :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.pos_x != 0 || g.pos_y != 0 do return false
	if g.hp >= g.max_hp do return false
	g.hp = g.max_hp
	return true
}

buy_potion :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.pos_x != 0 || g.pos_y != 0 do return false
	if g.gold < 10 do return false
	g.gold -= 10
	g.qty_potion += 1
	return true
}

gather_wood :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.pos_x != 1 || g.pos_y != 0 do return false
	g.qty_wood += 1
	return true
}

mine_iron :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.pos_x != 2 || g.pos_y != 1 do return false
	g.qty_iron += 1
	return true
}

craft_sword :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.pos_x != 0 || g.pos_y != 0 do return false
	if g.qty_wood < 1 || g.qty_iron < 2 do return false
	g.qty_wood -= 1
	g.qty_iron -= 2
	g.qty_sword += 1
	return true
}

equip_sword :: proc(g: ^Game_State) -> bool {
	if g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.qty_sword < 1 || g.has_sword do return false
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
	g.sword_dur = g.sword_max_dur
	g.gold -= REPAIR_COST
	return true
}
