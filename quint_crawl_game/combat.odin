package quint_crawl_game

import qc "../quint_crawl"
import rl "vendor:raylib"
import "core:fmt"
import "core:math"

draw_combat :: proc(app: ^App_State) {
	g := &app.game
	tier := qc.zone_level(g.pos_x, g.pos_y) - 1

	// Combat background with zone biome tint
	base_bg := COMBAT_BG
	biome := BASE_ZONE_COLORS[g.pos_x % 3][g.pos_y % 3]
	tinted_bg := rl.Color{
		u8((int(base_bg.r) * 3 + int(biome.r)) / 4),
		u8((int(base_bg.g) * 3 + int(biome.g)) / 4),
		u8((int(base_bg.b) * 3 + int(biome.b)) / 4),
		255,
	}
	rl.DrawRectangle(0, 0, HUD_X, WINDOW_H, tinted_bg)

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
	enemy_max_hp := qc.zone_enemy_hp(g.pos_x, g.pos_y)
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

	// Stamina bar in combat
	sta_bar_x := i32(200)
	sta_bar_y := player_cy + 70
	rl.DrawText("STA", sta_bar_x, sta_bar_y - 2, 12, TEXT_DIM)
	draw_bar(sta_bar_x + 30, sta_bar_y, 120, 12, g.stamina, g.max_stamina, {50, 200, 120, 255}, {20, 60, 40, 255})
	rl.DrawText(fmt.ctprintf("%d/%d", g.stamina, g.max_stamina), sta_bar_x + 155, sta_bar_y - 1, 12, {50, 200, 120, 255})

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
		rl.DrawText(fmt.ctprintf("COMBO %d/3 → %s", g.combo_count, combo_names[next - 1]),
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

	// Flee
	rl.DrawText("[F]", 560, action_y, 20, {255, 180, 100, 255})
	rl.DrawText("Flee", 600, action_y, 20, {255, 180, 100, 255})

	// Row 2: Combo / Poison / Antidote (only show unlocked skills)
	action_y2 := action_y + 28
	row2_x := i32(60)

	if g.skill_combo {
		combo_ok2 := g.combo_count < 3 && g.enemy_hp > 0 && g.stamina >= qc.COMBO_STAMINA
		combo_color2 := rl.Color{255, 220, 50, 255} if combo_ok2 else rl.Color{60, 60, 70, 255}
		rl.DrawText("[K]", row2_x, action_y2, 20, combo_color2)
		rl.DrawText("Combo", row2_x + 40, action_y2, 20, combo_color2)
		row2_x += 140
	}

	if g.skill_poison {
		ps_ok := g.enemy_poison_dur == 0 && g.stamina >= qc.ATTACK_STAMINA && g.qty_venom_sac > 0
		ps_color := rl.Color{100, 220, 50, 255} if ps_ok else rl.Color{60, 60, 70, 255}
		rl.DrawText("[V]", row2_x, action_y2, 20, ps_color)
		rl.DrawText(fmt.ctprintf("Poison(%d)", g.qty_venom_sac), row2_x + 40, action_y2, 20, ps_color)
		row2_x += 160
	}

	anti_ok := g.qty_potion > 0 && g.player_poison_dur > 0
	anti_color := rl.Color{100, 220, 50, 255} if anti_ok else rl.Color{60, 60, 70, 255}
	rl.DrawText("[X]", row2_x, action_y2, 20, anti_color)
	rl.DrawText("Antidote", row2_x + 40, action_y2, 20, anti_color)

	// Row 3: Heavy / Warcry / Block / Counter / Fortify (only show unlocked)
	action_y3 := action_y2 + 28
	row3_x := i32(60)

	if g.skill_heavy_strike {
		hs_ok := g.cd_heavy_strike == 0 && g.stamina >= qc.HEAVY_STRIKE_STAMINA && g.enemy_hp > 0
		hs_color := rl.Color{255, 120, 50, 255} if hs_ok else rl.Color{60, 60, 70, 255}
		rl.DrawText("[H]", row3_x, action_y3, 20, hs_color)
		if g.cd_heavy_strike > 0 {
			rl.DrawText(fmt.ctprintf("Heavy(%d)", g.cd_heavy_strike), row3_x + 40, action_y3, 20, hs_color)
		} else {
			rl.DrawText("Heavy", row3_x + 40, action_y3, 20, hs_color)
		}
		row3_x += 130
	}

	if g.skill_battle_cry {
		bc_ok := g.cd_battle_cry == 0 && g.stamina >= qc.BATTLE_CRY_STAMINA && g.enemy_hp > 0
		bc_color := rl.Color{255, 200, 100, 255} if bc_ok else rl.Color{60, 60, 70, 255}
		rl.DrawText("[Y]", row3_x, action_y3, 20, bc_color)
		if g.cd_battle_cry > 0 {
			rl.DrawText(fmt.ctprintf("Warcry(%d)", g.cd_battle_cry), row3_x + 40, action_y3, 20, bc_color)
		} else {
			rl.DrawText("Warcry", row3_x + 40, action_y3, 20, bc_color)
		}
		row3_x += 130
	}

	if g.skill_shield_block {
		sb_ok := g.stamina >= qc.SHIELD_BLOCK_STAMINA && g.enemy_hp > 0
		sb_color := rl.Color{100, 180, 255, 255} if sb_ok else rl.Color{60, 60, 70, 255}
		rl.DrawText("[Z]", row3_x, action_y3, 20, sb_color)
		rl.DrawText("Block", row3_x + 40, action_y3, 20, sb_color)
		row3_x += 110
	}

	if g.skill_counter_attack {
		ca_ok := g.stamina >= qc.COUNTER_STAMINA && g.enemy_hp > 0
		ca_color := rl.Color{180, 140, 255, 255} if ca_ok else rl.Color{60, 60, 70, 255}
		rl.DrawText("[N]", row3_x, action_y3, 20, ca_color)
		rl.DrawText("Counter", row3_x + 40, action_y3, 20, ca_color)
		row3_x += 130
	}

	// Row 4: Fortify (if unlocked, with cooldown)
	if g.skill_fortify {
		action_y4 := action_y3 + 28
		ft_ok := g.cd_fortify == 0 && g.stamina >= qc.FORTIFY_STAMINA && g.enemy_hp > 0
		ft_color := rl.Color{80, 200, 200, 255} if ft_ok else rl.Color{60, 60, 70, 255}
		rl.DrawText("[I]", 60, action_y4, 20, ft_color)
		if g.cd_fortify > 0 {
			rl.DrawText(fmt.ctprintf("Fortify(%d)", g.cd_fortify), 100, action_y4, 20, ft_color)
		} else {
			rl.DrawText("Fortify", 100, action_y4, 20, ft_color)
		}
	}

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
		xp_target := qc.XP_THRESHOLDS[g.level + 1] if g.level < qc.MAX_LEVEL else g.xp
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
