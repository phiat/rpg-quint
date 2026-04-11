package salvage_mbt

import mbt "../../../quint_mbt"
import "core:log"
import "core:testing"

// Step handler: dispatch Quint action names to Salvage_System procs
salvage_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
    s := cast(^Salvage_System)driver

    switch action {
    case "init":
        s.qty_wood = 5
        s.qty_iron = 5
        s.qty_gold_dust = 4
        s.qty_sword = 2
        s.qty_shield = 1
        s.qty_staff = 1
        s.equipped_weapon = 0
        s.equipped_armor = 0
        s.salvage_level = 1
        return true

    case "craft_sword":
        craft_sword(s)
        return true

    case "craft_shield":
        craft_shield(s)
        return true

    case "craft_staff":
        craft_staff(s)
        return true

    case "equip_sword":
        equip_sword(s)
        return true

    case "equip_staff":
        equip_staff(s)
        return true

    case "equip_shield":
        equip_shield(s)
        return true

    case "unequip_weapon":
        unequip_weapon(s)
        return true

    case "unequip_armor":
        unequip_armor(s)
        return true

    case "salvage_sword":
        do_salvage_sword(s)
        return true

    case "salvage_shield":
        do_salvage_shield(s)
        return true

    case "salvage_staff":
        do_salvage_staff(s)
        return true

    case "upgrade_salvage":
        upgrade_salvage(s)
        return true

    case "craft_blocked":
        // no-op
        return true

    case "salvage_blocked":
        // no-op
        return true

    case:
        return false
    }
}

// State getter: return all vars as ITF_Int for comparison
salvage_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
    s := cast(^Salvage_System)driver
    state := make(map[string]mbt.ITF_Value)

    state["qty_wood"] = mbt.ITF_Int{s.qty_wood}
    state["qty_iron"] = mbt.ITF_Int{s.qty_iron}
    state["qty_gold_dust"] = mbt.ITF_Int{s.qty_gold_dust}
    state["qty_sword"] = mbt.ITF_Int{s.qty_sword}
    state["qty_shield"] = mbt.ITF_Int{s.qty_shield}
    state["qty_staff"] = mbt.ITF_Int{s.qty_staff}
    state["equipped_weapon"] = mbt.ITF_Int{s.equipped_weapon}
    state["equipped_armor"] = mbt.ITF_Int{s.equipped_armor}
    state["salvage_level"] = mbt.ITF_Int{s.salvage_level}

    return state
}

@(test)
test_salvage_trace_replay :: proc(t: ^testing.T) {
    // Parse the ITF trace
    trace, err := mbt.parse_itf_file("traces/salvage_trace.itf.json")
    if err != .None {
        log.errorf("Failed to parse ITF trace: %v", err)
        testing.fail_now(t)
    }

    // Create a Salvage_System instance
    ss: Salvage_System

    // Replay the trace
    result := mbt.replay_trace(&trace, &ss, salvage_step, salvage_state)

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
