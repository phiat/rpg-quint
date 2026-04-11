package dialogue_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

// Step handler: dispatch Quint action names to Dialogue_System procs
dialogue_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	d := cast(^Dialogue_System)driver

	switch action {
	case "init":
		dialogue_init(d)
		return true

	case "start_dialogue":
		dialogue_start(d)
		return true

	case "choose_branch_1":
		dialogue_choose_branch(d, 1)
		return true

	case "choose_branch_2":
		dialogue_choose_branch(d, 2)
		return true

	case "choose_branch_3":
		dialogue_choose_branch(d, 3)
		return true

	case "advance_to_end":
		dialogue_advance_to_end(d)
		return true

	case "end_dialogue":
		dialogue_end(d)
		return true

	case:
		return false
	}
}

// State getter: extract Dialogue_System state as ITF values for comparison
dialogue_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	d := cast(^Dialogue_System)driver
	state := make(map[string]mbt.ITF_Value)

	state["current_node"]      = mbt.ITF_Int{d.current_node}
	state["in_dialogue"]       = mbt.ITF_Bool{d.in_dialogue}
	state["choices_made"]      = mbt.ITF_Int{d.choices_made}
	state["visited_1"]         = mbt.ITF_Bool{d.visited_1}
	state["visited_2"]         = mbt.ITF_Bool{d.visited_2}
	state["visited_3"]         = mbt.ITF_Bool{d.visited_3}
	state["reputation_change"] = mbt.ITF_Int{d.reputation_change}

	return state
}

@(test)
test_dialogue_trace_replay :: proc(t: ^testing.T) {
	// Parse the ITF trace
	trace, err := mbt.parse_itf_file("traces/dialogue_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	// Create a Dialogue_System instance
	d: Dialogue_System

	// Replay the trace
	result := mbt.replay_trace(&trace, &d, dialogue_step, dialogue_state)

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
