package cooldown_mbt

import mbt "../quint_mbt"
import "core:testing"
import "core:log"

// Step handler: dispatch Quint action names to Cooldown_System procs
cooldown_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	cs := cast(^Cooldown_System)driver

	switch action {
	case "init":
		cs.cd_fireball = 0
		cs.cd_heal = 0
		cs.cd_shield = 0
		cs.current_turn = 0
		return true

	case "use_fireball":
		use_fireball(cs)
		cs.current_turn += 1
		return true

	case "use_heal":
		use_heal(cs)
		cs.current_turn += 1
		return true

	case "use_shield":
		use_shield(cs)
		cs.current_turn += 1
		return true

	case "tick":
		tick(cs)
		cs.current_turn += 1
		return true

	case "blocked_fireball":
		cs.current_turn += 1
		return true

	case "blocked_heal":
		cs.current_turn += 1
		return true

	case "blocked_shield":
		cs.current_turn += 1
		return true

	case:
		return false
	}
}

// State getter: extract Cooldown_System state as ITF values for comparison
cooldown_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	cs := cast(^Cooldown_System)driver
	state := make(map[string]mbt.ITF_Value)

	state["cd_fireball"] = mbt.ITF_Int{cs.cd_fireball}
	state["cd_heal"] = mbt.ITF_Int{cs.cd_heal}
	state["cd_shield"] = mbt.ITF_Int{cs.cd_shield}
	state["current_turn"] = mbt.ITF_Int{cs.current_turn}

	return state
}

@(test)
test_cooldown_trace_replay :: proc(t: ^testing.T) {
	// Parse the ITF trace
	trace, err := mbt.parse_itf_file("traces/cooldown_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	// Create a Cooldown_System instance
	cs: Cooldown_System

	// Replay the trace
	result := mbt.replay_trace(&trace, &cs, cooldown_step, cooldown_state)

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
