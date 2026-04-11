package trap_mbt

TRAP_DAMAGE :: 10
PERCEPTION_THRESHOLD :: 3

Trap_State :: struct {
	pos_x:      int,
	pos_y:      int,
	hp:         int,
	max_hp:     int,
	perception: int,
	// Trap presence
	trap_present_00: bool,
	trap_present_01: bool,
	trap_present_10: bool,
	trap_present_11: bool,
	// Trap revealed
	trap_revealed_00: bool,
	trap_revealed_01: bool,
	trap_revealed_10: bool,
	trap_revealed_11: bool,
	// Trap triggered
	trap_triggered_00: bool,
	trap_triggered_01: bool,
	trap_triggered_10: bool,
	trap_triggered_11: bool,
}

get_present :: proc(s: ^Trap_State, x, y: int) -> bool {
	if x == 0 && y == 0 do return s.trap_present_00
	if x == 0 && y == 1 do return s.trap_present_01
	if x == 1 && y == 0 do return s.trap_present_10
	return s.trap_present_11
}

get_revealed :: proc(s: ^Trap_State, x, y: int) -> bool {
	if x == 0 && y == 0 do return s.trap_revealed_00
	if x == 0 && y == 1 do return s.trap_revealed_01
	if x == 1 && y == 0 do return s.trap_revealed_10
	return s.trap_revealed_11
}

get_triggered :: proc(s: ^Trap_State, x, y: int) -> bool {
	if x == 0 && y == 0 do return s.trap_triggered_00
	if x == 0 && y == 1 do return s.trap_triggered_01
	if x == 1 && y == 0 do return s.trap_triggered_10
	return s.trap_triggered_11
}

set_triggered :: proc(s: ^Trap_State, x, y: int) {
	if x == 0 && y == 0 do s.trap_triggered_00 = true
	if x == 0 && y == 1 do s.trap_triggered_01 = true
	if x == 1 && y == 0 do s.trap_triggered_10 = true
	if x == 1 && y == 1 do s.trap_triggered_11 = true
}

set_revealed :: proc(s: ^Trap_State, x, y: int) {
	if x == 0 && y == 0 do s.trap_revealed_00 = true
	if x == 0 && y == 1 do s.trap_revealed_01 = true
	if x == 1 && y == 0 do s.trap_revealed_10 = true
	if x == 1 && y == 1 do s.trap_revealed_11 = true
}

do_move :: proc(s: ^Trap_State, dx, dy: int) -> bool {
	nx := s.pos_x + dx
	ny := s.pos_y + dy
	if nx < 0 || nx > 1 || ny < 0 || ny > 1 do return false

	present := get_present(s, nx, ny)
	revealed := get_revealed(s, nx, ny)
	triggered := get_triggered(s, nx, ny)
	will_trigger := present && !revealed && !triggered

	s.pos_x = nx
	s.pos_y = ny

	if will_trigger {
		s.hp -= TRAP_DAMAGE
		set_triggered(s, nx, ny)
	}
	return true
}

do_scan :: proc(s: ^Trap_State) -> bool {
	if s.perception < PERCEPTION_THRESHOLD do return false
	set_revealed(s, s.pos_x, s.pos_y)
	return true
}

do_upgrade_perception :: proc(s: ^Trap_State) -> bool {
	if s.perception >= 5 do return false
	s.perception += 1
	return true
}
