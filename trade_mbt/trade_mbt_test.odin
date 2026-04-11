package trade_mbt

import mbt "../quint_mbt"
import "core:fmt"
import "core:log"
import "core:testing"

// Step handler: dispatch Quint action names to Trade_System procs
trade_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	sys := cast(^Trade_System)driver

	switch action {
	case "init":
		clear(&sys.player_a.inv)
		append(&sys.player_a.inv, "Sword", "Shield")
		sys.player_a.inv_cap = 3
		clear(&sys.player_b.inv)
		append(&sys.player_b.inv, "Potion")
		sys.player_b.inv_cap = 3
		sys.last_action = "init"
		return true

	case "give_a_to_b":
		itm_val, has := picks["itm"]
		if !has do return false
		itm, ok := mbt.value_as_str(itm_val)
		if !ok do return false
		give_item(&sys.player_a, &sys.player_b, itm)
		sys.last_action = "give_a_to_b"
		return true

	case "give_b_to_a":
		itm_val, has := picks["itm"]
		if !has do return false
		itm, ok := mbt.value_as_str(itm_val)
		if !ok do return false
		give_item(&sys.player_b, &sys.player_a, itm)
		sys.last_action = "give_b_to_a"
		return true

	case "trade_blocked_b_full":
		itm_val, has := picks["itm"]
		if !has do return false
		itm, ok := mbt.value_as_str(itm_val)
		if !ok do return false
		// Attempt the trade — should be rejected
		give_item(&sys.player_a, &sys.player_b, itm)
		sys.last_action = "trade_blocked_b_full"
		return true

	case "trade_blocked_a_full":
		itm_val, has := picks["itm"]
		if !has do return false
		itm, ok := mbt.value_as_str(itm_val)
		if !ok do return false
		give_item(&sys.player_b, &sys.player_a, itm)
		sys.last_action = "trade_blocked_a_full"
		return true

	case:
		return false
	}
}

// State getter: extract Trade_System state as ITF values for comparison
trade_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	sys := cast(^Trade_System)driver
	state := make(map[string]mbt.ITF_Value)

	// inv_a
	inv_a_list := mbt.ITF_List{}
	inv_a_list.items = make([dynamic]mbt.ITF_Value, 0, len(sys.player_a.inv))
	for s in sys.player_a.inv {
		append(&inv_a_list.items, mbt.ITF_Value(mbt.ITF_Str{s}))
	}
	state["inv_a"] = inv_a_list

	// inv_b
	inv_b_list := mbt.ITF_List{}
	inv_b_list.items = make([dynamic]mbt.ITF_Value, 0, len(sys.player_b.inv))
	for s in sys.player_b.inv {
		append(&inv_b_list.items, mbt.ITF_Value(mbt.ITF_Str{s}))
	}
	state["inv_b"] = inv_b_list

	// last_action
	state["last_action"] = mbt.ITF_Str{sys.last_action}

	return state
}

@(test)
test_trade_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/trade_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	sys: Trade_System
	defer delete(sys.player_a.inv)
	defer delete(sys.player_b.inv)

	result := mbt.replay_trace(&trace, &sys, trade_step, trade_state)

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
