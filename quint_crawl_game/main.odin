package quint_crawl_game

import qc "../quint_crawl"
import rl "vendor:raylib"
import "core:fmt"
import "core:strings"

// --- Screen state machine ---
Screen :: enum {
	Title,
	Map,
	Combat,
	Victory,
	Game_Over,
}

// --- Message log entry ---
Message :: struct {
	text:  string,
	color: rl.Color,
	timer: f32,
}

// --- Application state ---
App_State :: struct {
	game:         qc.Game_State,
	screen:       Screen,
	messages:     [dynamic]Message,
	pulse_timer:  f32,       // for player marker animation
	shake_timer:  f32,       // combat hit shake
	flash_color:  rl.Color,  // combat flash overlay
	flash_timer:  f32,
}

add_message :: proc(app: ^App_State, text: string, color: rl.Color) {
	if len(app.messages) >= MAX_MESSAGES {
		delete(app.messages[0].text)
		ordered_remove(&app.messages, 0)
	}
	append(&app.messages, Message{text = strings.clone(text), color = color, timer = MESSAGE_LIFETIME})
}

clear_messages :: proc(app: ^App_State) {
	for &msg in app.messages {
		delete(msg.text)
	}
	clear(&app.messages)
}

check_screen_transitions :: proc(app: ^App_State) {
	g := &app.game
	if g.game_won {
		app.screen = .Victory
	} else if g.hp <= 0 && !g.in_combat {
		app.screen = .Game_Over
	} else if g.in_combat && app.screen != .Combat {
		app.screen = .Combat
	} else if !g.in_combat && app.screen == .Combat {
		app.screen = .Map
	}
}

update :: proc(app: ^App_State) {
	dt := rl.GetFrameTime()

	// Animate pulse
	app.pulse_timer += dt * 3.0
	if app.pulse_timer > 6.28 do app.pulse_timer -= 6.28

	// Tick shake/flash
	if app.shake_timer > 0 do app.shake_timer -= dt
	if app.flash_timer > 0 do app.flash_timer -= dt

	// Tick messages
	for i := len(app.messages) - 1; i >= 0; i -= 1 {
		app.messages[i].timer -= dt
		if app.messages[i].timer <= 0 {
			delete(app.messages[i].text)
			ordered_remove(&app.messages, i)
		}
	}
}

main :: proc() {
	rl.InitWindow(WINDOW_W, WINDOW_H, "Quint Crawl")
	rl.SetTargetFPS(60)
	defer rl.CloseWindow()

	app: App_State
	app.screen = .Title
	qc.init_game(&app.game)

	for !rl.WindowShouldClose() {
		// Update
		update(&app)

		switch app.screen {
		case .Title:     handle_title_input(&app)
		case .Map:       handle_map_input(&app)
		case .Combat:    handle_combat_input(&app)
		case .Victory:   handle_endscreen_input(&app)
		case .Game_Over: handle_endscreen_input(&app)
		}

		// Draw
		rl.BeginDrawing()
		rl.ClearBackground(BG_COLOR)

		switch app.screen {
		case .Title:
			draw_title(&app)
		case .Map:
			draw_map(&app)
			draw_hud(&app)
		case .Combat:
			draw_combat(&app)
			draw_hud(&app)
		case .Victory:
			draw_victory(&app)
		case .Game_Over:
			draw_game_over(&app)
		}

		rl.EndDrawing()
	}
}
