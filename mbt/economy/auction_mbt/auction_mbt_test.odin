package auction_mbt

import mbt "../../../quint_mbt"
import "core:log"
import "core:testing"

// Step handler: dispatch Quint action names to Auction_System procs
auction_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	sys := cast(^Auction_System)driver

	switch action {
	case "init":
		sys.seller_gold        = 200
		sys.seller_items       = 3
		sys.buyer_gold         = 150
		sys.buyer_items        = 0
		sys.listing_active     = false
		sys.listing_price      = 0
		sys.listing_item_count = 0
		sys.last_action        = "init"
		return true

	case "list_item":
		price_val, has := picks["price"]
		if !has do return false
		price, ok := mbt.value_as_int(price_val)
		if !ok do return false
		list_item(sys, price)
		return true

	case "buy_listing":
		buy_listing(sys)
		return true

	case "cancel_listing":
		cancel_listing(sys)
		return true

	case "tick_auction":
		tick_auction(sys)
		return true

	case:
		return false
	}
}

// State getter: expose Auction_System fields as ITF values for comparison
auction_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	sys := cast(^Auction_System)driver
	state := make(map[string]mbt.ITF_Value)

	state["seller_gold"]        = mbt.ITF_Int{sys.seller_gold}
	state["seller_items"]       = mbt.ITF_Int{sys.seller_items}
	state["buyer_gold"]         = mbt.ITF_Int{sys.buyer_gold}
	state["buyer_items"]        = mbt.ITF_Int{sys.buyer_items}
	state["listing_active"]     = mbt.ITF_Bool{sys.listing_active}
	state["listing_price"]      = mbt.ITF_Int{sys.listing_price}
	state["listing_item_count"] = mbt.ITF_Int{sys.listing_item_count}
	state["last_action"]        = mbt.ITF_Str{sys.last_action}

	return state
}

@(test)
test_auction_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/auction_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	sys: Auction_System

	result := mbt.replay_trace(&trace, &sys, auction_step, auction_state)

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
