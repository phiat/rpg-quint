package capacity_craft_mbt

import mbt "../../../quint_mbt"
import "core:log"
import "core:testing"

// Step handler: dispatch Quint action names to Capacity_Craft procs
capacity_craft_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
    c := cast(^Capacity_Craft)driver

    switch action {
    case "init":
        c.qty_wood = 5
        c.qty_iron = 4
        c.qty_gem = 3
        c.qty_sword = 0
        c.qty_staff = 0
        c.qty_ring = 0
        c.qty_arrows = 0
        return true

    case "craft_sword":
        craft_sword(c)
        return true

    case "craft_staff":
        craft_staff(c)
        return true

    case "craft_ring":
        craft_ring(c)
        return true

    case "craft_arrows":
        craft_arrows(c)
        return true

    case "blocked_craft_arrows_full":
        // no-op: arrows craft blocked by capacity
        return true

    case "blocked_no_materials":
        // no-op: insufficient materials for any craft
        return true

    case:
        return false
    }
}

// State getter: return all 7 qty vars as ITF_Int for comparison
capacity_craft_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
    c := cast(^Capacity_Craft)driver
    state := make(map[string]mbt.ITF_Value)

    state["qty_wood"] = mbt.ITF_Int{c.qty_wood}
    state["qty_iron"] = mbt.ITF_Int{c.qty_iron}
    state["qty_gem"] = mbt.ITF_Int{c.qty_gem}
    state["qty_sword"] = mbt.ITF_Int{c.qty_sword}
    state["qty_staff"] = mbt.ITF_Int{c.qty_staff}
    state["qty_ring"] = mbt.ITF_Int{c.qty_ring}
    state["qty_arrows"] = mbt.ITF_Int{c.qty_arrows}

    return state
}

@(test)
test_capacity_craft_trace_replay :: proc(t: ^testing.T) {
    trace, err := mbt.parse_itf_file("traces/capacity_craft_trace.itf.json")
    if err != .None {
        log.errorf("Failed to parse ITF trace: %v", err)
        testing.fail_now(t)
    }

    cc: Capacity_Craft

    result := mbt.replay_trace(&trace, &cc, capacity_craft_step, capacity_craft_state)

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
