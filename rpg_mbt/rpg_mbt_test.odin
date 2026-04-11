package rpg_mbt

import mbt "../quint_mbt"
import "core:testing"
import "core:fmt"
import "core:log"

// Step handler: dispatch Quint action names to Character procs
rpg_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	char := cast(^Character)driver

	switch action {
	case "init":
		char.hp = 100
		char.attack = 25
		clear(&char.inv)
		char.inv_cap = 3
		return true

	case "take_damage":
		dmg_val, has_dmg := picks["dmg"]
		if !has_dmg do return false
		dmg, ok := mbt.value_as_int(dmg_val)
		if !ok do return false
		take_damage(char, dmg)
		return true

	case "add_itm":
		itm_val, has_itm := picks["itm"]
		if !has_itm do return false
		itm, ok := mbt.value_as_str(itm_val)
		if !ok do return false
		add_item(char, itm)
		return true

	case "add_itm_full":
		itm_val, has_itm := picks["itm"]
		if !has_itm do return false
		itm, ok := mbt.value_as_str(itm_val)
		if !ok do return false
		// Call add_item — it should return false (inventory full)
		add_item(char, itm)
		return true

	case:
		return false
	}
}

// State getter: extract Character state as ITF values for comparison
rpg_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	char := cast(^Character)driver
	state := make(map[string]mbt.ITF_Value)

	state["hp"] = mbt.ITF_Int{char.hp}
	state["attack"] = mbt.ITF_Int{char.attack}

	// Convert inventory to ITF_List
	inv_list := mbt.ITF_List{}
	inv_list.items = make([dynamic]mbt.ITF_Value, 0, len(char.inv))
	for item in char.inv {
		append(&inv_list.items, mbt.ITF_Value(mbt.ITF_Str{item}))
	}
	state["inventory"] = inv_list

	return state
}

@(test)
test_rpg_trace_replay :: proc(t: ^testing.T) {
	// Parse the ITF trace
	trace, err := mbt.parse_itf_file("traces/rpg_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	// Create a Character instance
	char: Character
	defer delete(char.inv)

	// Replay the trace
	result := mbt.replay_trace(&trace, &char, rpg_step, rpg_state)

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
