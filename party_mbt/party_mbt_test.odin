package party_mbt

import mbt "../quint_mbt"
import "core:log"
import "core:testing"

// Step handler: dispatch Quint action names to Party procs
party_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
    p := cast(^Party)driver

    switch action {
    case "init":
        clear(&p.inv_1)
        append(&p.inv_1, "Sword", "Shield")

        clear(&p.inv_2)
        append(&p.inv_2, "Bow")

        clear(&p.inv_3)
        append(&p.inv_3, "Staff")

        clear(&p.stash)
        append(&p.stash, "Potion", "Ring")

        p.member_cap = 5
        p.stash_cap = 10
        return true

    case "deposit_1":
        itm_val, has := picks["itm"]
        if !has do return false
        itm, ok := mbt.value_as_str(itm_val)
        if !ok do return false
        transfer_to_stash(p, &p.inv_1, itm)
        return true

    case "deposit_2":
        itm_val, has := picks["itm"]
        if !has do return false
        itm, ok := mbt.value_as_str(itm_val)
        if !ok do return false
        transfer_to_stash(p, &p.inv_2, itm)
        return true

    case "deposit_3":
        itm_val, has := picks["itm"]
        if !has do return false
        itm, ok := mbt.value_as_str(itm_val)
        if !ok do return false
        transfer_to_stash(p, &p.inv_3, itm)
        return true

    case "withdraw_1":
        itm_val, has := picks["itm"]
        if !has do return false
        itm, ok := mbt.value_as_str(itm_val)
        if !ok do return false
        transfer_from_stash(p, &p.inv_1, itm)
        return true

    case "withdraw_2":
        itm_val, has := picks["itm"]
        if !has do return false
        itm, ok := mbt.value_as_str(itm_val)
        if !ok do return false
        transfer_from_stash(p, &p.inv_2, itm)
        return true

    case "withdraw_3":
        itm_val, has := picks["itm"]
        if !has do return false
        itm, ok := mbt.value_as_str(itm_val)
        if !ok do return false
        transfer_from_stash(p, &p.inv_3, itm)
        return true

    case "deposit_blocked":
        // No-op: guard prevented the deposit
        return true

    case "withdraw_blocked":
        // No-op: guard prevented the withdrawal
        return true

    case:
        return false
    }
}

// State getter: extract Party state as ITF values for comparison
party_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
    p := cast(^Party)driver
    state := make(map[string]mbt.ITF_Value)

    state["inv_1"] = strings_to_itf_list(p.inv_1[:])
    state["inv_2"] = strings_to_itf_list(p.inv_2[:])
    state["inv_3"] = strings_to_itf_list(p.inv_3[:])
    state["stash"] = strings_to_itf_list(p.stash[:])

    return state
}

// Helper: convert a slice of strings to an ITF_List value
strings_to_itf_list :: proc(items: []string) -> mbt.ITF_Value {
    list := mbt.ITF_List{}
    list.items = make([dynamic]mbt.ITF_Value, 0, len(items))
    for item in items {
        append(&list.items, mbt.ITF_Value(mbt.ITF_Str{item}))
    }
    return list
}

@(test)
test_party_trace_replay :: proc(t: ^testing.T) {
    trace, err := mbt.parse_itf_file("traces/party_trace.itf.json")
    if err != .None {
        log.errorf("Failed to parse ITF trace: %v", err)
        testing.fail_now(t)
    }

    p: Party
    defer delete(p.inv_1)
    defer delete(p.inv_2)
    defer delete(p.inv_3)
    defer delete(p.stash)

    result := mbt.replay_trace(&trace, &p, party_step, party_state)

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
