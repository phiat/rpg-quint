package combat_full_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

// Step handler: dispatch Quint action names to Combat_Full procs
combat_full_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	c := cast(^Combat_Full)driver

	switch action {
	case "init":
		c.hp_a = 100
		c.hp_b = 100
		c.weapon_dmg_a = 25
		c.weapon_dmg_b = 20
		c.buff_a = 0
		c.buff_b = 0
		c.buff_turns_a = 0
		c.buff_turns_b = 0
		c.poison_a = 0
		c.poison_b = 0
		c.poison_turns_a = 0
		c.poison_turns_b = 0
		c.turn = "A"
		c.game_over = false
		return true

	case "attack_a":
		c.turn = "A"
		attack(c)
		return true

	case "attack_b":
		c.turn = "B"
		attack(c)
		return true

	case "apply_poison_a":
		dmg_val, has_dmg := picks["dmg"]
		if !has_dmg do return false
		dmg, dmg_ok := mbt.value_as_int(dmg_val)
		if !dmg_ok do return false

		dur_val, has_dur := picks["dur"]
		if !has_dur do return false
		dur, dur_ok := mbt.value_as_int(dur_val)
		if !dur_ok do return false

		apply_poison(c, "A", dmg, dur)
		return true

	case "apply_poison_b":
		dmg_val, has_dmg := picks["dmg"]
		if !has_dmg do return false
		dmg, dmg_ok := mbt.value_as_int(dmg_val)
		if !dmg_ok do return false

		dur_val, has_dur := picks["dur"]
		if !has_dur do return false
		dur, dur_ok := mbt.value_as_int(dur_val)
		if !dur_ok do return false

		apply_poison(c, "B", dmg, dur)
		return true

	case "apply_buff_a":
		amt_val, has_amt := picks["amt"]
		if !has_amt do return false
		amt, amt_ok := mbt.value_as_int(amt_val)
		if !amt_ok do return false

		dur_val, has_dur := picks["dur"]
		if !has_dur do return false
		dur, dur_ok := mbt.value_as_int(dur_val)
		if !dur_ok do return false

		apply_buff(c, "A", amt, dur)
		return true

	case "apply_buff_b":
		amt_val, has_amt := picks["amt"]
		if !has_amt do return false
		amt, amt_ok := mbt.value_as_int(amt_val)
		if !amt_ok do return false

		dur_val, has_dur := picks["dur"]
		if !has_dur do return false
		dur, dur_ok := mbt.value_as_int(dur_val)
		if !dur_ok do return false

		apply_buff(c, "B", amt, dur)
		return true

	case:
		return false
	}
}

// State getter: extract Combat_Full state as ITF values for comparison
combat_full_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	c := cast(^Combat_Full)driver
	state := make(map[string]mbt.ITF_Value)

	state["hp_a"] = mbt.ITF_Int{c.hp_a}
	state["hp_b"] = mbt.ITF_Int{c.hp_b}
	state["weapon_dmg_a"] = mbt.ITF_Int{c.weapon_dmg_a}
	state["weapon_dmg_b"] = mbt.ITF_Int{c.weapon_dmg_b}
	state["buff_a"] = mbt.ITF_Int{c.buff_a}
	state["buff_b"] = mbt.ITF_Int{c.buff_b}
	state["buff_turns_a"] = mbt.ITF_Int{c.buff_turns_a}
	state["buff_turns_b"] = mbt.ITF_Int{c.buff_turns_b}
	state["poison_a"] = mbt.ITF_Int{c.poison_a}
	state["poison_b"] = mbt.ITF_Int{c.poison_b}
	state["poison_turns_a"] = mbt.ITF_Int{c.poison_turns_a}
	state["poison_turns_b"] = mbt.ITF_Int{c.poison_turns_b}
	state["turn"] = mbt.ITF_Str{c.turn}
	state["game_over"] = mbt.ITF_Bool{c.game_over}

	return state
}

@(test)
test_combat_full_trace_replay :: proc(t: ^testing.T) {
	// Parse the ITF trace
	trace, err := mbt.parse_itf_file("traces/combat_full_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	// Create a Combat_Full instance
	c: Combat_Full

	// Replay the trace
	result := mbt.replay_trace(&trace, &c, combat_full_step, combat_full_state)

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
