package quint_crawl_game

import qc "../quint_crawl"
import rl "vendor:raylib"
import "core:fmt"

handle_title_input :: proc(app: ^App_State) {
	if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
		qc.init_game(&app.game)
		clear_messages(app)
		app.prev_level = app.game.level
		app.screen = .Map
		add_message(app, "Welcome to Quint Crawl! Explore the world.", TEXT_BRIGHT)
	}
}

handle_map_input :: proc(app: ^App_State) {
	g := &app.game

	// Movement
	moved := false
	if rl.IsKeyPressed(.W) || rl.IsKeyPressed(.UP) {
		moved = qc.move(g, 0, -1)
	} else if rl.IsKeyPressed(.S) || rl.IsKeyPressed(.DOWN) {
		moved = qc.move(g, 0, 1)
	} else if rl.IsKeyPressed(.A) || rl.IsKeyPressed(.LEFT) {
		moved = qc.move(g, -1, 0)
	} else if rl.IsKeyPressed(.D) || rl.IsKeyPressed(.RIGHT) {
		moved = qc.move(g, 1, 0)
	}

	if moved {
		zone := qc.zone_name(g.pos_x, g.pos_y)
		weather := qc.zone_weather(g.pos_x, g.pos_y, g.turn_count)
		if weather == 3 {
			add_message(app, fmt.tprintf("Entered %s — Storm! Took %d damage.", zone, qc.STORM_MOVE_DMG), {255, 150, 50, 255})
		} else {
			add_message(app, fmt.tprintf("Entered %s", zone), TEXT_BRIGHT)
		}
	}

	// Enter combat
	if rl.IsKeyPressed(.E) {
		if qc.enter_combat(g) {
			tier := qc.zone_level(g.pos_x, g.pos_y) - 1
			add_message(app, fmt.tprintf("A %s appears!", ENEMY_NAMES[tier]), BAR_HP_FG)
		} else if !g.in_combat && g.last_kill_turn != 0 && g.turn_count - g.last_kill_turn < qc.RESPAWN_TURNS {
			remaining := qc.RESPAWN_TURNS - (g.turn_count - g.last_kill_turn)
			add_message(app, fmt.tprintf("No enemies yet... %d turns until respawn.", remaining), TEXT_DIM)
		}
	}

	// Rest
	if rl.IsKeyPressed(.R) {
		if qc.rest_at_village(g) {
			add_message(app, "Rested at the inn. HP fully restored!", {100, 220, 100, 255})
		}
	}

	// Buy potion
	if rl.IsKeyPressed(.B) {
		if qc.buy_potion(g) {
			add_message(app, fmt.tprintf("Bought a potion for %d gold.", qc.POTION_COST), TEXT_GOLD)
		}
	}

	// Gather wood
	if rl.IsKeyPressed(.G) {
		if qc.gather_wood(g) {
			add_message(app, "Gathered wood.", {139, 119, 101, 255})
		}
	}

	// Mine iron
	if rl.IsKeyPressed(.M) {
		if qc.mine_iron(g) {
			add_message(app, "Mined iron ore.", {180, 180, 200, 255})
		}
	}

	// Craft sword
	if rl.IsKeyPressed(.C) {
		if qc.craft_sword(g) {
			add_message(app, "Crafted a sword! (1 wood + 2 iron)", {100, 200, 255, 255})
		}
	}

	// Repair sword
	if rl.IsKeyPressed(.T) {
		if qc.repair_sword(g) {
			add_message(app, fmt.tprintf("Repaired sword for %d gold.", qc.REPAIR_COST), TEXT_GOLD)
		}
	}

	// Equip sword
	if rl.IsKeyPressed(.Q) {
		if qc.equip_sword(g) {
			add_message(app, "Equipped sword. ATK +5!", {100, 200, 255, 255})
		}
	}

	// Fast travel (cycles to next waypoint)
	if rl.IsKeyPressed(.J) {
		// Find next waypoint after current position
		found := false
		for i in 1 ..< qc.WORLD_SIZE * qc.WORLD_SIZE {
			idx := (g.pos_x * qc.WORLD_SIZE + g.pos_y + i) % (qc.WORLD_SIZE * qc.WORLD_SIZE)
			wx := idx / qc.WORLD_SIZE
			wy := idx % qc.WORLD_SIZE
			if qc.fast_travel(g, wx, wy) {
				zone := qc.zone_name(g.pos_x, g.pos_y)
				add_message(app, fmt.tprintf("Fast traveled to %s!", zone), {100, 200, 255, 255})
				found = true
				break
			}
		}
		if !found {
			add_message(app, "No available waypoints.", TEXT_DIM)
		}
	}

	// Claim victory
	if rl.IsKeyPressed(.L) {
		if qc.claim_victory(g) {
			add_message(app, "Victory! You conquered the Castle!", TEXT_GOLD)
		}
	}

	// Save game
	if rl.IsKeyPressed(.F5) {
		if qc.save_game(g) {
			add_message(app, "Game saved!", {100, 220, 255, 255})
		}
	}

	// Load game
	if rl.IsKeyPressed(.F9) {
		if qc.load_game(g) {
			add_message(app, "Game loaded!", {100, 220, 255, 255})
		}
	}

	// Respec skills (at village)
	if rl.IsKeyPressed(.U) {
		if qc.respec(g) {
			add_message(app, fmt.tprintf("Skills reset! %d points refunded. (%d gold)", g.skill_points, qc.RESPEC_COST), TEXT_GOLD)
		}
	}

	// Salvage sword (at village)
	if rl.IsKeyPressed(.BACKSLASH) {
		if qc.salvage_sword(g) {
			wood := qc.salvage_wood_yield(g.salvage_level)
			iron := qc.salvage_iron_yield(g.salvage_level)
			add_message(app, fmt.tprintf("Salvaged sword! +%d wood, +%d iron", wood, iron), {180, 140, 100, 255})
		}
	}

	// Upgrade salvage (at village)
	if rl.IsKeyPressed(.EQUAL) {
		if qc.upgrade_salvage(g) {
			add_message(app, fmt.tprintf("Salvage upgraded to Lv%d! (%dg)", g.salvage_level, qc.UPGRADE_SALVAGE_COST), TEXT_GOLD)
		}
	}

	// Craft venom sac (at village)
	if rl.IsKeyPressed(.O) {
		if qc.craft_venom_sac(g) {
			add_message(app, fmt.tprintf("Crafted Venom Sac! (%d iron)", qc.CRAFT_VENOM_IRON_COST), {100, 220, 50, 255})
		}
	}

	// Enchant sword (at village, cycles through enchant types on slot)
	if rl.IsKeyPressed(.EIGHT) && g.has_sword && qc.zone_has_services(g.pos_x, g.pos_y) {
		// Cycle enchant type on slot 1: fire(1)→ice(2)→vampiric(3)→lightning(4)
		for etype in 1..=4 {
			if qc.apply_enchant(g, 1, etype) {
				ench_names := [5]string{"", "Fire", "Ice", "Vampiric", "Lightning"}
				add_message(app, fmt.tprintf("Enchanted slot 1: %s! (%dg)", ench_names[etype], qc.ENCHANT_COST), {255, 150, 50, 255})
				break
			}
		}
	}
	if rl.IsKeyPressed(.NINE) && g.has_sword && qc.zone_has_services(g.pos_x, g.pos_y) {
		for etype in 1..=4 {
			if qc.apply_enchant(g, 2, etype) {
				ench_names := [5]string{"", "Fire", "Ice", "Vampiric", "Lightning"}
				add_message(app, fmt.tprintf("Enchanted slot 2: %s! (%dg)", ench_names[etype], qc.ENCHANT_COST), {255, 150, 50, 255})
				break
			}
		}
	}
	if rl.IsKeyPressed(.ZERO) && g.has_sword && qc.zone_has_services(g.pos_x, g.pos_y) {
		for etype in 1..=4 {
			if qc.apply_enchant(g, 3, etype) {
				ench_names := [5]string{"", "Fire", "Ice", "Vampiric", "Lightning"}
				add_message(app, fmt.tprintf("Enchanted slot 3: %s! (%dg)", ench_names[etype], qc.ENCHANT_COST), {255, 150, 50, 255})
				break
			}
		}
	}

	// Skill unlocks (when skill points available)
	if g.skill_points > 0 {
		if rl.IsKeyPressed(.ONE) {
			if qc.unlock_combo(g) {
				add_message(app, "Learned: Combo Attack! [K]", {255, 220, 50, 255})
			}
		}
		if rl.IsKeyPressed(.TWO) {
			if qc.unlock_poison(g) {
				add_message(app, "Learned: Poison Strike! [V]", {100, 220, 50, 255})
			}
		}
		if rl.IsKeyPressed(.THREE) {
			if qc.unlock_shield_block(g) {
				add_message(app, "Learned: Shield Block! [Z]", {100, 180, 255, 255})
			}
		}
		if rl.IsKeyPressed(.FOUR) {
			if qc.unlock_heavy_strike(g) {
				add_message(app, "Learned: Heavy Strike! [H]", {255, 120, 50, 255})
			}
		}
		if rl.IsKeyPressed(.FIVE) {
			if qc.unlock_counter_attack(g) {
				add_message(app, "Learned: Counter-Attack! [N]", {180, 140, 255, 255})
			}
		}
		if rl.IsKeyPressed(.SIX) {
			if qc.unlock_battle_cry(g) {
				add_message(app, "Learned: Battle Cry! [Y] (2pts)", {255, 200, 100, 255})
			}
		}
		if rl.IsKeyPressed(.SEVEN) {
			if qc.unlock_fortify(g) {
				add_message(app, "Learned: Fortify! [I] (2pts)", {80, 200, 200, 255})
			}
		}
	}

	check_screen_transitions(app)
}

