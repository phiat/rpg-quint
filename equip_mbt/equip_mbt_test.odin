package equip_mbt

import mbt "../quint_mbt"
import "core:testing"
import "core:log"

// Step handler: dispatch Quint action names to Character_Equip procs
equip_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	ch := cast(^Character_Equip)driver

	switch action {
	case "init":
		clear(&ch.inv)
		ch.inv_cap = 5
		append(&ch.inv, "Sword")
		append(&ch.inv, "Shield")
		append(&ch.inv, "Ring")
		ch.weapon = ""
		ch.armor = ""
		ch.accessory = ""
		return true

	case "equip_weapon":
		itm_val, has := picks["itm"]
		if !has do return false
		itm, ok := mbt.value_as_str(itm_val)
		if !ok do return false
		equip_to_slot(ch, &ch.weapon, itm)
		return true

	case "equip_armor":
		itm_val, has := picks["itm"]
		if !has do return false
		itm, ok := mbt.value_as_str(itm_val)
		if !ok do return false
		equip_to_slot(ch, &ch.armor, itm)
		return true

	case "equip_accessory":
		itm_val, has := picks["itm"]
		if !has do return false
		itm, ok := mbt.value_as_str(itm_val)
		if !ok do return false
		equip_to_slot(ch, &ch.accessory, itm)
		return true

	case "unequip_weapon":
		unequip_from_slot(ch, &ch.weapon)
		return true

	case "unequip_armor":
		unequip_from_slot(ch, &ch.armor)
		return true

	case "unequip_accessory":
		unequip_from_slot(ch, &ch.accessory)
		return true

	case "equip_blocked_slot_full":
		itm_val, has := picks["itm"]
		if !has do return false
		itm, ok := mbt.value_as_str(itm_val)
		if !ok do return false
		// Attempt equip on an already-occupied slot — should fail
		// Try weapon first (it's the slot likely full in the spec)
		equip_to_slot(ch, &ch.weapon, itm)
		return true

	case:
		return false
	}
}

// State getter: extract Character_Equip state as ITF values for comparison
equip_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	ch := cast(^Character_Equip)driver
	state := make(map[string]mbt.ITF_Value)

	// Convert inventory to ITF_List
	inv_list := mbt.ITF_List{}
	inv_list.items = make([dynamic]mbt.ITF_Value, 0, len(ch.inv))
	for item in ch.inv {
		append(&inv_list.items, mbt.ITF_Value(mbt.ITF_Str{item}))
	}
	state["inventory"] = inv_list

	state["weapon"] = mbt.ITF_Str{ch.weapon}
	state["armor"] = mbt.ITF_Str{ch.armor}
	state["accessory"] = mbt.ITF_Str{ch.accessory}

	return state
}

@(test)
test_equip_trace_replay :: proc(t: ^testing.T) {
	// Parse the ITF trace
	trace, err := mbt.parse_itf_file("traces/equip_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	// Create a Character_Equip instance
	ch: Character_Equip
	defer delete(ch.inv)

	// Replay the trace
	result := mbt.replay_trace(&trace, &ch, equip_step, equip_state)

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
