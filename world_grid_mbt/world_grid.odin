package world_grid_mbt

World_Grid :: struct {
	player_x:      int,
	player_y:      int,
	player_level:  int,
	visited_count: int,
	current_zone:  string,
}

ZONE_NAMES := [3][3]string{
	{"Village", "Plains", "Ruins"},
	{"Forest", "Cave", "Shrine"},
	{"Swamp", "Mountain", "Castle"},
}

ZONE_LEVEL_REQ := [3][3]int{
	{1, 1, 2},
	{1, 2, 2},
	{1, 2, 3},
}

zone_name :: proc(x, y: int) -> string {
	if x < 0 || x > 2 || y < 0 || y > 2 do return "Unknown"
	return ZONE_NAMES[x][y]
}

zone_level_req :: proc(x, y: int) -> int {
	if x < 0 || x > 2 || y < 0 || y > 2 do return 99
	return ZONE_LEVEL_REQ[x][y]
}

move_up :: proc(w: ^World_Grid) -> bool {
	if w.player_y <= 0 do return false
	ny := w.player_y - 1
	if zone_level_req(w.player_x, ny) > w.player_level do return false
	w.player_y = ny
	w.visited_count += 1
	w.current_zone = zone_name(w.player_x, w.player_y)
	return true
}

move_down :: proc(w: ^World_Grid) -> bool {
	if w.player_y >= 2 do return false
	ny := w.player_y + 1
	if zone_level_req(w.player_x, ny) > w.player_level do return false
	w.player_y = ny
	w.visited_count += 1
	w.current_zone = zone_name(w.player_x, w.player_y)
	return true
}

move_left :: proc(w: ^World_Grid) -> bool {
	if w.player_x <= 0 do return false
	nx := w.player_x - 1
	if zone_level_req(nx, w.player_y) > w.player_level do return false
	w.player_x = nx
	w.visited_count += 1
	w.current_zone = zone_name(w.player_x, w.player_y)
	return true
}

move_right :: proc(w: ^World_Grid) -> bool {
	if w.player_x >= 2 do return false
	nx := w.player_x + 1
	if zone_level_req(nx, w.player_y) > w.player_level do return false
	w.player_x = nx
	w.visited_count += 1
	w.current_zone = zone_name(w.player_x, w.player_y)
	return true
}

level_up :: proc(w: ^World_Grid) -> bool {
	if w.player_level >= 3 do return false
	w.player_level += 1
	return true
}
