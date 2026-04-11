package trade_mbt

// Two-player inventory trade system
// Implementation under test — must satisfy trade.qnt invariants

Player :: struct {
	inv:     [dynamic]string,
	inv_cap: int,
}

Trade_System :: struct {
	player_a:    Player,
	player_b:    Player,
	last_action: string,
}

// Give item from src to dst. Returns false if src doesn't have it or dst is full.
give_item :: proc(src: ^Player, dst: ^Player, itm: string) -> bool {
	// Find item in src
	idx := -1
	for i in 0 ..< len(src.inv) {
		if src.inv[i] == itm {
			idx = i
			break
		}
	}
	if idx < 0 do return false
	if len(dst.inv) >= dst.inv_cap do return false

	// Remove from src (unordered remove would be faster, but ordered matches the spec)
	ordered_remove(&src.inv, idx)
	append(&dst.inv, itm)
	return true
}
