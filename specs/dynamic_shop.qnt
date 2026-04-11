module dynamic_shop {
  const BASE_PRICE: int

  var player_gold: int
  var shop_gold: int
  var shop_swords: int
  var shop_shields: int
  var shop_potions: int
  var player_swords: int
  var player_shields: int
  var player_potions: int

  pure def price(stock: int): int = 10 * BASE_PRICE / (stock + 1)

  action init = all {
    player_gold' = 200,
    shop_gold' = 500,
    shop_swords' = 3,
    shop_shields' = 3,
    shop_potions' = 3,
    player_swords' = 0,
    player_shields' = 0,
    player_potions' = 0,
  }

  action buy_sword = all {
    shop_swords > 0,
    player_gold >= price(shop_swords),
    player_gold' = player_gold - price(shop_swords),
    shop_gold' = shop_gold + price(shop_swords),
    shop_swords' = shop_swords - 1,
    player_swords' = player_swords + 1,
    shop_shields' = shop_shields,
    player_shields' = player_shields,
    shop_potions' = shop_potions,
    player_potions' = player_potions,
  }

  action buy_shield = all {
    shop_shields > 0,
    player_gold >= price(shop_shields),
    player_gold' = player_gold - price(shop_shields),
    shop_gold' = shop_gold + price(shop_shields),
    shop_shields' = shop_shields - 1,
    player_shields' = player_shields + 1,
    shop_swords' = shop_swords,
    player_swords' = player_swords,
    shop_potions' = shop_potions,
    player_potions' = player_potions,
  }

  action buy_potion = all {
    shop_potions > 0,
    player_gold >= price(shop_potions),
    player_gold' = player_gold - price(shop_potions),
    shop_gold' = shop_gold + price(shop_potions),
    shop_potions' = shop_potions - 1,
    player_potions' = player_potions + 1,
    shop_swords' = shop_swords,
    player_swords' = player_swords,
    shop_shields' = shop_shields,
    player_shields' = player_shields,
  }

  action sell_sword = all {
    player_swords > 0,
    shop_gold >= price(shop_swords + 1),
    player_gold' = player_gold + price(shop_swords + 1),
    shop_gold' = shop_gold - price(shop_swords + 1),
    shop_swords' = shop_swords + 1,
    player_swords' = player_swords - 1,
    shop_shields' = shop_shields,
    player_shields' = player_shields,
    shop_potions' = shop_potions,
    player_potions' = player_potions,
  }

  action sell_shield = all {
    player_shields > 0,
    shop_gold >= price(shop_shields + 1),
    player_gold' = player_gold + price(shop_shields + 1),
    shop_gold' = shop_gold - price(shop_shields + 1),
    shop_shields' = shop_shields + 1,
    player_shields' = player_shields - 1,
    shop_swords' = shop_swords,
    player_swords' = player_swords,
    shop_potions' = shop_potions,
    player_potions' = player_potions,
  }

  action sell_potion = all {
    player_potions > 0,
    shop_gold >= price(shop_potions + 1),
    player_gold' = player_gold + price(shop_potions + 1),
    shop_gold' = shop_gold - price(shop_potions + 1),
    shop_potions' = shop_potions + 1,
    player_potions' = player_potions - 1,
    shop_swords' = shop_swords,
    player_swords' = player_swords,
    shop_shields' = shop_shields,
    player_shields' = player_shields,
  }

  action step = any {
    buy_sword,
    buy_shield,
    buy_potion,
    sell_sword,
    sell_shield,
    sell_potion,
  }

  val gold_conserved = player_gold + shop_gold == 700

  val items_conserved = and {
    player_swords + shop_swords == 3,
    player_shields + shop_shields == 3,
    player_potions + shop_potions == 3,
  }

  val gold_non_negative = and {
    player_gold >= 0,
    shop_gold >= 0,
  }

  val stock_non_negative = and {
    shop_swords >= 0,
    shop_shields >= 0,
    shop_potions >= 0,
    player_swords >= 0,
    player_shields >= 0,
    player_potions >= 0,
  }
}

module dynamic_shop_run {
  import dynamic_shop(BASE_PRICE = 5).*
}
