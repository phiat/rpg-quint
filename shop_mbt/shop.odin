package shop_mbt

Shop_System :: struct {
	player_gold: int,
	shop_gold:   int,
	player_inv:  [dynamic]string,
	shop_inv:    [dynamic]string,
	price:       int,
	max_inv:     int,
}

// Buy an item from the shop. Returns true if the purchase succeeded.
buy :: proc(s: ^Shop_System, itm: string) -> bool {
	if s.player_gold < s.price do return false

	// Find item in shop inventory
	idx := -1
	for i in 0 ..< len(s.shop_inv) {
		if s.shop_inv[i] == itm {
			idx = i
			break
		}
	}
	if idx < 0 do return false

	// Transfer gold
	s.player_gold -= s.price
	s.shop_gold += s.price

	// Move item from shop to player
	ordered_remove(&s.shop_inv, idx)
	append(&s.player_inv, itm)

	return true
}

// Sell an item to the shop. Returns true if the sale succeeded.
sell :: proc(s: ^Shop_System, itm: string) -> bool {
	if s.shop_gold < s.price do return false

	// Find item in player inventory
	idx := -1
	for i in 0 ..< len(s.player_inv) {
		if s.player_inv[i] == itm {
			idx = i
			break
		}
	}
	if idx < 0 do return false

	// Transfer gold
	s.player_gold += s.price
	s.shop_gold -= s.price

	// Move item from player to shop
	ordered_remove(&s.player_inv, idx)
	append(&s.shop_inv, itm)

	return true
}
