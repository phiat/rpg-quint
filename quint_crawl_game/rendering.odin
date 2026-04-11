package quint_crawl_game

import qc "../quint_crawl"
import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:strings"

// --- Bar rendering ---
draw_bar :: proc(x, y, w, h: i32, current, maximum: int, fg, bg: rl.Color) {
	rl.DrawRectangle(x, y, w, h, bg)
	if maximum > 0 {
		fill_w := i32(f32(w) * f32(current) / f32(maximum))
		if fill_w > 0 do rl.DrawRectangle(x, y, fill_w, h, fg)
	}
	rl.DrawRectangleLines(x, y, w, h, TILE_BORDER)
}

// --- Tile rendering ---
draw_tile :: proc(x, y: int, g: ^qc.Game_State) {
	px := i32(TILE_OFFSET + x * (TILE_SIZE + TILE_PAD))
	py := i32(TILE_OFFSET + y * (TILE_SIZE + TILE_PAD))
	is_current := x == g.pos_x && y == g.pos_y
	level_req := qc.zone_level_req(x, y)
	locked := level_req > g.level
	name := qc.zone_name(x, y)

	// Tile background
	color := ZONE_COLORS[x][y]
	if !is_current {
		// Slightly dim non-current tiles
		color.r = u8(f32(color.r) * 0.7)
		color.g = u8(f32(color.g) * 0.7)
		color.b = u8(f32(color.b) * 0.7)
	}
	rl.DrawRectangle(px, py, TILE_SIZE, TILE_SIZE, color)

	// Zone name
	name_cstr := strings.clone_to_cstring(name, context.temp_allocator)
	name_size :: 22
	name_w := rl.MeasureText(name_cstr, name_size)
	rl.DrawText(name_cstr, px + (TILE_SIZE - name_w) / 2, py + 10, name_size, TEXT_BRIGHT)

	// Level requirement badge
	lvl_str := fmt.ctprintf("Lv.%d", level_req)
	rl.DrawText(lvl_str, px + 8, py + TILE_SIZE - 28, 18, TEXT_DIM)

	// Zone-specific icon hint
	draw_zone_icon(px, py, x, y)

	// Locked overlay
	if locked {
		rl.DrawRectangle(px, py, TILE_SIZE, TILE_SIZE, LOCKED_OVERLAY)
		lock_str := fmt.ctprintf("Lv.%d Required", level_req)
		lock_w := rl.MeasureText(lock_str, 20)
		rl.DrawText(lock_str, px + (TILE_SIZE - lock_w) / 2, py + TILE_SIZE / 2 - 10, 20, {255, 100, 100, 200})
	}

	// Tile border
	border_color := PLAYER_COLOR if is_current else TILE_BORDER
	border_thick := f32(3) if is_current else f32(1)
	rl.DrawRectangleLinesEx({f32(px), f32(py), f32(TILE_SIZE), f32(TILE_SIZE)}, border_thick, border_color)
}

// Simple icon hints per zone type
draw_zone_icon :: proc(px, py: i32, x, y: int) {
	cx := f32(px) + f32(TILE_SIZE) / 2
	cy := f32(py) + f32(TILE_SIZE) / 2 + 10

	switch {
	case x == 0 && y == 0: // Village — house shape
		rl.DrawTriangle({cx, cy - 30}, {cx - 25, cy - 5}, {cx + 25, cy - 5}, {180, 140, 100, 120})
		rl.DrawRectangle(i32(cx) - 15, i32(cy) - 5, 30, 25, {160, 120, 80, 120})
	case x == 1 && y == 0: // Forest — tree
		rl.DrawTriangle({cx, cy - 35}, {cx - 20, cy}, {cx + 20, cy}, {40, 120, 40, 120})
		rl.DrawRectangle(i32(cx) - 4, i32(cy), 8, 15, {100, 70, 40, 120})
	case x == 2 && y == 0: // Swamp — wavy water
		for i in 0..<3 {
			ox := f32(i) * 20 - 20
			rl.DrawCircle(i32(cx + ox), i32(cy), 8, {60, 90, 60, 100})
		}
	case x == 0 && y == 1: // Plains — grass tufts
		for i in 0..<3 {
			ox := f32(i) * 25 - 25
			rl.DrawLine(i32(cx + ox), i32(cy + 5), i32(cx + ox - 5), i32(cy - 15), {100, 160, 60, 120})
			rl.DrawLine(i32(cx + ox), i32(cy + 5), i32(cx + ox + 5), i32(cy - 15), {100, 160, 60, 120})
		}
	case x == 1 && y == 1: // Cave — dark circle
		rl.DrawCircle(i32(cx), i32(cy), 25, {30, 30, 40, 150})
		rl.DrawCircle(i32(cx), i32(cy), 20, {15, 15, 25, 200})
	case x == 2 && y == 1: // Mountain — peak
		rl.DrawTriangle({cx, cy - 35}, {cx - 30, cy + 10}, {cx + 30, cy + 10}, {150, 150, 170, 120})
		rl.DrawTriangle({cx, cy - 35}, {cx - 8, cy - 15}, {cx + 8, cy - 15}, {240, 240, 255, 150})
	case x == 0 && y == 2: // Ruins — broken pillars
		rl.DrawRectangle(i32(cx) - 20, i32(cy) - 15, 8, 30, {140, 130, 110, 120})
		rl.DrawRectangle(i32(cx) + 12, i32(cy) - 10, 8, 25, {140, 130, 110, 120})
		rl.DrawRectangle(i32(cx) - 5, i32(cy) - 5, 8, 20, {120, 110, 90, 100})
	case x == 1 && y == 2: // Shrine — glowing circle
		rl.DrawCircle(i32(cx), i32(cy), 20, {200, 180, 60, 80})
		rl.DrawCircle(i32(cx), i32(cy), 12, {255, 230, 100, 120})
	case x == 2 && y == 2: // Castle — tower
		rl.DrawRectangle(i32(cx) - 18, i32(cy) - 10, 36, 30, {100, 40, 40, 130})
		rl.DrawRectangle(i32(cx) - 22, i32(cy) - 20, 10, 15, {120, 50, 50, 130})
		rl.DrawRectangle(i32(cx) + 12, i32(cy) - 20, 10, 15, {120, 50, 50, 130})
	}
}

