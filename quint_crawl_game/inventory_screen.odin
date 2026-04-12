package quint_crawl_game

import qc "../quint_crawl"
import rl "vendor:raylib"
import "core:fmt"

INV_PANEL_W :: 760
INV_PANEL_H :: 680
INV_BG      :: rl.Color{20, 22, 38, 240}
INV_BORDER  :: rl.Color{120, 140, 200, 255}
INV_HEADER  :: rl.Color{255, 220, 120, 255}

draw_inventory_overlay :: proc(app: ^App_State) {
	g := &app.game

	// Dim background
	rl.DrawRectangle(0, 0, WINDOW_W, WINDOW_H, {0, 0, 0, 160})

	px := i32((WINDOW_W - INV_PANEL_W) / 2)
	py := i32((WINDOW_H - INV_PANEL_H) / 2)
	rl.DrawRectangle(px, py, INV_PANEL_W, INV_PANEL_H, INV_BG)
	rl.DrawRectangleLines(px, py, INV_PANEL_W, INV_PANEL_H, INV_BORDER)

	// Header
	rl.DrawText("INVENTORY", px + 24, py + 18, 28, INV_HEADER)
	used := qc.total_items(g)
	cap := qc.MAX_INVENTORY
	usage_color: rl.Color = TEXT_BRIGHT if used < cap else BAR_HP_FG
	rl.DrawText(fmt.ctprintf("%d / %d", used, cap), px + INV_PANEL_W - 120, py + 24, 20, usage_color)
	rl.DrawLine(px + 20, py + 56, px + INV_PANEL_W - 20, py + 56, INV_BORDER)

	col1_x := px + 30
	col2_x := px + 290
	col3_x := px + 530
	body_y := py + 78

	// --- Column 1: Consumables ---
	y := body_y
	rl.DrawText("CONSUMABLES", col1_x, y, 16, INV_HEADER)
	y += 24
	draw_inv_line(col1_x, &y, "[B] Potion",      g.qty_potion,     TEXT_BRIGHT)
	draw_inv_line(col1_x, &y, "[F] Bomb",        g.qty_bomb,       {255, 150, 80, 255})
	draw_inv_line(col1_x, &y, "[/] Smoke",       g.qty_smoke,      {180, 200, 220, 255})
	draw_inv_line(col1_x, &y, "['] Ration",      g.qty_ration,     {200, 220, 140, 255})
	draw_inv_line(col1_x, &y, "    Venom Sac",   g.qty_venom_sac,  {100, 220, 50, 255})
	draw_inv_line(col1_x, &y, "[INS] Holy Water",g.qty_holy_water, {220, 240, 255, 255})
	draw_inv_line(col1_x, &y, "    Fire Scroll", g.qty_scroll_fire,{255, 120, 60, 255})
	draw_inv_line(col1_x, &y, "    Battery",     g.qty_battery,    {220, 220, 255, 255})

	// --- Column 2: Resources ---
	y = body_y
	rl.DrawText("RESOURCES", col2_x, y, 16, INV_HEADER)
	y += 24
	draw_inv_line(col2_x, &y, "Wood",      g.qty_wood,      {180, 140, 80, 255})
	draw_inv_line(col2_x, &y, "Iron",      g.qty_iron,      {180, 180, 200, 255})
	draw_inv_line(col2_x, &y, "Holy Dust", g.qty_holy_dust, {240, 240, 200, 255})
	draw_inv_line(col2_x, &y, "Pelt",      g.qty_pelt,      {160, 120, 80, 255})
	draw_inv_line(col2_x, &y, "Core",      g.qty_core,      {200, 200, 240, 255})
	draw_inv_line(col2_x, &y, "Essence",   g.qty_essence,   {200, 240, 200, 255})
	draw_inv_line(col2_x, &y, "Coin",      g.qty_coin,      TEXT_GOLD)
	draw_inv_line(col2_x, &y, "Ichor",     g.qty_ichor,     {140, 200, 140, 255})

	// --- Column 3: Gear ---
	y = body_y
	rl.DrawText("GEAR", col3_x, y, 16, INV_HEADER)
	y += 24
	if g.has_sword {
		name := sword_rarity_name(g.sword_rarity)
		col := rarity_text_color(g.sword_rarity) if g.sword_rarity > 0 else TEXT_BRIGHT
		rl.DrawText(fmt.ctprintf("%s %d/%d", name, g.sword_dur, g.sword_max_dur), col3_x, y, 14, col)
	} else if g.weapon_type == 1 {
		rl.DrawText("Pistol", col3_x, y, 14, {220, 180, 120, 255})
	} else if g.weapon_type == 2 {
		rl.DrawText("Staff", col3_x, y, 14, {180, 140, 220, 255})
	} else if g.weapon_type == 3 {
		rl.DrawText("Dagger", col3_x, y, 14, {200, 200, 220, 255})
	} else {
		rl.DrawText("No weapon", col3_x, y, 14, TEXT_DIM)
	}
	y += 20
	if g.qty_sword > 0 {
		if g.pending_sword_rarity > 0 {
			rl.DrawText(fmt.ctprintf("Spare %s (pending) x%d", sword_rarity_name(g.pending_sword_rarity), g.qty_sword), col3_x, y, 13, rarity_text_color(g.pending_sword_rarity))
		} else {
			rl.DrawText(fmt.ctprintf("Spare Sword x%d", g.qty_sword), col3_x, y, 13, TEXT_BRIGHT)
		}
		y += 18
	}
	// Enchants
	slots := [3]int{g.enchant_slot_1, g.enchant_slot_2, g.enchant_slot_3}
	for i in 0..<3 {
		if slots[i] > 0 {
			rl.DrawText(fmt.ctprintf("  E%d: %s", i + 1, ENCH_NAMES[slots[i]]), col3_x, y, 12, ENCH_COLORS[slots[i]])
			y += 16
		}
	}
	if g.has_shield {
		rl.DrawText(fmt.ctprintf("Shield %d/%d", g.shield_dur, qc.SHIELD_MAX_DUR), col3_x, y, 14, {180, 200, 255, 255})
	} else {
		rl.DrawText("No shield", col3_x, y, 14, TEXT_DIM)
	}
	y += 20
	if g.has_armor {
		rl.DrawText(fmt.ctprintf("Armor %d/%d", g.armor_dur, qc.ARMOR_MAX_DUR), col3_x, y, 14, {200, 180, 140, 255})
	} else {
		rl.DrawText("No armor", col3_x, y, 14, TEXT_DIM)
	}
	y += 20
	if g.trinket == 1 {
		rl.DrawText(fmt.ctprintf("Vitality Trinket (+%d HP)", qc.TRINKET_VITALITY_HP), col3_x, y, 14, {220, 140, 220, 255})
	} else {
		rl.DrawText("No trinket", col3_x, y, 14, TEXT_DIM)
	}
	y += 20

	// Trophies
	trophies := qc.unique_count(g.unique_drops_mask)
	rl.DrawText(fmt.ctprintf("Trophies: %d/5", trophies), col3_x, y, 14, INV_HEADER)
	y += 18
	for i in 0..<5 {
		if qc.has_unique(g.unique_drops_mask, i) {
			rl.DrawText(fmt.ctprintf("  * %s", UNIQUE_DROP_NAMES[i]), col3_x, y, 12, {255, 220, 120, 255})
			y += 15
		}
	}

	// Footer: gold + companion + hint
	footer_y := py + INV_PANEL_H - 60
	rl.DrawLine(px + 20, footer_y - 10, px + INV_PANEL_W - 20, footer_y - 10, INV_BORDER)
	rl.DrawText(fmt.ctprintf("Gold: %d", g.gold), col1_x, footer_y, 16, TEXT_GOLD)
	if g.comp_active {
		rl.DrawText(fmt.ctprintf("Companion: T%d R%d  Loyalty %d", g.comp_trait, g.comp_rarity, g.comp_loyalty), col2_x, footer_y, 14, {180, 220, 180, 255})
	} else {
		rl.DrawText("No companion", col2_x, footer_y, 14, TEXT_DIM)
	}
	rl.DrawText("[I] / [ESC] close", col3_x, footer_y, 14, TEXT_DIM)
}

draw_inv_line :: proc(x: i32, y: ^i32, label: cstring, qty: int, color: rl.Color) {
	dim: rl.Color = color if qty > 0 else TEXT_DIM
	rl.DrawText(label, x, y^, 14, dim)
	rl.DrawText(fmt.ctprintf("x%d", qty), x + 180, y^, 14, dim)
	y^ += 20
}
