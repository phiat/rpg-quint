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

	// Title
	rl.DrawText("QUINT CRAWL", x, y, 20, PLAYER_COLOR)
	y += 30

	// Level
	rl.DrawText(fmt.ctprintf("Level %d", g.level), x, y, 22, TEXT_GOLD)
	y += 30

	// HP bar
	rl.DrawText("HP", x, y, 14, TEXT_DIM)
	y += 16
	draw_bar(x, y, w, 16, g.hp, g.max_hp, BAR_HP_FG, BAR_HP_BG)
	hp_str := fmt.ctprintf("%d/%d", g.hp, g.max_hp)
	hp_w := rl.MeasureText(hp_str, 12)
	rl.DrawText(hp_str, x + (w - hp_w) / 2, y + 2, 12, TEXT_BRIGHT)
	y += 24

	// XP bar
	xp_target := qc.XP_THRESHOLDS[g.level + 1] if g.level < qc.MAX_LEVEL else g.xp
	rl.DrawText("XP", x, y, 14, TEXT_DIM)
	y += 16
	draw_bar(x, y, w, 16, g.xp, xp_target, BAR_XP_FG, BAR_XP_BG)
	xp_str := fmt.ctprintf("%d/%d", g.xp, xp_target)
	xp_w := rl.MeasureText(xp_str, 12)
	rl.DrawText(xp_str, x + (w - xp_w) / 2, y + 2, 12, TEXT_BRIGHT)
	y += 24

	// Stamina bar
	rl.DrawText("STA", x, y, 14, TEXT_DIM)
	y += 16
	draw_bar(x, y, w, 16, g.stamina, g.max_stamina, BAR_STAMINA_FG, BAR_STAMINA_BG)
	sta_str := fmt.ctprintf("%d/%d", g.stamina, g.max_stamina)
	sta_w := rl.MeasureText(sta_str, 12)
	rl.DrawText(sta_str, x + (w - sta_w) / 2, y + 2, 12, TEXT_BRIGHT)
	y += 24

	// Attack
	atk := qc.attack_power(g)
	if g.has_sword {
		rl.DrawText(fmt.ctprintf("ATK: %d (%d+%d)", atk, g.base_attack, qc.SWORD_ATK_BONUS), x, y, 16, TEXT_BRIGHT)
	} else {
		rl.DrawText(fmt.ctprintf("ATK: %d", atk), x, y, 16, TEXT_BRIGHT)
	}
	y += 22

	// Gold
	rl.DrawText(fmt.ctprintf("Gold: %d", g.gold), x, y, 16, TEXT_GOLD)
	y += 20

	// Skill points
	if g.skill_points > 0 {
		rl.DrawText(fmt.ctprintf("Skill Pts: %d", g.skill_points), x, y, 16, {255, 220, 50, 255})
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
	} else {
		rl.DrawText("Equipped: None", x + 8, y, 14, TEXT_DIM)
	}
	y += 26

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

	// --- Available actions ---
	if !g.in_combat && !g.game_won && g.hp > 0 {
		rl.DrawLine(x, y, x + w, y, TILE_BORDER)
		y += 6
		rl.DrawText("Actions", x, y, 16, TEXT_DIM)
		y += 22

		draw_action :: proc(x: i32, y: ^i32, key: cstring, label: cstring, available: bool) {
			color := KEY_HIGHLIGHT if available else rl.Color{60, 60, 70, 255}
			text_color := TEXT_BRIGHT if available else rl.Color{60, 60, 70, 255}
			rl.DrawText(key, x, y^, 14, color)
			rl.DrawText(label, x + 28, y^, 14, text_color)
			y^ += 18
		}

		can_fight := g.last_kill_turn == 0 || g.turn_count - g.last_kill_turn >= qc.RESPAWN_TURNS
		if can_fight {
			draw_action(x, &y, "[E]", "Fight", true)
		} else {
			remaining := qc.RESPAWN_TURNS - (g.turn_count - g.last_kill_turn)
			draw_action(x, &y, "[E]", fmt.ctprintf("Respawn in %d turns", remaining), false)
		}

		// Town actions
		if qc.zone_has_services(g.pos_x, g.pos_y) {
			draw_action(x, &y, "[R]", "Rest", g.hp < g.max_hp || g.stamina < g.max_stamina)
			draw_action(x, &y, "[B]", fmt.ctprintf("Buy Potion (%dg)", qc.POTION_COST), g.gold >= qc.POTION_COST)
			draw_action(x, &y, "[C]", fmt.ctprintf("Craft Sword (Lv%d)", qc.CRAFT_LEVEL_REQ), g.level >= qc.CRAFT_LEVEL_REQ && g.qty_wood >= qc.CRAFT_WOOD_COST && g.qty_iron >= qc.CRAFT_IRON_COST)
			if g.has_sword && g.sword_dur < g.sword_max_dur {
				draw_action(x, &y, "[T]", fmt.ctprintf("Repair Sword (%dg)", qc.REPAIR_COST), g.gold >= qc.REPAIR_COST)
			}
			draw_action(x, &y, "[O]", fmt.ctprintf("Craft Venom (%di)", qc.CRAFT_VENOM_IRON_COST), g.qty_iron >= qc.CRAFT_VENOM_IRON_COST)
			draw_action(x, &y, "[U]", fmt.ctprintf("Respec (%dg)", qc.RESPEC_COST), g.gold >= qc.RESPEC_COST)
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

		// Claim Victory (on Castle biome at max level)
		if g.level >= qc.MAX_LEVEL && g.pos_x % 3 == 2 && g.pos_y % 3 == 2 && qc.zone_level(g.pos_x, g.pos_y) >= qc.MAX_LEVEL {
			draw_action(x, &y, "[L]", "Claim Victory!", true)
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