// --- Player marker ---
draw_player_marker :: proc(app: ^App_State) {
	g := &app.game
	px := f32(TILE_OFFSET + g.pos_x * (TILE_SIZE + TILE_PAD)) + f32(TILE_SIZE) / 2
	py := f32(TILE_OFFSET + g.pos_y * (TILE_SIZE + TILE_PAD)) + f32(TILE_SIZE) - 40

	pulse := math.sin(app.pulse_timer) * 4
	size := f32(12) + pulse

	// Diamond shape
	rl.DrawPoly({px, py}, 4, size, 45, PLAYER_COLOR)
	rl.DrawPoly({px, py}, 4, size - 3, 45, {0, 180, 220, 255})

	// "You" label
	rl.DrawText("You", i32(px) - 12, i32(py) + i32(size) + 4, 14, PLAYER_COLOR)
}

// --- Enemy drawing (combat) ---
draw_enemy_shape_tinted :: proc(cx, cy: f32, tier: int, shake: f32, alpha: u8) {
	ox := shake * math.sin(shake * 30)
	base := ENEMY_COLORS[tier]
	color := rl.Color{base.r, base.g, base.b, alpha}
	eye_white := rl.Color{255, 255, 255, alpha}
	eye_black := rl.Color{0, 0, 0, alpha}

	switch tier {
	case 0: // Slime
		rl.DrawCircle(i32(cx + ox), i32(cy), 50, color)
		rl.DrawCircle(i32(cx + ox), i32(cy + 20), 55, color)
		rl.DrawCircle(i32(cx + ox - 15), i32(cy - 10), 8, eye_white)
		rl.DrawCircle(i32(cx + ox + 15), i32(cy - 10), 8, eye_white)
		rl.DrawCircle(i32(cx + ox - 15), i32(cy - 10), 4, eye_black)
		rl.DrawCircle(i32(cx + ox + 15), i32(cy - 10), 4, eye_black)
	case 1: // Skeleton
		rl.DrawRectangle(i32(cx + ox) - 20, i32(cy) - 40, 40, 70, color)
		rl.DrawCircle(i32(cx + ox), i32(cy) - 55, 22, color)
		rl.DrawRectangle(i32(cx + ox) - 12, i32(cy) - 62, 8, 8, eye_black)
		rl.DrawRectangle(i32(cx + ox) + 4, i32(cy) - 62, 8, 8, eye_black)
		rl.DrawLine(i32(cx + ox) - 20, i32(cy) - 30, i32(cx + ox) - 45, i32(cy), color)
		rl.DrawLine(i32(cx + ox) + 20, i32(cy) - 30, i32(cx + ox) + 45, i32(cy), color)
	case 2: // Dragon
		rl.DrawTriangle({cx + ox, cy - 60}, {cx + ox - 50, cy + 30}, {cx + ox + 50, cy + 30}, color)
		wing := rl.Color{color.r - 30 if color.r >= 30 else 0, color.g, color.b, alpha}
		rl.DrawTriangle({cx + ox - 30, cy - 20}, {cx + ox - 80, cy - 40}, {cx + ox - 30, cy + 10}, wing)
		rl.DrawTriangle({cx + ox + 30, cy - 20}, {cx + ox + 80, cy - 40}, {cx + ox + 30, cy + 10}, wing)
		eye_yellow := rl.Color{255, 255, 0, alpha}
		rl.DrawCircle(i32(cx + ox) - 12, i32(cy) - 30, 6, eye_yellow)
		rl.DrawCircle(i32(cx + ox) + 12, i32(cy) - 30, 6, eye_yellow)
	}
}

