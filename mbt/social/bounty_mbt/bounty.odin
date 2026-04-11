package bounty_mbt

// Bounty Board system with 3 slots.
// Each slot has: active status, kills needed, current kills, reward gold.
// The player tracks their gold and which bounty slot (if any) is active.

Bounty_Slot :: struct {
	active:        bool,
	kills_needed:  int,
	current_kills: int,
	reward_gold:   int,
}

Bounty_Board :: struct {
	slots:             [3]Bounty_Slot,
	player_gold:       int,
	active_bounty_idx: int, // 0 = none, 1-3 = slot index
}

// Accept a bounty from the given slot (1-indexed).
// Requires: slot is active, no current bounty.
accept_bounty :: proc(b: ^Bounty_Board, slot: int) {
	idx := slot - 1
	if b.slots[idx].active && b.active_bounty_idx == 0 {
		b.active_bounty_idx = slot
	}
}

// Record a kill toward the active bounty.
// Increments current_kills if < kills_needed.
record_kill :: proc(b: ^Bounty_Board) {
	if b.active_bounty_idx == 0 do return
	idx := b.active_bounty_idx - 1
	if b.slots[idx].current_kills < b.slots[idx].kills_needed {
		b.slots[idx].current_kills += 1
	}
}

// Claim the active bounty reward.
// Requires: current_kills >= kills_needed.
// Deactivates the slot, awards gold, clears active bounty.
claim_bounty :: proc(b: ^Bounty_Board) {
	if b.active_bounty_idx == 0 do return
	idx := b.active_bounty_idx - 1
	if b.slots[idx].current_kills >= b.slots[idx].kills_needed {
		b.player_gold += b.slots[idx].reward_gold
		b.slots[idx].active = false
		b.active_bounty_idx = 0
	}
}

// Abandon the active bounty. No reward, slot stays active.
abandon_bounty :: proc(b: ^Bounty_Board) {
	b.active_bounty_idx = 0
}

// Refresh all 3 slots with new bounty values. Requires no active bounty.
refresh_board :: proc(b: ^Bounty_Board) {
	if b.active_bounty_idx != 0 do return
	b.slots[0] = Bounty_Slot{active = true, kills_needed = 4, current_kills = 0, reward_gold = 60}
	b.slots[1] = Bounty_Slot{active = true, kills_needed = 6, current_kills = 0, reward_gold = 100}
	b.slots[2] = Bounty_Slot{active = true, kills_needed = 3, current_kills = 0, reward_gold = 45}
}
