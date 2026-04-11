package quint_crawl_mbt

import qc "../quint_crawl"
import mbt "../quint_mbt"
import "core:testing"
import "core:log"

crawl_step :: proc(driver: rawptr, action: string, picks: map[string]mbt.ITF_Value) -> bool {
	g := cast(^qc.Game_State)driver

	switch action {
	case "init":
		qc.init_game(g)
		return true
	case "move_up":
		qc.move(g, 0, -1)
		return true
	case "move_down":
		qc.move(g, 0, 1)
		return true
	case "move_left":
		qc.move(g, -1, 0)
		return true
	case "move_right":
		qc.move(g, 1, 0)
		return true
	case "enter_combat":
		qc.enter_combat(g)
		return true
	case "combat_attack":
		qc.combat_attack(g)
		return true
	case "combat_potion":
		qc.combat_potion(g)
		return true
	case "flee_combat":
		qc.flee_combat(g)
		return true
	case "rest_at_village":
		qc.rest_at_village(g)
		return true
	case "buy_potion":
		qc.buy_potion(g)
		return true
	case "gather_wood":
		qc.gather_wood(g)
		return true
	case "mine_iron":
		qc.mine_iron(g)
		return true
	case "craft_sword":
		qc.craft_sword(g)
		return true
	case "equip_sword":
		qc.equip_sword(g)
		return true
	case "repair_sword":
		qc.repair_sword(g)
		return true
	case:
		return false
	}
}

crawl_state :: proc(driver: rawptr) -> map[string]mbt.ITF_Value {
	g := cast(^qc.Game_State)driver
	state := make(map[string]mbt.ITF_Value)
	state["hp"] = mbt.ITF_Int{g.hp}
	state["max_hp"] = mbt.ITF_Int{g.max_hp}
	state["base_attack"] = mbt.ITF_Int{g.base_attack}
	state["xp"] = mbt.ITF_Int{g.xp}
	state["level"] = mbt.ITF_Int{g.level}
	state["gold"] = mbt.ITF_Int{g.gold}
	state["pos_x"] = mbt.ITF_Int{g.pos_x}
	state["pos_y"] = mbt.ITF_Int{g.pos_y}
	state["qty_potion"] = mbt.ITF_Int{g.qty_potion}
	state["qty_wood"] = mbt.ITF_Int{g.qty_wood}
	state["qty_iron"] = mbt.ITF_Int{g.qty_iron}
	state["qty_sword"] = mbt.ITF_Int{g.qty_sword}
	state["has_sword"] = mbt.ITF_Bool{g.has_sword}
	state["in_combat"] = mbt.ITF_Bool{g.in_combat}
	state["enemy_hp"] = mbt.ITF_Int{g.enemy_hp}
	state["enemy_attack"] = mbt.ITF_Int{g.enemy_attack}
	state["game_won"] = mbt.ITF_Bool{g.game_won}
	state["sword_dur"] = mbt.ITF_Int{g.sword_dur}
	state["sword_max_dur"] = mbt.ITF_Int{g.sword_max_dur}
	return state
}

@(test)
test_quint_crawl_trace_replay :: proc(t: ^testing.T) {
	trace, err := mbt.parse_itf_file("traces/quint_crawl_trace.itf.json")
	if err != .None {
		log.errorf("Failed to parse ITF trace: %v", err)
		testing.fail_now(t)
	}

	g: qc.Game_State
	result := mbt.replay_trace(&trace, &g, crawl_step, crawl_state)

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
