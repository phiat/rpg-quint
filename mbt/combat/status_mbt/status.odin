package status_mbt

Status_System :: struct {
	hp:           int,
	base_atk:     int,
	poison_turns: int,
	buff_turns:   int,
	poison_dmg:   int,
	buff_amount:  int,
}

apply_poison :: proc(s: ^Status_System, dmg: int, dur: int) -> bool {
	if s.poison_turns != 0 do return false
	s.poison_dmg = dmg
	s.poison_turns = dur
	return true
}

apply_buff :: proc(s: ^Status_System, amt: int, dur: int) -> bool {
	if s.buff_turns != 0 do return false
	s.buff_amount = amt
	s.buff_turns = dur
	return true
}

tick :: proc(s: ^Status_System) {
	if s.poison_turns > 0 {
		s.hp -= s.poison_dmg
		s.poison_turns -= 1
		if s.poison_turns == 0 do s.poison_dmg = 0
	}
	if s.buff_turns > 0 {
		s.buff_turns -= 1
		if s.buff_turns == 0 do s.buff_amount = 0
	}
}
