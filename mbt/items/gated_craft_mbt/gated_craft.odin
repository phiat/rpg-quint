package gated_craft_mbt

Gated_Craft :: struct {
    xp:        int,
    level:     int,
    hp:        int,
    qty_wood:  int,
    qty_iron:  int,
    qty_gem:   int,
    qty_sword: int,
    qty_staff: int,
    qty_ring:  int,
    prev_xp:   int,
}

fight_enemy :: proc(gc: ^Gated_Craft, xp_gain: int, dmg: int) {
    gc.prev_xp = gc.xp
    new_xp := gc.xp + xp_gain
    threshold := gc.level * 100
    if new_xp >= threshold {
        gc.level += 1
    }
    gc.xp = new_xp
    gc.hp -= dmg
}

craft_sword :: proc(gc: ^Gated_Craft) -> bool {
    if gc.level < 1 || gc.qty_wood < 1 || gc.qty_iron < 2 do return false
    gc.prev_xp = gc.xp
    gc.qty_wood -= 1
    gc.qty_iron -= 2
    gc.qty_sword += 1
    return true
}

craft_staff :: proc(gc: ^Gated_Craft) -> bool {
    if gc.level < 2 || gc.qty_wood < 2 || gc.qty_gem < 1 do return false
    gc.prev_xp = gc.xp
    gc.qty_wood -= 2
    gc.qty_gem -= 1
    gc.qty_staff += 1
    return true
}

craft_ring :: proc(gc: ^Gated_Craft) -> bool {
    if gc.level < 3 || gc.qty_iron < 1 || gc.qty_gem < 1 do return false
    gc.prev_xp = gc.xp
    gc.qty_iron -= 1
    gc.qty_gem -= 1
    gc.qty_ring += 1
    return true
}
