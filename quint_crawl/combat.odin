package quint_crawl

enter_combat :: proc(g: ^Game_State) -> bool {
	if !can_act_map(g) do return false
	if g.last_kill_turn != 0 && g.turn_count - g.last_kill_turn < RESPAWN_TURNS do return false
	g.turn_count += 1
	g.in_combat = true
	is_boss := is_castle_zone(g.pos_x, g.pos_y) && !g.boss_defeated
	base_hp := BOSS_HP if is_boss else zone_enemy_hp(g.pos_x, g.pos_y)
	base_atk := BOSS_ATK if is_boss else zone_enemy_atk(g.pos_x, g.pos_y)
	base_elem := BOSS_ELEMENT if is_boss else zone_element(g.pos_x, g.pos_y)
	g.enemy_hp = base_hp
	// Fog reduces enemy attack
	weather := zone_weather(g.pos_x, g.pos_y, g.turn_count)
	fog_penalty := FOG_ATK_PENALTY if weather == 2 else 0
	raw_atk := base_atk - fog_penalty
	g.enemy_attack = max(raw_atk, 1)
	g.combo_count = 0

	g.cd_heavy_strike = 0
	g.cd_battle_cry = 0
	g.cd_fortify = 0
	g.last_drop = 0
	g.enemy_element = base_elem
	// Companion loyalty tick: pays to be brought into combat
	if g.comp_active {
		g.comp_loyalty -= LOYALTY_COMBAT_COST
		if g.comp_loyalty <= 0 {
			g.comp_active = false
			g.comp_species = -1
			g.comp_trait = 0
			g.comp_rarity = 0
			g.comp_loyalty = 0
		}
		g.comp_command_used = false
	}
	// Armor wear: one point per fight engaged. Breaks at 0.
	if g.has_armor {
		g.armor_dur -= 1
		if g.armor_dur <= 0 {
			g.has_armor = false
			g.armor_dur = 0
		}
	}
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

// Level-up check called at every kill site. Matches the spec's inline
// `if (new_level > ch.level)` branch. Idempotent — safe to call anywhere.
maybe_level_up :: proc(g: ^Game_State) {
	if g.level < MAX_LEVEL && g.xp >= XP_THRESHOLDS[g.level + 1] {
		g.level += 1
		g.max_hp += HP_PER_LEVEL
		g.base_attack += ATK_PER_LEVEL_UP
		g.max_stamina += STAMINA_PER_LEVEL
		if g.skill_magic do g.max_mana += MANA_PER_LEVEL
		g.skill_points += SKILL_POINTS_PER_LEVEL
	}
}

// Damage dealt by the enemy's "free hit" that follows non-attack combat
// actions (potion, antidote, shield_block, fortify, counter_attack, and the
// standard resolve_combat_hit retaliation). Always subtracts the three DEF
// sources and clamps to min 1. Callers pass the enchant_def value they
// already computed — some sites snapshot it before the sword may break.
// Flee_combat intentionally bypasses this helper (spec design: flee ignores
// DEF buff + companion reduction).
enemy_free_hit_damage :: proc(g: ^Game_State, enchant_def: int) -> int {
	shield_def := SHIELD_DEF if g.has_shield else 0
	armor_def := ARMOR_DEF if g.has_armor else 0
	d := g.enemy_attack - enchant_def - def_reduction_active(g) - comp_dmg_reduction(g) - shield_def - armor_def
	return max(d, 1)
}

// Shared kill-accounting: called from every kill path (resolve_combat_hit,
// counter_attack, and any future site). Handles xp, quest counters, boss
// flag, companion win, loot, and level-up. The caller is still responsible
// for in_combat/enemy_* teardown since those differ per action.
kill_accounting :: proc(g: ^Game_State) {
	g.last_kill_turn = g.turn_count - 1
	g.xp += zone_xp_reward(g.pos_x, g.pos_y)
	zone_tier := zone_level(g.pos_x, g.pos_y)
	if zone_tier == 1 && g.q1_kills < Q1_TARGET do g.q1_kills += 1
	if zone_tier == MAX_LEVEL && g.q3_kills < Q3_TARGET do g.q3_kills += 1
	if is_castle_zone(g.pos_x, g.pos_y) do g.boss_defeated = true
	if comp_active(g) && g.cq3_wins < CQ3_TARGET do g.cq3_wins += 1
	resolve_loot(g)
	maybe_level_up(g)
}

// Resolve loot drop on enemy defeat. Uses pre-increment turn for determinism (matches spec).
// Primary drop follows the zone-tier table (potion / venom sac). A secondary
// trait-keyed drop fires on ~25% of kills, flavored by the archetype trait
// cached on g.enemy_trait (set in input.enter_combat). The trait drop is
// Odin-only — no spec fields are touched — so the MBT contract is preserved.
resolve_loot :: proc(g: ^Game_State) {
	// turn_count was already incremented before resolve_combat_hit, so use -1 to match spec
	pre_turn := g.turn_count - 1
	// ch.xp in spec is the pre-kill value; Odin has already granted the xp reward by now.
	pre_xp := g.xp - zone_xp_reward(g.pos_x, g.pos_y)
	tot := total_items(g)
	should_drop := (g.pity_counter >= PITY_THRESHOLD || ((pre_turn + pre_xp) % LOOT_DROP_MODULO == 0)) && tot < MAX_INVENTORY
	if should_drop {
		zlvl := zone_level(g.pos_x, g.pos_y)
		if zlvl >= POISON_APPLY_TIER {
			g.qty_venom_sac += 1
			g.last_drop = 2
		} else {
			g.qty_potion += 1
			g.last_drop = 1
		}
		// Bonus holy_dust drop at tier 2+ when room for both items — mirrors spec drops_holy.
		if zlvl >= POISON_APPLY_TIER && tot + 1 < MAX_INVENTORY {
			g.qty_holy_dust += 1
		}
		g.pity_counter = 0
	} else {
		g.pity_counter += 1
		g.last_drop = 0
	}

	// Trait-keyed secondary drop (~25%). Deterministic hash of position +
	// turn, same style used elsewhere in the catalog. Aberration reuses the
	// existing venom sac field; Humanoid bleeds out as bonus gold.
	h := enemy_hash3(g.pos_x, g.pos_y, pre_turn + 911)
	if h % 4 == 0 {
		switch g.enemy_trait {
		case .Undead:
			// holy_dust now granted by the spec-visible tier-2 bonus drop above.
		case .Beast:
			g.qty_pelt += 1
		case .Construct:
			g.qty_core += 1
		case .Elemental:
			g.qty_essence += 1
		case .Humanoid:
			g.qty_coin += 1
		case .Aberration:
			g.qty_ichor += 1
		}
	}
}

// Shared combat hit resolution: applies damage, ticks statuses, resolves combat end.
// Returns true if combat ended.
resolve_combat_hit :: proc(g: ^Game_State, dmg: int) -> bool {
	// Capture pre-state enchant-derived values before any sword-break zeroing.
	pre_elem_mult := damage_multiplier(player_element(g), g.enemy_element)
	pre_enchant_def := enchant_def_bonus(g)
	// Degrade sword on attack. If it breaks (dur hits 0), lose enchants.
	if g.has_sword && g.sword_dur > 0 {
		g.sword_dur -= 1
		if g.sword_dur == 0 {
			g.enchant_slot_1 = 0
			g.enchant_slot_2 = 0
			g.enchant_slot_3 = 0
		}
	}
	// Enemy takes elemental-modified hit + poison damage
	enemy_poison_dmg := POISON_DMG if g.enemy_poison_dur > 0 else 0
	elem_dmg := effective_damage(dmg, pre_elem_mult)
	new_enemy_hp := g.enemy_hp - elem_dmg - enemy_poison_dmg

	// Player takes enemy hit (reduced by enchant DEF + DEF buff) + poison damage
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	new_hp := g.hp - poison_dmg
	if new_enemy_hp > 0 {
		new_hp -= enemy_free_hit_damage(g, pre_enchant_def)
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
		g.enemy_element = 0
		return true
	}

	if new_enemy_hp <= 0 {
		g.in_combat = false
		g.enemy_attack = 0
		g.enemy_element = 0
		kill_accounting(g)
	}
	return combat_ends
}

pistol_shot :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if g.weapon_type != 1 do return false
	if g.qty_battery < 1 do return false
	if g.stamina < PISTOL_STAMINA do return false
	g.turn_count += 1
	g.stamina -= PISTOL_STAMINA
	g.qty_battery -= 1
	pistol_dmg := g.base_attack + PISTOL_BASE_BONUS + comp_atk_bonus(g)
	if g.player_atk_buff_dur > 0 do pistol_dmg += ATK_BUFF_BONUS
	combat_ends := resolve_combat_hit(g, pistol_dmg)
	if combat_ends {
		g.combo_count = 0
	}
	return true
}