// Helper: handle enemy defeat — show rewards overlay
handle_enemy_defeated :: proc(app: ^App_State, old_level: int) {
	g := &app.game
	leveled := g.level > old_level
	begin_victory_rewards(app,
		qc.zone_xp_reward(g.pos_x, g.pos_y),
		qc.zone_gold_reward(g.pos_x, g.pos_y),
		leveled,
		g.level,
		qc.HP_PER_LEVEL if leveled else 0,
		qc.ATK_PER_LEVEL_UP if leveled else 0,
	)
	if g.last_drop == 1 {
		add_message(app, "Loot: +1 Potion!", {100, 220, 255, 255})
	} else if g.last_drop == 2 {
		add_message(app, "Loot: +1 Venom Sac!", {100, 220, 50, 255})
	}
}

// Helper: handle player taking damage in combat (shake + flash + poison notification)
handle_combat_damage :: proc(app: ^App_State, old_hp: int, old_poison: int, flash_color: rl.Color) {
	g := &app.game
	dmg_taken := old_hp - g.hp
	if dmg_taken > 0 {
		add_message(app, fmt.tprintf("Enemy hits you for %d!", dmg_taken), BAR_HP_FG)
	}
	if old_poison == 0 && g.player_poison_dur > 0 {
		add_message(app, "You've been poisoned!", {100, 220, 50, 255})
	}
	app.shake_timer = 0.2
	app.flash_color = flash_color
	app.flash_timer = 0.15
}

