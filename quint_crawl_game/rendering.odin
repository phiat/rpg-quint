package quint_crawl_game

import qc "../quint_crawl"
import rl "vendor:raylib"
import "core:fmt"
import "core:math"

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
// Get tile color from biome pattern, adjusted by zone level for brightness
tile_color :: proc(x, y: int) -> rl.Color {
	base := BASE_ZONE_COLORS[x % 3][y % 3]
	lvl := qc.zone_level(x, y)
	// Slightly darken higher-level zones for visual progression
	scale := f32(1.0) - f32(lvl - 1) * 0.08
	return {u8(f32(base.r) * scale), u8(f32(base.g) * scale), u8(f32(base.b) * scale), 255}
}

draw_tile :: proc(x, y: int, g: ^qc.Game_State) {
	px := i32(TILE_OFFSET + x * (TILE_SIZE + TILE_PAD))
	py := i32(TILE_OFFSET + y * (TILE_SIZE + TILE_PAD))
	is_current := x == g.pos_x && y == g.pos_y
	level_req := qc.zone_level(x, y)
	locked := level_req > g.level

	// Tile background
	color := tile_color(x, y)
	if !is_current {
		color.r = u8(f32(color.r) * 0.7)
		color.g = u8(f32(color.g) * 0.7)
		color.b = u8(f32(color.b) * 0.7)
	}
	rl.DrawRectangle(px, py, TILE_SIZE, TILE_SIZE, color)

	// Zone name (abbreviated for small tiles)
	abbrev := zone_abbrev(x, y)
	name_size := i32(10)
	name_w := rl.MeasureText(abbrev, name_size)
	rl.DrawText(abbrev, px + (TILE_SIZE - name_w) / 2, py + 2, name_size, TEXT_BRIGHT)

	// Level pips (colored dots in bottom-left corner)
	pip_colors := [5]rl.Color{
		{100, 200, 100, 200},  // L1: green
		{100, 180, 255, 200},  // L2: blue
		{200, 180, 60, 200},   // L3: gold
		{180, 100, 220, 200},  // L4: purple
		{220, 60, 60, 200},    // L5: red
	}
	pip_color := pip_colors[min(level_req, 5) - 1]
	pip_size := i32(3)
	pip_y := py + TILE_SIZE - pip_size * 2 - 2
	for i in 0 ..< level_req {
		rl.DrawRectangle(px + 3 + i32(i) * (pip_size + 2), pip_y, pip_size, pip_size, pip_color)
	}

	// Locked overlay
	if locked {
		rl.DrawRectangle(px, py, TILE_SIZE, TILE_SIZE, {0, 0, 0, 160})
		lvl_lock := fmt.ctprintf("L%d", level_req)
		lw := rl.MeasureText(lvl_lock, 10)
		rl.DrawText(lvl_lock, px + (TILE_SIZE - lw) / 2, py + TILE_SIZE / 2 - 5, 10, {255, 100, 100, 200})
	}

	// Tile border (glow ring for player tile)
	if is_current {
		// Outer glow — semi-transparent expanding ring
		glow_alpha := u8(60 + i32(math.sin(f32(rl.GetTime()) * 3.0) * 30))
		rl.DrawRectangleLinesEx({f32(px) - 2, f32(py) - 2, f32(TILE_SIZE) + 4, f32(TILE_SIZE) + 4}, 2, {0, 220, 255, glow_alpha})
		rl.DrawRectangleLinesEx({f32(px), f32(py), f32(TILE_SIZE), f32(TILE_SIZE)}, 2, PLAYER_COLOR)
	} else {
		rl.DrawRectangleLinesEx({f32(px), f32(py), f32(TILE_SIZE), f32(TILE_SIZE)}, 1, TILE_BORDER)
	}
}

