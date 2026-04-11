package respawn_mbt

// Respawn system implementation — zone-based spawning with timers.

ZONE1_CAP    :: 4
ZONE2_CAP    :: 3
RESPAWN_TIME :: 3

Respawn_System :: struct {
	zone1_count: int,
	zone2_count: int,
	dead_count:  int,
	timer1:      int,
	timer2:      int,
}

kill_zone :: proc(sys: ^Respawn_System, zone: int) {
	switch zone {
	case 1:
		if sys.zone1_count > 0 {
			sys.zone1_count -= 1
			sys.dead_count += 1
			sys.timer1 = RESPAWN_TIME
		}
	case 2:
		if sys.zone2_count > 0 {
			sys.zone2_count -= 1
			sys.dead_count += 1
			sys.timer2 = RESPAWN_TIME
		}
	}
}

tick_respawn :: proc(sys: ^Respawn_System) {
	if sys.timer1 > 0 do sys.timer1 -= 1
	if sys.timer2 > 0 do sys.timer2 -= 1
}

spawn_zone :: proc(sys: ^Respawn_System, zone: int) -> bool {
	switch zone {
	case 1:
		if sys.timer1 == 0 && sys.dead_count > 0 && sys.zone1_count < ZONE1_CAP {
			sys.zone1_count += 1
			sys.dead_count -= 1
			return true
		}
	case 2:
		if sys.timer2 == 0 && sys.dead_count > 0 && sys.zone2_count < ZONE2_CAP {
			sys.zone2_count += 1
			sys.dead_count -= 1
			return true
		}
	}
	return false
}
