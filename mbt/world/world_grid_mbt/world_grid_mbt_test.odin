package world_grid_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

world_grid_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	w := cast(^World_Grid)driver

	switch action {
	case "init":
		w.player_x = 0
		w.player_y = 0
		w.player_level = 1
		w.visited_count = 1
		w.current_zone = "Village"
		return true
	case "move_up":
		move_up(w)
		return true
	case "move_down":
		move_down(w)
		return true
	case "move_left":
		move_left(w)
		return true
	case "move_right":
		move_right(w)
		return true
	case "level_up":
		level_up(w)
		return true
	case "blocked_move_level":
		// no-op
		return true
	case:
		return false
	}
}

world_grid_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	w := cast(^World_Grid)driver
	state := make(map[string]mbt.ITF_Value)
	state["player_x"] = mbt.ITF_Int{w.player_x}
	state["player_y"] = mbt.ITF_Int{w.player_y}
	state["player_level"] = mbt.ITF_Int{w.player_level}
	state["visited_count"] = mbt.ITF_Int{w.visited_count}
	state["current_zone"] = mbt.ITF_Str{w.current_zone}
	return state
}

@(test)
test_world_grid_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/world_grid_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	w: World_Grid
	result := mbt.replay_trace(&trace, &w, world_grid_step, world_grid_state)

	if result.failed > 0 {
		mbt.print_result(&result)
		for &e in result.errors {
			log.errorf("Step %d, var '%s': expected %s, got %s",
				e.step, e.var_name, e.expected, e.actual)
		}
	}

	testing.expectf(t, result.failed == 0,
		"MBT replay: %d/%d steps failed", result.failed, result.total_steps)
	log.infof("MBT replay: %d/%d steps passed", result.passed, result.total_steps)
}
