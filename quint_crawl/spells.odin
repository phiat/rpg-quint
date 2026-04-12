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

// Shared fireball damage resolution — used by cast_fireball and use_scroll_fire.
// Caller must have already validated preconditions, incremented turn_count,
// and deducted the resource (mana or scroll).
resolve_fireball_hit :: proc(g: ^Game_State) {
	enemy_poison_dmg := POISON_DMG if g.enemy_poison_dur > 0 else 0
	new_enemy_hp := g.enemy_hp - FIREBALL_DMG - enemy_poison_dmg

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
		if g.player_poison_dur > 0 do g.player_poison_dur -= 1
		if g.player_atk_buff_dur > 0 do g.player_atk_buff_dur -= 1
		if g.player_def_buff_dur > 0 do g.player_def_buff_dur -= 1
		if g.enemy_poison_dur > 0 do g.enemy_poison_dur -= 1
		tick_cooldowns(g)
	}

	if new_enemy_hp <= 0 {
		g.gold += zone_gold_reward(g.pos_x, g.pos_y)
	}
	if g.hp <= 0 {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		g.enemy_element = 0
		return
	}
	if new_enemy_hp <= 0 {
		g.in_combat = false
		g.enemy_attack = 0
		g.enemy_element = 0
		kill_accounting(g)
	}
}

cast_fireball :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !g.skill_magic do return false
	if g.mana < FIREBALL_COST do return false
	g.turn_count += 1
	g.mana -= FIREBALL_COST
	resolve_fireball_hit(g)
	return true
}

// Unified dispatch — id matches SPELL_HEAL / SPELL_FIRE constants.
cast_spell :: proc(g: ^Game_State, id: int) -> bool {
	switch id {
	case SPELL_HEAL: return cast_heal(g)
	case SPELL_FIRE: return cast_fireball(g)
	}
	return false
}

// Buy a fire scroll at a village (no skill_magic required).
buy_scroll_fire :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if g.gold < SCROLL_FIRE_COST do return false
	if total_items(g) >= MAX_INVENTORY do return false
	g.turn_count += 1
	g.gold -= SCROLL_FIRE_COST
	g.qty_scroll_fire += 1
	return true
}

// Consume a fire scroll in combat — bypasses mana/magic gate.
use_scroll_fire :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if g.qty_scroll_fire < 1 do return false
	g.turn_count += 1
	g.qty_scroll_fire -= 1
	resolve_fireball_hit(g)
	return true
}
