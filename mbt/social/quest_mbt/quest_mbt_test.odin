package quest_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

// Step handler: dispatch Quint action names to Quest_System procs
quest_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	qs := cast(^Quest_System)driver

	switch action {
	case "init":
		qs.quest1_status = "active"
		qs.quest2_status = "locked"
		qs.quest3_status = "locked"
		qs.quest1_step = 0
		qs.quest2_step = 0
		qs.quest3_step = 0
		qs.quest1_max = 2
		qs.quest2_max = 3
		qs.quest3_max = 2
		return true

	case "unlock_quest2":
		unlock_quest(qs, 2)
		return true

	case "unlock_quest3":
		unlock_quest(qs, 3)
		return true

	case "advance_quest1":
		advance_quest(qs, 1)
		return true

	case "advance_quest2":
		advance_quest(qs, 2)
		return true

	case "advance_quest3":
		advance_quest(qs, 3)
		return true

	case "fail_quest1":
		fail_quest(qs, 1)
		return true

	case "blocked_advance_locked":
		// Attempt to advance a locked quest — should be a no-op
		advance_quest(qs, 2)
		return true

	case:
		return false
	}
}

// State getter: extract Quest_System state as ITF values for comparison
quest_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	qs := cast(^Quest_System)driver
	state := make(map[string]mbt.ITF_Value)

	state["quest1_status"] = mbt.ITF_Str{qs.quest1_status}
	state["quest2_status"] = mbt.ITF_Str{qs.quest2_status}
	state["quest3_status"] = mbt.ITF_Str{qs.quest3_status}
	state["quest1_step"] = mbt.ITF_Int{qs.quest1_step}
	state["quest2_step"] = mbt.ITF_Int{qs.quest2_step}
	state["quest3_step"] = mbt.ITF_Int{qs.quest3_step}

	return state
}

@(test)
test_quest_trace_replay :: proc(t: ^testing.T) {
	// Parse the ITF trace
	trace, err := mbt.parse_itf_file("traces/quest_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	// Create a Quest_System instance
	qs: Quest_System

	// Replay the trace
	result := mbt.replay_trace(&trace, &qs, quest_step, quest_state)

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
