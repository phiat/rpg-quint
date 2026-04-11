package dynamic_shop_mbt

BASE_PRICE :: 5

Dynamic_Shop :: struct {
	player_gold:    int,
	shop_gold:      int,
	shop_swords:    int,
	shop_shields:   int,
	shop_potions:   int,
	player_swords:  int,
	player_shields: int,
	player_potions: int,
	base_price:     int,
}

// Dynamic price based on current stock: 10 * BASE_PRICE / (stock + 1)
price :: proc(stock: int) -> int {
	return 10 * BASE_PRICE / (stock + 1)
}

// Buy a sword from the shop.
buy_sword :: proc(s: ^Dynamic_Shop) -> bool {
	p := price(s.shop_swords)
	if s.player_gold < p do return false
	if s.shop_swords <= 0 do return false
	s.player_gold -= p
	s.shop_gold += p
	s.shop_swords -= 1
	s.player_swords += 1
	return true
}

// Buy a shield from the shop.
buy_shield :: proc(s: ^Dynamic_Shop) -> bool {
	p := price(s.shop_shields)
	if s.player_gold < p do return false
	if s.shop_shields <= 0 do return false
	s.player_gold -= p
	s.shop_gold += p
	s.shop_shields -= 1
	s.player_shields += 1
	return true
}

// Buy a potion from the shop.
buy_potion :: proc(s: ^Dynamic_Shop) -> bool {
	p := price(s.shop_potions)
	if s.player_gold < p do return false
	if s.shop_potions <= 0 do return false
	s.player_gold -= p
	s.shop_gold += p
	s.shop_potions -= 1
	s.player_potions += 1
	return true
}

// Sell a sword back to the shop. Earn price based on shop_stock + 1 (post-sale stock).
sell_sword :: proc(s: ^Dynamic_Shop) -> bool {
	p := price(s.shop_swords + 1)
	if s.player_swords <= 0 do return false
	if s.shop_gold < p do return false
	s.player_gold += p
	s.shop_gold -= p
	s.shop_swords += 1
	s.player_swords -= 1
	return true
}

// Sell a shield back to the shop.
sell_shield :: proc(s: ^Dynamic_Shop) -> bool {
	p := price(s.shop_shields + 1)
	if s.player_shields <= 0 do return false
	if s.shop_gold < p do return false
	s.player_gold += p
	s.shop_gold -= p
	s.shop_shields += 1
	s.player_shields -= 1
	return true
}

// Sell a potion back to the shop.
sell_potion :: proc(s: ^Dynamic_Shop) -> bool {
	p := price(s.shop_potions + 1)
	if s.player_potions <= 0 do return false
	if s.shop_gold < p do return false
	s.player_gold += p
	s.shop_gold -= p
	s.shop_potions += 1
	s.player_potions -= 1
	return true
}
