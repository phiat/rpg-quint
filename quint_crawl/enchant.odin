package quint_crawl

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
	if g.weapon_type != 0 do return false
	if g.sword_dur <= 0 do return false
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
