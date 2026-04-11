module equip {
  const MAX_INV: int

  var inventory: List[str]
  var weapon: str
  var armor: str
  var accessory: str

  val EMPTY = ""

  val all_items = Set("Sword", "Shield", "Ring", "Helmet", "Cloak")

  val slot_items: List[str] =
    if (weapon != EMPTY and armor != EMPTY and accessory != EMPTY)
      [weapon, armor, accessory]
    else if (weapon != EMPTY and armor != EMPTY)
      [weapon, armor]
    else if (weapon != EMPTY and accessory != EMPTY)
      [weapon, accessory]
    else if (armor != EMPTY and accessory != EMPTY)
      [armor, accessory]
    else if (weapon != EMPTY)
      [weapon]
    else if (armor != EMPTY)
      [armor]
    else if (accessory != EMPTY)
      [accessory]
    else
      []

  val total_count: int = inventory.length() + slot_items.length()

  pure def list_has(lst: List[str], elem: str): bool =
    lst.foldl(false, (acc, x) => acc or x == elem)

  pure def list_remove_first(lst: List[str], elem: str): List[str] =
    lst.foldl(([], false), (pair, x) =>
      if (not(pair._2) and x == elem)
        (pair._1, true)
      else
        (pair._1.append(x), false)
    )._1

  action init = all {
    inventory' = ["Sword", "Shield", "Ring"],
    weapon' = EMPTY,
    armor' = EMPTY,
    accessory' = EMPTY,
  }

  action equip_weapon(itm: str): bool = all {
    list_has(inventory, itm),
    weapon == EMPTY,
    inventory' = list_remove_first(inventory, itm),
    weapon' = itm,
    armor' = armor,
    accessory' = accessory,
  }

  action equip_armor(itm: str): bool = all {
    list_has(inventory, itm),
    armor == EMPTY,
    inventory' = list_remove_first(inventory, itm),
    weapon' = weapon,
    armor' = itm,
    accessory' = accessory,
  }

  action equip_accessory(itm: str): bool = all {
    list_has(inventory, itm),
    accessory == EMPTY,
    inventory' = list_remove_first(inventory, itm),
    weapon' = weapon,
    armor' = armor,
    accessory' = itm,
  }

  action unequip_weapon: bool = all {
    weapon != EMPTY,
    inventory.length() < MAX_INV,
    inventory' = inventory.append(weapon),
    weapon' = EMPTY,
    armor' = armor,
    accessory' = accessory,
  }

  action unequip_armor: bool = all {
    armor != EMPTY,
    inventory.length() < MAX_INV,
    inventory' = inventory.append(armor),
    weapon' = weapon,
    armor' = EMPTY,
    accessory' = accessory,
  }

  action unequip_accessory: bool = all {
    accessory != EMPTY,
    inventory.length() < MAX_INV,
    inventory' = inventory.append(accessory),
    weapon' = weapon,
    armor' = armor,
    accessory' = EMPTY,
  }

  action equip_blocked_slot_full(itm: str): bool = all {
    list_has(inventory, itm),
    weapon != EMPTY,
    armor != EMPTY,
    accessory != EMPTY,
    inventory' = inventory,
    weapon' = weapon,
    armor' = armor,
    accessory' = accessory,
  }

  action step = {
    nondet itm = all_items.oneOf()
    any {
      equip_weapon(itm),
      equip_armor(itm),
      equip_accessory(itm),
      unequip_weapon,
      unequip_armor,
      unequip_accessory,
      equip_blocked_slot_full(itm),
    }
  }

  /// Total number of items is always conserved.
  val item_conservation: bool = total_count == 3

  /// No item string appears in more than one location.
  val no_duplicates: bool = {
    val locs: List[str] = inventory.concat(slot_items)
    locs.foldl(true, (acc, x) =>
      acc and locs.foldl(0, (cnt, y) => if (y == x) cnt + 1 else cnt) == 1
    )
  }

  /// Inventory never exceeds maximum size.
  val inv_bounded: bool = inventory.length() <= MAX_INV
}

module equip_run {
  import equip(MAX_INV = 5).*
}
