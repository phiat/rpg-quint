package reputation_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

reputation_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	r := cast(^Reputation_System)driver

	switch action {
	case "init":
		r.rep_warriors = 0
		r.rep_mages = 0
		r.rep_thieves = 0
		return true
	case "help_warriors":
		amount_val, ok := picks["amount"]
		if !ok do return false
		amount_int, ok2 := amount_val.(mbt.ITF_Int)
		if !ok2 do return false
		help_warriors(r, amount_int.value)
		return true
	case "help_mages":
		amount_val, ok := picks["amount"]
		if !ok do return false
		amount_int, ok2 := amount_val.(mbt.ITF_Int)
		if !ok2 do return false
		help_mages(r, amount_int.value)
		return true
	case "help_thieves":
		amount_val, ok := picks["amount"]
		if !ok do return false
		amount_int, ok2 := amount_val.(mbt.ITF_Int)
		if !ok2 do return false
		help_thieves(r, amount_int.value)
		return true
	case "betray_warriors":
		betray_warriors(r)
		return true
	case "betray_thieves":
		betray_thieves(r)
		return true
	case:
		return false
	}
}

reputation_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	r := cast(^Reputation_System)driver
	state := make(map[string]mbt.ITF_Value)
	state["rep_warriors"] = mbt.ITF_Int{r.rep_warriors}
	state["rep_mages"] = mbt.ITF_Int{r.rep_mages}
	state["rep_thieves"] = mbt.ITF_Int{r.rep_thieves}
	return state
}

@(test)
test_reputation_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/reputation_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	r: Reputation_System
	result := mbt.replay_trace(&trace, &r, reputation_step, reputation_state)

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
