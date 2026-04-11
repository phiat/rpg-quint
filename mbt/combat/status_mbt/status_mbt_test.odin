package status_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

// Step handler: dispatch Quint action names to Status_System procs
status_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	s := cast(^Status_System)driver

	switch action {
	case "init":
		s.hp = 100
		s.base_atk = 25
		s.poison_turns = 0
		s.buff_turns = 0
		s.poison_dmg = 0
		s.buff_amount = 0
		return true

	case "apply_poison":
		dmg_val, has_dmg := picks["dmg"]
		if !has_dmg do return false
		dmg, dmg_ok := mbt.value_as_int(dmg_val)
		if !dmg_ok do return false

		dur_val, has_dur := picks["dur"]
		if !has_dur do return false
		dur, dur_ok := mbt.value_as_int(dur_val)
		if !dur_ok do return false

		apply_poison(s, dmg, dur)
		return true

	case "apply_buff":
		amt_val, has_amt := picks["amt"]
		if !has_amt do return false
		amt, amt_ok := mbt.value_as_int(amt_val)
		if !amt_ok do return false

		dur_val, has_dur := picks["dur"]
		if !has_dur do return false
		dur, dur_ok := mbt.value_as_int(dur_val)
		if !dur_ok do return false

		apply_buff(s, amt, dur)
		return true

	case "tick":
		tick(s)
		return true

	case "tick_no_effects":
		// No-op when no active effects
		return true

	case:
		return false
	}
}

// State getter: extract Status_System state as ITF values for comparison
status_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	s := cast(^Status_System)driver
	state := make(map[string]mbt.ITF_Value)

	state["hp"] = mbt.ITF_Int{s.hp}
	state["base_atk"] = mbt.ITF_Int{s.base_atk}
	state["poison_turns"] = mbt.ITF_Int{s.poison_turns}
	state["buff_turns"] = mbt.ITF_Int{s.buff_turns}
	state["poison_dmg"] = mbt.ITF_Int{s.poison_dmg}
	state["buff_amount"] = mbt.ITF_Int{s.buff_amount}

	return state
}

@(test)
test_status_trace_replay :: proc(t: ^testing.T) {
	// Parse the ITF trace
	trace, err := mbt.parse_itf_file("traces/status_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	// Create a Status_System instance
	sys: Status_System

	// Replay the trace
	result := mbt.replay_trace(&trace, &sys, status_step, status_state)

	// Report results
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
