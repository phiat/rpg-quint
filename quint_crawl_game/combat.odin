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

	// Player ATK + sword durability
	atk := qc.attack_power(g)
	if g.has_sword {
		dur_color := TEXT_BRIGHT if g.sword_dur > 3 else BAR_HP_FG
		rl.DrawText(fmt.ctprintf("ATK: %d  Sword: %d/%d", atk, g.sword_dur, g.sword_max_dur), 200, player_cy + 48, 16, dur_color)
	} else {
		rl.DrawText(fmt.ctprintf("ATK: %d", atk), 200, player_cy + 48, 16, TEXT_BRIGHT)
	}

	// --- Status effects ---
	status_y := i32(500)
	if g.player_poison_dur > 0 {
		rl.DrawText(fmt.ctprintf("POISONED (%d)", g.player_poison_dur), 60, status_y, 16, {100, 220, 50, 255})
	}
	if g.player_atk_buff_dur > 0 {
		rl.DrawText(fmt.ctprintf("ATK+ (%d)", g.player_atk_buff_dur), 220, status_y, 16, {255, 200, 100, 255})
	}
	if g.player_def_buff_dur > 0 {
		rl.DrawText(fmt.ctprintf("DEF+ (%d)", g.player_def_buff_dur), 340, status_y, 16, {100, 180, 255, 255})
	}
	if g.enemy_poison_dur > 0 {
		rl.DrawText(fmt.ctprintf("Enemy POISONED (%d)", g.enemy_poison_dur), 60, status_y - 20, 14, {100, 220, 50, 255})
	}
	// Combo indicator
	if g.combo_count > 0 {
		combo_names := [3]string{"Slash", "Thrust", "Finisher"}
		next := min(g.combo_count + 1, 3)
		rl.DrawText(fmt.ctprintf("COMBO %d/3 → %s (timer: %d)", g.combo_count, combo_names[next - 1], g.combo_timer),
			60, status_y + 20, 16, {255, 220, 50, 255})
	}

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

	// Combo
	combo_ok := g.combo_count < 3 && g.enemy_hp > 0
	combo_color := rl.Color{255, 220, 50, 255} if combo_ok else rl.Color{60, 60, 70, 255}
	rl.DrawText("[K]", 420, action_y, 20, combo_color)
	rl.DrawText("Combo", 460, action_y, 20, combo_color)

	// Flee
	rl.DrawText("[F]", 560, action_y, 20, {255, 180, 100, 255})
	rl.DrawText("Flee", 600, action_y, 20, {255, 180, 100, 255})

	// Row 2: Poison strike / Antidote
	action_y2 := action_y + 28
	ps_color := rl.Color{100, 220, 50, 255} if g.enemy_poison_dur == 0 else rl.Color{60, 60, 70, 255}
	rl.DrawText("[V]", 60, action_y2, 20, ps_color)
	rl.DrawText("Poison", 100, action_y2, 20, ps_color)

	anti_ok := g.qty_potion > 0 && g.player_poison_dur > 0
	anti_color := rl.Color{100, 220, 50, 255} if anti_ok else rl.Color{60, 60, 70, 255}
	rl.DrawText("[X]", 230, action_y2, 20, anti_color)
	rl.DrawText("Antidote", 270, action_y2, 20, anti_color)

	// Flash overlay for hit feedback
	if app.flash_timer > 0 {
		alpha := u8(f32(app.flash_color.a) * (app.flash_timer / 0.15))
		rl.DrawRectangle(0, 0, HUD_X, WINDOW_H, {app.flash_color.r, app.flash_color.g, app.flash_color.b, alpha})
	}

	// Victory rewards overlay
	if app.showing_rewards {
		draw_victory_rewards(app)
	} else {
		// Combat hint (only when actively fighting)
		rl.DrawText("Space also attacks  |  Esc also flees", 140, WINDOW_H - 30, 12, TEXT_DIM)
	}
}

// Smooth ease-out interpolation
ease_out :: proc(t: f32) -> f32 {
	return 1.0 - (1.0 - t) * (1.0 - t)
}