combat_attack :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !uses_blade(g) do return false
	cost := blade_attack_stamina(g)
	if g.stamina < cost do return false
	g.turn_count += 1
	g.stamina -= cost
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
	g.qty_potion -= 1
	// Heal first
	g.hp = min(g.hp + POTION_HEAL, g.max_hp)
	// Enemy gets a free hit (plus player poison tick)
	enemy_dmg := enemy_free_hit_damage(g, enchant_def_bonus(g))
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	g.hp = max(g.hp - enemy_dmg - poison_dmg, 0)
	g.combo_count = 0
	if g.hp <= 0 {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		g.enemy_element = 0
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
	return true
}

flee_combat :: proc(g: ^Game_State) -> bool {
	if !g.in_combat || g.game_won || g.hp <= 0 do return false
	g.turn_count += 1
	flee_dmg := g.enemy_attack - enchant_def_bonus(g)
	if flee_dmg < 1 do flee_dmg = 1
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	// Flee should not kill — clamp HP to 1 minimum so escape hatch remains.
	new_hp := g.hp - flee_dmg - poison_dmg
	if new_hp < 1 do new_hp = 1
	g.hp = new_hp
	g.in_combat = false
	g.enemy_hp = 0
	g.enemy_attack = 0
	g.enemy_element = 0
	g.player_poison_dur = 0
	g.player_atk_buff_dur = 0
	g.player_def_buff_dur = 0
	g.enemy_poison_dur = 0
	g.combo_count = 0

	reset_cooldowns(g)
	return true
}

