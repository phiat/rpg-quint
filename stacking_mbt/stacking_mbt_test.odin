package stacking_mbt

import mbt "../quint_mbt"
import "core:log"
import "core:testing"

// Step handler: dispatch Quint action names to Stacks procs.
// No nondet picks — all actions are parameterless.
stacking_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	s := cast(^Stacks)driver

	switch action {
	case "init":
		s.qty_sword = 2
		s.qty_shield = 1
		s.qty_potion = 3
		return true

	case "add_sword":
		add_sword(s)
		return true

	case "add_shield":
		add_shield(s)
		return true

	case "add_potion":
		add_potion(s)
		return true

	case "remove_sword":
		remove_sword(s)
		return true

	case "remove_shield":
		remove_shield(s)
		return true

	case "remove_potion":
		remove_potion(s)
		return true

	case:
		return false
	}
}

// State getter: return current quantities as ITF values for comparison.
stacking_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	s := cast(^Stacks)driver
	state := make(map[string]mbt.ITF_Value)

	state["qty_sword"] = mbt.ITF_Int{s.qty_sword}
	state["qty_shield"] = mbt.ITF_Int{s.qty_shield}
	state["qty_potion"] = mbt.ITF_Int{s.qty_potion}

	return state
}

@(test)
test_stacking_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/stacking_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	stacks: Stacks

	result := mbt.replay_trace(&trace, &stacks, stacking_step, stacking_state)

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
