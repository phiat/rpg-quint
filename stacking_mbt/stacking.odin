package stacking_mbt

// Item-stacking implementation matching the stacking.qnt spec.
// State vars: qty_sword, qty_shield, qty_potion.
// Invariant: total quantity never exceeds max_total.

MAX_TOTAL :: 10

Stacks :: struct {
	qty_sword:  int,
	qty_shield: int,
	qty_potion: int,
}

total :: proc(s: ^Stacks) -> int {
	return s.qty_sword + s.qty_shield + s.qty_potion
}

add_sword :: proc(s: ^Stacks) -> bool {
	if total(s) >= MAX_TOTAL do return false
	s.qty_sword += 1
	return true
}

add_shield :: proc(s: ^Stacks) -> bool {
	if total(s) >= MAX_TOTAL do return false
	s.qty_shield += 1
	return true
}

add_potion :: proc(s: ^Stacks) -> bool {
	if total(s) >= MAX_TOTAL do return false
	s.qty_potion += 1
	return true
}

remove_sword :: proc(s: ^Stacks) -> bool {
	if s.qty_sword <= 0 do return false
	s.qty_sword -= 1
	return true
}

remove_shield :: proc(s: ^Stacks) -> bool {
	if s.qty_shield <= 0 do return false
	s.qty_shield -= 1
	return true
}

remove_potion :: proc(s: ^Stacks) -> bool {
	if s.qty_potion <= 0 do return false
	s.qty_potion -= 1
	return true
}
