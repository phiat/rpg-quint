package durability_mbt

import mbt "../quint_mbt"
import "core:log"
import "core:testing"

// Step handler: dispatch Quint action names to Durability_System procs
durability_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
    ds := cast(^Durability_System)driver

    switch action {
    case "init":
        ds.max_sword = 10
        ds.max_shield = 8
        ds.max_bow = 6
        ds.dur_sword = ds.max_sword
        ds.dur_shield = ds.max_shield
        ds.dur_bow = ds.max_bow
        ds.broken_sword = false
        ds.broken_shield = false
        ds.broken_bow = false
        ds.gold = 100
        return true

    case "use_sword":
        use_item(ds, "sword")
        return true

    case "use_shield":
        use_item(ds, "shield")
        return true

    case "use_bow":
        use_item(ds, "bow")
        return true

    case "repair_sword":
        repair_item(ds, "sword")
        return true

    case "repair_shield":
        repair_item(ds, "shield")
        return true

    case "repair_bow":
        repair_item(ds, "bow")
        return true

    case "blocked_use_broken":
        // Attempt to use a broken item — should no-op
        use_item(ds, "sword")
        return true

    case "blocked_repair_no_gold":
        // Attempt to repair without enough gold — should no-op
        repair_item(ds, "sword")
        return true

    case:
        return false
    }
}

// State getter: extract Durability_System state as ITF values for comparison
durability_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
    ds := cast(^Durability_System)driver
    state := make(map[string]mbt.ITF_Value)

    state["dur_sword"] = mbt.ITF_Int{ds.dur_sword}
    state["dur_shield"] = mbt.ITF_Int{ds.dur_shield}
    state["dur_bow"] = mbt.ITF_Int{ds.dur_bow}
    state["max_sword"] = mbt.ITF_Int{ds.max_sword}
    state["max_shield"] = mbt.ITF_Int{ds.max_shield}
    state["max_bow"] = mbt.ITF_Int{ds.max_bow}
    state["broken_sword"] = mbt.ITF_Bool{ds.broken_sword}
    state["broken_shield"] = mbt.ITF_Bool{ds.broken_shield}
    state["broken_bow"] = mbt.ITF_Bool{ds.broken_bow}
    state["gold"] = mbt.ITF_Int{ds.gold}

    return state
}

@(test)
test_durability_trace_replay :: proc(t: ^testing.T) {
    // Parse the ITF trace
    trace, err := mbt.parse_itf_file("traces/durability_trace.itf.json")
    if err != .None {
        log.errorf("Failed to parse ITF trace: %v", err)
        testing.fail_now(t)
    }

    // Create a Durability_System instance
    ds: Durability_System

    // Replay the trace
    result := mbt.replay_trace(&trace, &ds, durability_step, durability_state)

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
