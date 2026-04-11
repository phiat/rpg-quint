package faction_mbt

Faction_System :: struct {
	standing_guild:  int,
	standing_crown:  int,
	standing_rebels: int,
	allied_faction:  int, // 0=none, 1=guild, 2=crown, 3=rebels
}

clamp :: proc(v, lo, hi: int) -> int {
	if v < lo do return lo
	if v > hi do return hi
	return v
}

faction_init :: proc(f: ^Faction_System) {
	f.standing_guild  = 0
	f.standing_crown  = 0
	f.standing_rebels = 0
	f.allied_faction  = 0
}

join_guild :: proc(f: ^Faction_System) {
	f.standing_guild  = 50
	f.standing_crown  = clamp(f.standing_crown - 25, -100, 100)
	f.standing_rebels = clamp(f.standing_rebels - 25, -100, 100)
	f.allied_faction  = 1
}

join_crown :: proc(f: ^Faction_System) {
	f.standing_guild  = clamp(f.standing_guild - 25, -100, 100)
	f.standing_crown  = 50
	f.standing_rebels = clamp(f.standing_rebels - 25, -100, 100)
	f.allied_faction  = 2
}

join_rebels :: proc(f: ^Faction_System) {
	f.standing_guild  = clamp(f.standing_guild - 25, -100, 100)
	f.standing_crown  = clamp(f.standing_crown - 25, -100, 100)
	f.standing_rebels = 50
	f.allied_faction  = 3
}

quest_guild :: proc(f: ^Faction_System) {
	f.standing_guild  = clamp(f.standing_guild + 10, -100, 100)
	f.standing_crown  = clamp(f.standing_crown - 5, -100, 100)
	f.standing_rebels = clamp(f.standing_rebels - 5, -100, 100)
	// allied_faction unchanged
}

quest_crown :: proc(f: ^Faction_System) {
	f.standing_guild  = clamp(f.standing_guild - 5, -100, 100)
	f.standing_crown  = clamp(f.standing_crown + 10, -100, 100)
	f.standing_rebels = clamp(f.standing_rebels - 5, -100, 100)
	// allied_faction unchanged
}

quest_rebels :: proc(f: ^Faction_System) {
	f.standing_guild  = clamp(f.standing_guild - 5, -100, 100)
	f.standing_crown  = clamp(f.standing_crown - 5, -100, 100)
	f.standing_rebels = clamp(f.standing_rebels + 10, -100, 100)
	// allied_faction unchanged
}

betray_current :: proc(f: ^Faction_System) {
	switch f.allied_faction {
	case 1:
		f.standing_guild = clamp(-f.standing_guild, -100, 100)
	case 2:
		f.standing_crown = clamp(-f.standing_crown, -100, 100)
	case 3:
		f.standing_rebels = clamp(-f.standing_rebels, -100, 100)
	}
	f.allied_faction = 0
}