// Short zone name abbreviations for small tiles
zone_abbrev :: proc(x, y: int) -> cstring {
	bx, by := x % 3, y % 3
	switch {
	case bx == 0 && by == 0: return "Vlg"
	case bx == 1 && by == 0: return "For"
	case bx == 2 && by == 0: return "Swp"
	case bx == 0 && by == 1: return "Pln"
	case bx == 1 && by == 1: return "Cav"
	case bx == 2 && by == 1: return "Mtn"
	case bx == 0 && by == 2: return "Rns"
	case bx == 1 && by == 2: return "Shr"
	case bx == 2 && by == 2: return "Cst"
	case: return "???"
	}
}

// Draw biome boundary lines — thicker separators every 3 tiles
draw_biome_grid :: proc() {
	boundary_color := rl.Color{100, 100, 130, 120}
	num_regions :: qc.WORLD_SIZE / 3
	for i in 1 ..< num_regions {
		// Vertical boundary (between columns 2-3 and 5-6)
		vx := i32(TILE_OFFSET + i * 3 * (TILE_SIZE + TILE_PAD)) - TILE_PAD / 2 - 1
		rl.DrawRectangle(vx, 0, 2, MAP_SIZE, boundary_color)
		// Horizontal boundary
		hy := i32(TILE_OFFSET + i * 3 * (TILE_SIZE + TILE_PAD)) - TILE_PAD / 2 - 1
		rl.DrawRectangle(0, hy, MAP_SIZE, 2, boundary_color)
	}
}

// --- Player marker ---
draw_player_marker :: proc(app: ^App_State) {
	g := &app.game
	px := f32(TILE_OFFSET + g.pos_x * (TILE_SIZE + TILE_PAD)) + f32(TILE_SIZE) / 2
	py := f32(TILE_OFFSET + g.pos_y * (TILE_SIZE + TILE_PAD)) + f32(TILE_SIZE) / 2 + 8

	pulse := math.sin(app.pulse_timer) * 2
	size := f32(8) + pulse

	// Diamond shape (scaled for 76px tiles)
	rl.DrawPoly({px, py}, 4, size, 45, PLAYER_COLOR)
	rl.DrawPoly({px, py}, 4, size - 2, 45, {0, 180, 220, 255})
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
	case 2: // Wolf — crouching body with pointed ears
		rl.DrawEllipse(i32(cx + ox), i32(cy + 10), 50, 30, color)  // body
		rl.DrawCircle(i32(cx + ox - 30), i32(cy - 10), 18, color)  // head
		rl.DrawTriangle({cx + ox - 38, cy - 28}, {cx + ox - 45, cy - 50}, {cx + ox - 30, cy - 28}, color)  // ear L
		rl.DrawTriangle({cx + ox - 22, cy - 28}, {cx + ox - 28, cy - 50}, {cx + ox - 15, cy - 28}, color)  // ear R
		rl.DrawCircle(i32(cx + ox - 35), i32(cy - 14), 4, eye_white)
		rl.DrawCircle(i32(cx + ox - 25), i32(cy - 14), 4, eye_white)
		rl.DrawCircle(i32(cx + ox - 35), i32(cy - 14), 2, eye_black)
		rl.DrawCircle(i32(cx + ox - 25), i32(cy - 14), 2, eye_black)
		// Tail
		rl.DrawLine(i32(cx + ox + 45), i32(cy + 5), i32(cx + ox + 65), i32(cy - 15), color)
	case 3: // Wraith — floating hooded figure
		// Hood/cloak shape
		rl.DrawTriangle({cx + ox, cy - 55}, {cx + ox - 35, cy + 30}, {cx + ox + 35, cy + 30}, color)
		// Inner darkness
		inner := rl.Color{color.r / 2, color.g / 2, color.b / 2, alpha}
		rl.DrawTriangle({cx + ox, cy - 40}, {cx + ox - 25, cy + 20}, {cx + ox + 25, cy + 20}, inner)
		// Glowing eyes
		eye_glow := rl.Color{200, 100, 255, alpha}
		rl.DrawCircle(i32(cx + ox) - 10, i32(cy) - 20, 5, eye_glow)
		rl.DrawCircle(i32(cx + ox) + 10, i32(cy) - 20, 5, eye_glow)
		// Wispy tendrils at bottom
		for i in 0..<4 {
			tx := cx + ox + f32(i) * 18 - 27
			ty := cy + 30 + math.sin(ox * 0.5 + f32(i)) * 8
			rl.DrawLine(i32(tx), i32(cy + 25), i32(tx), i32(ty + 15), {color.r, color.g, color.b, alpha / 2})
		}
	case 4: // Dragon — winged beast
		rl.DrawTriangle({cx + ox, cy - 60}, {cx + ox - 50, cy + 30}, {cx + ox + 50, cy + 30}, color)
		wing := rl.Color{u8(int(color.r) * 3 / 4), u8(int(color.g) * 3 / 4), u8(int(color.b) * 3 / 4), alpha}
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
	for y in 0 ..< qc.WORLD_SIZE {
		for x in 0 ..< qc.WORLD_SIZE {
			draw_tile(x, y, g)
		}
	}

	// Biome region boundaries
	draw_biome_grid()

	// Player marker
	if !g.in_combat {
		draw_player_marker(app)
	}

	// Mouse hover tooltip
	if !g.in_combat {
		draw_tile_tooltip(g)
	}
}

