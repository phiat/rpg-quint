package combat_mbt

Combat :: struct {
	hp_a:      int,
	hp_b:      int,
	atk_a:     int,
	atk_b:     int,
	turn:      string,
	game_over: bool,
}

attack :: proc(c: ^Combat) {
	if c.game_over do return

	switch c.turn {
	case "A":
		c.hp_b -= c.atk_a
		if c.hp_b <= 0 {
			c.game_over = true
		}
		c.turn = "B"
	case "B":
		c.hp_a -= c.atk_b
		if c.hp_a <= 0 {
			c.game_over = true
		}
		c.turn = "A"
	}
}
