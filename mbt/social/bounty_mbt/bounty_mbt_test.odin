package bounty_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

// Step handler: dispatch Quint action names to Bounty_Board procs
bounty_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	b := cast(^Bounty_Board)driver

	switch action {
	case "init":
		b.slots[0] = Bounty_Slot{active = true, kills_needed = 3, current_kills = 0, reward_gold = 50}
		b.slots[1] = Bounty_Slot{active = true, kills_needed = 5, current_kills = 0, reward_gold = 80}
		b.slots[2] = Bounty_Slot{active = true, kills_needed = 2, current_kills = 0, reward_gold = 30}
		b.player_gold = 0
		b.active_bounty_idx = 0
		return true

	case "accept_bounty_1":
		accept_bounty(b, 1)
		return true

	case "accept_bounty_2":
		accept_bounty(b, 2)
		return true

	case "accept_bounty_3":
		accept_bounty(b, 3)
		return true

	case "record_kill":
		record_kill(b)
		return true

	case "claim_bounty":
		claim_bounty(b)
		return true

	case "abandon_bounty":
		abandon_bounty(b)
		return true

	case "refresh_board":
		refresh_board(b)
		return true

	case:
		return false
	}
}

// State getter: extract Bounty_Board state as ITF values for comparison
bounty_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	b := cast(^Bounty_Board)driver
	state := make(map[string]mbt.ITF_Value)

	state["slot1_active"]        = mbt.ITF_Bool{b.slots[0].active}
	state["slot1_kills_needed"]  = mbt.ITF_Int{b.slots[0].kills_needed}
	state["slot1_current_kills"] = mbt.ITF_Int{b.slots[0].current_kills}
	state["slot1_reward_gold"]   = mbt.ITF_Int{b.slots[0].reward_gold}

	state["slot2_active"]        = mbt.ITF_Bool{b.slots[1].active}
	state["slot2_kills_needed"]  = mbt.ITF_Int{b.slots[1].kills_needed}
	state["slot2_current_kills"] = mbt.ITF_Int{b.slots[1].current_kills}
	state["slot2_reward_gold"]   = mbt.ITF_Int{b.slots[1].reward_gold}

	state["slot3_active"]        = mbt.ITF_Bool{b.slots[2].active}
	state["slot3_kills_needed"]  = mbt.ITF_Int{b.slots[2].kills_needed}
	state["slot3_current_kills"] = mbt.ITF_Int{b.slots[2].current_kills}
	state["slot3_reward_gold"]   = mbt.ITF_Int{b.slots[2].reward_gold}

	state["player_gold"]         = mbt.ITF_Int{b.player_gold}
	state["active_bounty_idx"]   = mbt.ITF_Int{b.active_bounty_idx}

	return state
}

@(test)
test_bounty_trace_replay :: proc(t: ^testing.T) {
	// Parse the ITF trace
	trace, err := mbt.parse_itf_file("traces/bounty_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	// Create a Bounty_Board instance
	b: Bounty_Board

	// Replay the trace
	result := mbt.replay_trace(&trace, &b, bounty_step, bounty_state)

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
