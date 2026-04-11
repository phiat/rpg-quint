// Auction house system
// Players can list items for gold, buy listings, or cancel them.
// Invariants: gold conserved, items conserved, gold non-negative, price positive when listed.
module auction {
  const INITIAL_SELLER_GOLD: int
  const INITIAL_BUYER_GOLD: int
  const INITIAL_ITEM_COUNT: int

  // --- State ---
  var seller_gold:        int    // seller's current gold
  var seller_items:       int    // number of items the seller holds
  var buyer_gold:         int    // buyer's current gold
  var buyer_items:        int    // number of items the buyer holds
  var listing_active:     bool   // is there an active listing?
  var listing_price:      int    // price of the listed item (meaningful only when listing_active)
  var listing_item_count: int    // items held in escrow by the listing (always 0 or 1)
  var last_action:        str    // trace readability

  // --- Init ---
  action init = all {
    seller_gold'        = INITIAL_SELLER_GOLD,
    seller_items'       = INITIAL_ITEM_COUNT,
    buyer_gold'         = INITIAL_BUYER_GOLD,
    buyer_items'        = 0,
    listing_active'     = false,
    listing_price'      = 0,
    listing_item_count' = 0,
    last_action'        = "init",
  }

  // --- Actions ---

  // Seller posts one item at a given price; item moves into escrow
  action list_item(price: int): bool = {
    val can_list = not(listing_active) and seller_items >= 1 and price > 0
    all {
      can_list,
      seller_gold'        = seller_gold,
      seller_items'       = seller_items - 1,
      buyer_gold'         = buyer_gold,
      buyer_items'        = buyer_items,
      listing_active'     = true,
      listing_price'      = price,
      listing_item_count' = 1,
      last_action'        = "list_item",
    }
  }

  // Buyer pays the listing price and receives the escrowed item
  action buy_listing: bool = {
    val can_buy = listing_active and buyer_gold >= listing_price
    all {
      can_buy,
      seller_gold'        = seller_gold + listing_price,
      seller_items'       = seller_items,
      buyer_gold'         = buyer_gold - listing_price,
      buyer_items'        = buyer_items + listing_item_count,
      listing_active'     = false,
      listing_price'      = 0,
      listing_item_count' = 0,
      last_action'        = "buy_listing",
    }
  }

  // Seller cancels the listing and reclaims the escrowed item
  action cancel_listing: bool = {
    val can_cancel = listing_active
    all {
      can_cancel,
      seller_gold'        = seller_gold,
      seller_items'       = seller_items + listing_item_count,
      buyer_gold'         = buyer_gold,
      buyer_items'        = buyer_items,
      listing_active'     = false,
      listing_price'      = 0,
      listing_item_count' = 0,
      last_action'        = "cancel_listing",
    }
  }

  // No-op turn: time passes, nothing happens
  action tick_auction: bool = all {
    seller_gold'        = seller_gold,
    seller_items'       = seller_items,
    buyer_gold'         = buyer_gold,
    buyer_items'        = buyer_items,
    listing_active'     = listing_active,
    listing_price'      = listing_price,
    listing_item_count' = listing_item_count,
    last_action'        = "tick_auction",
  }

  // Nondeterministic step
  action step = {
    nondet price = Set(10, 25, 50, 100).oneOf()
    any {
      list_item(price),
      buy_listing,
      cancel_listing,
      tick_auction,
    }
  }

  // --- Invariants ---

  // Total gold (seller + buyer + escrowed = 0 since escrow holds no gold) is constant
  val gold_conserved =
    seller_gold + buyer_gold == INITIAL_SELLER_GOLD + INITIAL_BUYER_GOLD

  // Total items (seller + buyer + escrow) is constant
  val items_conserved =
    seller_items + buyer_items + listing_item_count == INITIAL_ITEM_COUNT

  // Gold never goes negative
  val gold_non_negative = seller_gold >= 0 and buyer_gold >= 0

  // Price is positive whenever there is an active listing
  val price_positive_when_listed =
    listing_active.implies(listing_price > 0)
}

// Runner module with concrete initial values
module auction_run {
  import auction(
    INITIAL_SELLER_GOLD = 200,
    INITIAL_BUYER_GOLD  = 150,
    INITIAL_ITEM_COUNT  = 3,
  ).*
}
