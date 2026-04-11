package rpg_mbt

// RPG Character implementation — same logic as weba-fool/src/rpg.odin
// Copied here so it's part of the test package.

Character :: struct {
	name:    string,
	hp:      int,
	attack:  int,
	inv:     [dynamic]string,
	inv_cap: int,
}

take_damage :: proc(c: ^Character, dmg: int) {
	c.hp -= dmg
}

is_alive :: proc(c: Character) -> bool {
	return c.hp > 0
}

add_item :: proc(c: ^Character, item: string) -> bool {
	if len(c.inv) >= c.inv_cap {
		return false
	}
	append(&c.inv, item)
	return true
}
