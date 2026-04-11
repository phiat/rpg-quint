package reputation_mbt

Reputation_System :: struct {
	rep_warriors: int,
	rep_mages:    int,
	rep_thieves:  int,
}

clamp :: proc(v, lo, hi: int) -> int {
	if v < lo do return lo
	if v > hi do return hi
	return v
}

help_warriors :: proc(r: ^Reputation_System, amount: int) {
	r.rep_warriors = clamp(r.rep_warriors + amount, -100, 100)
	r.rep_thieves = clamp(r.rep_thieves - amount, -100, 100)
}

help_mages :: proc(r: ^Reputation_System, amount: int) {
	r.rep_mages = clamp(r.rep_mages + amount, -100, 100)
}

help_thieves :: proc(r: ^Reputation_System, amount: int) {
	r.rep_warriors = clamp(r.rep_warriors - amount, -100, 100)
	r.rep_thieves = clamp(r.rep_thieves + amount, -100, 100)
}

betray_warriors :: proc(r: ^Reputation_System) {
	r.rep_warriors = clamp(r.rep_warriors - 50, -100, 100)
	r.rep_thieves = clamp(r.rep_thieves + 25, -100, 100)
}

betray_thieves :: proc(r: ^Reputation_System) {
	r.rep_warriors = clamp(r.rep_warriors + 25, -100, 100)
	r.rep_thieves = clamp(r.rep_thieves - 50, -100, 100)
}
