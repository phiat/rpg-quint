package healing_mbt

MAX_HP :: 100
INIT_HP :: 80
POTION_HEAL :: 25

Healer :: struct {
    hp:     int,
    max_hp: int,
    inv:    [dynamic]string,
}

take_damage :: proc(h: ^Healer, dmg: int) {
    h.hp -= dmg
}

use_potion :: proc(h: ^Healer, heal_amount: int) -> bool {
    if h.hp <= 0 do return false

    // Find and remove a "Potion" from inventory
    potion_idx := -1
    for item, i in h.inv {
        if item == "Potion" {
            potion_idx = i
            break
        }
    }
    if potion_idx < 0 do return false

    ordered_remove(&h.inv, potion_idx)

    h.hp += heal_amount
    if h.hp > h.max_hp {
        h.hp = h.max_hp
    }
    return true
}
