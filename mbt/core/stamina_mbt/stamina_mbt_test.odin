package stamina_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

stamina_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	s := cast(^Stamina_System)driver

	switch action {
	case "init":
		s.current_stamina = 10
		s.max_stamina = 10
		s.regen_rate = 3
		s.turn = 0
		return true
	case "attack":
		attack(s)
		return true
	case "defend":
		defend(s)
		return true
	case "special":
		special(s)
		return true
	case "rest":
		rest(s)
		return true
	case "blocked_no_stamina":
		s.turn += 1
		return true
	case:
		return false
	}
}

stamina_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	s := cast(^Stamina_System)driver
	state := make(map[string]mbt.ITF_Value)
	state["current_stamina"] = mbt.ITF_Int{s.current_stamina}
	state["max_stamina"] = mbt.ITF_Int{s.max_stamina}
	state["regen_rate"] = mbt.ITF_Int{s.regen_rate}
	state["turn"] = mbt.ITF_Int{s.turn}
	return state
}

@(test)
test_stamina_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/stamina_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	s: Stamina_System
	result := mbt.replay_trace(&trace, &s, stamina_step, stamina_state)

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
