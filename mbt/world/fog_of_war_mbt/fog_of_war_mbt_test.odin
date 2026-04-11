package fog_of_war_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

fog_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	s := cast(^Fog_State)driver

	switch action {
	case "init":
		s.pos_x = 0
		s.pos_y = 0
		for x in 0 ..< FOG_GRID_SIZE {
			for y in 0 ..< FOG_GRID_SIZE {
				s.visited[x][y] = false
				s.revealed[x][y] = false
			}
		}
		s.visited[0][0] = true
		update_revealed(s)
		return true
	case "move_up":
		do_move(s, s.pos_x, s.pos_y - 1)
		return true
	case "move_down":
		do_move(s, s.pos_x, s.pos_y + 1)
		return true
	case "move_left":
		do_move(s, s.pos_x - 1, s.pos_y)
		return true
	case "move_right":
		do_move(s, s.pos_x + 1, s.pos_y)
		return true
	case:
		return false
	}
}

fog_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	s := cast(^Fog_State)driver
	state := make(map[string]mbt.ITF_Value)
	state["pos_x"] = mbt.ITF_Int{s.pos_x}
	state["pos_y"] = mbt.ITF_Int{s.pos_y}
	state["visited_00"] = mbt.ITF_Bool{s.visited[0][0]}
	state["visited_01"] = mbt.ITF_Bool{s.visited[0][1]}
	state["visited_02"] = mbt.ITF_Bool{s.visited[0][2]}
	state["visited_10"] = mbt.ITF_Bool{s.visited[1][0]}
	state["visited_11"] = mbt.ITF_Bool{s.visited[1][1]}
	state["visited_12"] = mbt.ITF_Bool{s.visited[1][2]}
	state["visited_20"] = mbt.ITF_Bool{s.visited[2][0]}
	state["visited_21"] = mbt.ITF_Bool{s.visited[2][1]}
	state["visited_22"] = mbt.ITF_Bool{s.visited[2][2]}
	state["revealed_00"] = mbt.ITF_Bool{s.revealed[0][0]}
	state["revealed_01"] = mbt.ITF_Bool{s.revealed[0][1]}
	state["revealed_02"] = mbt.ITF_Bool{s.revealed[0][2]}
	state["revealed_10"] = mbt.ITF_Bool{s.revealed[1][0]}
	state["revealed_11"] = mbt.ITF_Bool{s.revealed[1][1]}
	state["revealed_12"] = mbt.ITF_Bool{s.revealed[1][2]}
	state["revealed_20"] = mbt.ITF_Bool{s.revealed[2][0]}
	state["revealed_21"] = mbt.ITF_Bool{s.revealed[2][1]}
	state["revealed_22"] = mbt.ITF_Bool{s.revealed[2][2]}
	return state
}

@(test)
test_fog_of_war_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/fog_of_war_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}
	defer mbt.delete_trace(&trace)

	s: Fog_State
	result := mbt.replay_trace(&trace, &s, fog_step, fog_state)
	defer mbt.delete_result(&result)

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
