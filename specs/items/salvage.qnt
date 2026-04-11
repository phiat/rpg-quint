module salvage {
  var qty_wood: int
  var qty_iron: int
  var qty_gold_dust: int
  var qty_sword: int
  var qty_shield: int
  var qty_staff: int
  var equipped_weapon: int   // 0=none, 1=sword, 2=staff
  var equipped_armor: int    // 0=none, 1=shield
  var salvage_level: int     // 1-3

  // --- Pure helpers for salvage output ---
  pure def salvage_sword_wood(lvl: int): int = 1 + (lvl - 1)
  pure def salvage_sword_iron(lvl: int): int = 2 + (lvl - 1)

  pure def salvage_shield_wood(lvl: int): int = 2 + (lvl - 1)
  pure def salvage_shield_iron(lvl: int): int = 1 + (lvl - 1)

  pure def salvage_staff_wood(lvl: int): int = 1 + (lvl - 1)
  pure def salvage_staff_iron(lvl: int): int = 1 + (lvl - 1)
  pure def salvage_staff_gold(lvl: int): int = 1 + (lvl - 1)

  // --- Invariants ---
  val quantities_non_negative = and {
    qty_wood >= 0,
    qty_iron >= 0,
    qty_gold_dust >= 0,
    qty_sword >= 0,
    qty_shield >= 0,
    qty_staff >= 0,
  }

  val salvage_level_bounded = salvage_level >= 1 and salvage_level <= 3

  val equip_bounded = and {
    equipped_weapon >= 0,
    equipped_weapon <= 2,
    equipped_armor >= 0,
    equipped_armor <= 1,
  }

  // --- Init ---
  action init = all {
    qty_wood' = 5,
    qty_iron' = 5,
    qty_gold_dust' = 4,
    qty_sword' = 2,
    qty_shield' = 1,
    qty_staff' = 1,
    equipped_weapon' = 0,
    equipped_armor' = 0,
    salvage_level' = 1,
  }

  // --- Crafting ---
  // Sword: 2 wood + 3 iron -> 1 sword
  action craft_sword = all {
    qty_wood >= 2,
    qty_iron >= 3,
    qty_wood' = qty_wood - 2,
    qty_iron' = qty_iron - 3,
    qty_gold_dust' = qty_gold_dust,
    qty_sword' = qty_sword + 1,
    qty_shield' = qty_shield,
    qty_staff' = qty_staff,
    equipped_weapon' = equipped_weapon,
    equipped_armor' = equipped_armor,
    salvage_level' = salvage_level,
  }

  // Shield: 3 wood + 1 iron -> 1 shield
  action craft_shield = all {
    qty_wood >= 3,
    qty_iron >= 1,
    qty_wood' = qty_wood - 3,
    qty_iron' = qty_iron - 1,
    qty_gold_dust' = qty_gold_dust,
    qty_sword' = qty_sword,
    qty_shield' = qty_shield + 1,
    qty_staff' = qty_staff,
    equipped_weapon' = equipped_weapon,
    equipped_armor' = equipped_armor,
    salvage_level' = salvage_level,
  }

  // Staff: 1 wood + 1 iron + 2 gold_dust -> 1 staff
  action craft_staff = all {
    qty_wood >= 1,
    qty_iron >= 1,
    qty_gold_dust >= 2,
    qty_wood' = qty_wood - 1,
    qty_iron' = qty_iron - 1,
    qty_gold_dust' = qty_gold_dust - 2,
    qty_sword' = qty_sword,
    qty_shield' = qty_shield,
    qty_staff' = qty_staff + 1,
    equipped_weapon' = equipped_weapon,
    equipped_armor' = equipped_armor,
    salvage_level' = salvage_level,
  }

  // --- Equip / Unequip ---
  action equip_sword = all {
    qty_sword >= 1,
    equipped_weapon == 0,
    qty_sword' = qty_sword - 1,
    equipped_weapon' = 1,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron,
    qty_gold_dust' = qty_gold_dust,
    qty_shield' = qty_shield,
    qty_staff' = qty_staff,
    equipped_armor' = equipped_armor,
    salvage_level' = salvage_level,
  }

  action equip_staff = all {
    qty_staff >= 1,
    equipped_weapon == 0,
    qty_staff' = qty_staff - 1,
    equipped_weapon' = 2,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron,
    qty_gold_dust' = qty_gold_dust,
    qty_sword' = qty_sword,
    qty_shield' = qty_shield,
    equipped_armor' = equipped_armor,
    salvage_level' = salvage_level,
  }

  action equip_shield = all {
    qty_shield >= 1,
    equipped_armor == 0,
    qty_shield' = qty_shield - 1,
    equipped_armor' = 1,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron,
    qty_gold_dust' = qty_gold_dust,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff,
    equipped_weapon' = equipped_weapon,
    salvage_level' = salvage_level,
  }

  action unequip_weapon = all {
    equipped_weapon != 0,
    if (equipped_weapon == 1) all {
      qty_sword' = qty_sword + 1,
      qty_staff' = qty_staff,
    } else all {
      qty_staff' = qty_staff + 1,
      qty_sword' = qty_sword,
    },
    equipped_weapon' = 0,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron,
    qty_gold_dust' = qty_gold_dust,
    qty_shield' = qty_shield,
    equipped_armor' = equipped_armor,
    salvage_level' = salvage_level,
  }

  action unequip_armor = all {
    equipped_armor != 0,
    qty_shield' = qty_shield + 1,
    equipped_armor' = 0,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron,
    qty_gold_dust' = qty_gold_dust,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff,
    equipped_weapon' = equipped_weapon,
    salvage_level' = salvage_level,
  }

  // --- Salvage (cannot salvage equipped items) ---
  action salvage_sword = all {
    qty_sword >= 1,
    qty_sword' = qty_sword - 1,
    qty_wood' = qty_wood + salvage_sword_wood(salvage_level),
    qty_iron' = qty_iron + salvage_sword_iron(salvage_level),
    qty_gold_dust' = qty_gold_dust,
    qty_shield' = qty_shield,
    qty_staff' = qty_staff,
    equipped_weapon' = equipped_weapon,
    equipped_armor' = equipped_armor,
    salvage_level' = salvage_level,
  }

  action salvage_shield = all {
    qty_shield >= 1,
    qty_shield' = qty_shield - 1,
    qty_wood' = qty_wood + salvage_shield_wood(salvage_level),
    qty_iron' = qty_iron + salvage_shield_iron(salvage_level),
    qty_gold_dust' = qty_gold_dust,
    qty_sword' = qty_sword,
    qty_staff' = qty_staff,
    equipped_weapon' = equipped_weapon,
    equipped_armor' = equipped_armor,
    salvage_level' = salvage_level,
  }

  action salvage_staff = all {
    qty_staff >= 1,
    qty_staff' = qty_staff - 1,
    qty_wood' = qty_wood + salvage_staff_wood(salvage_level),
    qty_iron' = qty_iron + salvage_staff_iron(salvage_level),
    qty_gold_dust' = qty_gold_dust + salvage_staff_gold(salvage_level),
    qty_sword' = qty_sword,
    qty_shield' = qty_shield,
    equipped_weapon' = equipped_weapon,
    equipped_armor' = equipped_armor,
    salvage_level' = salvage_level,
  }

  // --- Upgrade salvage level ---
  action upgrade_salvage = all {
    salvage_level < 3,
    qty_gold_dust >= 5,
    salvage_level' = salvage_level + 1,
    qty_gold_dust' = qty_gold_dust - 5,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron,
    qty_sword' = qty_sword,
    qty_shield' = qty_shield,
    qty_staff' = qty_staff,
    equipped_weapon' = equipped_weapon,
    equipped_armor' = equipped_armor,
  }

  // --- Blocked actions (no-ops for reachability) ---
  action craft_blocked = all {
    (qty_wood < 2 or qty_iron < 3),
    (qty_wood < 3 or qty_iron < 1),
    (qty_wood < 1 or qty_iron < 1 or qty_gold_dust < 2),
    qty_wood' = qty_wood,
    qty_iron' = qty_iron,
    qty_gold_dust' = qty_gold_dust,
    qty_sword' = qty_sword,
    qty_shield' = qty_shield,
    qty_staff' = qty_staff,
    equipped_weapon' = equipped_weapon,
    equipped_armor' = equipped_armor,
    salvage_level' = salvage_level,
  }

  action salvage_blocked = all {
    qty_sword < 1,
    qty_shield < 1,
    qty_staff < 1,
    qty_wood' = qty_wood,
    qty_iron' = qty_iron,
    qty_gold_dust' = qty_gold_dust,
    qty_sword' = qty_sword,
    qty_shield' = qty_shield,
    qty_staff' = qty_staff,
    equipped_weapon' = equipped_weapon,
    equipped_armor' = equipped_armor,
    salvage_level' = salvage_level,
  }

  action step = any {
    craft_sword,
    craft_shield,
    craft_staff,
    equip_sword,
    equip_staff,
    equip_shield,
    unequip_weapon,
    unequip_armor,
    salvage_sword,
    salvage_shield,
    salvage_staff,
    upgrade_salvage,
    craft_blocked,
    salvage_blocked,
  }
}

module salvage_run {
  import salvage.*
}
