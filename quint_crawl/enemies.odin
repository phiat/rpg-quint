package quint_crawl

// --- Enemy catalog (data-driven hybrid) ---
//
// Design: the Quint spec stays abstract. Combat only reads `enemy_hp`,
// `enemy_attack`, and `enemy_element` — these are the only effect axes
// model-checked by MBT. Enemy identity (name, trait tag, sprite) lives
// entirely on the Odin side, so the catalog can grow without inflating
// the spec state space.
//
// Hybrid structure:
//   - ~20 archetypes (4 per tier, 5 tiers) define the abstract stat row
//   - each archetype owns a name pool of ~10 thematic variants
//   - zone level picks the tier, a deterministic hash picks the archetype
//     within that tier, and another hash picks a name within the pool
//
// Stats are flat (base_hp / base_attack from zone level formulas). Variance
// is deliberately held off in v1 — the spec does not model per-encounter
// variance and adding it here would diverge the Odin side from the MBT
// harness's abstract contract. Element comes from `zone_element`, not the
// archetype row, matching the spec.
//
// Trait tags feed future systems (loot tables, elemental weakness, quest
// targets). For v1 they are wired in the struct but not consumed —
// `resolve_loot` has a TODO hook.

Enemy_Trait :: enum {
	Undead,
	Beast,
	Elemental,
	Construct,
	Humanoid,
	Aberration,
}

Enemy_Archetype :: struct {
	name_pool:   []string,  // ~10 distinct names for this archetype
	tier:        int,       // 1..MAX_LEVEL, matches zone_level
	base_hp:     int,       // flavor baseline; actual HP comes from zone_enemy_hp
	base_attack: int,       // flavor baseline; actual ATK comes from zone_enemy_atk
	element:     int,       // 0=none,1=fire,2=ice,3=lightning,4=earth (flavor)
	trait:       Enemy_Trait,
}

