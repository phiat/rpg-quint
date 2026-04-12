package quint_crawl_game

import qc "../quint_crawl"
import rl "vendor:raylib"
import "core:fmt"
import "core:math"

// --- HUD sidebar ---
draw_hud :: proc(app: ^App_State) {
	g := &app.game

	// Background
	rl.DrawRectangle(HUD_X, 0, HUD_W, WINDOW_H, HUD_BG)
	rl.DrawLine(HUD_X, 0, HUD_X, WINDOW_H, TILE_BORDER)

	x := i32(HUD_X + HUD_PAD)
	y := i32(HUD_PAD)
	w := i32(HUD_W - HUD_PAD * 2)

	// Title + level (one row)
	rl.DrawText("QUINT CRAWL", x, y, 18, PLAYER_COLOR)
	rl.DrawText(fmt.ctprintf("Lv %d", g.level), x + w - 50, y, 18, TEXT_GOLD)
	y += 24

	// Inline label+bar helper
	label_w := i32(32)
	bar_w := w - label_w
	draw_inline_bar :: proc(x, y, label_w, bar_w: i32, label: cstring, cur, mx: int, fg, bg: rl.Color) {
		rl.DrawText(label, x, y + 2, 13, TEXT_DIM)
		draw_bar(x + label_w, y, bar_w, 16, cur, mx, fg, bg)
		s := fmt.ctprintf("%d/%d", cur, mx)
		sw := rl.MeasureText(s, 12)
		rl.DrawText(s, x + label_w + (bar_w - sw) / 2, y + 2, 12, TEXT_BRIGHT)
	}

	draw_inline_bar(x, y, label_w, bar_w, "HP", g.hp, g.max_hp, BAR_HP_FG, BAR_HP_BG)
	y += 20

	xp_target := qc.XP_THRESHOLDS[g.level + 1] if g.level < qc.MAX_LEVEL else g.xp
	draw_inline_bar(x, y, label_w, bar_w, "XP", g.xp, xp_target, BAR_XP_FG, BAR_XP_BG)
	y += 20

	draw_inline_bar(x, y, label_w, bar_w, "STA", g.stamina, g.max_stamina, BAR_STAMINA_FG, BAR_STAMINA_BG)
	y += 20

	if g.skill_magic {
		draw_inline_bar(x, y, label_w, bar_w, "MP", g.mana, g.max_mana, {100, 140, 255, 255}, {30, 40, 80, 255})
		y += 20
	}

	// ATK / DEF inline
	atk := qc.attack_power(g)
	def := qc.enchant_def_bonus(g) + (qc.SHIELD_DEF if g.has_shield else 0) + qc.comp_dmg_reduction(g)
	rl.DrawText(fmt.ctprintf("ATK: %d", atk), x, y, 14, TEXT_BRIGHT)
	rl.DrawText(fmt.ctprintf("DEF: %d", def), x + w / 2, y, 14, TEXT_BRIGHT)
	y += 18

	// Gold + skill points inline
	rl.DrawText(fmt.ctprintf("Gold: %d", g.gold), x, y, 14, TEXT_GOLD)
	if g.skill_points > 0 {
		rl.DrawText(fmt.ctprintf("SP: %d", g.skill_points), x + w / 2, y, 14, {255, 220, 50, 255})
	}
	y += 20

	// --- Inventory ---
	rl.DrawLine(x, y, x + w, y, TILE_BORDER)
	y += 6
	items := qc.total_items(g)
	rl.DrawText(fmt.ctprintf("Inventory (%d/%d)", items, qc.MAX_INVENTORY), x, y, 16, TEXT_DIM)
	y += 22

	rl.DrawText(fmt.ctprintf("Potions: %d", g.qty_potion), x + 8, y, 14, TEXT_BRIGHT)
	y += 18
	rl.DrawText(fmt.ctprintf("Wood: %d", g.qty_wood), x + 8, y, 14, TEXT_BRIGHT)
	y += 18
	rl.DrawText(fmt.ctprintf("Iron: %d", g.qty_iron), x + 8, y, 14, TEXT_BRIGHT)
	y += 18
	rl.DrawText(fmt.ctprintf("Swords: %d", g.qty_sword), x + 8, y, 14, TEXT_BRIGHT)
	y += 18
	if g.qty_venom_sac > 0 {
		rl.DrawText(fmt.ctprintf("Venom Sacs: %d", g.qty_venom_sac), x + 8, y, 14, {100, 220, 50, 255})
		y += 18
	}
	// Trait-keyed archetype drops (shown only when non-zero)
	if g.qty_holy_dust > 0 {
		rl.DrawText(fmt.ctprintf("Holy Dust: %d", g.qty_holy_dust), x + 8, y, 14, {240, 230, 170, 255})
		y += 18
	}
	if g.qty_pelt > 0 {
		rl.DrawText(fmt.ctprintf("Pelts: %d", g.qty_pelt), x + 8, y, 14, {200, 150, 90, 255})
		y += 18
	}
	if g.qty_core > 0 {
		rl.DrawText(fmt.ctprintf("Cores: %d", g.qty_core), x + 8, y, 14, {160, 180, 220, 255})
		y += 18
	}
	if g.qty_essence > 0 {
		rl.DrawText(fmt.ctprintf("Essence: %d", g.qty_essence), x + 8, y, 14, {180, 140, 230, 255})
		y += 18
	}
	if g.qty_coin > 0 {
		rl.DrawText(fmt.ctprintf("Trophy Coins: %d", g.qty_coin), x + 8, y, 14, {220, 200, 120, 255})
		y += 18
	}
	if g.qty_ichor > 0 {
		rl.DrawText(fmt.ctprintf("Ichor: %d", g.qty_ichor), x + 8, y, 14, {140, 200, 140, 255})
		y += 18
	}

	// Holy Water (inventory, shown only when non-zero)
	if g.qty_holy_water > 0 {
		rl.DrawText(fmt.ctprintf("Holy Water: %d", g.qty_holy_water), x + 8, y, 14, {220, 240, 255, 255})
		y += 18
	}

	// Weapon (reflects weapon_type: 0=sword, 1=pistol, 2=staff)
	if g.has_sword {
		dur_color := TEXT_BRIGHT if g.sword_dur > 3 else BAR_HP_FG
		rl.DrawText(fmt.ctprintf("Sword: %d/%d dur", g.sword_dur, g.sword_max_dur), x + 8, y, 14, dur_color)
		y += 18
		// Enchantment slots
		slots := [3]int{g.enchant_slot_1, g.enchant_slot_2, g.enchant_slot_3}
		has_any_enchant := g.enchant_slot_1 > 0 || g.enchant_slot_2 > 0 || g.enchant_slot_3 > 0
		if has_any_enchant {
			for i in 0..<3 {
				if slots[i] > 0 {
					rl.DrawText(fmt.ctprintf("  E%d: %s", i + 1, ENCH_NAMES[slots[i]]), x + 8, y, 12, ENCH_COLORS[slots[i]])
					y += 15
				}
			}
			atk_bonus := qc.enchant_atk_bonus(g)
			def_bonus := qc.enchant_def_bonus(g)
			if atk_bonus > 0 || def_bonus > 0 {
				rl.DrawText(fmt.ctprintf("  Bonus: +%d ATK, +%d DEF", atk_bonus, def_bonus), x + 8, y, 12, {200, 180, 100, 255})
				y += 15
			}
		}
	} else if g.weapon_type == 1 {
		rl.DrawText("Pistol equipped", x + 8, y, 14, {200, 180, 255, 255})
		y += 18
	} else if g.weapon_type == 2 {
		rl.DrawText("Staff equipped", x + 8, y, 14, {140, 200, 255, 255})
		y += 18
	} else {
		rl.DrawText("Equipped: None", x + 8, y, 14, TEXT_DIM)
		y += 18
	}

	// Shield slot
	if g.has_shield {
		dur_color := TEXT_BRIGHT if g.shield_dur > 2 else BAR_HP_FG
		rl.DrawText(fmt.ctprintf("Shield: %d/%d dur", g.shield_dur, qc.SHIELD_MAX_DUR), x + 8, y, 14, dur_color)
		y += 18
	}

	// Armor slot
	if g.has_armor {
		dur_color := TEXT_BRIGHT if g.armor_dur > 3 else BAR_HP_FG
		rl.DrawText(fmt.ctprintf("Armor: %d/%d dur", g.armor_dur, qc.ARMOR_MAX_DUR), x + 8, y, 14, dur_color)
		y += 18
	}

	// Trinket slot
	if g.trinket == 1 {
		rl.DrawText("Trinket: Vitality (+HP)", x + 8, y, 14, {220, 200, 255, 255})
		y += 18
	}
	y += 8

	// --- Zone info ---
	rl.DrawLine(x, y, x + w, y, TILE_BORDER)
	y += 6
	zone := qc.zone_name(g.pos_x, g.pos_y)
	zlvl := qc.zone_level(g.pos_x, g.pos_y)
	rl.DrawText(fmt.ctprintf("%s (Lv.%d)", zone, zlvl), x, y, 16, TEXT_BRIGHT)
	y += 20

	// Turn count
	rl.DrawText(fmt.ctprintf("Turn: %d", g.turn_count), x + 8, y, 13, TEXT_DIM)
	y += 16

	// Weather
	weather := qc.zone_weather(g.pos_x, g.pos_y, g.turn_count)
	weather_name: cstring
	weather_color: rl.Color
	switch weather {
	case 0: weather_name = "Clear"; weather_color = {200, 200, 100, 255}
	case 1: weather_name = "Rain (+gather)"; weather_color = {100, 150, 255, 255}
	case 2: weather_name = "Fog (-enemy atk)"; weather_color = {180, 180, 200, 255}
	case 3: weather_name = "Storm (move dmg)"; weather_color = {255, 150, 50, 255}
	case: weather_name = "Clear"; weather_color = TEXT_DIM
	}
	rl.DrawText(weather_name, x + 8, y, 13, weather_color)
	y += 22

	// --- Quests ---
	rl.DrawLine(x, y, x + w, y, TILE_BORDER)
	y += 6
	rl.DrawText("Quests", x, y, 16, TEXT_DIM)
	y += 22
	draw_quest_line :: proc(x: i32, y: ^i32, label: cstring, cur, tgt: int, unlocked: bool) {
		if !unlocked {
			rl.DrawText(fmt.ctprintf("%s — locked", label), x + 8, y^, 13, rl.Color{80, 80, 90, 255})
		} else if cur >= tgt {
			rl.DrawText(fmt.ctprintf("%s — done", label), x + 8, y^, 13, rl.Color{120, 220, 120, 255})
		} else {
			rl.DrawText(fmt.ctprintf("%s %d/%d", label, cur, tgt), x + 8, y^, 13, TEXT_BRIGHT)
		}
		y^ += 16
	}
	q1_done := g.q1_kills >= qc.Q1_TARGET
	q2_done := q1_done && g.q2_zones >= qc.Q2_TARGET
	draw_quest_line(x, &y, "Slime Slayer", g.q1_kills, qc.Q1_TARGET, true)
	draw_quest_line(x, &y, "Venture Forth", g.q2_zones, qc.Q2_TARGET, q1_done)
	draw_quest_line(x, &y, "Castle Conqueror", g.q3_kills, qc.Q3_TARGET, q2_done)
	// Claim hint when the next unclaimed quest is complete
	claim_ready := false
	switch g.quest_rewards_claimed {
	case 0: claim_ready = q1_done
	case 1: claim_ready = q1_done && g.q2_zones >= qc.Q2_TARGET
	case 2: claim_ready = q1_done && g.q2_zones >= qc.Q2_TARGET && g.q3_kills >= qc.Q3_TARGET
	}
	if claim_ready {
		rl.DrawText("[TAB] Claim reward", x + 8, y, 13, TEXT_GOLD)
		y += 16
	}
	y += 4
	cq1_done := g.cq1_adopted >= qc.CQ1_TARGET
	cq2_done := cq1_done && g.cq2_maxed >= qc.CQ2_TARGET
	draw_quest_line(x, &y, "Adopt Companion", g.cq1_adopted, qc.CQ1_TARGET, true)
	draw_quest_line(x, &y, "Earn Loyalty", g.cq2_maxed, qc.CQ2_TARGET, cq1_done)
	draw_quest_line(x, &y, "Battle Bond", g.cq3_wins, qc.CQ3_TARGET, cq2_done)
	y += 8

	// --- Companion ---
	if g.comp_active {
		rl.DrawLine(x, y, x + w, y, TILE_BORDER)
		y += 6
		rl.DrawText("Companion", x, y, 16, TEXT_DIM)
		y += 22
		species_name: cstring = "Unknown"
		if g.comp_species >= 0 && g.comp_species < len(qc.SPECIES_DEFS) {
			species_name = fmt.ctprintf("%s", qc.SPECIES_DEFS[g.comp_species].name)
		}
		trait_name: cstring
		switch qc.Comp_Trait(g.comp_trait) {
		case .Attacker: trait_name = "Attacker"
		case .Defender: trait_name = "Defender"
		case .Scout:    trait_name = "Scout"
		case .Support:  trait_name = "Support"
		}
		rarity_name: cstring
		switch g.comp_rarity {
		case 0: rarity_name = "Common"
		case 1: rarity_name = "Rare"
		case 2: rarity_name = "Legendary"
		case:   rarity_name = "?"
		}
		rl.DrawText(fmt.ctprintf("%s (%s %s)", species_name, rarity_name, trait_name), x + 8, y, 13, TEXT_BRIGHT)
		y += 16
		rl.DrawText(fmt.ctprintf("Loyalty: %d/%d", g.comp_loyalty, qc.MAX_LOYALTY), x + 8, y, 13, TEXT_DIM)
		y += 16
		y += 4
	}

	// --- Available actions ---
	if !g.in_combat && !g.game_won && g.hp > 0 {
		rl.DrawLine(x, y, x + w, y, TILE_BORDER)
		y += 6
		rl.DrawText("Actions", x, y, 16, TEXT_DIM)
		y += 22

		draw_action :: proc(x: i32, y: ^i32, key: cstring, label: cstring, available: bool) {
			if !available do return
			rl.DrawText(key, x, y^, 14, KEY_HIGHLIGHT)
			rl.DrawText(label, x + 28, y^, 14, TEXT_BRIGHT)
			y^ += 18
		}

		// Treasure chest (one-time per chest zone)
		if qc.chest_present(g.pos_x, g.pos_y) && !g.chests_opened[g.pos_x][g.pos_y] {
			draw_action(x, &y, "[Z]", fmt.ctprintf("Open Chest (+%dg)", qc.chest_gold(g.pos_x, g.pos_y)), true)
		}

		can_fight := g.last_kill_turn == 0 || g.turn_count - g.last_kill_turn >= qc.RESPAWN_TURNS
		if can_fight {
			draw_action(x, &y, "[E]", "Fight", true)
		} else {
			remaining := qc.RESPAWN_TURNS - (g.turn_count - g.last_kill_turn)
			rl.DrawText(fmt.ctprintf("[E] Respawn in %d turns", remaining), x, y, 14, TEXT_DIM)
			y += 18
		}

		// Town actions
		if qc.zone_has_services(g.pos_x, g.pos_y) {
			draw_action(x, &y, "[R]", "Rest", g.hp < g.max_hp || g.stamina < g.max_stamina)
			draw_action(x, &y, "[B]", fmt.ctprintf("Buy Potion (%dg)", qc.POTION_COST), g.gold >= qc.POTION_COST)
			draw_action(x, &y, "[F]", fmt.ctprintf("Buy Bomb (%dg)", qc.BOMB_COST), g.gold >= qc.BOMB_COST)
			draw_action(x, &y, "[/]", fmt.ctprintf("Buy Smoke (%dg)", qc.SMOKE_COST), g.gold >= qc.SMOKE_COST)
			draw_action(x, &y, "[']", fmt.ctprintf("Buy Ration (%dg)", qc.RATION_COST), g.gold >= qc.RATION_COST)
			if !g.skill_magic {
				draw_action(x, &y, "[[]", fmt.ctprintf("Spellbook (%dg)", qc.SPELLBOOK_COST), g.gold >= qc.SPELLBOOK_COST)
			}
			draw_action(x, &y, "[C]", fmt.ctprintf("Craft Sword (Lv%d)", qc.CRAFT_LEVEL_REQ), g.level >= qc.CRAFT_LEVEL_REQ && g.qty_wood >= qc.CRAFT_WOOD_COST && g.qty_iron >= qc.CRAFT_IRON_COST)
			if g.has_sword && g.sword_dur < g.sword_max_dur {
				draw_action(x, &y, "[T]", fmt.ctprintf("Repair Sword (%dg)", qc.REPAIR_COST), g.gold >= qc.REPAIR_COST)
			}
			draw_action(x, &y, "[O]", fmt.ctprintf("Craft Venom (%di)", qc.CRAFT_VENOM_IRON_COST), g.qty_iron >= qc.CRAFT_VENOM_IRON_COST)
			if g.qty_holy_dust >= 1 {
				draw_action(x, &y, "[V]", fmt.ctprintf("Craft Holy Water (%dw)", qc.CRAFT_HOLY_WATER_WOOD), g.qty_wood >= qc.CRAFT_HOLY_WATER_WOOD)
			}
			if !g.has_shield {
				draw_action(x, &y, "[K]", fmt.ctprintf("Buy Shield (%dg)", qc.SHIELD_COST), g.gold >= qc.SHIELD_COST)
			}
			if !g.has_armor {
				draw_action(x, &y, "[H]", fmt.ctprintf("Buy Armor (%dg)", qc.ARMOR_COST), g.gold >= qc.ARMOR_COST)
			}
			if g.trinket == 0 {
				draw_action(x, &y, "[N]", fmt.ctprintf("Buy Trinket (%dg)", qc.TRINKET_COST), g.gold >= qc.TRINKET_COST)
			} else {
				draw_action(x, &y, "[X]", "Remove Trinket", true)
			}
			if g.has_sword && g.weapon_type == 0 && g.skill_magic {
				draw_action(x, &y, "[Y]", fmt.ctprintf("Equip Staff (%dg)", qc.STAFF_UNLOCK_COST), g.gold >= qc.STAFF_UNLOCK_COST)
			}
			if g.comp_active && g.comp_rarity < qc.COMP_RARITY_COUNT - 1 {
				train_cost := (g.comp_rarity + 2) * qc.TRAIN_COST
				draw_action(x, &y, "[P]", fmt.ctprintf("Train Companion (%dw)", train_cost), g.qty_wood >= train_cost)
			}
			draw_action(x, &y, "[U]", fmt.ctprintf("Respec (%dg)", qc.respec_cost(g)), g.gold >= qc.respec_cost(g))
			if g.qty_sword >= 1 {
				draw_action(x, &y, "[\\]", fmt.ctprintf("Salvage (Lv%d)", g.salvage_level), true)
			}
			if g.salvage_level < qc.MAX_SALVAGE_LEVEL {
				draw_action(x, &y, "[=]", fmt.ctprintf("Upgrade Salvage (%dg)", qc.UPGRADE_SALVAGE_COST), g.gold >= qc.UPGRADE_SALVAGE_COST)
			}
			if g.has_sword {
				draw_action(x, &y, "[8]", fmt.ctprintf("Enchant S1 (%dg)", qc.ENCHANT_COST), g.gold >= qc.ENCHANT_COST)
				draw_action(x, &y, "[9]", fmt.ctprintf("Enchant S2 (%dg)", qc.ENCHANT_COST), g.gold >= qc.ENCHANT_COST)
				draw_action(x, &y, "[0]", fmt.ctprintf("Enchant S3 (%dg)", qc.ENCHANT_COST), g.gold >= qc.ENCHANT_COST)
			}
		}
		// Forest
		if qc.zone_has_wood(g.pos_x, g.pos_y) {
			draw_action(x, &y, "[G]", "Gather Wood", true)
		}
		// Mountain
		if qc.zone_has_iron(g.pos_x, g.pos_y) {
			draw_action(x, &y, "[M]", "Mine Iron", true)
		}
		// Equip (anywhere)
		if g.qty_sword >= 1 && !g.has_sword {
			draw_action(x, &y, "[Q]", "Equip Sword", true)
		}
		if g.qty_holy_water >= 1 {
			draw_action(x, &y, "[I]", "Use Holy Water", g.hp < g.max_hp)
		}
		if g.qty_ration >= 1 {
			draw_action(x, &y, "[-]", "Eat Ration (+stam)", g.stamina < g.max_stamina)
		}

		// Castle: fight boss first, then claim victory
		if qc.is_castle_zone(g.pos_x, g.pos_y) && g.level >= qc.MAX_LEVEL {
			if !g.boss_defeated {
				draw_action(x, &y, "[E]", "Face the Castle Boss", true)
			} else {
				draw_action(x, &y, "[L]", "Claim Victory!", true)
			}
		}

		// Fast travel (if any waypoints besides current)
		has_waypoints := false
		for wx in 0 ..< qc.WORLD_SIZE {
			for wy in 0 ..< qc.WORLD_SIZE {
				if g.waypoints[wx][wy] && (wx != g.pos_x || wy != g.pos_y) {
					has_waypoints = true
				}
			}
		}
		if has_waypoints {
			draw_action(x, &y, "[J]", "Fast Travel", true)
		}

		// Save/Load
		draw_action(x, &y, "[F5]", "Save", true)
		draw_action(x, &y, "[F9]", "Load", g.saved_exists)

		// Skill unlocks (when points available)
		if g.skill_points > 0 {
			y += 4
			rl.DrawLine(x, y, x + w, y, TILE_BORDER)
			y += 6
			rl.DrawText("Skills", x, y, 14, {255, 220, 50, 255})
			y += 18
			if !g.skill_combo {
				draw_action(x, &y, "[1]", "Combo (1pt)", true)
			}
			if !g.skill_poison {
				draw_action(x, &y, "[2]", "Poison (1pt)", true)
			}
			if !g.skill_shield_block {
				draw_action(x, &y, "[3]", "Shield (1pt)", true)
			}
			if !g.skill_heavy_strike && g.skill_combo {
				draw_action(x, &y, "[4]", "Heavy (1pt)", true)
			}
			if !g.skill_counter_attack && g.skill_shield_block {
				draw_action(x, &y, "[5]", "Counter (1pt)", true)
			}
			if !g.skill_battle_cry && g.skill_heavy_strike && g.skill_points >= 2 {
				draw_action(x, &y, "[6]", "Warcry (2pt)", true)
			}
			if !g.skill_fortify && g.skill_counter_attack && g.skill_points >= 2 {
				draw_action(x, &y, "[7]", "Fortify (2pt)", true)
			}
		}

		y += 4
	}

	// --- Minimap (biome regions) ---
	if !g.in_combat {
		NUM_REGIONS :: qc.WORLD_SIZE / 3

		rl.DrawLine(x, y, x + w, y, TILE_BORDER)
		y += 6
		rl.DrawText("Region", x, y, 14, TEXT_DIM)
		y += 18

		mini_size := i32(20)
		mini_pad := i32(2)
		mini_x0 := x + (w - NUM_REGIONS * (mini_size + mini_pad)) / 2
		region_x := g.pos_x / 3
		region_y := g.pos_y / 3

		for ry in 0 ..< NUM_REGIONS {
			for rx in 0 ..< NUM_REGIONS {
				mx := mini_x0 + i32(rx) * (mini_size + mini_pad)
				my := y + i32(ry) * (mini_size + mini_pad)
				// Biome color for this region (tiled from 3x3 palette)
				base := BASE_ZONE_COLORS[rx % 3][ry % 3]
				is_here := rx == region_x && ry == region_y
				if !is_here {
					base.r = u8(f32(base.r) * 0.5)
					base.g = u8(f32(base.g) * 0.5)
					base.b = u8(f32(base.b) * 0.5)
				}
				rl.DrawRectangle(mx, my, mini_size, mini_size, base)
				if is_here {
					rl.DrawRectangleLinesEx({f32(mx), f32(my), f32(mini_size), f32(mini_size)}, 2, PLAYER_COLOR)
				} else {
					rl.DrawRectangleLines(mx, my, mini_size, mini_size, TILE_BORDER)
				}
			}
		}
		y += NUM_REGIONS * (mini_size + mini_pad) + 6
	}

	// --- Message log ---
	if len(app.messages) > 0 {
		rl.DrawLine(x, y, x + w, y, TILE_BORDER)
		y += 6
		rl.DrawText("Log", x, y, 14, TEXT_DIM)
		y += 18

		// Show messages bottom-up (newest at top)
		start := max(0, len(app.messages) - 5)
		for i in start ..< len(app.messages) {
			msg := &app.messages[i]
			alpha := u8(min(255, i32(msg.timer / MESSAGE_LIFETIME * 255)))
			color := rl.Color{msg.color.r, msg.color.g, msg.color.b, alpha}
			rl.DrawText(fmt.ctprintf("%s", msg.text), x + 4, y, 12, color)
			y += 15
		}
	}
}
