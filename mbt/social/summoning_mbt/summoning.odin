package summoning_mbt

Summon_Slot :: struct {
	active: bool,
	hp:     int,
	dur:    int,
}

Summoning_System :: struct {
	slots:        [3]Summon_Slot,
	active_count: int,
}

summon_slot :: proc(ss: ^Summoning_System, idx: int, hp: int, dur: int) -> bool {
	if ss.slots[idx].active do return false
	ss.slots[idx] = {true, hp, dur}
	ss.active_count += 1
	return true
}

tick_duration :: proc(ss: ^Summoning_System) {
	count := 0
	for i in 0 ..< 3 {
		slot := &ss.slots[i]
		if slot.active {
			slot.dur -= 1
			if slot.dur <= 0 {
				slot.active = false
				slot.hp = 0
				slot.dur = 0
			} else {
				count += 1
			}
		}
	}
	ss.active_count = count
}

dismiss_slot :: proc(ss: ^Summoning_System, idx: int) -> bool {
	if !ss.slots[idx].active do return false
	ss.slots[idx] = {}
	ss.active_count -= 1
	return true
}
