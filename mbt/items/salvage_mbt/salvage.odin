package salvage_mbt

Salvage_System :: struct {
    qty_wood:        int,
    qty_iron:        int,
    qty_gold_dust:   int,
    qty_sword:       int,
    qty_shield:      int,
    qty_staff:       int,
    equipped_weapon: int, // 0=none, 1=sword, 2=staff
    equipped_armor:  int, // 0=none, 1=shield
    salvage_level:   int, // 1-3
}

// --- Salvage output helpers (pure functions of item + level) ---

salvage_sword_wood :: proc(lvl: int) -> int { return 1 + (lvl - 1) }
salvage_sword_iron :: proc(lvl: int) -> int { return 2 + (lvl - 1) }

salvage_shield_wood :: proc(lvl: int) -> int { return 2 + (lvl - 1) }
salvage_shield_iron :: proc(lvl: int) -> int { return 1 + (lvl - 1) }

salvage_staff_wood :: proc(lvl: int) -> int { return 1 + (lvl - 1) }
salvage_staff_iron :: proc(lvl: int) -> int { return 1 + (lvl - 1) }
salvage_staff_gold :: proc(lvl: int) -> int { return 1 + (lvl - 1) }

// --- Crafting ---

craft_sword :: proc(s: ^Salvage_System) -> bool {
    if s.qty_wood < 2 || s.qty_iron < 3 do return false
    s.qty_wood -= 2
    s.qty_iron -= 3
    s.qty_sword += 1
    return true
}

craft_shield :: proc(s: ^Salvage_System) -> bool {
    if s.qty_wood < 3 || s.qty_iron < 1 do return false
    s.qty_wood -= 3
    s.qty_iron -= 1
    s.qty_shield += 1
    return true
}

craft_staff :: proc(s: ^Salvage_System) -> bool {
    if s.qty_wood < 1 || s.qty_iron < 1 || s.qty_gold_dust < 2 do return false
    s.qty_wood -= 1
    s.qty_iron -= 1
    s.qty_gold_dust -= 2
    s.qty_staff += 1
    return true
}

// --- Equip / Unequip ---

equip_sword :: proc(s: ^Salvage_System) -> bool {
    if s.qty_sword < 1 || s.equipped_weapon != 0 do return false
    s.qty_sword -= 1
    s.equipped_weapon = 1
    return true
}

equip_staff :: proc(s: ^Salvage_System) -> bool {
    if s.qty_staff < 1 || s.equipped_weapon != 0 do return false
    s.qty_staff -= 1
    s.equipped_weapon = 2
    return true
}

equip_shield :: proc(s: ^Salvage_System) -> bool {
    if s.qty_shield < 1 || s.equipped_armor != 0 do return false
    s.qty_shield -= 1
    s.equipped_armor = 1
    return true
}

unequip_weapon :: proc(s: ^Salvage_System) -> bool {
    if s.equipped_weapon == 0 do return false
    if s.equipped_weapon == 1 {
        s.qty_sword += 1
    } else {
        s.qty_staff += 1
    }
    s.equipped_weapon = 0
    return true
}

unequip_armor :: proc(s: ^Salvage_System) -> bool {
    if s.equipped_armor == 0 do return false
    s.qty_shield += 1
    s.equipped_armor = 0
    return true
}

// --- Salvage ---

do_salvage_sword :: proc(s: ^Salvage_System) -> bool {
    if s.qty_sword < 1 do return false
    s.qty_sword -= 1
    s.qty_wood += salvage_sword_wood(s.salvage_level)
    s.qty_iron += salvage_sword_iron(s.salvage_level)
    return true
}

do_salvage_shield :: proc(s: ^Salvage_System) -> bool {
    if s.qty_shield < 1 do return false
    s.qty_shield -= 1
    s.qty_wood += salvage_shield_wood(s.salvage_level)
    s.qty_iron += salvage_shield_iron(s.salvage_level)
    return true
}

do_salvage_staff :: proc(s: ^Salvage_System) -> bool {
    if s.qty_staff < 1 do return false
    s.qty_staff -= 1
    s.qty_wood += salvage_staff_wood(s.salvage_level)
    s.qty_iron += salvage_staff_iron(s.salvage_level)
    s.qty_gold_dust += salvage_staff_gold(s.salvage_level)
    return true
}

// --- Upgrade ---

upgrade_salvage :: proc(s: ^Salvage_System) -> bool {
    if s.salvage_level >= 3 || s.qty_gold_dust < 5 do return false
    s.salvage_level += 1
    s.qty_gold_dust -= 5
    return true
}
