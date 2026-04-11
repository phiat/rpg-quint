package stamina_mbt

Stamina_System :: struct {
	current_stamina: int,
	max_stamina:     int,
	regen_rate:      int,
	turn:            int,
}

attack :: proc(s: ^Stamina_System) -> bool {
	if s.current_stamina < 3 do return false
	s.current_stamina -= 3
	s.turn += 1
	return true
}

defend :: proc(s: ^Stamina_System) -> bool {
	if s.current_stamina < 2 do return false
	s.current_stamina -= 2
	s.turn += 1
	return true
}

special :: proc(s: ^Stamina_System) -> bool {
	if s.current_stamina < 6 do return false
	s.current_stamina -= 6
	s.turn += 1
	return true
}

rest :: proc(s: ^Stamina_System) {
	new_stam := s.current_stamina + s.regen_rate
	s.current_stamina = min(new_stam, s.max_stamina)
	s.turn += 1
}