// --- Tile hover tooltip ---
draw_tile_tooltip :: proc(g: ^qc.Game_State) {
	mouse := rl.GetMousePosition()
	mx, my := i32(mouse.x), i32(mouse.y)

	// Convert mouse position to tile coordinates
	// tile_x = (mx - TILE_OFFSET) / (TILE_SIZE + TILE_PAD)
	rel_x := mx - TILE_OFFSET
	rel_y := my - TILE_OFFSET
	if rel_x < 0 || rel_y < 0 do return

	tile_x := int(rel_x / (TILE_SIZE + TILE_PAD))
	tile_y := int(rel_y / (TILE_SIZE + TILE_PAD))
	if tile_x < 0 || tile_x >= qc.WORLD_SIZE || tile_y < 0 || tile_y >= qc.WORLD_SIZE do return

	// Check we're actually inside a tile (not in the padding)
	in_tile_x := int(rel_x) % (TILE_SIZE + TILE_PAD)
	in_tile_y := int(rel_y) % (TILE_SIZE + TILE_PAD)
	if in_tile_x >= TILE_SIZE || in_tile_y >= TILE_SIZE do return

	// Build tooltip
	zone := qc.zone_name(tile_x, tile_y)
	lvl := qc.zone_level(tile_x, tile_y)
	locked := lvl > g.level

	// Tooltip lines
	line1 := fmt.ctprintf("%s — Level %d", zone, lvl)
	line2: cstring
	if locked {
		line2 = fmt.ctprintf("Locked (need Lv.%d)", lvl)
	} else if qc.zone_has_services(tile_x, tile_y) {
		line2 = "Rest, Shop, Craft"
	} else if qc.zone_has_wood(tile_x, tile_y) {
		line2 = "Gather Wood"
	} else if qc.zone_has_iron(tile_x, tile_y) {
		line2 = "Mine Iron"
	} else {
		line2 = "Fight enemies here"
	}

	// Measure and position
	w1 := rl.MeasureText(line1, 13)
	w2 := rl.MeasureText(line2, 11)
	tip_w := max(w1, w2) + 12
	tip_h := i32(34)
	tip_x := mx + 16
	tip_y := my - tip_h - 4

	// Keep on screen
	if tip_x + tip_w > MAP_SIZE do tip_x = mx - tip_w - 4
	if tip_y < 0 do tip_y = my + 20

	// Draw tooltip box
	rl.DrawRectangle(tip_x, tip_y, tip_w, tip_h, {20, 20, 35, 220})
	rl.DrawRectangleLines(tip_x, tip_y, tip_w, tip_h, TILE_BORDER)

	// Text
	line1_color := TEXT_BRIGHT if !locked else rl.Color{255, 100, 100, 200}
	rl.DrawText(line1, tip_x + 6, tip_y + 3, 13, line1_color)
	rl.DrawText(line2, tip_x + 6, tip_y + 18, 11, TEXT_DIM)
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
	rl.DrawText("Goal: Reach Level 5 and conquer the Castle!", cx - 200, cy + 180, 16, TEXT_GOLD)
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
