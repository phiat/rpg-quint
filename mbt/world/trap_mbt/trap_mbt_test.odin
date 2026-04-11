package trap_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

trap_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	s := cast(^Trap_State)driver

	switch action {
	case "init":
		s.pos_x = 0
		s.pos_y = 0
		s.hp = 50
		s.max_hp = 50
		s.perception = 2
		s.trap_present_00 = false
		s.trap_present_01 = true
		s.trap_present_10 = true
		s.trap_present_11 = false
		s.trap_revealed_00 = false
		s.trap_revealed_01 = false
		s.trap_revealed_10 = false
		s.trap_revealed_11 = false
		s.trap_triggered_00 = false
		s.trap_triggered_01 = false
		s.trap_triggered_10 = false
		s.trap_triggered_11 = false
		return true
	case "move_right":
		do_move(s, 1, 0)
		return true
	case "move_left":
		do_move(s, -1, 0)
		return true
	case "move_down":
		do_move(s, 0, 1)
		return true
	case "move_up":
		do_move(s, 0, -1)
		return true
	case "scan":
		do_scan(s)
		return true
	case "upgrade_perception":
		do_upgrade_perception(s)
		return true
	case:
		return false
	}
}

trap_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	s := cast(^Trap_State)driver
	state := make(map[string]mbt.ITF_Value)
	state["pos_x"] = mbt.ITF_Int{s.pos_x}
	state["pos_y"] = mbt.ITF_Int{s.pos_y}
	state["hp"] = mbt.ITF_Int{s.hp}
	state["max_hp"] = mbt.ITF_Int{s.max_hp}
	state["perception"] = mbt.ITF_Int{s.perception}
	state["trap_present_00"] = mbt.ITF_Bool{s.trap_present_00}
	state["trap_present_01"] = mbt.ITF_Bool{s.trap_present_01}
	state["trap_present_10"] = mbt.ITF_Bool{s.trap_present_10}
	state["trap_present_11"] = mbt.ITF_Bool{s.trap_present_11}
	state["trap_revealed_00"] = mbt.ITF_Bool{s.trap_revealed_00}
	state["trap_revealed_01"] = mbt.ITF_Bool{s.trap_revealed_01}
	state["trap_revealed_10"] = mbt.ITF_Bool{s.trap_revealed_10}
	state["trap_revealed_11"] = mbt.ITF_Bool{s.trap_revealed_11}
	state["trap_triggered_00"] = mbt.ITF_Bool{s.trap_triggered_00}
	state["trap_triggered_01"] = mbt.ITF_Bool{s.trap_triggered_01}
	state["trap_triggered_10"] = mbt.ITF_Bool{s.trap_triggered_10}
	state["trap_triggered_11"] = mbt.ITF_Bool{s.trap_triggered_11}
	return state
}

@(test)
test_trap_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/trap_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	s: Trap_State
	result := mbt.replay_trace(&trace, &s, trap_step, trap_state)

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
