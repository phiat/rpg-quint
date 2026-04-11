package combat_full_mbt

Combat_Full :: struct {
	hp_a:           int,
	hp_b:           int,
	weapon_dmg_a:   int,
	weapon_dmg_b:   int,
	buff_a:         int,
	buff_b:         int,
	buff_turns_a:   int,
	buff_turns_b:   int,
	poison_a:       int,
	poison_b:       int,
	poison_turns_a: int,
	poison_turns_b: int,
	turn:           string,
	game_over:      bool,
}

attack :: proc(c: ^Combat_Full) {
	if c.game_over do return

	switch c.turn {
	case "A":
		c.hp_b -= (c.weapon_dmg_a + c.buff_a)
		tick_effects(c)
		check_game_over(c)
		c.turn = "B"
	case "B":
		c.hp_a -= (c.weapon_dmg_b + c.buff_b)
		tick_effects(c)
		check_game_over(c)
		c.turn = "A"
	}
}

apply_poison :: proc(c: ^Combat_Full, who: string, dmg: int, dur: int) -> bool {
	switch who {
	case "A":
		if c.poison_turns_a != 0 do return false
		c.poison_a = dmg
		c.poison_turns_a = dur
	case "B":
		if c.poison_turns_b != 0 do return false
		c.poison_b = dmg
		c.poison_turns_b = dur
	}
	return true
}

apply_buff :: proc(c: ^Combat_Full, who: string, amt: int, dur: int) -> bool {
	switch who {
	case "A":
		if c.buff_turns_a != 0 do return false
		c.buff_a = amt
		c.buff_turns_a = dur
	case "B":
		if c.buff_turns_b != 0 do return false
		c.buff_b = amt
		c.buff_turns_b = dur
	}
	return true
}

tick_effects :: proc(c: ^Combat_Full) {
	// Poison ticks for both players
	if c.poison_turns_a > 0 {
		c.hp_a -= c.poison_a
		c.poison_turns_a -= 1
		if c.poison_turns_a == 0 do c.poison_a = 0
	}
	if c.poison_turns_b > 0 {
		c.hp_b -= c.poison_b
		c.poison_turns_b -= 1
		if c.poison_turns_b == 0 do c.poison_b = 0
	}

	// Buff timer ticks for both players
	if c.buff_turns_a > 0 {
		c.buff_turns_a -= 1
		if c.buff_turns_a == 0 do c.buff_a = 0
	}
	if c.buff_turns_b > 0 {
		c.buff_turns_b -= 1
		if c.buff_turns_b == 0 do c.buff_b = 0
	}
}

check_game_over :: proc(c: ^Combat_Full) {
	if c.hp_a <= 0 || c.hp_b <= 0 {
		c.game_over = true
	}
}
