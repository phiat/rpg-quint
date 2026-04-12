package quint_crawl

rest_at_village :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if g.hp >= g.max_hp && g.stamina >= g.max_stamina do return false
	g.turn_count += 1
	g.hp = g.max_hp
	g.stamina = g.max_stamina
	g.mana = g.max_mana
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

buy_spellbook :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if g.skill_magic do return false
	if g.gold < SPELLBOOK_COST do return false
	g.turn_count += 1
	g.gold -= SPELLBOOK_COST
	g.skill_magic = true
	g.max_mana = INITIAL_MAX_MANA
	g.mana = INITIAL_MAX_MANA
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

equip_pistol :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if !g.has_sword || g.weapon_type != 0 do return false
	if g.gold < PISTOL_UNLOCK_COST do return false
	g.turn_count += 1
	g.gold -= PISTOL_UNLOCK_COST
	g.has_sword = false
	g.sword_dur = 0
	g.weapon_type = 1
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


craft_venom_sac :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if g.qty_iron < CRAFT_VENOM_IRON_COST do return false
	g.turn_count += 1
	g.qty_iron -= CRAFT_VENOM_IRON_COST
	g.qty_venom_sac += 1
	return true
}

craft_holy_water :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if g.qty_holy_dust < 1 do return false
	if g.qty_wood < CRAFT_HOLY_WATER_WOOD do return false
	if total_items(g) - 1 - CRAFT_HOLY_WATER_WOOD + 1 > MAX_INVENTORY do return false
	g.turn_count += 1
	g.qty_holy_dust -= 1
	g.qty_wood -= CRAFT_HOLY_WATER_WOOD
	g.qty_holy_water += 1
	return true
}

use_holy_water :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.qty_holy_water < 1 do return false
	if g.hp >= g.max_hp do return false
	g.turn_count += 1
	g.qty_holy_water -= 1
	g.hp = g.max_hp
	return true
}

