package shop_mbt

import mbt "../../../quint_mbt"
import "core:log"
import "core:testing"

// Step handler: dispatch Quint action names to Shop_System procs
shop_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	s := cast(^Shop_System)driver

	switch action {
	case "init":
		s.player_gold = 100
		s.shop_gold = 200
		s.price = 25
		s.max_inv = 10
		clear(&s.player_inv)
		clear(&s.shop_inv)
		append(&s.shop_inv, "Sword")
		append(&s.shop_inv, "Shield")
		append(&s.shop_inv, "Potion")
		return true

	case "buy":
		itm_val, has_itm := picks["itm"]
		if !has_itm do return false
		itm, ok := mbt.value_as_str(itm_val)
		if !ok do return false
		buy(s, itm)
		return true

	case "sell":
		itm_val, has_itm := picks["itm"]
		if !has_itm do return false
		itm, ok := mbt.value_as_str(itm_val)
		if !ok do return false
		sell(s, itm)
		return true

	case "buy_blocked_no_gold":
		// No-op: player cannot afford the item
		return true

	case "sell_blocked_no_item":
		// No-op: player does not have the item
		return true

	case:
		return false
	}
}

// State getter: extract Shop_System state as ITF values for comparison
shop_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	s := cast(^Shop_System)driver
	state := make(map[string]mbt.ITF_Value)

	state["player_gold"] = mbt.ITF_Int{s.player_gold}
	state["shop_gold"] = mbt.ITF_Int{s.shop_gold}

	// Convert player_inv to ITF_List
	p_list := mbt.ITF_List{}
	p_list.items = make([dynamic]mbt.ITF_Value, 0, len(s.player_inv))
	for item in s.player_inv {
		append(&p_list.items, mbt.ITF_Value(mbt.ITF_Str{item}))
	}
	state["player_inv"] = p_list

	// Convert shop_inv to ITF_List
	s_list := mbt.ITF_List{}
	s_list.items = make([dynamic]mbt.ITF_Value, 0, len(s.shop_inv))
	for item in s.shop_inv {
		append(&s_list.items, mbt.ITF_Value(mbt.ITF_Str{item}))
	}
	state["shop_inv"] = s_list

	return state
}

@(test)
test_shop_trace_replay :: proc(t: ^testing.T) {
	// Parse the ITF trace
	trace, err := mbt.parse_itf_file("traces/shop_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	// Create a Shop_System instance
	s: Shop_System
	defer delete(s.player_inv)
	defer delete(s.shop_inv)

	// Replay the trace
	result := mbt.replay_trace(&trace, &s, shop_step, shop_state)

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