draw_enemy_shape :: proc(cx, cy: f32, tier: int, shake: f32) {
	draw_enemy_shape_tinted(cx, cy, tier, shake, 255)
}

// --- Full map screen ---
draw_map :: proc(app: ^App_State) {
	g := &app.game

	// Draw all tiles
	for y in 0 ..< 3 {
		for x in 0 ..< 3 {
			draw_tile(x, y, g)
		}
	}

	// Player marker
	if !g.in_combat {
		draw_player_marker(app)
	}
}

// --- Title screen ---
draw_title :: proc(app: ^App_State) {
	cx := i32(WINDOW_W / 2)
	cy := i32(WINDOW_H / 2)

	title_text :: "QUINT CRAWL"
	title_w := rl.MeasureText(title_text, 60)
	rl.DrawText(title_text, cx - title_w / 2, cy - 100, 60, PLAYER_COLOR)

	sub_text :: "A Formally Verified RPG"
	sub_w := rl.MeasureText(sub_text, 24)
	rl.DrawText(sub_text, cx - sub_w / 2, cy - 30, 24, TEXT_DIM)

	pulse := u8(140 + i32(math.sin(app.pulse_timer) * 60))
	start_text :: "Press ENTER to begin"
	start_w := rl.MeasureText(start_text, 28)
	rl.DrawText(start_text, cx - start_w / 2, cy + 60, 28, {pulse, pulse, pulse, 255})

	// Controls hint
	rl.DrawText("WASD: Move   E: Fight   R: Rest", cx - 160, cy + 150, 16, TEXT_DIM)
	rl.DrawText("Goal: Reach Level 3 and conquer the Castle!", cx - 200, cy + 180, 16, TEXT_GOLD)
}

// --- Victory screen ---
draw_victory :: proc(app: ^App_State) {
	cx := i32(WINDOW_W / 2)
	cy := i32(WINDOW_H / 2)

	title_text :: "VICTORY!"
	title_w := rl.MeasureText(title_text, 72)
	rl.DrawText(title_text, cx - title_w / 2, cy - 100, 72, TEXT_GOLD)

	sub := fmt.ctprintf("Level %d  |  %d XP  |  %d Gold", app.game.level, app.game.xp, app.game.gold)
	sub_w := rl.MeasureText(sub, 24)
	rl.DrawText(sub, cx - sub_w / 2, cy - 10, 24, TEXT_BRIGHT)

	msg_text :: "The Castle has fallen. The realm is yours."
	msg_w := rl.MeasureText(msg_text, 20)
	rl.DrawText(msg_text, cx - msg_w / 2, cy + 40, 20, TEXT_DIM)

	restart_text :: "Press ENTER to play again"
	restart_w := rl.MeasureText(restart_text, 22)
	pulse := u8(140 + i32(math.sin(app.pulse_timer) * 60))
	rl.DrawText(restart_text, cx - restart_w / 2, cy + 120, 22, {pulse, pulse, pulse, 255})
}

// --- Game over screen ---
draw_game_over :: proc(app: ^App_State) {
	cx := i32(WINDOW_W / 2)
	cy := i32(WINDOW_H / 2)

	title_text :: "GAME OVER"
	title_w := rl.MeasureText(title_text, 60)
	rl.DrawText(title_text, cx - title_w / 2, cy - 80, 60, BAR_HP_FG)

	sub := fmt.ctprintf("Fell at Level %d in %s", app.game.level, qc.zone_name(app.game.pos_x, app.game.pos_y))
	sub_w := rl.MeasureText(sub, 22)
	rl.DrawText(sub, cx - sub_w / 2, cy, 22, TEXT_DIM)

	restart_text :: "Press ENTER to try again"
	restart_w := rl.MeasureText(restart_text, 22)
	pulse := u8(140 + i32(math.sin(app.pulse_timer) * 60))
	rl.DrawText(restart_text, cx - restart_w / 2, cy + 80, 22, {pulse, pulse, pulse, 255})
}
