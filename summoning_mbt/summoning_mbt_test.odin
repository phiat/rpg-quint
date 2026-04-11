package summoning_mbt

import mbt "../quint_mbt"
import "core:testing"
import "core:log"

summoning_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	ss := cast(^Summoning_System)driver

	switch action {
	case "init":
		for i in 0 ..< 3 {
			ss.slots[i] = {}
		}
		ss.active_count = 0
		return true
	case "summon_slot1":
		hp_val, ok1 := picks["hp"]
		if !ok1 do return false
		hp_int, ok2 := hp_val.(mbt.ITF_Int)
		if !ok2 do return false
		dur_val, ok3 := picks["dur"]
		if !ok3 do return false
		dur_int, ok4 := dur_val.(mbt.ITF_Int)
		if !ok4 do return false
		summon_slot(ss, 0, hp_int.value, dur_int.value)
		return true
	case "summon_slot2":
		hp_val, ok1 := picks["hp"]
		if !ok1 do return false
		hp_int, ok2 := hp_val.(mbt.ITF_Int)
		if !ok2 do return false
		dur_val, ok3 := picks["dur"]
		if !ok3 do return false
		dur_int, ok4 := dur_val.(mbt.ITF_Int)
		if !ok4 do return false
		summon_slot(ss, 1, hp_int.value, dur_int.value)
		return true
	case "summon_slot3":
		hp_val, ok1 := picks["hp"]
		if !ok1 do return false
		hp_int, ok2 := hp_val.(mbt.ITF_Int)
		if !ok2 do return false
		dur_val, ok3 := picks["dur"]
		if !ok3 do return false
		dur_int, ok4 := dur_val.(mbt.ITF_Int)
		if !ok4 do return false
		summon_slot(ss, 2, hp_int.value, dur_int.value)
		return true
	case "tick_duration":
		tick_duration(ss)
		return true
	case "dismiss_slot1":
		dismiss_slot(ss, 0)
		return true
	case "dismiss_slot2":
		dismiss_slot(ss, 1)
		return true
	case "dismiss_slot3":
		dismiss_slot(ss, 2)
		return true
	case "blocked_summon_full":
		// no-op
		return true
	case:
		return false
	}
}

summoning_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	ss := cast(^Summoning_System)driver
	state := make(map[string]mbt.ITF_Value)
	state["slot1_active"] = mbt.ITF_Bool{ss.slots[0].active}
	state["slot1_hp"] = mbt.ITF_Int{ss.slots[0].hp}
	state["slot1_dur"] = mbt.ITF_Int{ss.slots[0].dur}
	state["slot2_active"] = mbt.ITF_Bool{ss.slots[1].active}
	state["slot2_hp"] = mbt.ITF_Int{ss.slots[1].hp}
	state["slot2_dur"] = mbt.ITF_Int{ss.slots[1].dur}
	state["slot3_active"] = mbt.ITF_Bool{ss.slots[2].active}
	state["slot3_hp"] = mbt.ITF_Int{ss.slots[2].hp}
	state["slot3_dur"] = mbt.ITF_Int{ss.slots[2].dur}
	state["active_count"] = mbt.ITF_Int{ss.active_count}
	return state
}

@(test)
test_summoning_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/summoning_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	ss: Summoning_System
	result := mbt.replay_trace(&trace, &ss, summoning_step, summoning_state)

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
