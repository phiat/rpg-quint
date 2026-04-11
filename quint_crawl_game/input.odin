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
			tier := qc.zone_level_req(g.pos_x, g.pos_y) - 1
			add_message(app, fmt.tprintf("A %s appears!", ENEMY_NAMES[tier]), BAR_HP_FG)
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
			add_message(app, "Bought a potion for 10 gold.", TEXT_GOLD)
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

	check_screen_transitions(app)
}

// Helper: handle enemy defeat — show rewards overlay
handle_enemy_defeated :: proc(app: ^App_State, old_level: int) {
	g := &app.game
	tier := qc.zone_level_req(g.pos_x, g.pos_y) - 1
	leveled := g.level > old_level
	begin_victory_rewards(app,
		qc.ZONE_XP_REWARD[tier],
		qc.ZONE_GOLD_REWARD[tier],
		leveled,
		g.level,
		20 if leveled else 0,
		3 if leveled else 0,
	)
	if g.last_drop == 1 {
		add_message(app, "Loot: +1 Potion!", {100, 220, 255, 255})
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
