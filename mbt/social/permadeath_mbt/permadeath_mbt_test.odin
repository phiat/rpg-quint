package permadeath_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

permadeath_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	p := cast(^Permadeath_System)driver

	switch action {
	case "init":
		permadeath_init(p)
		return true
	case "take_damage":
		amount_val, ok := picks["amount"]
		if !ok do return false
		amount_int, ok2 := amount_val.(mbt.ITF_Int)
		if !ok2 do return false
		take_damage(p, amount_int.value)
		return true
	case "die_and_inherit":
		die_and_inherit(p)
		return true
	case "earn_gold":
		amount_val, ok := picks["amount"]
		if !ok do return false
		amount_int, ok2 := amount_val.(mbt.ITF_Int)
		if !ok2 do return false
		earn_gold(p, amount_int.value)
		return true
	case "deposit_legacy":
		amount_val, ok := picks["amount"]
		if !ok do return false
		amount_int, ok2 := amount_val.(mbt.ITF_Int)
		if !ok2 do return false
		deposit_legacy(p, amount_int.value)
		return true
	case:
		return false
	}
}

permadeath_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	p := cast(^Permadeath_System)driver
	state := make(map[string]mbt.ITF_Value)
	state["hp"] = mbt.ITF_Int{p.hp}
	state["alive"] = mbt.ITF_Bool{p.alive}
	state["generation"] = mbt.ITF_Int{p.generation}
	state["legacy_gold"] = mbt.ITF_Int{p.legacy_gold}
	state["legacy_bonus_atk"] = mbt.ITF_Int{p.legacy_bonus_atk}
	state["gold"] = mbt.ITF_Int{p.gold}
	state["total_deaths"] = mbt.ITF_Int{p.total_deaths}
	return state
}

@(test)
test_permadeath_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/permadeath_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	p: Permadeath_System
	result := mbt.replay_trace(&trace, &p, permadeath_step, permadeath_state)

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
