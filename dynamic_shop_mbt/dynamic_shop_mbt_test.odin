package dynamic_shop_mbt

import mbt "../quint_mbt"
import "core:log"
import "core:testing"

// Step handler: dispatch Quint action names to Dynamic_Shop procs
dynamic_shop_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	s := cast(^Dynamic_Shop)driver

	switch action {
	case "init":
		s.player_gold = 200
		s.shop_gold = 500
		s.shop_swords = 3
		s.shop_shields = 3
		s.shop_potions = 3
		s.player_swords = 0
		s.player_shields = 0
		s.player_potions = 0
		s.base_price = BASE_PRICE
		return true

	case "buy_sword":
		buy_sword(s)
		return true

	case "buy_shield":
		buy_shield(s)
		return true

	case "buy_potion":
		buy_potion(s)
		return true

	case "sell_sword":
		sell_sword(s)
		return true

	case "sell_shield":
		sell_shield(s)
		return true

	case "sell_potion":
		sell_potion(s)
		return true

	case:
		return false
	}
}

// State getter: extract Dynamic_Shop state as ITF values for comparison
dynamic_shop_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	s := cast(^Dynamic_Shop)driver
	state := make(map[string]mbt.ITF_Value)

	state["player_gold"] = mbt.ITF_Int{s.player_gold}
	state["shop_gold"] = mbt.ITF_Int{s.shop_gold}
	state["shop_swords"] = mbt.ITF_Int{s.shop_swords}
	state["shop_shields"] = mbt.ITF_Int{s.shop_shields}
	state["shop_potions"] = mbt.ITF_Int{s.shop_potions}
	state["player_swords"] = mbt.ITF_Int{s.player_swords}
	state["player_shields"] = mbt.ITF_Int{s.player_shields}
	state["player_potions"] = mbt.ITF_Int{s.player_potions}

	return state
}

@(test)
test_dynamic_shop_trace_replay :: proc(t: ^testing.T) {
	// Parse the ITF trace
	trace, err := mbt.parse_itf_file("traces/dynamic_shop_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	// Create a Dynamic_Shop instance
	s: Dynamic_Shop

	// Replay the trace
	result := mbt.replay_trace(&trace, &s, dynamic_shop_step, dynamic_shop_state)

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
