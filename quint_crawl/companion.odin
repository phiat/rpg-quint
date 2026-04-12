package quint_crawl

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
	refund := comp_adopt_cost(g.comp_rarity)
	g.qty_wood += refund
	g.comp_active = false
	g.comp_species = -1
	g.comp_trait = 0
	g.comp_rarity = 0
	g.comp_loyalty = 0
	g.comp_command_used = false
	return true
}

train_companion :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if !zone_has_services(g.pos_x, g.pos_y) do return false
	if !g.comp_active do return false
	if g.comp_rarity >= COMP_RARITY_COUNT - 1 do return false
	new_rarity := g.comp_rarity + 1
	cost := (new_rarity + 1) * TRAIN_COST
	if g.qty_wood < cost do return false
	g.turn_count += 1
	g.qty_wood -= cost
	g.comp_rarity = new_rarity
	return true
}

companion_command :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !g.comp_active do return false
	if g.comp_loyalty < HIGH_LOYALTY do return false
	if g.comp_command_used do return false
	g.turn_count += 1
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
