package leveling_mbt

Leveler :: struct {
	xp:            int,
	level:         int,
	hp_max:        int,
	atk:           int,
	xp_per_level:  int,
	hp_per_level:  int,
	atk_per_level: int,
}

gain_xp :: proc(l: ^Leveler, amount: int) {
	l.xp += amount
	threshold := l.level * l.xp_per_level
	if l.xp >= threshold {
		l.level += 1
		l.hp_max += l.hp_per_level
		l.atk += l.atk_per_level
	}
}