draw_victory_rewards :: proc(app: ^App_State) {
	r := &app.rewards
	t := r.timer

	// Darken background
	overlay_alpha := u8(min(f32(160), t * 400))
	rl.DrawRectangle(0, 0, HUD_X, WINDOW_H, {0, 0, 0, overlay_alpha})

	cx := i32(HUD_X) / 2
	panel_w :: i32(400)
	panel_h :: i32(300)
	panel_x := cx - panel_w / 2
	panel_y := i32(200)

	// Panel background with border
	rl.DrawRectangle(panel_x, panel_y, panel_w, panel_h, {30, 30, 50, 230})
	rl.DrawRectangleLinesEx({f32(panel_x), f32(panel_y), f32(panel_w), f32(panel_h)}, 2, TEXT_GOLD)

	// "VICTORY!" title — fades in immediately
	title_alpha := u8(min(255, t * 600))
	title_text :: "VICTORY!"
	title_w := rl.MeasureText(title_text, 36)
	rl.DrawText(title_text, cx - title_w / 2, panel_y + 16, 36, {255, 215, 0, title_alpha})

	// Divider
	if t > 0.2 {
		div_progress := min((t - 0.2) * 5, 1.0)
		div_w := i32(f32(panel_w - 40) * ease_out(div_progress))
		rl.DrawRectangle(cx - div_w / 2, panel_y + 60, div_w, 2, {255, 215, 0, 120})
	}

	// XP gained — slides in from left
	if t > REWARDS_XP_DELAY {
		xp_t := min((t - REWARDS_XP_DELAY) / 0.5, 1.0)
		xp_ease := ease_out(xp_t)
		slide_x := i32(f32(-100) * (1.0 - xp_ease))

		// Animated XP counter
		displayed_xp := int(f32(r.xp_gained) * xp_ease)
		xp_alpha := u8(255.0 * min(xp_t * 3, 1.0))

		rl.DrawText(fmt.ctprintf("+%d XP", displayed_xp),
			panel_x + 40 + slide_x, panel_y + 80, 24, {100, 180, 255, xp_alpha})

		// XP bar
		g := &app.game
		xp_target := qc.XP_THRESHOLDS[g.level + 1] if g.level < 3 else g.xp
		bar_w := panel_w - 80
		bar_x := panel_x + 40 + slide_x
		bar_y := panel_y + 110
		draw_bar(bar_x, bar_y, bar_w, 14, g.xp, xp_target, BAR_XP_FG, BAR_XP_BG)
		xp_str := fmt.ctprintf("%d/%d", g.xp, xp_target)
		xp_str_w := rl.MeasureText(xp_str, 11)
		rl.DrawText(xp_str, bar_x + (bar_w - xp_str_w) / 2, bar_y + 1, 11, TEXT_BRIGHT)
	}

	// Gold gained — slides in from right
	if t > REWARDS_GOLD_DELAY {
		gold_t := min((t - REWARDS_GOLD_DELAY) / 0.5, 1.0)
		gold_ease := ease_out(gold_t)
		slide_x := i32(f32(100) * (1.0 - gold_ease))

		displayed_gold := int(f32(r.gold_gained) * gold_ease)
		gold_alpha := u8(255.0 * min(gold_t * 3, 1.0))

		rl.DrawText(fmt.ctprintf("+%d Gold", displayed_gold),
			panel_x + 40 + slide_x, panel_y + 140, 24, {255, 215, 0, gold_alpha})
	}

	// Level-up section
	if r.leveled_up && t > REWARDS_LEVEL_DELAY {
		lvl_t := min((t - REWARDS_LEVEL_DELAY) / 0.6, 1.0)
		lvl_ease := ease_out(lvl_t)
		lvl_alpha := u8(255.0 * lvl_ease)

		// Scale effect for level-up text
		base_size := i32(28)
		pop := f32(1.0) + (1.0 - lvl_ease) * 0.3  // starts 30% bigger, settles to normal
		size := i32(f32(base_size) * pop)

		lvl_text := fmt.ctprintf("LEVEL UP!  Lv.%d", r.new_level)
		lvl_w := rl.MeasureText(lvl_text, size)
		rl.DrawText(lvl_text, cx - lvl_w / 2, panel_y + 185, size, {255, 255, 100, lvl_alpha})

		// Stat gains
		if lvl_t > 0.3 {
			stat_alpha := u8(255.0 * min((lvl_t - 0.3) * 3, 1.0))
			rl.DrawText(fmt.ctprintf("+%d Max HP   +%d ATK", r.hp_gained, r.atk_gained),
				panel_x + 80, panel_y + 220, 18, {180, 220, 180, stat_alpha})
		}
	}

	// "Press ENTER to continue" — appears after everything else
	prompt_delay := f32(1.4) if r.leveled_up else f32(1.0)
	if t > prompt_delay {
		pulse := u8(140 + i32(math.sin(app.pulse_timer * 2) * 60))
		continue_text :: "Press ENTER to continue"
		continue_w := rl.MeasureText(continue_text, 18)
		rl.DrawText(continue_text, cx - continue_w / 2, panel_y + panel_h - 35, 18, {pulse, pulse, pulse, 255})
	}
}
