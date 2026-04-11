package combat_mbt

import mbt "../quint_mbt"
import "core:testing"
import "core:log"

// Step handler: dispatch Quint action names to Combat procs
combat_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	c := cast(^Combat)driver

	switch action {
	case "init", "step":
		if c.hp_a == 0 && c.hp_b == 0 {
			// First call — initialize
			c.hp_a = 100
			c.hp_b = 100
			c.atk_a = 25
			c.atk_b = 20
			c.turn = "A"
			c.game_over = false
			return true
		}
		// Otherwise "step" is not a real action we handle — fall through
		return true

	case "attack_a":
		c.turn = "A"
		attack(c)
		return true

	case "attack_b":
		c.turn = "B"
		attack(c)
		return true

	case:
		return false
	}
}

// State getter: extract Combat state as ITF values for comparison
combat_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	c := cast(^Combat)driver
	state := make(map[string]mbt.ITF_Value)

	state["hp_a"] = mbt.ITF_Int{c.hp_a}
	state["hp_b"] = mbt.ITF_Int{c.hp_b}
	state["atk_a"] = mbt.ITF_Int{c.atk_a}
	state["atk_b"] = mbt.ITF_Int{c.atk_b}
	state["turn"] = mbt.ITF_Str{c.turn}
	state["game_over"] = mbt.ITF_Bool{c.game_over}

	return state
}

@(test)
test_combat_trace_replay :: proc(t: ^testing.T) {
	// Parse the ITF trace
	trace, err := mbt.parse_itf_file("traces/combat_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	// Create a Combat instance
	c: Combat

	// Replay the trace
	result := mbt.replay_trace(&trace, &c, combat_step, combat_state)

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
