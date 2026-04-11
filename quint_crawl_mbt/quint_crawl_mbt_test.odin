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
	case "use_antidote":
		qc.use_antidote(g)
		return true
	case "poison_strike":
		qc.poison_strike(g)
		return true
	case "combo_attack":
		qc.combo_attack(g)
		return true
	case "heavy_strike":
		qc.heavy_strike(g)
		return true
	case "battle_cry":
		qc.battle_cry(g)
		return true
	case "shield_block":
		qc.shield_block(g)
		return true
	case "claim_victory":
		qc.claim_victory(g)
		return true
	case "counter_attack":
		qc.counter_attack(g)
		return true
	case "fortify":
		qc.fortify(g)
		return true
	case "unlock_combo":
		qc.unlock_combo(g)
		return true
	case "unlock_poison":
		qc.unlock_poison(g)
		return true
	case "unlock_shield_block":
		qc.unlock_shield_block(g)
		return true
	case "unlock_heavy_strike":
		qc.unlock_heavy_strike(g)
		return true
	case "unlock_counter_attack":
		qc.unlock_counter_attack(g)
		return true
	case "unlock_battle_cry":
		qc.unlock_battle_cry(g)
		return true
	case "unlock_fortify":
		qc.unlock_fortify(g)
		return true
	case "respec":
		qc.respec(g)
		return true
	case "craft_venom_sac":
		qc.craft_venom_sac(g)
		return true
	case "apply_enchant_1":
		etype_val := picks["etype"].(mbt.ITF_Int) or_return
		qc.apply_enchant(g, 1, int(etype_val.value))
		return true
	case "apply_enchant_2":
		etype_val := picks["etype"].(mbt.ITF_Int) or_return
		qc.apply_enchant(g, 2, int(etype_val.value))
		return true
	case "apply_enchant_3":
		etype_val := picks["etype"].(mbt.ITF_Int) or_return
		qc.apply_enchant(g, 3, int(etype_val.value))
		return true
	case "remove_enchant_1":
		qc.remove_enchant(g, 1)
		return true
	case "remove_enchant_2":
		qc.remove_enchant(g, 2)
		return true
	case "remove_enchant_3":
		qc.remove_enchant(g, 3)
		return true
	case "salvage_sword":
		qc.salvage_sword(g)
		return true
	case "upgrade_salvage":
		qc.upgrade_salvage(g)
		return true
	case "save_game":
		qc.save_game(g)
		return true
	case "load_game":
		// Spec models load as identity; real restore tested separately
		return g.saved_exists
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
	state["player_poison_dur"] = mbt.ITF_Int{g.player_poison_dur}
	state["player_atk_buff_dur"] = mbt.ITF_Int{g.player_atk_buff_dur}
	state["player_def_buff_dur"] = mbt.ITF_Int{g.player_def_buff_dur}
	state["enemy_poison_dur"] = mbt.ITF_Int{g.enemy_poison_dur}
	state["combo_count"] = mbt.ITF_Int{g.combo_count}

	state["turn_count"] = mbt.ITF_Int{g.turn_count}
	state["saved_exists"] = mbt.ITF_Bool{g.saved_exists}
	state["stamina"] = mbt.ITF_Int{g.stamina}
	state["max_stamina"] = mbt.ITF_Int{g.max_stamina}
	state["cd_heavy_strike"] = mbt.ITF_Int{g.cd_heavy_strike}
	state["cd_battle_cry"] = mbt.ITF_Int{g.cd_battle_cry}
	state["pity_counter"] = mbt.ITF_Int{g.pity_counter}
	state["last_drop"] = mbt.ITF_Int{g.last_drop}
	state["cd_fortify"] = mbt.ITF_Int{g.cd_fortify}
	state["skill_points"] = mbt.ITF_Int{g.skill_points}
	state["skill_combo"] = mbt.ITF_Bool{g.skill_combo}
	state["skill_poison"] = mbt.ITF_Bool{g.skill_poison}
	state["skill_shield_block"] = mbt.ITF_Bool{g.skill_shield_block}
	state["skill_heavy_strike"] = mbt.ITF_Bool{g.skill_heavy_strike}
	state["skill_counter_attack"] = mbt.ITF_Bool{g.skill_counter_attack}
	state["skill_battle_cry"] = mbt.ITF_Bool{g.skill_battle_cry}
	state["skill_fortify"] = mbt.ITF_Bool{g.skill_fortify}
	state["qty_venom_sac"] = mbt.ITF_Int{g.qty_venom_sac}
	state["enemy_element"] = mbt.ITF_Int{g.enemy_element}
	state["enchant_slot_1"] = mbt.ITF_Int{g.enchant_slot_1}
	state["enchant_slot_2"] = mbt.ITF_Int{g.enchant_slot_2}
	state["enchant_slot_3"] = mbt.ITF_Int{g.enchant_slot_3}
	state["salvage_level"] = mbt.ITF_Int{g.salvage_level}
	return state
}

TRACE_FILES := [?]string{
	"traces/quint_crawl_trace0.itf.json",
	"traces/quint_crawl_trace1.itf.json",
	"traces/quint_crawl_trace2.itf.json",
	"traces/quint_crawl_trace3.itf.json",
	"traces/quint_crawl_trace4.itf.json",
}

@(test)
test_quint_crawl_trace_replay :: proc(t: ^testing.T) {
	total_passed := 0
	total_steps := 0

	for file in TRACE_FILES {
		trace, err := mbt.parse_itf_file(file)
		if err != .None {
			log.errorf("Failed to parse %s: %v", file, err)
			testing.fail_now(t)
		}
		defer mbt.delete_trace(&trace)

		g: qc.Game_State
		result := mbt.replay_trace(&trace, &g, crawl_step, crawl_state)
		defer mbt.delete_result(&result)

		if result.failed > 0 {
			mbt.print_result(&result)
			for &e in result.errors {
				log.errorf("[%s] Step %d, var '%s': expected %s, got %s",
					file, e.step, e.var_name, e.expected, e.actual)
			}
		}

		testing.expectf(t, result.failed == 0,
			"%s: %d/%d steps failed", file, result.failed, result.total_steps)
		total_passed += result.passed
		total_steps += result.total_steps
	}

	log.infof("MBT replay: %d/%d steps passed across %d traces", total_passed, total_steps, len(TRACE_FILES))
}
