package fast_travel_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

fast_travel_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	s := cast(^Fast_Travel_State)driver

	switch action {
	case "init":
		s.pos_x = 0
		s.pos_y = 0
		s.gold = 20
		s.wp_00 = true
		s.wp_10 = false
		s.wp_20 = false
		s.wp_01 = false
		s.wp_11 = false
		s.wp_21 = false
		s.wp_02 = false
		s.wp_12 = false
		s.wp_22 = false
		return true
	case "move_up":
		return do_move(s, s.pos_x, s.pos_y - 1)
	case "move_down":
		return do_move(s, s.pos_x, s.pos_y + 1)
	case "move_left":
		return do_move(s, s.pos_x - 1, s.pos_y)
	case "move_right":
		return do_move(s, s.pos_x + 1, s.pos_y)
	case "fast_travel_00":
		return do_fast_travel(s, 0, 0)
	case "fast_travel_10":
		return do_fast_travel(s, 1, 0)
	case "fast_travel_20":
		return do_fast_travel(s, 2, 0)
	case "fast_travel_01":
		return do_fast_travel(s, 0, 1)
	case "fast_travel_11":
		return do_fast_travel(s, 1, 1)
	case "fast_travel_21":
		return do_fast_travel(s, 2, 1)
	case "fast_travel_02":
		return do_fast_travel(s, 0, 2)
	case "fast_travel_12":
		return do_fast_travel(s, 1, 2)
	case "fast_travel_22":
		return do_fast_travel(s, 2, 2)
	case:
		return false
	}
}

fast_travel_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	s := cast(^Fast_Travel_State)driver
	state := make(map[string]mbt.ITF_Value)
	state["pos_x"] = mbt.ITF_Int{s.pos_x}
	state["pos_y"] = mbt.ITF_Int{s.pos_y}
	state["gold"] = mbt.ITF_Int{s.gold}
	state["wp_00"] = mbt.ITF_Bool{s.wp_00}
	state["wp_10"] = mbt.ITF_Bool{s.wp_10}
	state["wp_20"] = mbt.ITF_Bool{s.wp_20}
	state["wp_01"] = mbt.ITF_Bool{s.wp_01}
	state["wp_11"] = mbt.ITF_Bool{s.wp_11}
	state["wp_21"] = mbt.ITF_Bool{s.wp_21}
	state["wp_02"] = mbt.ITF_Bool{s.wp_02}
	state["wp_12"] = mbt.ITF_Bool{s.wp_12}
	state["wp_22"] = mbt.ITF_Bool{s.wp_22}
	return state
}

@(test)
test_fast_travel_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/fast_travel_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	s: Fast_Travel_State
	result := mbt.replay_trace(&trace, &s, fast_travel_step, fast_travel_state)

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
