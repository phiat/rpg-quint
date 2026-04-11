package quint_crawl_game

import qc "../quint_crawl"
import rl "vendor:raylib"
import "core:fmt"
import "core:math"

Shader_Pipeline :: struct {
	rt:               [2]rl.RenderTexture2D,
	daynight_shader:  rl.Shader,
	effects_shader:   rl.Shader,
	// daynight uniforms
	loc_time_of_day:  i32,
	// effects uniforms
	loc_zone_tint:    i32,
	loc_aberration:   i32,
	loc_danger:       i32,
	loc_time:         i32,
	loc_bloom:        i32,
	loc_poison:       i32,
	pipeline_enabled: bool,
}

init_shaders :: proc(pipeline: ^Shader_Pipeline) {
	pipeline.rt[0] = rl.LoadRenderTexture(WINDOW_W, WINDOW_H)
	pipeline.rt[1] = rl.LoadRenderTexture(WINDOW_W, WINDOW_H)

	pipeline.daynight_shader = rl.LoadShader(nil, "quint_crawl_game/assets/daynight.fs")
	pipeline.effects_shader = rl.LoadShader(nil, "quint_crawl_game/assets/effects.fs")

	if pipeline.daynight_shader.id == 0 || pipeline.effects_shader.id == 0 {
		fmt.println("[shaders] WARNING: Failed to load shaders, pipeline disabled")
		pipeline.pipeline_enabled = false
		return
	}

	// Cache uniform locations
	pipeline.loc_time_of_day = rl.GetShaderLocation(pipeline.daynight_shader, "u_time_of_day")

	pipeline.loc_zone_tint   = rl.GetShaderLocation(pipeline.effects_shader, "u_zone_tint")
	pipeline.loc_aberration  = rl.GetShaderLocation(pipeline.effects_shader, "u_aberration")
	pipeline.loc_danger      = rl.GetShaderLocation(pipeline.effects_shader, "u_danger")
	pipeline.loc_time        = rl.GetShaderLocation(pipeline.effects_shader, "u_time")
	pipeline.loc_bloom       = rl.GetShaderLocation(pipeline.effects_shader, "u_bloom")
	pipeline.loc_poison      = rl.GetShaderLocation(pipeline.effects_shader, "u_poison")

	pipeline.pipeline_enabled = true
	fmt.println("[shaders] Pipeline initialized (daynight + effects)")
}

destroy_shaders :: proc(pipeline: ^Shader_Pipeline) {
	if pipeline.daynight_shader.id != 0 do rl.UnloadShader(pipeline.daynight_shader)
	if pipeline.effects_shader.id != 0  do rl.UnloadShader(pipeline.effects_shader)
	rl.UnloadRenderTexture(pipeline.rt[0])
	rl.UnloadRenderTexture(pipeline.rt[1])
}

begin_pipeline :: proc(pipeline: ^Shader_Pipeline) {
	if !pipeline.pipeline_enabled do return
	rl.BeginTextureMode(pipeline.rt[0])
	rl.ClearBackground(BG_COLOR)
}

// Zone tint colors — subtle palette shift per zone
zone_tint :: proc(x, y: int) -> [3]f32 {
	switch {
	case x == 0 && y == 0: return {1.05, 0.98, 0.90}  // Village: warm
	case x == 1 && y == 0: return {0.90, 1.08, 0.90}  // Forest: green
	case x == 2 && y == 0: return {0.90, 0.95, 1.05}  // Swamp: cool purple-green
	case x == 0 && y == 1: return {1.02, 1.05, 0.95}  // Plains: bright warm
	case x == 1 && y == 1: return {0.85, 0.88, 1.00}  // Cave: cool blue
	case x == 2 && y == 1: return {0.95, 0.95, 1.05}  // Mountain: cool gray
	case x == 0 && y == 2: return {0.95, 0.90, 0.85}  // Ruins: dusty warm
	case x == 1 && y == 2: return {1.08, 1.02, 0.85}  // Shrine: golden
	case x == 2 && y == 2: return {1.10, 0.85, 0.85}  // Castle: red
	case:                  return {1.0, 1.0, 1.0}
	}
}

end_pipeline :: proc(pipeline: ^Shader_Pipeline, app: ^App_State) {
	if !pipeline.pipeline_enabled do return
	rl.EndTextureMode()

	g := &app.game
	flip_rect := rl.Rectangle{0, 0, f32(WINDOW_W), -f32(WINDOW_H)}

	// --- Pass 1: Day/night color grading ---
	time_val := app.day_time
	rl.SetShaderValue(pipeline.daynight_shader, pipeline.loc_time_of_day, &time_val, .FLOAT)

	rl.BeginTextureMode(pipeline.rt[1])
	rl.ClearBackground(BG_COLOR)
	rl.BeginShaderMode(pipeline.daynight_shader)
	rl.DrawTextureRec(pipeline.rt[0].texture, flip_rect, {0, 0}, rl.WHITE)
	rl.EndShaderMode()
	rl.EndTextureMode()

	// --- Pass 2: Effects (zone tint, aberration, danger, bloom, poison) ---

	// Zone tint
	tint := zone_tint(g.pos_x, g.pos_y)
	rl.SetShaderValue(pipeline.effects_shader, pipeline.loc_zone_tint, &tint, .VEC3)

	// Chromatic aberration + barrel distortion (driven by shake_timer)
	aberration := clamp(app.shake_timer * 5.0, 0.0, 1.0)
	rl.SetShaderValue(pipeline.effects_shader, pipeline.loc_aberration, &aberration, .FLOAT)

	// Low-HP danger pulse
	danger: f32 = 0
	if g.max_hp > 0 {
		hp_ratio := f32(g.hp) / f32(g.max_hp)
		if hp_ratio < 0.3 {
			danger = (0.3 - hp_ratio) / 0.3  // 0 at 30%, 1 at 0%
		}
	}
	rl.SetShaderValue(pipeline.effects_shader, pipeline.loc_danger, &danger, .FLOAT)

	// Global time
	global_time := f32(rl.GetTime())
	rl.SetShaderValue(pipeline.effects_shader, pipeline.loc_time, &global_time, .FLOAT)

	// Level-up bloom
	bloom := clamp(app.bloom_timer * 2.0, 0.0, 1.0)
	rl.SetShaderValue(pipeline.effects_shader, pipeline.loc_bloom, &bloom, .FLOAT)

	// Poison (driven by player_poison_dur)
	poison: f32 = f32(g.player_poison_dur) / f32(qc.STATUS_DURATION)
	rl.SetShaderValue(pipeline.effects_shader, pipeline.loc_poison, &poison, .FLOAT)

	rl.BeginTextureMode(pipeline.rt[0])
	rl.ClearBackground(BG_COLOR)
	rl.BeginShaderMode(pipeline.effects_shader)
	rl.DrawTextureRec(pipeline.rt[1].texture, flip_rect, {0, 0}, rl.WHITE)
	rl.EndShaderMode()
	rl.EndTextureMode()

	// --- Final output to screen ---
	rl.DrawTextureRec(pipeline.rt[0].texture, flip_rect, {0, 0}, rl.WHITE)
}

clamp :: proc(v, lo, hi: f32) -> f32 {
	return max(lo, min(hi, v))
}
