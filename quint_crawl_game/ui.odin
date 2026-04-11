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
	xp_target := qc.XP_THRESHOLDS[g.level + 1] if g.level < 3 else g.xp
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
	draw_bar(x, y, w, 16, g.stamina, g.max_stamina, {50, 200, 120, 255}, {20, 60, 40, 255})
	sta_str := fmt.ctprintf("%d/%d", g.stamina, g.max_stamina)
	sta_w := rl.MeasureText(sta_str, 12)
	rl.DrawText(sta_str, x + (w - sta_w) / 2, y + 2, 12, TEXT_BRIGHT)
	y += 24

	// Attack
	atk := qc.attack_power(g)
	if g.has_sword {
		rl.DrawText(fmt.ctprintf("ATK: %d (%d+5)", atk, g.base_attack), x, y, 16, TEXT_BRIGHT)
	} else {
		rl.DrawText(fmt.ctprintf("ATK: %d", atk), x, y, 16, TEXT_BRIGHT)
	}
	y += 22

	// Gold
	rl.DrawText(fmt.ctprintf("Gold: %d", g.gold), x, y, 16, TEXT_GOLD)
	y += 30

	// --- Inventory ---
	rl.DrawLine(x, y, x + w, y, TILE_BORDER)
	y += 6
	rl.DrawText("Inventory", x, y, 16, TEXT_DIM)
	y += 22

	rl.DrawText(fmt.ctprintf("Potions: %d", g.qty_potion), x + 8, y, 14, TEXT_BRIGHT)
	y += 18
	rl.DrawText(fmt.ctprintf("Wood: %d", g.qty_wood), x + 8, y, 14, TEXT_BRIGHT)
	y += 18
	rl.DrawText(fmt.ctprintf("Iron: %d", g.qty_iron), x + 8, y, 14, TEXT_BRIGHT)
	y += 18
	rl.DrawText(fmt.ctprintf("Swords: %d", g.qty_sword), x + 8, y, 14, TEXT_BRIGHT)
	y += 18

	if g.has_sword {
		dur_color := TEXT_BRIGHT if g.sword_dur > 3 else BAR_HP_FG
		rl.DrawText(fmt.ctprintf("Sword: %d/%d dur", g.sword_dur, g.sword_max_dur), x + 8, y, 14, dur_color)
	} else {
		rl.DrawText("Equipped: None", x + 8, y, 14, TEXT_DIM)
	}
	y += 26

	// --- Zone info ---
	rl.DrawLine(x, y, x + w, y, TILE_BORDER)
	y += 6
	zone := qc.zone_name(g.pos_x, g.pos_y)
	zlvl := qc.zone_level_req(g.pos_x, g.pos_y)
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

		draw_action(x, &y, "[E]", "Fight", true)

		// Village actions
		if g.pos_x == 0 && g.pos_y == 0 {
			draw_action(x, &y, "[R]", "Rest", g.hp < g.max_hp || g.stamina < g.max_stamina)
			draw_action(x, &y, "[B]", "Buy Potion (10g)", g.gold >= 10)
			draw_action(x, &y, "[C]", "Craft Sword", g.qty_wood >= 1 && g.qty_iron >= 2)
			if g.has_sword && g.sword_dur < g.sword_max_dur {
				draw_action(x, &y, "[T]", fmt.ctprintf("Repair Sword (%dg)", qc.REPAIR_COST), g.gold >= qc.REPAIR_COST)
			}
		}
		// Forest
		if g.pos_x == 1 && g.pos_y == 0 {
			draw_action(x, &y, "[G]", "Gather Wood", true)
		}
		// Mountain
		if g.pos_x == 2 && g.pos_y == 1 {
			draw_action(x, &y, "[M]", "Mine Iron", true)
		}
		// Equip (anywhere)
		if g.qty_sword >= 1 && !g.has_sword {
			draw_action(x, &y, "[Q]", "Equip Sword", true)
		}

		// Save/Load
		draw_action(x, &y, "[F5]", "Save", true)
		draw_action(x, &y, "[F9]", "Load", g.saved_exists)

		y += 4
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
