module party {
  const MEMBER_CAP: int
  const STASH_CAP: int

  var inv_1: List[str]
  var inv_2: List[str]
  var inv_3: List[str]
  var stash: List[str]

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

  pure def has_item(lst: List[str], itm: str): bool = {
    lst.indices().exists(i => lst[i] == itm)
  }

  action init = all {
    inv_1' = ["Sword", "Shield"],
    inv_2' = ["Bow"],
    inv_3' = ["Staff"],
    stash' = ["Potion", "Ring"],
  }

  action deposit_1(itm: str): bool = all {
    has_item(inv_1, itm),
    stash.length() < STASH_CAP,
    inv_1' = remove_first(inv_1, itm),
    inv_2' = inv_2,
    inv_3' = inv_3,
    stash' = stash.append(itm),
  }

  action deposit_2(itm: str): bool = all {
    has_item(inv_2, itm),
    stash.length() < STASH_CAP,
    inv_1' = inv_1,
    inv_2' = remove_first(inv_2, itm),
    inv_3' = inv_3,
    stash' = stash.append(itm),
  }

  action deposit_3(itm: str): bool = all {
    has_item(inv_3, itm),
    stash.length() < STASH_CAP,
    inv_1' = inv_1,
    inv_2' = inv_2,
    inv_3' = remove_first(inv_3, itm),
    stash' = stash.append(itm),
  }

  action withdraw_1(itm: str): bool = all {
    has_item(stash, itm),
    inv_1.length() < MEMBER_CAP,
    inv_1' = inv_1.append(itm),
    inv_2' = inv_2,
    inv_3' = inv_3,
    stash' = remove_first(stash, itm),
  }

  action withdraw_2(itm: str): bool = all {
    has_item(stash, itm),
    inv_2.length() < MEMBER_CAP,
    inv_1' = inv_1,
    inv_2' = inv_2.append(itm),
    inv_3' = inv_3,
    stash' = remove_first(stash, itm),
  }

  action withdraw_3(itm: str): bool = all {
    has_item(stash, itm),
    inv_3.length() < MEMBER_CAP,
    inv_1' = inv_1,
    inv_2' = inv_2,
    inv_3' = inv_3.append(itm),
    stash' = remove_first(stash, itm),
  }

  action deposit_blocked(itm: str): bool = all {
    stash.length() >= STASH_CAP,
    inv_1' = inv_1,
    inv_2' = inv_2,
    inv_3' = inv_3,
    stash' = stash,
  }

  action withdraw_blocked(itm: str): bool = all {
    inv_1.length() >= MEMBER_CAP,
    inv_2.length() >= MEMBER_CAP,
    inv_3.length() >= MEMBER_CAP,
    inv_1' = inv_1,
    inv_2' = inv_2,
    inv_3' = inv_3,
    stash' = stash,
  }

  val all_items = Set("Sword", "Shield", "Bow", "Staff", "Potion", "Ring", "Elixir")

  action step = {
    nondet itm = all_items.oneOf()
    any {
      deposit_1(itm),
      deposit_2(itm),
      deposit_3(itm),
      withdraw_1(itm),
      withdraw_2(itm),
      withdraw_3(itm),
      deposit_blocked(itm),
      withdraw_blocked(itm),
    }
  }

  val items_conserved: bool = {
    inv_1.length() + inv_2.length() + inv_3.length() + stash.length() == 7
  }

  val all_bounded: bool = {
    inv_1.length() <= MEMBER_CAP and
    inv_2.length() <= MEMBER_CAP and
    inv_3.length() <= MEMBER_CAP and
    stash.length() <= STASH_CAP
  }
}

module party_run {
  import party(MEMBER_CAP = 4, STASH_CAP = 6).*
}
