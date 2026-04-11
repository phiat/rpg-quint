package elemental_mbt

import mbt "../../../quint_mbt"
import "core:testing"
import "core:log"

// Elemental affinity system state
Elemental :: struct {
	player_element: int,
	enemy_element:  int,
	player_hp:      int,
	enemy_hp:       int,
	base_damage:    int,
	in_combat:      bool,
}

// Element cycle: Fire(1) > Ice(2) > Lightning(3) > Earth(4) > Fire(1)
is_strong :: proc(a: int, d: int) -> bool {
	return (a == 1 && d == 2) ||
	       (a == 2 && d == 3) ||
	       (a == 3 && d == 4) ||
	       (a == 4 && d == 1)
}

damage_multiplier :: proc(attacker_elem: int, defender_elem: int) -> int {
	if attacker_elem == 0 || defender_elem == 0 do return 100
	if is_strong(attacker_elem, defender_elem) do return 200
	if is_strong(defender_elem, attacker_elem) do return 50
	return 100
}

effective_damage :: proc(base: int, mult: int) -> int {
	raw := base * mult / 100
	if raw < 1 do return 1
	return raw
}

zone_element :: proc(pos: int) -> int {
	return (pos %% 4) + 1
}

// Step handler: dispatch Quint action names
elemental_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	s := cast(^Elemental)driver

	switch action {
	case "init", "step":
		// Initialize
		s.player_element = 0
		s.enemy_element = 0
		s.player_hp = 100
		s.enemy_hp = 80
		s.base_damage = 10
		s.in_combat = false
		return true

	case "set_player_element":
		e_val, has_e := picks["e"]
		if !has_e do return false
		e, ok := mbt.value_as_int(e_val)
		if !ok do return false
		if e < 0 || e > 4 do return false
		s.player_element = e
		return true

	case "enter_combat":
		if s.in_combat do return false
		pos_val, has_pos := picks["pos"]
		if !has_pos do return false
		pos, ok := mbt.value_as_int(pos_val)
		if !ok do return false
		s.in_combat = true
		s.enemy_element = zone_element(pos)
		s.enemy_hp = 80
		return true

	case "attack":
		if !s.in_combat || s.enemy_hp <= 0 do return false
		mult := damage_multiplier(s.player_element, s.enemy_element)
		dmg := effective_damage(s.base_damage, mult)
		s.enemy_hp = max(0, s.enemy_hp - dmg)
		if s.enemy_hp <= 0 do s.in_combat = false
		return true

	case "enemy_attack":
		if !s.in_combat || s.player_hp <= 0 do return false
		mult := damage_multiplier(s.enemy_element, s.player_element)
		dmg := effective_damage(s.base_damage, mult)
		s.player_hp = max(0, s.player_hp - dmg)
		if s.player_hp <= 0 do s.in_combat = false
		return true

	case:
		return false
	}
}

// State getter: extract state as ITF values for comparison
elemental_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	s := cast(^Elemental)driver
	state := make(map[string]mbt.ITF_Value)

	state["player_element"] = mbt.ITF_Int{s.player_element}
	state["enemy_element"] = mbt.ITF_Int{s.enemy_element}
	state["player_hp"] = mbt.ITF_Int{s.player_hp}
	state["enemy_hp"] = mbt.ITF_Int{s.enemy_hp}
	state["base_damage"] = mbt.ITF_Int{s.base_damage}
	state["in_combat"] = mbt.ITF_Bool{s.in_combat}

	return state
}

@(test)
test_elemental_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/elemental_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	s: Elemental

	result := mbt.replay_trace(&trace, &s, elemental_step, elemental_state)

	if result.failed > 0 {
		mbt.print_result(&result)
		for &e in result.errors {
			log.errorf("Step %d, var '%s': expected %s, got %s",
				e.step, e.var_name, e.expected, e.actual)
		}
	}

	testing.expectf(t, result.failed == 0,
		"MBT replay: %d/%d steps failed", result.failed, result.total_steps)

	log.infof("MBT replay: %d/%d steps passed", result.passed, result.total_steps)
}