handle_combat_input :: proc(app: ^App_State) {
	g := &app.game

	// While showing victory rewards, only accept dismiss input
	if app.showing_rewards {
		if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
			dismiss_victory_rewards(app)
		}
		return
	}

	// Attack
	if rl.IsKeyPressed(.A) || rl.IsKeyPressed(.SPACE) {
		old_enemy_hp := g.enemy_hp
		old_hp := g.hp
		old_level := g.level
		old_poison := g.player_poison_dur
		if qc.combat_attack(g) {
			dmg_dealt := old_enemy_hp - g.enemy_hp
			add_message(app, fmt.tprintf("You deal %d damage!", dmg_dealt), {255, 200, 100, 255})

			if g.enemy_hp <= 0 {
				handle_enemy_defeated(app, old_level)
			} else {
				handle_combat_damage(app, old_hp, old_poison, {255, 50, 50, 80})
			}
		}
	}

	// Potion
	if rl.IsKeyPressed(.P) {
		old_hp := g.hp
		if qc.combat_potion(g) {
			healed := g.hp - old_hp
			add_message(app, fmt.tprintf("Used potion. Healed %d HP!", healed), {100, 220, 100, 255})
		}
	}

	// Flee
	if rl.IsKeyPressed(.F) || rl.IsKeyPressed(.ESCAPE) {
		old_hp := g.hp
		if qc.flee_combat(g) {
			dmg := old_hp - g.hp
			if dmg > 0 {
				add_message(app, fmt.tprintf("Fled! Took %d damage escaping.", dmg), {255, 180, 100, 255})
			} else {
				add_message(app, "Fled from battle!", {255, 180, 100, 255})
			}
		}
	}

	// Poison strike
	if rl.IsKeyPressed(.V) {
		old_hp := g.hp
		if qc.poison_strike(g) {
			dmg := old_hp - g.hp
			add_message(app, fmt.tprintf("Poison strike! Enemy poisoned for %d turns.", qc.STATUS_DURATION), {100, 220, 50, 255})
			if dmg > 0 {
				add_message(app, fmt.tprintf("Enemy hits you for %d!", dmg), BAR_HP_FG)
				app.shake_timer = 0.15
				app.flash_color = {255, 50, 50, 60}
				app.flash_timer = 0.1
			}
		}
	}

	// Combo attack
	if rl.IsKeyPressed(.K) {
		old_enemy_hp := g.enemy_hp
		old_hp := g.hp
		old_level := g.level
		old_poison := g.player_poison_dur
		combo_num := g.combo_count + 1  // what hit this will be
		if qc.combo_attack(g) {
			dmg_dealt := old_enemy_hp - g.enemy_hp
			combo_names := [3]string{"Slash", "Thrust", "Finisher"}
			name := combo_names[min(combo_num, 3) - 1]
			add_message(app, fmt.tprintf("%s! %d damage! (combo %d/3)", name, dmg_dealt, combo_num), {255, 220, 50, 255})

			if g.enemy_hp <= 0 {
				handle_enemy_defeated(app, old_level)
			} else {
				handle_combat_damage(app, old_hp, old_poison, {255, 220, 50, 80})
			}
		}
	}

	// Use antidote
	if rl.IsKeyPressed(.X) {
		if qc.use_antidote(g) {
			add_message(app, "Used antidote! Poison cured.", {100, 220, 50, 255})
		}
	}

	// Heavy strike
	if rl.IsKeyPressed(.H) {
		old_enemy_hp := g.enemy_hp
		old_hp := g.hp
		old_level := g.level
		old_poison := g.player_poison_dur
		if qc.heavy_strike(g) {
			dmg_dealt := old_enemy_hp - g.enemy_hp
			add_message(app, fmt.tprintf("HEAVY STRIKE! %d damage!", dmg_dealt), {255, 120, 50, 255})

			if g.enemy_hp <= 0 {
				handle_enemy_defeated(app, old_level)
			} else {
				handle_combat_damage(app, old_hp, old_poison, {255, 120, 50, 80})
			}
		}
	}

	// Battle cry
	if rl.IsKeyPressed(.Y) {
		old_hp := g.hp
		old_poison := g.player_poison_dur
		if qc.battle_cry(g) {
			add_message(app, "BATTLE CRY! ATK boosted!", {255, 200, 100, 255})
			if g.hp < old_hp {
				handle_combat_damage(app, old_hp, old_poison, {255, 200, 100, 60})
			}
		}
	}

	// Shield block
	if rl.IsKeyPressed(.Z) {
		old_hp := g.hp
		old_poison := g.player_poison_dur
		if qc.shield_block(g) {
			add_message(app, "SHIELD BLOCK! DEF boosted!", {100, 180, 255, 255})
			if g.hp < old_hp {
				handle_combat_damage(app, old_hp, old_poison, {100, 180, 255, 60})
			}
		}
	}

	// Counter-attack
	if rl.IsKeyPressed(.N) {
		old_enemy_hp := g.enemy_hp
		old_hp := g.hp
		old_level := g.level
		old_poison := g.player_poison_dur
		if qc.counter_attack(g) {
			dmg_dealt := old_enemy_hp - g.enemy_hp
			add_message(app, fmt.tprintf("COUNTER! %d damage + DEF buff!", dmg_dealt), {180, 140, 255, 255})
			if g.enemy_hp <= 0 {
				handle_enemy_defeated(app, old_level)
			} else if g.hp < old_hp {
				handle_combat_damage(app, old_hp, old_poison, {180, 140, 255, 60})
			}
		}
	}

	// Fortify
	if rl.IsKeyPressed(.I) {
		old_hp := g.hp
		old_poison := g.player_poison_dur
		if qc.fortify(g) {
			add_message(app, fmt.tprintf("FORTIFY! Extended DEF buff (%d turns)!", qc.FORTIFY_DURATION), {80, 200, 200, 255})
			if g.hp < old_hp {
				handle_combat_damage(app, old_hp, old_poison, {80, 200, 200, 60})
			}
		}
	}

	check_screen_transitions(app)
}

handle_endscreen_input :: proc(app: ^App_State) {
	if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
		qc.init_game(&app.game)
		clear_messages(app)
		app.prev_level = app.game.level
		app.screen = .Map
		add_message(app, "A new adventure begins...", TEXT_BRIGHT)
	}
}
