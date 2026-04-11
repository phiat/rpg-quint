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
	pipeline:      Shader_Pipeline,
	day_time:      f32,
	bloom_timer:   f32,       // level-up bloom flash
	dissolve_timer: f32,      // enemy death dissolve (0 = no dissolve, >0 = dissolving)
	prev_level:    int,       // track level-ups
	// Screen transitions
	transition_timer:  f32,   // >0 = transitioning (fade out then in)
	transition_target: Screen, // screen to switch to at midpoint
	transition_phase:  bool,  // false = fading out, true = fading in
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

start_transition :: proc(app: ^App_State, target: Screen) {
	if app.transition_timer <= 0 && app.screen != target {
		app.transition_timer = TRANSITION_DURATION
		app.transition_target = target
		app.transition_phase = false  // start with fade-out
	}
}

check_screen_transitions :: proc(app: ^App_State) {
	g := &app.game
	if g.game_won && app.screen != .Victory {
		start_transition(app, .Victory)
	} else if g.hp <= 0 && !g.in_combat && app.screen != .Game_Over {
		start_transition(app, .Game_Over)
	} else if g.in_combat && app.screen != .Combat {
		start_transition(app, .Combat)
	} else if !g.in_combat && app.screen == .Combat {
		start_transition(app, .Map)
	}
}

update :: proc(app: ^App_State) {
	dt := rl.GetFrameTime()

	// Animate pulse
	app.pulse_timer += dt * 3.0
	if app.pulse_timer > 6.28 do app.pulse_timer -= 6.28

	// Tick shake/flash/bloom/dissolve
	if app.shake_timer > 0 do app.shake_timer -= dt
	if app.flash_timer > 0 do app.flash_timer -= dt
	if app.bloom_timer > 0 do app.bloom_timer -= dt
	if app.dissolve_timer > 0 do app.dissolve_timer -= dt

	// Tick screen transition
	if app.transition_timer > 0 {
		app.transition_timer -= dt
		half := TRANSITION_DURATION / 2
		if !app.transition_phase && app.transition_timer <= half {
			// Midpoint: switch screen
			app.screen = app.transition_target
			app.transition_phase = true
		}
		if app.transition_timer < 0 do app.transition_timer = 0
	}

	// Detect level-up
	if app.game.level > app.prev_level {
		app.bloom_timer = 0.6
		app.prev_level = app.game.level
	}

	// Tick messages
	for i := len(app.messages) - 1; i >= 0; i -= 1 {
		app.messages[i].timer -= dt
		if app.messages[i].timer <= 0 {
			delete(app.messages[i].text)
			ordered_remove(&app.messages, i)
		}
	}

	// Advance day/night cycle
	app.day_time += dt * DAY_CYCLE_SPEED
	if app.day_time > 1.0 do app.day_time -= 1.0
}

main :: proc() {
	rl.InitWindow(WINDOW_W, WINDOW_H, "Quint Crawl")
	rl.SetTargetFPS(60)
	defer rl.CloseWindow()

	app: App_State
	app.screen = .Title
	qc.init_game(&app.game)
	app.prev_level = app.game.level
	init_shaders(&app.pipeline)
	defer destroy_shaders(&app.pipeline)

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
		begin_pipeline(&app.pipeline)

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

		end_pipeline(&app.pipeline, &app)

		// Screen transition overlay (drawn after shaders)
		if app.transition_timer > 0 {
			half := TRANSITION_DURATION / 2
			progress: f32
			if !app.transition_phase {
				// Fading out: 0 → 1 alpha
				progress = 1.0 - (app.transition_timer - half) / half
			} else {
				// Fading in: 1 → 0 alpha
				progress = app.transition_timer / half
			}
			alpha := u8(clamp(progress * 255, 0, 255))
			rl.DrawRectangle(0, 0, WINDOW_W, WINDOW_H, {0, 0, 0, alpha})
		}

		rl.EndDrawing()
	}
}
