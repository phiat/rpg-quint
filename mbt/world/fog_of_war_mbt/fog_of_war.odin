package fog_of_war_mbt

FOG_GRID_SIZE :: 3

Fog_State :: struct {
	pos_x:      int,
	pos_y:      int,
	visited:    [FOG_GRID_SIZE][FOG_GRID_SIZE]bool,
	revealed:   [FOG_GRID_SIZE][FOG_GRID_SIZE]bool,
}

// A cell is revealed if visited, or is an orthogonal neighbor of a visited cell
should_reveal :: proc(s: ^Fog_State, cx, cy: int) -> bool {
	if s.visited[cx][cy] do return true
	if cx > 0 && s.visited[cx - 1][cy] do return true
	if cx < FOG_GRID_SIZE - 1 && s.visited[cx + 1][cy] do return true
	if cy > 0 && s.visited[cx][cy - 1] do return true
	if cy < FOG_GRID_SIZE - 1 && s.visited[cx][cy + 1] do return true
	return false
}

update_revealed :: proc(s: ^Fog_State) {
	for x in 0 ..< FOG_GRID_SIZE {
		for y in 0 ..< FOG_GRID_SIZE {
			s.revealed[x][y] = should_reveal(s, x, y)
		}
	}
}

do_move :: proc(s: ^Fog_State, nx, ny: int) -> bool {
	if nx < 0 || nx >= FOG_GRID_SIZE || ny < 0 || ny >= FOG_GRID_SIZE do return false
	s.pos_x = nx
	s.pos_y = ny
	s.visited[nx][ny] = true
	update_revealed(s)
	return true
}
