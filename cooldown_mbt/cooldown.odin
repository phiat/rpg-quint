package cooldown_mbt

// Cooldown constants
FIREBALL_CD :: 3
HEAL_CD     :: 5
SHIELD_CD   :: 2

Cooldown_System :: struct {
	cd_fireball:  int,
	cd_heal:      int,
	cd_shield:    int,
	current_turn: int,
}

// Returns true if fireball was used (cd must be 0), false if on cooldown.
use_fireball :: proc(cs: ^Cooldown_System) -> bool {
	if cs.cd_fireball != 0 do return false
	cs.cd_fireball = FIREBALL_CD
	return true
}

// Returns true if heal was used (cd must be 0), false if on cooldown.
use_heal :: proc(cs: ^Cooldown_System) -> bool {
	if cs.cd_heal != 0 do return false
	cs.cd_heal = HEAL_CD
	return true
}

// Returns true if shield was used (cd must be 0), false if on cooldown.
use_shield :: proc(cs: ^Cooldown_System) -> bool {
	if cs.cd_shield != 0 do return false
	cs.cd_shield = SHIELD_CD
	return true
}

// Decrement all non-zero cooldowns by 1.
tick :: proc(cs: ^Cooldown_System) {
	if cs.cd_fireball > 0 do cs.cd_fireball -= 1
	if cs.cd_heal > 0     do cs.cd_heal -= 1
	if cs.cd_shield > 0   do cs.cd_shield -= 1
}
