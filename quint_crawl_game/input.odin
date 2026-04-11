package quint_crawl_game

import qc "../quint_crawl"
import rl "vendor:raylib"
import "core:fmt"

handle_title_input :: proc(app: ^App_State) {
	if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
		qc.init_game(&app.game)
		clear(&app.messages)
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
		add_message(app, fmt.aprintf("Entered %s", zone), TEXT_BRIGHT)
	}

	// Enter combat
	if rl.IsKeyPressed(.E) {
		if qc.enter_combat(g) {
			tier := qc.zone_level_req(g.pos_x, g.pos_y) - 1
			add_message(app, fmt.aprintf("A %s appears!", ENEMY_NAMES[tier]), BAR_HP_FG)
			app.screen = .Combat
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

	// Equip sword
	if rl.IsKeyPressed(.Q) {
		if qc.equip_sword(g) {
			add_message(app, "Equipped sword. ATK +5!", {100, 200, 255, 255})
		}
	}

	check_screen_transitions(app)
}

handle_combat_input :: proc(app: ^App_State) {
	g := &app.game

	// Attack
	if rl.IsKeyPressed(.A) || rl.IsKeyPressed(.SPACE) {
		old_enemy_hp := g.enemy_hp
		old_hp := g.hp
		old_level := g.level
		if qc.combat_attack(g) {
			dmg_dealt := old_enemy_hp - g.enemy_hp
			add_message(app, fmt.aprintf("You deal %d damage!", dmg_dealt), {255, 200, 100, 255})

			if g.enemy_hp <= 0 {
				add_message(app, "Enemy defeated!", {100, 255, 100, 255})
				tier := qc.zone_level_req(g.pos_x, g.pos_y) - 1
				add_message(app, fmt.aprintf("+%d XP, +%d Gold", qc.ZONE_XP_REWARD[tier], qc.ZONE_GOLD_REWARD[tier]), TEXT_GOLD)
				if g.level > old_level {
					add_message(app, fmt.aprintf("LEVEL UP! Now level %d!", g.level), {255, 255, 100, 255})
				}
			} else {
				dmg_taken := old_hp - g.hp
				if dmg_taken > 0 {
					add_message(app, fmt.aprintf("Enemy hits you for %d!", dmg_taken), BAR_HP_FG)
				}
				app.shake_timer = 0.2
				app.flash_color = {255, 50, 50, 80}
				app.flash_timer = 0.15
			}
		}
	}

	// Potion
	if rl.IsKeyPressed(.P) {
		old_hp := g.hp
		if qc.combat_potion(g) {
			healed := g.hp - old_hp
			add_message(app, fmt.aprintf("Used potion. Healed %d HP!", healed), {100, 220, 100, 255})
		}
	}

	// Flee
	if rl.IsKeyPressed(.F) || rl.IsKeyPressed(.ESCAPE) {
		old_hp := g.hp
		if qc.flee_combat(g) {
			dmg := old_hp - g.hp
			if dmg > 0 {
				add_message(app, fmt.aprintf("Fled! Took %d damage escaping.", dmg), {255, 180, 100, 255})
			} else {
				add_message(app, "Fled from battle!", {255, 180, 100, 255})
			}
		}
	}

	check_screen_transitions(app)
}

handle_endscreen_input :: proc(app: ^App_State) {
	if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
		qc.init_game(&app.game)
		clear(&app.messages)
		app.screen = .Map
		add_message(app, "A new adventure begins...", TEXT_BRIGHT)
	}
}
