package healing_mbt

import mbt "../quint_mbt"
import "core:log"
import "core:testing"

// Step handler: dispatch Quint action names to Healer procs
healing_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
    h := cast(^Healer)driver

    switch action {
    case "init":
        h.hp = INIT_HP
        h.max_hp = MAX_HP
        clear(&h.inv)
        append(&h.inv, "Potion")
        append(&h.inv, "Potion")
        append(&h.inv, "Potion")
        return true

    case "take_damage":
        dmg_val, has_dmg := picks["dmg"]
        if !has_dmg do return false
        dmg, ok := mbt.value_as_int(dmg_val)
        if !ok do return false
        take_damage(h, dmg)
        return true

    case "use_potion":
        use_potion(h, POTION_HEAL)
        return true

    case "use_potion_dead":
        // Attempt use_potion; should no-op when hp <= 0
        use_potion(h, POTION_HEAL)
        return true

    case "use_potion_none":
        // Attempt use_potion; should no-op when no potions in inventory
        use_potion(h, POTION_HEAL)
        return true

    case:
        return false
    }
}

// State getter: extract Healer state as ITF values for comparison
healing_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
    h := cast(^Healer)driver
    state := make(map[string]mbt.ITF_Value)

    state["hp"] = mbt.ITF_Int{h.hp}

    // Convert inventory to ITF_List
    inv_list := mbt.ITF_List{}
    inv_list.items = make([dynamic]mbt.ITF_Value, 0, len(h.inv))
    for item in h.inv {
        append(&inv_list.items, mbt.ITF_Value(mbt.ITF_Str{item}))
    }
    state["inventory"] = inv_list

    return state
}

@(test)
test_healing_trace_replay :: proc(t: ^testing.T) {
    // Parse the ITF trace
    trace, err := mbt.parse_itf_file("traces/healing_trace.itf.json")
    if err != .None {
        log.errorf("Failed to parse ITF trace: %v", err)
        testing.fail_now(t)
    }

    // Create a Healer instance
    h: Healer
    defer delete(h.inv)

    // Replay the trace
    result := mbt.replay_trace(&trace, &h, healing_step, healing_state)

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
