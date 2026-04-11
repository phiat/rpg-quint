package auction_mbt

// Auction house system implementation under test.
// Must satisfy the invariants in specs/economy/auction.qnt.

Auction_System :: struct {
	seller_gold:        int,
	seller_items:       int,
	buyer_gold:         int,
	buyer_items:        int,
	listing_active:     bool,
	listing_price:      int,
	listing_item_count: int,
	last_action:        string,
}

// list_item: seller posts one item at the given price.
// Returns false if a listing is already active, seller has no items, or price <= 0.
list_item :: proc(sys: ^Auction_System, price: int) -> bool {
	if sys.listing_active do return false
	if sys.seller_items < 1 do return false
	if price <= 0 do return false

	sys.seller_items -= 1
	sys.listing_active = true
	sys.listing_price = price
	sys.listing_item_count = 1
	sys.last_action = "list_item"
	return true
}

// buy_listing: buyer pays the listing price and receives the escrowed item.
// Returns false if there is no active listing or buyer cannot afford it.
buy_listing :: proc(sys: ^Auction_System) -> bool {
	if !sys.listing_active do return false
	if sys.buyer_gold < sys.listing_price do return false

	sys.seller_gold += sys.listing_price
	sys.buyer_gold -= sys.listing_price
	sys.buyer_items += sys.listing_item_count
	sys.listing_active = false
	sys.listing_price = 0
	sys.listing_item_count = 0
	sys.last_action = "buy_listing"
	return true
}

// cancel_listing: seller reclaims the escrowed item.
// Returns false if there is no active listing.
cancel_listing :: proc(sys: ^Auction_System) -> bool {
	if !sys.listing_active do return false

	sys.seller_items += sys.listing_item_count
	sys.listing_active = false
	sys.listing_price = 0
	sys.listing_item_count = 0
	sys.last_action = "cancel_listing"
	return true
}

// tick_auction: no-op turn; state is unchanged.
tick_auction :: proc(sys: ^Auction_System) {
	sys.last_action = "tick_auction"
}
