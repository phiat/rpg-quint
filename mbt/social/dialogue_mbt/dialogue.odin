package dialogue_mbt

// Dialogue Tree system with 5 nodes: 0=start, 1-3=branches, 4=end.
// Players enter dialogue, choose a branch (affecting reputation), advance to end, then exit.

Dialogue_System :: struct {
	current_node:      int,
	in_dialogue:       bool,
	choices_made:      int,
	visited_1:         bool,
	visited_2:         bool,
	visited_3:         bool,
	reputation_change: int,
}

dialogue_init :: proc(d: ^Dialogue_System) {
	d.current_node      = 0
	d.in_dialogue       = false
	d.choices_made      = 0
	d.visited_1         = false
	d.visited_2         = false
	d.visited_3         = false
	d.reputation_change = 0
}

dialogue_start :: proc(d: ^Dialogue_System) {
	if !d.in_dialogue {
		d.current_node = 0
		d.in_dialogue  = true
	}
}

dialogue_choose_branch :: proc(d: ^Dialogue_System, branch: int) {
	if !d.in_dialogue || d.current_node != 0 do return
	switch branch {
	case 1:
		d.current_node       = 1
		d.choices_made      += 1
		d.visited_1          = true
		d.reputation_change += 5
	case 2:
		d.current_node       = 2
		d.choices_made      += 1
		d.visited_2          = true
		d.reputation_change -= 5
	case 3:
		d.current_node       = 3
		d.choices_made      += 1
		d.visited_3          = true
		// reputation unchanged
	}
}

dialogue_advance_to_end :: proc(d: ^Dialogue_System) {
	if d.in_dialogue && d.current_node >= 1 && d.current_node <= 3 {
		d.current_node = 4
	}
}

dialogue_end :: proc(d: ^Dialogue_System) {
	if d.in_dialogue && d.current_node == 4 {
		d.current_node = 0
		d.in_dialogue  = false
	}
}
