module shop {
  const MAX_INV: int
  const PRICE: int

  var player_gold: int
  var shop_gold: int
  var player_inv: List[str]
  var shop_inv: List[str]

  pure def has_item(lst: List[str], itm: str): bool = {
    lst.indices().exists(i => lst[i] == itm)
  }

  pure def remove_first(lst: List[str], itm: str): List[str] = {
    val idx = lst.indices().filter(i => lst[i] == itm)
    if (idx.size() == 0) lst
    else {
      val first_idx = idx.fold(lst.length(), (acc, i) => if (i < acc) i else acc)
      range(0, lst.length()).foldl(List(), (acc, i) =>
        if (i == first_idx) acc else acc.append(lst[i])
      )
    }
  }

  action init = all {
    player_gold' = 100,
    shop_gold' = 200,
    player_inv' = List(),
    shop_inv' = ["Sword", "Shield", "Potion"],
  }

  action buy(itm: str): bool = all {
    has_item(shop_inv, itm),
    player_gold >= PRICE,
    player_inv.length() < MAX_INV,
    player_gold' = player_gold - PRICE,
    shop_gold' = shop_gold + PRICE,
    player_inv' = player_inv.append(itm),
    shop_inv' = remove_first(shop_inv, itm),
  }

  action sell(itm: str): bool = all {
    has_item(player_inv, itm),
    shop_gold >= PRICE,
    shop_inv.length() < MAX_INV,
    player_gold' = player_gold + PRICE,
    shop_gold' = shop_gold - PRICE,
    player_inv' = remove_first(player_inv, itm),
    shop_inv' = shop_inv.append(itm),
  }

  action buy_blocked_no_gold(itm: str): bool = all {
    has_item(shop_inv, itm),
    player_gold < PRICE,
    player_gold' = player_gold,
    shop_gold' = shop_gold,
    player_inv' = player_inv,
    shop_inv' = shop_inv,
  }

  action sell_blocked_no_item(itm: str): bool = all {
    not(has_item(player_inv, itm)),
    player_gold' = player_gold,
    shop_gold' = shop_gold,
    player_inv' = player_inv,
    shop_inv' = shop_inv,
  }

  action step = {
    nondet itm = Set("Sword", "Shield", "Potion").oneOf()
    any {
      buy(itm),
      sell(itm),
      buy_blocked_no_gold(itm),
      sell_blocked_no_item(itm),
    }
  }

  val gold_conserved = player_gold + shop_gold == 300

  val items_conserved = player_inv.length() + shop_inv.length() == 3

  val gold_non_negative = player_gold >= 0 and shop_gold >= 0

  val inv_bounded = player_inv.length() <= MAX_INV
}

module shop_run {
  import shop(MAX_INV = 5, PRICE = 25).*
}
