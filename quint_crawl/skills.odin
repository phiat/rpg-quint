package quint_crawl

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