use_bomb :: proc(g: ^Game_State) -> bool {
	if !g.in_combat || g.game_won || g.qty_bomb <= 0 || g.hp <= 0 do return false
	g.turn_count += 1
	g.qty_bomb -= 1
	new_enemy_hp := g.enemy_hp - BOMB_DAMAGE
	if new_enemy_hp < 0 do new_enemy_hp = 0
	g.enemy_hp = new_enemy_hp
	combat_ends := (new_enemy_hp <= 0)
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	if !combat_ends {
		enemy_dmg := enemy_free_hit_damage(g, enchant_def_bonus(g))
		g.hp = max(g.hp - enemy_dmg - poison_dmg, 0)
	} else {
		g.hp = max(g.hp - poison_dmg, 0)
	}
	g.combo_count = 0
	if g.hp <= 0 || combat_ends {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		g.enemy_element = 0
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
	return true
}

use_smoke :: proc(g: ^Game_State) -> bool {
	if !g.in_combat || g.game_won || g.qty_smoke <= 0 || g.hp <= 0 do return false
	g.turn_count += 1
	g.qty_smoke -= 1
	g.in_combat = false
	g.enemy_hp = 0
	g.enemy_attack = 0
	g.enemy_element = 0
	g.player_poison_dur = 0
	g.player_atk_buff_dur = 0
	g.player_def_buff_dur = 0
	g.enemy_poison_dur = 0
	g.combo_count = 0
	reset_cooldowns(g)
	return true
}

use_antidote :: proc(g: ^Game_State) -> bool {
	if !g.in_combat || g.game_won || g.hp <= 0 do return false
	if g.qty_potion <= 0 || g.player_poison_dur <= 0 do return false
	g.turn_count += 1
	g.qty_potion -= 1
	// Poison cleared this turn — no player poison tick this action.
	g.player_poison_dur = 0
	// Enemy gets a free hit
	enemy_dmg := enemy_free_hit_damage(g, enchant_def_bonus(g))
	g.hp = max(g.hp - enemy_dmg, 0)
	g.combo_count = 0
	if g.hp <= 0 {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		g.enemy_element = 0
		g.player_atk_buff_dur = 0
		g.player_def_buff_dur = 0
		g.enemy_poison_dur = 0
		reset_cooldowns(g)
	} else {
		if g.player_atk_buff_dur > 0 do g.player_atk_buff_dur -= 1
		if g.player_def_buff_dur > 0 do g.player_def_buff_dur -= 1
		if g.enemy_poison_dur > 0 do g.enemy_poison_dur -= 1
		tick_cooldowns(g)
	}
	return true
}

poison_strike :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !uses_blade(g) do return false
	if !g.skill_poison do return false
	if g.qty_venom_sac <= 0 do return false
	cost := blade_attack_stamina(g)
	if g.stamina < cost do return false
	g.turn_count += 1
	g.stamina -= cost
	g.qty_venom_sac -= 1
	enemy_dmg := enemy_free_hit_damage(g, enchant_def_bonus(g))
	g.hp = max(g.hp - enemy_dmg, 0)
	if g.hp <= 0 {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		g.enemy_element = 0
		g.player_poison_dur = 0
		g.player_atk_buff_dur = 0
		g.player_def_buff_dur = 0
		g.enemy_poison_dur = 0
		reset_cooldowns(g)
	} else {
		// Refresh (not overwrite): allows re-cast on already-poisoned enemy.
		if g.enemy_poison_dur < STATUS_DURATION do g.enemy_poison_dur = STATUS_DURATION
		tick_cooldowns(g)
	}
	g.combo_count = 0

	return true
}

