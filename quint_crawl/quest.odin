package quint_crawl

claim_victory :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.level < MAX_LEVEL do return false
	// Must be on a Castle biome (x%3==2, y%3==2) at zone level >= MAX_LEVEL
	if g.pos_x % 3 != 2 || g.pos_y % 3 != 2 do return false
	if zone_level(g.pos_x, g.pos_y) < MAX_LEVEL do return false
	if !g.boss_defeated do return false
	g.game_won = true
	return true
}

claim_quest_reward :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.quest_rewards_claimed >= 3 do return false
	// Each claim requires the next quest complete.
	switch g.quest_rewards_claimed {
	case 0:
		if g.q1_kills < Q1_TARGET do return false
	case 1:
		if g.q1_kills < Q1_TARGET || g.q2_zones < Q2_TARGET do return false
	case 2:
		if g.q1_kills < Q1_TARGET || g.q2_zones < Q2_TARGET || g.q3_kills < Q3_TARGET do return false
	}
	g.turn_count += 1
	g.gold += QUEST_REWARD_GOLD
	g.skill_points += 1
	g.quest_rewards_claimed += 1
	return true
}

