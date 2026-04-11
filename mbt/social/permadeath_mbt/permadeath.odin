package permadeath_mbt

Permadeath_System :: struct {
	hp:               int,
	alive:            bool,
	generation:       int,
	legacy_gold:      int,
	legacy_bonus_atk: int,
	gold:             int,
	total_deaths:     int,
}

permadeath_init :: proc(p: ^Permadeath_System) {
	p.hp = 100
	p.alive = true
	p.generation = 1
	p.legacy_gold = 0
	p.legacy_bonus_atk = 0
	p.gold = 0
	p.total_deaths = 0
}

take_damage :: proc(p: ^Permadeath_System, amount: int) {
	if amount <= 0 || !p.alive do return
	new_hp := p.hp - amount
	if new_hp <= 0 {
		p.hp = 0
		p.alive = false
	} else {
		p.hp = new_hp
	}
}

die_and_inherit :: proc(p: ^Permadeath_System) -> bool {
	if p.alive do return false
	new_gen := p.generation + 1
	new_bonus := new_gen if new_gen < 5 else 5
	p.generation = new_gen
	p.gold = p.legacy_gold / 2
	p.legacy_bonus_atk = new_bonus
	p.hp = 50
	p.alive = true
	p.total_deaths += 1
	return true
}

earn_gold :: proc(p: ^Permadeath_System, amount: int) {
	if amount <= 0 || !p.alive do return
	p.gold += amount
}

deposit_legacy :: proc(p: ^Permadeath_System, amount: int) -> bool {
	if amount <= 0 || p.gold < amount || !p.alive do return false
	p.legacy_gold += amount
	p.gold -= amount
	return true
}
