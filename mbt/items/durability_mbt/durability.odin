package durability_mbt

REPAIR_COST :: 15

Durability_System :: struct {
    dur_sword:    int,
    dur_shield:   int,
    dur_bow:      int,
    max_sword:    int,
    max_shield:   int,
    max_bow:      int,
    broken_sword: bool,
    broken_shield: bool,
    broken_bow:   bool,
    gold:         int,
}

use_item :: proc(ds: ^Durability_System, name: string) -> bool {
    switch name {
    case "sword":
        if ds.broken_sword do return false
        ds.dur_sword -= 1
        if ds.dur_sword == 0 {
            ds.broken_sword = true
        }
        return true
    case "shield":
        if ds.broken_shield do return false
        ds.dur_shield -= 1
        if ds.dur_shield == 0 {
            ds.broken_shield = true
        }
        return true
    case "bow":
        if ds.broken_bow do return false
        ds.dur_bow -= 1
        if ds.dur_bow == 0 {
            ds.broken_bow = true
        }
        return true
    case:
        return false
    }
}

repair_item :: proc(ds: ^Durability_System, name: string) -> bool {
    if ds.gold < REPAIR_COST do return false

    switch name {
    case "sword":
        if !ds.broken_sword do return false
        ds.dur_sword = ds.max_sword
        ds.broken_sword = false
        ds.gold -= REPAIR_COST
        return true
    case "shield":
        if !ds.broken_shield do return false
        ds.dur_shield = ds.max_shield
        ds.broken_shield = false
        ds.gold -= REPAIR_COST
        return true
    case "bow":
        if !ds.broken_bow do return false
        ds.dur_bow = ds.max_bow
        ds.broken_bow = false
        ds.gold -= REPAIR_COST
        return true
    case:
        return false
    }
}
