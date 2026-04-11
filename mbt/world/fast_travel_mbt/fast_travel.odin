package fast_travel_mbt

TRAVEL_COST :: 5

Fast_Travel_State :: struct {
	pos_x: int,
	pos_y: int,
	gold:  int,
	// Unlocked waypoints: wp_XY where X=col, Y=row
	wp_00: bool,
	wp_10: bool,
	wp_20: bool,
	wp_01: bool,
	wp_11: bool,
	wp_21: bool,
	wp_02: bool,
	wp_12: bool,
	wp_22: bool,
}

get_wp :: proc(s: ^Fast_Travel_State, x, y: int) -> bool {
	if x == 0 && y == 0 do return s.wp_00
	if x == 1 && y == 0 do return s.wp_10
	if x == 2 && y == 0 do return s.wp_20
	if x == 0 && y == 1 do return s.wp_01
	if x == 1 && y == 1 do return s.wp_11
	if x == 2 && y == 1 do return s.wp_21
	if x == 0 && y == 2 do return s.wp_02
	if x == 1 && y == 2 do return s.wp_12
	return s.wp_22
}

unlock_wp :: proc(s: ^Fast_Travel_State, x, y: int) {
	if x == 0 && y == 0 do s.wp_00 = true
	if x == 1 && y == 0 do s.wp_10 = true
	if x == 2 && y == 0 do s.wp_20 = true
	if x == 0 && y == 1 do s.wp_01 = true
	if x == 1 && y == 1 do s.wp_11 = true
	if x == 2 && y == 1 do s.wp_21 = true
	if x == 0 && y == 2 do s.wp_02 = true
	if x == 1 && y == 2 do s.wp_12 = true
	if x == 2 && y == 2 do s.wp_22 = true
}

do_move :: proc(s: ^Fast_Travel_State, nx, ny: int) -> bool {
	if nx < 0 || nx > 2 || ny < 0 || ny > 2 do return false
	s.pos_x = nx
	s.pos_y = ny
	unlock_wp(s, nx, ny)
	return true
}

do_fast_travel :: proc(s: ^Fast_Travel_State, tx, ty: int) -> bool {
	if !get_wp(s, tx, ty) do return false
	if s.gold < TRAVEL_COST do return false
	s.pos_x = tx
	s.pos_y = ty
	s.gold -= TRAVEL_COST
	return true
}
