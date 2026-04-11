package leveling_mbt

import mbt "../quint_mbt"
import "core:testing"
import "core:log"

// Step handler: dispatch Quint action names to Leveler procs
leveling_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	l := cast(^Leveler)driver

	switch action {
	case "init":
		l.xp = 0
		l.level = 1
		l.hp_max = 100
		l.atk = 10
		l.xp_per_level = 100
		l.hp_per_level = 20
		l.atk_per_level = 5
		return true

	case "gain_xp", "gain_xp_no_level":
		amt_val, has := picks["amount"]
		if !has do return false
		amount, ok := mbt.value_as_int(amt_val)
		if !ok do return false
		gain_xp(l, amount)
		return true

	case:
		return false
	}
}

// State getter: extract Leveler state as ITF values for comparison
leveling_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	l := cast(^Leveler)driver
	state := make(map[string]mbt.ITF_Value)

	state["xp"] = mbt.ITF_Int{l.xp}
	state["level"] = mbt.ITF_Int{l.level}
	state["hp_max"] = mbt.ITF_Int{l.hp_max}
	state["atk"] = mbt.ITF_Int{l.atk}

	return state
}

@(test)
test_leveling_trace_replay :: proc(t: ^testing.T) {
	// Parse the ITF trace
	trace, err := mbt.parse_itf_file("traces/leveling_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	// Create a Leveler instance
	l: Leveler

	// Replay the trace
	result := mbt.replay_trace(&trace, &l, leveling_step, leveling_state)

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
