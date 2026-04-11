package companion_mbt

Companion_System :: struct {
	player_hp:       int,
	companion_hp:    int,
	companion_max_hp: int,
	companion_alive: bool,
	loyalty:         int,
	companion_type:  int,
	in_combat:       bool,
	enemy_hp:        int,
	enemy_attack:    int,
	turn_count:      int,
}

LOYALTY_GAIN :: 5
LOYALTY_LOSS :: 10
COMPANION_REVIVE_COST :: 20
WOLF_BONUS :: 3
HAWK_DODGE :: 1
TURTLE_ABSORB :: 2

companion_init :: proc(cs: ^Companion_System) {
	cs.player_hp = 50
	cs.companion_hp = 0
	cs.companion_max_hp = 30
	cs.companion_alive = false
	cs.loyalty = 0
	cs.companion_type = 0
	cs.in_combat = false
	cs.enemy_hp = 0
	cs.enemy_attack = 5
	cs.turn_count = 0
}

adopt_companion :: proc(cs: ^Companion_System, ctype: int) -> bool {
	if cs.companion_type != 0 do return false
	if ctype < 1 || ctype > 3 do return false
	cs.companion_type = ctype
	cs.companion_alive = true
	cs.companion_hp = 30
	cs.companion_max_hp = 30
	cs.loyalty = 50
	return true
}

feed_companion :: proc(cs: ^Companion_System) -> bool {
	if !cs.companion_alive do return false
	cs.loyalty = min(cs.loyalty + LOYALTY_GAIN, 100)
	return true
}

enter_combat :: proc(cs: ^Companion_System) -> bool {
	if cs.in_combat do return false
	if !cs.companion_alive do return false
	cs.in_combat = true
	cs.enemy_hp = 20
	cs.enemy_attack = 5
	cs.turn_count = 0
	return true
}

attack :: proc(cs: ^Companion_System) -> bool {
	if !cs.in_combat do return false
	if cs.enemy_hp <= 0 do return false
	if cs.player_hp <= 0 do return false

	player_damage := 10
	if cs.companion_alive && cs.companion_type == 1 {
		player_damage += WOLF_BONUS
	}

	raw_enemy_dmg := cs.enemy_attack
	hawk_reduction := 0
	if cs.companion_alive && cs.companion_type == 2 {
		hawk_reduction = HAWK_DODGE
	}
	turtle_reduction := 0
	if cs.companion_alive && cs.companion_type == 3 {
		turtle_reduction = TURTLE_ABSORB
	}
	damage_to_player := raw_enemy_dmg - hawk_reduction - turtle_reduction

	damage_to_companion := 0
	if cs.companion_alive && cs.companion_type == 3 {
		damage_to_companion = TURTLE_ABSORB
	}

	new_companion_hp := cs.companion_hp - damage_to_companion
	if new_companion_hp <= 0 {
		new_companion_hp = 0
	}

	companion_dies := cs.companion_alive && new_companion_hp == 0 && damage_to_companion > 0

	new_enemy_hp := cs.enemy_hp - player_damage
	if new_enemy_hp <= 0 {
		new_enemy_hp = 0
	}

	cs.enemy_hp = new_enemy_hp
	new_player_hp := cs.player_hp - damage_to_player
	if new_player_hp <= 0 {
		new_player_hp = 0
	}
	cs.player_hp = new_player_hp
	cs.companion_hp = new_companion_hp

	if companion_dies {
		cs.companion_alive = false
		cs.loyalty = max(cs.loyalty - LOYALTY_LOSS, 0)
	}

	if new_enemy_hp == 0 {
		cs.in_combat = false
	}

	cs.turn_count += 1
	return true
}

rest :: proc(cs: ^Companion_System) -> bool {
	if cs.in_combat do return false
	if !cs.companion_alive do return false
	cs.player_hp = 50
	cs.companion_hp = cs.companion_max_hp
	cs.loyalty = min(cs.loyalty + LOYALTY_GAIN, 100)
	return true
}

revive_companion :: proc(cs: ^Companion_System) -> bool {
	if cs.companion_alive do return false
	if cs.companion_type <= 0 do return false
	if cs.loyalty < COMPANION_REVIVE_COST do return false
	cs.companion_alive = true
	cs.companion_hp = cs.companion_max_hp / 2
	cs.loyalty -= COMPANION_REVIVE_COST
	return true
}
