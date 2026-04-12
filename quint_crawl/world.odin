package quint_crawl

// Fog of war: a zone is revealed if visited or orthogonally adjacent to a visited zone
is_revealed :: proc(g: ^Game_State, x, y: int) -> bool {
	if x < 0 || x >= WORLD_SIZE || y < 0 || y >= WORLD_SIZE do return false
	if g.visited[x][y] do return true
	if x > 0 && g.visited[x - 1][y] do return true
	if x < WORLD_SIZE - 1 && g.visited[x + 1][y] do return true
	if y > 0 && g.visited[x][y - 1] do return true
	if y < WORLD_SIZE - 1 && g.visited[x][y + 1] do return true
	return false
}

// Update revealed state (call after any move)
update_revealed :: proc(g: ^Game_State) {
	// revealed is derived from visited — no separate storage needed
	// We use is_revealed() as a pure function instead
}

// Fast travel to a waypoint
fast_travel :: proc(g: ^Game_State, tx, ty: int) -> bool {
	if !can_act_map(g) do return false
	if tx < 0 || tx >= WORLD_SIZE || ty < 0 || ty >= WORLD_SIZE do return false
	if !g.waypoints[tx][ty] do return false
	if tx == g.pos_x && ty == g.pos_y do return false  // already there
	if zone_level(tx, ty) > g.level do return false
	was_visited := g.visited[tx][ty]
	g.pos_x = tx
	g.pos_y = ty
	g.turn_count += 1
	g.visited[tx][ty] = true
	// Quest 2: count NEW ZL2+ zone entries after Q1 complete
	if g.q1_kills >= Q1_TARGET && zone_level(tx, ty) >= 2 && !was_visited && g.q2_zones < Q2_TARGET {
		g.q2_zones += 1
	}
	return true
}

move :: proc(g: ^Game_State, dx, dy: int) -> bool {
	nx, ny := g.pos_x + dx, g.pos_y + dy
	if nx < 0 || nx >= WORLD_SIZE || ny < 0 || ny >= WORLD_SIZE do return false
	if !can_act_map(g) do return false
	if zone_level(nx, ny) > g.level do return false
	was_visited := g.visited[nx][ny]
	g.pos_x = nx
	g.pos_y = ny
	g.turn_count += 1
	// Mark visited + unlock waypoint at villages
	g.visited[nx][ny] = true
	if zone_has_services(nx, ny) {
		g.waypoints[nx][ny] = true
	}
	// Quest 2: count NEW ZL2+ zone entries after Q1 complete
	if g.q1_kills >= Q1_TARGET && zone_level(nx, ny) >= 2 && !was_visited && g.q2_zones < Q2_TARGET {
		g.q2_zones += 1
	}
	// Storm damage (can't kill — floor at 1)
	if zone_weather(nx, ny, g.turn_count) == 3 {
		g.hp = max(g.hp - STORM_MOVE_DMG, 1)
	}
	g.stamina = min(g.stamina + STAMINA_REGEN_PER_MOVE, g.max_stamina)
	if g.max_mana > 0 do g.mana = min(g.mana + MANA_REGEN_PER_MOVE, g.max_mana)
	return true
}

