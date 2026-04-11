package gated_craft_mbt

import mbt "../quint_mbt"
import "core:log"
import "core:testing"

// Step handler: dispatch Quint action names to Gated_Craft procs
gated_craft_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
    gc := cast(^Gated_Craft)driver

    switch action {
    case "init":
        gc.xp = 0
        gc.level = 1
        gc.hp = 100
        gc.qty_wood = 5
        gc.qty_iron = 4
        gc.qty_gem = 3
        gc.qty_sword = 0
        gc.qty_staff = 0
        gc.qty_ring = 0
        gc.prev_xp = 0
        return true

    case "fight_enemy":
        xp_gain_val, has_xp := picks["xp_gain"]
        dmg_val, has_dmg := picks["dmg"]
        if !has_xp || !has_dmg do return false
        xp_gain, xp_ok := mbt.value_as_int(xp_gain_val)
        dmg, dmg_ok := mbt.value_as_int(dmg_val)
        if !xp_ok || !dmg_ok do return false
        fight_enemy(gc, xp_gain, dmg)
        return true

    case "craft_sword":
        craft_sword(gc)
        return true

    case "craft_staff":
        craft_staff(gc)
        return true

    case "craft_ring":
        craft_ring(gc)
        return true

    case "blocked_craft_level":
        // no-op: craft blocked by level requirement
        gc.prev_xp = gc.xp
        return true

    case "blocked_craft_materials":
        // no-op: craft blocked by insufficient materials
        gc.prev_xp = gc.xp
        return true

    case:
        return false
    }
}

// State getter: return all state vars as ITF values for comparison
gated_craft_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
    gc := cast(^Gated_Craft)driver
    state := make(map[string]mbt.ITF_Value)

    state["xp"] = mbt.ITF_Int{gc.xp}
    state["level"] = mbt.ITF_Int{gc.level}
    state["hp"] = mbt.ITF_Int{gc.hp}
    state["qty_wood"] = mbt.ITF_Int{gc.qty_wood}
    state["qty_iron"] = mbt.ITF_Int{gc.qty_iron}
    state["qty_gem"] = mbt.ITF_Int{gc.qty_gem}
    state["qty_sword"] = mbt.ITF_Int{gc.qty_sword}
    state["qty_staff"] = mbt.ITF_Int{gc.qty_staff}
    state["qty_ring"] = mbt.ITF_Int{gc.qty_ring}
    state["prev_xp"] = mbt.ITF_Int{gc.prev_xp}

    return state
}

@(test)
test_gated_craft_trace_replay :: proc(t: ^testing.T) {
    // Parse the ITF trace
    trace, err := mbt.parse_itf_file("traces/gated_craft_trace.itf.json")
    if err != .None {
        log.errorf("Failed to parse ITF trace: %v", err)
        testing.fail_now(t)
    }

    // Create a Gated_Craft instance
    gc: Gated_Craft

    // Replay the trace
    result := mbt.replay_trace(&trace, &gc, gated_craft_step, gated_craft_state)

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
