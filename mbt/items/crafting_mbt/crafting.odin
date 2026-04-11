package crafting_mbt

Craft_System :: struct {
    qty_wood:  int,
    qty_iron:  int,
    qty_gem:   int,
    qty_sword: int,
    qty_staff: int,
    qty_ring:  int,
}

craft_sword :: proc(c: ^Craft_System) -> bool {
    if c.qty_wood < 1 || c.qty_iron < 2 do return false
    c.qty_wood -= 1
    c.qty_iron -= 2
    c.qty_sword += 1
    return true
}

craft_staff :: proc(c: ^Craft_System) -> bool {
    if c.qty_wood < 2 || c.qty_gem < 1 do return false
    c.qty_wood -= 2
    c.qty_gem -= 1
    c.qty_staff += 1
    return true
}

craft_ring :: proc(c: ^Craft_System) -> bool {
    if c.qty_iron < 1 || c.qty_gem < 1 do return false
    c.qty_iron -= 1
    c.qty_gem -= 1
    c.qty_ring += 1
    return true
}
