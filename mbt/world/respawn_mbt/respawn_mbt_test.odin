package respawn_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

// Step handler: dispatch Quint action names to Respawn_System procs
respawn_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	sys := cast(^Respawn_System)driver

	switch action {
	case "init":
		sys.zone1_count = 3
		sys.zone2_count = 2
		sys.dead_count = 0
		sys.timer1 = 0
		sys.timer2 = 0
		return true

	case "kill_zone1":
		kill_zone(sys, 1)
		return true

	case "kill_zone2":
		kill_zone(sys, 2)
		return true

	case "tick_respawn":
		tick_respawn(sys)
		return true

	case "spawn_zone1":
		spawn_zone(sys, 1)
		return true

	case "spawn_zone2":
		spawn_zone(sys, 2)
		return true

	case "blocked_spawn_full":
		// No-op: spawn is blocked because zone is full
		return true

	case:
		return false
	}
}

// State getter: extract Respawn_System state as ITF values for comparison
respawn_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	sys := cast(^Respawn_System)driver
	state := make(map[string]mbt.ITF_Value)

	state["zone1_count"] = mbt.ITF_Int{sys.zone1_count}
	state["zone2_count"] = mbt.ITF_Int{sys.zone2_count}
	state["dead_count"] = mbt.ITF_Int{sys.dead_count}
	state["timer1"] = mbt.ITF_Int{sys.timer1}
	state["timer2"] = mbt.ITF_Int{sys.timer2}

	return state
}

@(test)
test_respawn_trace_replay :: proc(t: ^testing.T) {
	// Parse the ITF trace
	trace, err := mbt.parse_itf_file("traces/respawn_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	// Create a Respawn_System instance
	sys: Respawn_System

	// Replay the trace
	result := mbt.replay_trace(&trace, &sys, respawn_step, respawn_state)

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
