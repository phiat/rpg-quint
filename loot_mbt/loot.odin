package loot_mbt

PITY_THRESHOLD :: 5

Loot_System :: struct {
	pity_counter:   int,
	total_drops:    int,
	rare_drops:     int,
	common_drops:   int,
	last_rarity:    string,
	guaranteed_next: bool,
	pity_threshold: int,
}

drop_common :: proc(ls: ^Loot_System) {
	ls.pity_counter += 1
	ls.total_drops += 1
	ls.common_drops += 1
	ls.last_rarity = "common"
	if ls.pity_counter >= ls.pity_threshold {
		ls.guaranteed_next = true
	}
}

drop_rare :: proc(ls: ^Loot_System) {
	ls.pity_counter = 0
	ls.total_drops += 1
	ls.rare_drops += 1
	ls.last_rarity = "rare"
	ls.guaranteed_next = false
}

drop_guaranteed_rare :: proc(ls: ^Loot_System) {
	// Guard: guaranteed_next must be true
	if !ls.guaranteed_next do return
	ls.pity_counter = 0
	ls.total_drops += 1
	ls.rare_drops += 1
	ls.last_rarity = "rare"
	ls.guaranteed_next = false
}
