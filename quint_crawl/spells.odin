package quint_crawl

cast_heal :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !g.skill_magic do return false
	if g.mana < HEAL_COST do return false
	if g.hp >= g.max_hp do return false
	g.turn_count += 1
	g.mana -= HEAL_COST
	g.hp = min(g.hp + HEAL_AMOUNT, g.max_hp)
	return true
}

cast_fireball :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !g.skill_magic do return false
	if g.mana < FIREBALL_COST do return false
	g.turn_count += 1
	g.mana -= FIREBALL_COST

	// Enemy takes flat FIREBALL_DMG + enemy poison tick (no elements, no sword)
	enemy_poison_dmg := POISON_DMG if g.enemy_poison_dur > 0 else 0
	new_enemy_hp := g.enemy_hp - FIREBALL_DMG - enemy_poison_dmg

	// Player takes counter-hit if enemy still alive + player poison tick
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	new_hp := g.hp - poison_dmg
	if new_enemy_hp > 0 {
		new_hp -= enemy_free_hit_damage(g, enchant_def_bonus(g))
	}
	g.enemy_hp = max(new_enemy_hp, 0)
	g.hp = max(new_hp, 0)
	g.combo_count = 0

	combat_ends := (new_enemy_hp <= 0 || g.hp <= 0)
	if combat_ends {
		g.player_poison_dur = 0
		g.player_atk_buff_dur = 0
		g.player_def_buff_dur = 0
		g.enemy_poison_dur = 0
		reset_cooldowns(g)
	} else {
		// Fireball does not apply poison; just tick existing durations
		if g.player_poison_dur > 0 do g.player_poison_dur -= 1
		if g.player_atk_buff_dur > 0 do g.player_atk_buff_dur -= 1
		if g.player_def_buff_dur > 0 do g.player_def_buff_dur -= 1
		if g.enemy_poison_dur > 0 do g.enemy_poison_dur -= 1
		tick_cooldowns(g)
	}

	// Gold on kill (spec grants even on mutual kill)
	if new_enemy_hp <= 0 {
		g.gold += zone_gold_reward(g.pos_x, g.pos_y)
	}
	// Player died — end combat with no loot/xp
	if g.hp <= 0 {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		g.enemy_element = 0
		return true
	}
	// Enemy defeated — kill accounting handles xp/level/loot/quest tracking
	if new_enemy_hp <= 0 {
		g.in_combat = false
		g.enemy_attack = 0
		g.enemy_element = 0
		kill_accounting(g)
	}
	return true
}
