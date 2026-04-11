package quint_crawl_game

import qc "../quint_crawl"
import rl "vendor:raylib"
import "core:fmt"
import "core:math"

draw_combat :: proc(app: ^App_State) {
	g := &app.game
	tier := qc.zone_level_req(g.pos_x, g.pos_y) - 1

	// Combat background
	rl.DrawRectangle(0, 0, HUD_X, WINDOW_H, COMBAT_BG)

	// Zone name at top
	zone := qc.zone_name(g.pos_x, g.pos_y)
	rl.DrawText(fmt.ctprintf("Battle in %s", zone), 20, 10, 18, TEXT_DIM)

	// --- Enemy section (top half) ---
	enemy_cx := f32(HUD_X) / 2
	enemy_cy := f32(200)

	// Enemy name
	name := ENEMY_NAMES[tier]
	rl.DrawText(fmt.ctprintf("%s", name), i32(enemy_cx) - 40, 60, 28, ENEMY_COLORS[tier])

	// Enemy shape with shake + dissolve on death
	shake := app.shake_timer * 20 if app.shake_timer > 0 else 0
	if app.dissolve_timer > 0 {
		// Dissolve effect: fade + scatter particles
		progress := 1.0 - (app.dissolve_timer / 0.5) // 0 → 1 as dissolve completes
		alpha := u8(255.0 * (1.0 - progress))
		// Draw fading enemy
		color := ENEMY_COLORS[tier]
		color.a = alpha
		draw_enemy_shape_tinted(enemy_cx, enemy_cy, tier, shake + progress * 10, alpha)
		// Scatter particles rising from enemy position
		for i in 0..<8 {
			fi := f32(i)
			px := enemy_cx + math.sin(fi * 1.7 + progress * 5) * (30 + progress * 60)
			py := enemy_cy - progress * (40 + fi * 15)
			p_alpha := u8(f32(alpha) * (1.0 - fi / 8.0))
			rl.DrawCircle(i32(px), i32(py), 3.0 - progress * 2, {color.r, color.g, color.b, p_alpha})
		}
	} else {
		draw_enemy_shape(enemy_cx, enemy_cy, tier, shake)
	}

	// Enemy HP bar
	bar_x := i32(enemy_cx) - 100
	bar_y := i32(320)
	rl.DrawText("Enemy HP", bar_x, bar_y - 18, 14, TEXT_DIM)
	enemy_max_hp := qc.ZONE_ENEMY_HP[tier]
	draw_bar(bar_x, bar_y, 200, 20, g.enemy_hp, enemy_max_hp, ENEMY_COLORS[tier], BAR_HP_BG)
	hp_str := fmt.ctprintf("%d/%d", g.enemy_hp, enemy_max_hp)
	hp_w := rl.MeasureText(hp_str, 14)
	rl.DrawText(hp_str, bar_x + (200 - hp_w) / 2, bar_y + 3, 14, TEXT_BRIGHT)

	// --- Divider ---
	rl.DrawLine(40, 370, HUD_X - 40, 370, TILE_BORDER)

	// --- Player section (bottom half) ---
	player_cy := i32(420)

	// Player diamond
	diamond_x := f32(100)
	diamond_y := f32(player_cy + 40)
	pulse := math.sin(app.pulse_timer) * 3
	rl.DrawPoly({diamond_x, diamond_y}, 4, 20 + pulse, 45, PLAYER_COLOR)
	rl.DrawPoly({diamond_x, diamond_y}, 4, 15 + pulse, 45, {0, 180, 220, 255})
	rl.DrawText("You", 82, player_cy + 68, 16, PLAYER_COLOR)

	// Player HP bar
	rl.DrawText("Your HP", 200, player_cy, 14, TEXT_DIM)
	draw_bar(200, player_cy + 18, 200, 20, g.hp, g.max_hp, BAR_HP_FG, BAR_HP_BG)
	player_hp := fmt.ctprintf("%d/%d", g.hp, g.max_hp)
	player_hp_w := rl.MeasureText(player_hp, 14)
	rl.DrawText(player_hp, 200 + (200 - player_hp_w) / 2, player_cy + 21, 14, TEXT_BRIGHT)

	// Player ATK
	atk := qc.attack_power(g)
	rl.DrawText(fmt.ctprintf("ATK: %d", atk), 200, player_cy + 48, 16, TEXT_BRIGHT)

	// --- Combat actions ---
	action_y := i32(560)
	rl.DrawLine(40, action_y - 10, HUD_X - 40, action_y - 10, TILE_BORDER)

	// Attack
	rl.DrawText("[A]", 60, action_y, 20, KEY_HIGHLIGHT)
	rl.DrawText("Attack", 100, action_y, 20, TEXT_BRIGHT)

	// Potion
	pot_color := KEY_HIGHLIGHT if g.qty_potion > 0 else rl.Color{60, 60, 70, 255}
	pot_text_color := TEXT_BRIGHT if g.qty_potion > 0 else rl.Color{60, 60, 70, 255}
	rl.DrawText("[P]", 230, action_y, 20, pot_color)
	rl.DrawText(fmt.ctprintf("Potion (%d)", g.qty_potion), 270, action_y, 20, pot_text_color)

	// Flee
	rl.DrawText("[F]", 470, action_y, 20, {255, 180, 100, 255})
	rl.DrawText("Flee", 510, action_y, 20, {255, 180, 100, 255})

	// Flash overlay for hit feedback
	if app.flash_timer > 0 {
		alpha := u8(f32(app.flash_color.a) * (app.flash_timer / 0.15))
		rl.DrawRectangle(0, 0, HUD_X, WINDOW_H, {app.flash_color.r, app.flash_color.g, app.flash_color.b, alpha})
	}

	// Combat hint
	rl.DrawText("Space also attacks  |  Esc also flees", 140, WINDOW_H - 30, 12, TEXT_DIM)
}
