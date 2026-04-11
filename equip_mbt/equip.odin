package equip_mbt

Character_Equip :: struct {
	inv:       [dynamic]string,
	inv_cap:   int,
	weapon:    string,
	armor:     string,
	accessory: string,
}

// equip_to_slot: remove item from inv, put in slot. Return false if item not in inv or slot occupied.
equip_to_slot :: proc(ch: ^Character_Equip, slot: ^string, item: string) -> bool {
	if slot^ != "" {
		return false
	}
	// Find item in inventory
	for i := 0; i < len(ch.inv); i += 1 {
		if ch.inv[i] == item {
			ordered_remove(&ch.inv, i)
			slot^ = item
			return true
		}
	}
	return false
}

// unequip_from_slot: move slot item back to inv. Return false if slot empty or inv full.
unequip_from_slot :: proc(ch: ^Character_Equip, slot: ^string) -> bool {
	if slot^ == "" {
		return false
	}
	if len(ch.inv) >= ch.inv_cap {
		return false
	}
	append(&ch.inv, slot^)
	slot^ = ""
	return true
}
