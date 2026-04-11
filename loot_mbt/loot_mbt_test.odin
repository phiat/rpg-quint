package loot_mbt

import mbt "../quint_mbt"
import "core:testing"
import "core:log"

// Step handler: dispatch Quint action names to Loot_System procs
loot_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	ls := cast(^Loot_System)driver

	switch action {
	case "init":
		ls.pity_counter = 0
		ls.total_drops = 0
		ls.rare_drops = 0
		ls.common_drops = 0
		ls.last_rarity = "none"
		ls.guaranteed_next = false
		ls.pity_threshold = PITY_THRESHOLD
		return true

	case "drop_common":
		drop_common(ls)
		return true

	case "drop_rare":
		drop_rare(ls)
		return true

	case "drop_guaranteed_rare":
		drop_guaranteed_rare(ls)
		return true

	case:
		return false
	}
}

// State getter: extract Loot_System state as ITF values for comparison
loot_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	ls := cast(^Loot_System)driver
	state := make(map[string]mbt.ITF_Value)

	state["pity_counter"] = mbt.ITF_Int{ls.pity_counter}
	state["total_drops"] = mbt.ITF_Int{ls.total_drops}
	state["rare_drops"] = mbt.ITF_Int{ls.rare_drops}
	state["common_drops"] = mbt.ITF_Int{ls.common_drops}
	state["last_rarity"] = mbt.ITF_Str{ls.last_rarity}
	state["guaranteed_next"] = mbt.ITF_Bool{ls.guaranteed_next}

	return state
}

@(test)
test_loot_trace_replay :: proc(t: ^testing.T) {
	// Parse the ITF trace
	trace, err := mbt.parse_itf_file("traces/loot_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	// Create a Loot_System instance
	ls: Loot_System

	// Replay the trace
	result := mbt.replay_trace(&trace, &ls, loot_step, loot_state)

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
