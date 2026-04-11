package capacity_craft_mbt

MAX_CAPACITY :: 15

Capacity_Craft :: struct {
    qty_wood:   int,
    qty_iron:   int,
    qty_gem:    int,
    qty_sword:  int,
    qty_staff:  int,
    qty_ring:   int,
    qty_arrows: int,
}

total :: proc(c: ^Capacity_Craft) -> int {
    return c.qty_wood + c.qty_iron + c.qty_gem + c.qty_sword + c.qty_staff + c.qty_ring + c.qty_arrows
}

craft_sword :: proc(c: ^Capacity_Craft) -> bool {
    if c.qty_wood < 1 || c.qty_iron < 2 do return false
    if total(c) - 2 > MAX_CAPACITY do return false
    c.qty_wood -= 1
    c.qty_iron -= 2
    c.qty_sword += 1
    return true
}

craft_staff :: proc(c: ^Capacity_Craft) -> bool {
    if c.qty_wood < 2 || c.qty_gem < 1 do return false
    if total(c) - 2 > MAX_CAPACITY do return false
    c.qty_wood -= 2
    c.qty_gem -= 1
    c.qty_staff += 1
    return true
}

craft_ring :: proc(c: ^Capacity_Craft) -> bool {
    if c.qty_iron < 1 || c.qty_gem < 1 do return false
    if total(c) - 1 > MAX_CAPACITY do return false
    c.qty_iron -= 1
    c.qty_gem -= 1
    c.qty_ring += 1
    return true
}

craft_arrows :: proc(c: ^Capacity_Craft) -> bool {
    if c.qty_wood < 1 do return false
    if total(c) + 2 > MAX_CAPACITY do return false
    c.qty_wood -= 1
    c.qty_arrows += 3
    return true
}
