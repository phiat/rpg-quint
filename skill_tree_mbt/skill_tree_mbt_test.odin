package skill_tree_mbt

import mbt "../quint_mbt"
import "core:testing"
import "core:log"

skill_tree_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	st := cast(^Skill_Tree)driver

	switch action {
	case "init":
		st.skill_points = 3
		st.total_earned = 3
		st.strength = false
		st.agility = false
		st.power_strike = false
		st.quick_dodge = false
		st.whirlwind = false
		st.shadow_step = false
		return true
	case "unlock_strength":
		unlock_strength(st)
		return true
	case "unlock_agility":
		unlock_agility(st)
		return true
	case "unlock_power_strike":
		unlock_power_strike(st)
		return true
	case "unlock_quick_dodge":
		unlock_quick_dodge(st)
		return true
	case "unlock_whirlwind":
		unlock_whirlwind(st)
		return true
	case "unlock_shadow_step":
		unlock_shadow_step(st)
		return true
	case "earn_points":
		amount_val, ok := picks["amount"]
		if !ok do return false
		amount_int, ok2 := amount_val.(mbt.ITF_Int)
		if !ok2 do return false
		earn_points(st, amount_int.value)
		return true
	case "respec":
		respec(st)
		return true
	case "blocked_no_prereq":
		// no-op
		return true
	case:
		return false
	}
}

skill_tree_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	st := cast(^Skill_Tree)driver
	state := make(map[string]mbt.ITF_Value)
	state["skill_points"] = mbt.ITF_Int{st.skill_points}
	state["total_earned"] = mbt.ITF_Int{st.total_earned}
	state["strength"] = mbt.ITF_Bool{st.strength}
	state["agility"] = mbt.ITF_Bool{st.agility}
	state["power_strike"] = mbt.ITF_Bool{st.power_strike}
	state["quick_dodge"] = mbt.ITF_Bool{st.quick_dodge}
	state["whirlwind"] = mbt.ITF_Bool{st.whirlwind}
	state["shadow_step"] = mbt.ITF_Bool{st.shadow_step}
	return state
}

@(test)
test_skill_tree_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/skill_tree_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	st: Skill_Tree
	result := mbt.replay_trace(&trace, &st, skill_tree_step, skill_tree_state)

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