ENEMY_ARCHETYPES := [?]Enemy_Archetype{
	// --- Tier 1: weak vermin, slimes, wisps, imps ---
	{
		name_pool   = []string{
			"Green Slime", "Blue Slime", "Acid Slime", "Mud Slime",
			"Toxic Slime", "Ember Slime", "Frost Slime", "Ooze",
			"Pudding", "Jelly",
		},
		tier = 1, base_hp = 12, base_attack = 3, element = 0, trait = .Aberration,
	},
	{
		name_pool   = []string{
			"Giant Rat", "Sewer Rat", "Plague Rat", "Cave Bat",
			"Vampire Bat", "Dire Rat", "Pack Rat", "Shadow Bat",
			"Rot Rat", "Blood Bat",
		},
		tier = 1, base_hp = 10, base_attack = 4, element = 0, trait = .Beast,
	},
	{
		name_pool   = []string{
			"Lesser Imp", "Fire Imp", "Soot Imp", "Cinder Imp",
			"Scamp", "Mischief Imp", "Needletooth Imp", "Coal Imp",
			"Ash Imp", "Spark Imp",
		},
		tier = 1, base_hp = 11, base_attack = 4, element = 1, trait = .Aberration,
	},
	{
		name_pool   = []string{
			"Will-o-Wisp", "Marsh Wisp", "Pale Wisp", "Blue Wisp",
			"Corpse Candle", "Moon Wisp", "Dusk Wisp", "Spark Mote",
			"Glimmer", "Hollow Light",
		},
		tier = 1, base_hp = 9, base_attack = 3, element = 3, trait = .Elemental,
	},

	// --- Tier 2: skeletons, wolves, bandits, lesser elementals ---
	{
		name_pool   = []string{
			"Skeleton Warrior", "Skeleton Archer", "Bone Scout", "Rattling Skeleton",
			"Cracked Skeleton", "Grave Skeleton", "Rusted Skeleton", "Tomb Skeleton",
			"Husk Skeleton", "Dust Skeleton",
		},
		tier = 2, base_hp = 22, base_attack = 6, element = 0, trait = .Undead,
	},
	{
		name_pool   = []string{
			"Grey Wolf", "Timber Wolf", "Dire Wolf", "Shadow Wolf",
			"Alpha Wolf", "Snow Wolf", "Dusk Wolf", "Rabid Wolf",
			"Moon Wolf", "Bone Wolf",
		},
		tier = 2, base_hp = 24, base_attack = 7, element = 0, trait = .Beast,
	},
	{
		name_pool   = []string{
			"Highway Bandit", "Forest Bandit", "Thug", "Cutpurse",
			"Marauder", "Brigand", "Raider", "Outlaw",
			"Deserter", "Mercenary",
		},
		tier = 2, base_hp = 26, base_attack = 6, element = 0, trait = .Humanoid,
	},
	{
		name_pool   = []string{
			"Lesser Fire Mote", "Lesser Ice Mote", "Lesser Spark", "Stone Mote",
			"Ember Spirit", "Frost Spirit", "Storm Mote", "Clay Spirit",
			"Flame Wisp", "Hail Wisp",
		},
		tier = 2, base_hp = 20, base_attack = 7, element = 1, trait = .Elemental,
	},

	// --- Tier 3: wraiths, trolls, gargoyles, harpies ---
	{
		name_pool   = []string{
			"Wraith", "Shade", "Tomb Wraith", "Banshee",
			"Specter", "Phantom", "Hollow Wraith", "Veil Wraith",
			"Death Shade", "Ashen Wraith",
		},
		tier = 3, base_hp = 40, base_attack = 10, element = 2, trait = .Undead,
	},
	{
		name_pool   = []string{
			"Cave Troll", "Mountain Troll", "Bog Troll", "Moss Troll",
			"Stone Troll", "Frost Troll", "River Troll", "Ogre",
			"Hill Giant", "Brute Troll",
		},
		tier = 3, base_hp = 50, base_attack = 9, element = 4, trait = .Humanoid,
	},
	{
		name_pool   = []string{
			"Gargoyle", "Stone Watcher", "Ruin Gargoyle", "Obsidian Gargoyle",
			"Winged Statue", "Temple Guardian", "Grim Sentinel", "Chapel Gargoyle",
			"Basalt Gargoyle", "Granite Watcher",
		},
		tier = 3, base_hp = 44, base_attack = 10, element = 4, trait = .Construct,
	},
	{
		name_pool   = []string{
			"Harpy", "Storm Harpy", "Siren", "Cliff Harpy",
			"Manticore Cub", "Chimera Whelp", "Wyvern Scout", "Dire Eagle",
			"Razor Harpy", "Screech Harpy",
		},
		tier = 3, base_hp = 38, base_attack = 11, element = 3, trait = .Beast,
	},

	// --- Tier 4: liches, golems, demons, greater elementals ---
	{
		name_pool   = []string{
			"Lich", "Bone Lich", "Frost Lich", "Death Knight",
			"Tomb Lord", "Crypt Lich", "Wight King", "Revenant",
			"Bone Pharaoh", "Shadow Lich",
		},
		tier = 4, base_hp = 70, base_attack = 14, element = 2, trait = .Undead,
	},
	{
		name_pool   = []string{
			"Stone Golem", "Iron Golem", "Clay Golem", "Crystal Golem",
			"Obsidian Golem", "Bronze Golem", "Rune Golem", "War Golem",
			"Marble Golem", "Forge Golem",
		},
		tier = 4, base_hp = 80, base_attack = 13, element = 4, trait = .Construct,
	},
	{
		name_pool   = []string{
			"Greater Demon", "Pit Fiend", "Hellhound", "Balor",
			"Incubus", "Succubus", "Horned Demon", "Shadow Demon",
			"Flame Demon", "Abyssal Demon",
		},
		tier = 4, base_hp = 72, base_attack = 15, element = 1, trait = .Aberration,
	},
	{
		name_pool   = []string{
			"Fire Elemental", "Ice Elemental", "Storm Elemental", "Earth Elemental",
			"Magma Elemental", "Glacier Elemental", "Thunder Elemental", "Mountain Elemental",
			"Ash Elemental", "Tempest Elemental",
		},
		tier = 4, base_hp = 68, base_attack = 14, element = 3, trait = .Elemental,
	},

	// --- Tier 5: dragons, archdemons, ancient liches, titans ---
	{
		name_pool   = []string{
			"Red Dragon", "Green Dragon", "Black Dragon", "White Dragon",
			"Blue Dragon", "Bronze Dragon", "Shadow Dragon", "Frost Wyrm",
			"Elder Wyrm", "Volcanic Dragon",
		},
		tier = 5, base_hp = 120, base_attack = 20, element = 1, trait = .Beast,
	},
	{
		name_pool   = []string{
			"Archdemon", "Demon Lord", "Abyssal Prince", "Hellgate Tyrant",
			"Infernal Overlord", "Void Demon", "Throne of Ash", "Doom Bringer",
			"Pit Lord", "Black Seraph",
		},
		tier = 5, base_hp = 110, base_attack = 22, element = 1, trait = .Aberration,
	},
	{
		name_pool   = []string{
			"Ancient Lich", "Eternal Lich", "Lich King", "Undying Pharaoh",
			"Mummy Lord", "Death Sovereign", "Bone Emperor", "Necrarch",
			"Grave Sovereign", "Crown of Dust",
		},
		tier = 5, base_hp = 115, base_attack = 19, element = 2, trait = .Undead,
	},
	{
		name_pool   = []string{
			"Titan", "Stone Colossus", "Iron Titan", "Forgotten Golem",
			"Primordial Titan", "World Shaker", "Mountain Titan", "Sky Colossus",
			"Obsidian Titan", "Runebound Colossus",
		},
		tier = 5, base_hp = 130, base_attack = 18, element = 4, trait = .Construct,
	},
}

// Count of named enemies across the catalog (for diagnostics / tests).
enemy_name_count :: proc() -> int {
	total := 0
	for a in ENEMY_ARCHETYPES {
		total += len(a.name_pool)
	}
	return total
}

// Deterministic non-negative hash of three ints. Kept simple on purpose:
// this is UI flavor, not a cryptographic seed.
enemy_hash3 :: proc(a, b, c: int) -> int {
	h := a * 73856093 ~ b * 19349663 ~ c * 83492791
	if h < 0 do h = -h
	return h
}

// Pick the archetype index for a given zone position and seed.
// Returns an index into ENEMY_ARCHETYPES whose tier matches zone_level(x,y).
// Falls back to the first matching archetype if the hash lands outside.
select_enemy_archetype :: proc(x, y, seed: int) -> int {
	tier := zone_level(x, y)
	// Collect matches on the stack — small fixed upper bound.
	matches: [len(ENEMY_ARCHETYPES)]int
	n := 0
	for a, i in ENEMY_ARCHETYPES {
		if a.tier == tier {
			matches[n] = i
			n += 1
		}
	}
	if n == 0 do return 0
	idx := enemy_hash3(x, y, seed) % n
	return matches[idx]
}

// Pick a specific name within an archetype's name pool, using a second hash.
select_enemy_name :: proc(archetype_idx, x, y, seed: int) -> string {
	if archetype_idx < 0 || archetype_idx >= len(ENEMY_ARCHETYPES) do return "Enemy"
	pool := ENEMY_ARCHETYPES[archetype_idx].name_pool
	if len(pool) == 0 do return "Enemy"
	idx := enemy_hash3(x + 131, y + 17, seed * 3 + 7) % len(pool)
	return pool[idx]
}
