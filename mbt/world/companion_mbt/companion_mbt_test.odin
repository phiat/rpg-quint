package companion_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

companion_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	cs := cast(^Companion_System)driver

	switch action {
	case "init":
		companion_init(cs)
		return true
	case "adopt_companion":
		ctype_val, ok1 := picks["ctype"]
		if !ok1 do return false
		ctype_int, ok2 := ctype_val.(mbt.ITF_Int)
		if !ok2 do return false
		adopt_companion(cs, ctype_int.value)
		return true
	case "feed_companion":
		feed_companion(cs)
		return true
	case "enter_combat":
		enter_combat(cs)
		return true
	case "attack":
		attack(cs)
		return true
	case "rest":
		rest(cs)
		return true
	case "revive_companion":
		revive_companion(cs)
		return true
	case:
		return false
	}
}

companion_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	cs := cast(^Companion_System)driver
	state := make(map[string]mbt.ITF_Value)
	state["player_hp"] = mbt.ITF_Int{cs.player_hp}
	state["companion_hp"] = mbt.ITF_Int{cs.companion_hp}
	state["companion_max_hp"] = mbt.ITF_Int{cs.companion_max_hp}
	state["companion_alive"] = mbt.ITF_Bool{cs.companion_alive}
	state["loyalty"] = mbt.ITF_Int{cs.loyalty}
	state["companion_type"] = mbt.ITF_Int{cs.companion_type}
	state["in_combat"] = mbt.ITF_Bool{cs.in_combat}
	state["enemy_hp"] = mbt.ITF_Int{cs.enemy_hp}
	state["enemy_attack"] = mbt.ITF_Int{cs.enemy_attack}
	state["turn_count"] = mbt.ITF_Int{cs.turn_count}
	return state
}

@(test)
test_companion_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/companion_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	cs: Companion_System
	result := mbt.replay_trace(&trace, &cs, companion_step, companion_state)

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
