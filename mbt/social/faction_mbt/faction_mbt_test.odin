package faction_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

faction_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	f := cast(^Faction_System)driver

	switch action {
	case "init":
		faction_init(f)
		return true
	case "join_guild":
		join_guild(f)
		return true
	case "join_crown":
		join_crown(f)
		return true
	case "join_rebels":
		join_rebels(f)
		return true
	case "quest_guild":
		quest_guild(f)
		return true
	case "quest_crown":
		quest_crown(f)
		return true
	case "quest_rebels":
		quest_rebels(f)
		return true
	case "betray_current":
		betray_current(f)
		return true
	case:
		return false
	}
}

faction_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	f := cast(^Faction_System)driver
	state := make(map[string]mbt.ITF_Value)
	state["standing_guild"]  = mbt.ITF_Int{f.standing_guild}
	state["standing_crown"]  = mbt.ITF_Int{f.standing_crown}
	state["standing_rebels"] = mbt.ITF_Int{f.standing_rebels}
	state["allied_faction"]  = mbt.ITF_Int{f.allied_faction}
	return state
}

@(test)
test_faction_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/faction_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	f: Faction_System
	result := mbt.replay_trace(&trace, &f, faction_step, faction_state)

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
