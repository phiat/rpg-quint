package quint_crawl_game

import rl "vendor:raylib"
import "core:fmt"

Shader_Pipeline :: struct {
	rt:               [2]rl.RenderTexture2D,
	daynight_shader:  rl.Shader,
	loc_time_of_day:  i32,
	pipeline_enabled: bool,
}

init_shaders :: proc(pipeline: ^Shader_Pipeline) {
	// Create ping-pong render textures
	pipeline.rt[0] = rl.LoadRenderTexture(WINDOW_W, WINDOW_H)
	pipeline.rt[1] = rl.LoadRenderTexture(WINDOW_W, WINDOW_H)

	// Load day/night shader
	pipeline.daynight_shader = rl.LoadShader(nil, "quint_crawl_game/assets/daynight.fs")

	if pipeline.daynight_shader.id == 0 {
		fmt.println("[shaders] WARNING: Failed to load daynight.fs, pipeline disabled")
		pipeline.pipeline_enabled = false
		return
	}

	// Cache uniform locations
	pipeline.loc_time_of_day = rl.GetShaderLocation(pipeline.daynight_shader, "u_time_of_day")

	pipeline.pipeline_enabled = true
	fmt.println("[shaders] Pipeline initialized")
}

destroy_shaders :: proc(pipeline: ^Shader_Pipeline) {
	if pipeline.daynight_shader.id != 0 {
		rl.UnloadShader(pipeline.daynight_shader)
	}
	rl.UnloadRenderTexture(pipeline.rt[0])
	rl.UnloadRenderTexture(pipeline.rt[1])
}

begin_pipeline :: proc(pipeline: ^Shader_Pipeline) {
	if !pipeline.pipeline_enabled do return
	rl.BeginTextureMode(pipeline.rt[0])
	rl.ClearBackground(BG_COLOR)
}

end_pipeline :: proc(pipeline: ^Shader_Pipeline, app: ^App_State) {
	if !pipeline.pipeline_enabled do return
	rl.EndTextureMode()

	// Set uniforms
	time_val := app.day_time
	rl.SetShaderValue(pipeline.daynight_shader, pipeline.loc_time_of_day, &time_val, .FLOAT)

	// Apply daynight shader: draw rt[0] into rt[1] with shader
	rl.BeginTextureMode(pipeline.rt[1])
	rl.ClearBackground(BG_COLOR)
	rl.BeginShaderMode(pipeline.daynight_shader)
	// Render textures are Y-flipped, so flip when drawing between them
	rl.DrawTextureRec(
		pipeline.rt[0].texture,
		rl.Rectangle{0, 0, f32(WINDOW_W), -f32(WINDOW_H)},
		rl.Vector2{0, 0},
		rl.WHITE,
	)
	rl.EndShaderMode()
	rl.EndTextureMode()

	// Draw final result to screen (flip Y again for screen output)
	rl.DrawTextureRec(
		pipeline.rt[1].texture,
		rl.Rectangle{0, 0, f32(WINDOW_W), -f32(WINDOW_H)},
		rl.Vector2{0, 0},
		rl.WHITE,
	)
}