combo_attack :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !uses_blade(g) do return false
	if !g.skill_combo do return false
	if g.combo_count >= MAX_COMBO_CHAIN do return false
	cost := blade_combo_stamina(g)
	if g.stamina < cost do return false
	g.turn_count += 1
	g.stamina -= cost

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

	pre_venom := g.qty_venom_sac
	pre_skill_poison := g.skill_poison
	combat_ends := resolve_combat_hit(g, combo_dmg)

	// Passive venom infusion: skill_poison turns combos into a venom carrier.
	if !combat_ends && pre_skill_poison && pre_venom > 0 {
		g.enemy_poison_dur = STATUS_DURATION
		g.qty_venom_sac -= 1
	}

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
	if !uses_blade(g) do return false
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

	pre_venom := g.qty_venom_sac
	pre_skill_poison := g.skill_poison
	combat_ends := resolve_combat_hit(g, heavy_dmg)

	// Passive venom infusion: skill_poison turns heavy into a venom carrier.
	if !combat_ends && pre_skill_poison && pre_venom > 0 {
		g.enemy_poison_dur = STATUS_DURATION
		g.qty_venom_sac -= 1
	}

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
	if !uses_blade(g) do return false
	if !g.skill_battle_cry do return false
	if g.cd_battle_cry != 0 do return false
	if g.stamina < BATTLE_CRY_STAMINA do return false
	g.turn_count += 1
	g.stamina -= BATTLE_CRY_STAMINA

	// Battle cry is a pure setup move — enemy does NOT retaliate (only poison ticks).
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	g.hp = max(g.hp - poison_dmg, 0)

	combat_ends := (g.hp <= 0)

	if combat_ends {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		g.enemy_element = 0
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
	if !uses_blade(g) do return false
	if !g.skill_shield_block do return false
	if g.stamina < SHIELD_BLOCK_STAMINA do return false
	g.turn_count += 1
	g.stamina -= SHIELD_BLOCK_STAMINA

	enemy_dmg := enemy_free_hit_damage(g, enchant_def_bonus(g))
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	g.hp = max(g.hp - enemy_dmg - poison_dmg, 0)

	combat_ends := (g.hp <= 0)

	if combat_ends {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		g.enemy_element = 0
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

	// Shield wear: shield_block degrades shield durability. Break at 0.
	if g.has_shield {
		g.shield_dur -= 1
		if g.shield_dur <= 0 {
			g.has_shield = false
			g.shield_dur = 0
		}
	}

	return true
}

// --- Skill unlock procs ---


counter_attack :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !uses_blade(g) do return false
	if !g.skill_counter_attack do return false
	if g.stamina < COUNTER_STAMINA do return false
	g.turn_count += 1
	g.stamina -= COUNTER_STAMINA

	// Counter-attack is a retaliatory strike — deals HALF attack power (min 1).
	// Compute elemental multiplier BEFORE sword break, matching spec's pre-state read.
	dmg := attack_power(g) / 2
	if dmg < 1 do dmg = 1
	elem_mult := damage_multiplier(player_element(g), g.enemy_element)
	pre_enchant_def := enchant_def_bonus(g)
	if g.has_sword && g.sword_dur > 0 {
		g.sword_dur -= 1
		if g.sword_dur == 0 {
			g.enchant_slot_1 = 0
			g.enchant_slot_2 = 0
			g.enchant_slot_3 = 0
		}
	}

	// Enemy takes elemental-modified hit + poison
	enemy_poison_dmg := POISON_DMG if g.enemy_poison_dur > 0 else 0
	elem_dmg := effective_damage(dmg, elem_mult)
	new_enemy_hp := g.enemy_hp - elem_dmg - enemy_poison_dmg
	g.enemy_hp = max(new_enemy_hp, 0)

	enemy_dmg := enemy_free_hit_damage(g, pre_enchant_def)
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
			g.enemy_element = 0
			g.player_poison_dur = 0
			g.player_atk_buff_dur = 0
			g.player_def_buff_dur = 0
			g.enemy_poison_dur = 0
			reset_cooldowns(g)
		} else {
			// Enemy defeated, player alive
			g.in_combat = false
			g.enemy_attack = 0
			g.enemy_element = 0
			g.player_poison_dur = 0
			g.player_atk_buff_dur = 0
			g.player_def_buff_dur = 0
			g.enemy_poison_dur = 0
			reset_cooldowns(g)
			kill_accounting(g)
		}
	} else {
		// Grant DEF + ATK buffs on counter (atk buff differentiates from shield_block)
		g.player_def_buff_dur = STATUS_DURATION
		g.player_atk_buff_dur = STATUS_DURATION
		// Tick statuses
		zone_tier := zone_level(g.pos_x, g.pos_y)
		if zone_tier >= POISON_APPLY_TIER && g.player_poison_dur == 0 {
			g.player_poison_dur = STATUS_DURATION
		} else if g.player_poison_dur > 0 {
			g.player_poison_dur -= 1
		}
		if g.enemy_poison_dur > 0 do g.enemy_poison_dur -= 1
		tick_cooldowns(g)
	}
	g.combo_count = 0
	return true
}

fortify :: proc(g: ^Game_State) -> bool {
	if !can_act_combat(g) do return false
	if !uses_blade(g) do return false
	if !g.skill_fortify do return false
	if g.cd_fortify != 0 do return false
	if g.stamina < FORTIFY_STAMINA do return false
	g.turn_count += 1
	g.stamina -= FORTIFY_STAMINA

	enemy_dmg := enemy_free_hit_damage(g, enchant_def_bonus(g))
	poison_dmg := POISON_DMG if g.player_poison_dur > 0 else 0
	g.hp = max(g.hp - enemy_dmg - poison_dmg, 0)

	combat_ends := (g.hp <= 0)

	if combat_ends {
		g.in_combat = false
		g.enemy_hp = 0
		g.enemy_attack = 0
		g.enemy_element = 0
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

