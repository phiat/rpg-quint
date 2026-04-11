package enchantment_mbt

import mbt "../../../quint_mbt"
import "core:log"
import "core:testing"

ENCHANT_COST :: 10

Enchantment_System :: struct {
    enchant_slot_1:  int,
    enchant_slot_2:  int,
    enchant_slot_3:  int,
    total_atk_bonus: int,
    total_def_bonus: int,
    gold:            int,
}

atk_for :: proc(slot: int) -> int {
    switch slot {
    case 1:  return 3  // Fire
    case 4:  return 1  // Lightning
    case:    return 0
    }
}

def_for :: proc(slot: int) -> int {
    switch slot {
    case 2:  return 2  // Ice
    case 4:  return 1  // Lightning
    case:    return 0
    }
}

has_fire :: proc(es: ^Enchantment_System) -> bool {
    return es.enchant_slot_1 == 1 || es.enchant_slot_2 == 1 || es.enchant_slot_3 == 1
}

has_ice :: proc(es: ^Enchantment_System) -> bool {
    return es.enchant_slot_1 == 2 || es.enchant_slot_2 == 2 || es.enchant_slot_3 == 2
}

recompute_stats :: proc(es: ^Enchantment_System) {
    es.total_atk_bonus = atk_for(es.enchant_slot_1) + atk_for(es.enchant_slot_2) + atk_for(es.enchant_slot_3)
    es.total_def_bonus = def_for(es.enchant_slot_1) + def_for(es.enchant_slot_2) + def_for(es.enchant_slot_3)
}

apply_enchant :: proc(es: ^Enchantment_System, slot: int, etype: int) -> bool {
    if etype < 1 || etype > 4 do return false
    if es.gold < ENCHANT_COST do return false
    // Fire/Ice incompatibility
    if etype == 1 && has_ice(es) do return false
    if etype == 2 && has_fire(es) do return false

    switch slot {
    case 1: es.enchant_slot_1 = etype
    case 2: es.enchant_slot_2 = etype
    case 3: es.enchant_slot_3 = etype
    case:   return false
    }
    es.gold -= ENCHANT_COST
    recompute_stats(es)
    return true
}

remove_enchant :: proc(es: ^Enchantment_System, slot: int) -> bool {
    switch slot {
    case 1:
        if es.enchant_slot_1 == 0 do return false
        es.enchant_slot_1 = 0
    case 2:
        if es.enchant_slot_2 == 0 do return false
        es.enchant_slot_2 = 0
    case 3:
        if es.enchant_slot_3 == 0 do return false
        es.enchant_slot_3 = 0
    case:
        return false
    }
    recompute_stats(es)
    return true
}

// Step handler: dispatch Quint action names to Enchantment_System procs
enchantment_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
    es := cast(^Enchantment_System)driver

    switch action {
    case "init":
        es.enchant_slot_1 = 0
        es.enchant_slot_2 = 0
        es.enchant_slot_3 = 0
        es.total_atk_bonus = 0
        es.total_def_bonus = 0
        es.gold = 100
        return true

    case "apply_enchant_1":
        etype_val, has_etype := picks["etype"]
        if !has_etype do return false
        etype, ok := mbt.value_as_int(etype_val)
        if !ok do return false
        apply_enchant(es, 1, etype)
        return true

    case "apply_enchant_2":
        etype_val, has_etype := picks["etype"]
        if !has_etype do return false
        etype, ok := mbt.value_as_int(etype_val)
        if !ok do return false
        apply_enchant(es, 2, etype)
        return true

    case "apply_enchant_3":
        etype_val, has_etype := picks["etype"]
        if !has_etype do return false
        etype, ok := mbt.value_as_int(etype_val)
        if !ok do return false
        apply_enchant(es, 3, etype)
        return true

    case "remove_enchant_1":
        remove_enchant(es, 1)
        return true

    case "remove_enchant_2":
        remove_enchant(es, 2)
        return true

    case "remove_enchant_3":
        remove_enchant(es, 3)
        return true

    case "compute_stats":
        recompute_stats(es)
        return true

    case:
        return false
    }
}

// State getter: extract Enchantment_System state as ITF values for comparison
enchantment_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
    es := cast(^Enchantment_System)driver
    state := make(map[string]mbt.ITF_Value)

    state["enchant_slot_1"] = mbt.ITF_Int{es.enchant_slot_1}
    state["enchant_slot_2"] = mbt.ITF_Int{es.enchant_slot_2}
    state["enchant_slot_3"] = mbt.ITF_Int{es.enchant_slot_3}
    state["total_atk_bonus"] = mbt.ITF_Int{es.total_atk_bonus}
    state["total_def_bonus"] = mbt.ITF_Int{es.total_def_bonus}
    state["gold"] = mbt.ITF_Int{es.gold}

    return state
}

@(test)
test_enchantment_trace_replay :: proc(t: ^testing.T) {
    // Parse the ITF trace
    trace, err := mbt.parse_itf_file("traces/enchantment_trace.itf.json")
    if err != .None {
        log.errorf("Failed to parse ITF trace: %v", err)
        testing.fail_now(t)
    }

    // Create an Enchantment_System instance
    es: Enchantment_System

    // Replay the trace
    result := mbt.replay_trace(&trace, &es, enchantment_step, enchantment_state)

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
