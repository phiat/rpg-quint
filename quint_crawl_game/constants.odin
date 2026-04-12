package quint_crawl_game

import qc "../quint_crawl"
import rl "vendor:raylib"

// Window
WINDOW_W :: 1120
WINDOW_H :: 880

// Map area (left side)
MAP_X :: 0
MAP_Y :: 0
MAP_SIZE :: 800
TILE_PAD :: 4
TILE_OFFSET :: TILE_PAD  // offset from top-left of map area
TILE_SIZE :: (MAP_SIZE - TILE_OFFSET - TILE_PAD * (qc.WORLD_SIZE - 1)) / qc.WORLD_SIZE

// HUD (right sidebar)
HUD_X :: 800
HUD_W :: 320
HUD_PAD :: 12

// Messages
MAX_MESSAGES :: 6
MESSAGE_LIFETIME :: f32(5.0)

// Colors
BG_COLOR       :: rl.Color{18, 18, 28, 255}
HUD_BG         :: rl.Color{30, 30, 45, 255}
TILE_BORDER    :: rl.Color{60, 60, 80, 255}
TEXT_BRIGHT    :: rl.Color{230, 230, 240, 255}
TEXT_DIM       :: rl.Color{140, 140, 160, 255}
TEXT_GOLD      :: rl.Color{255, 215, 0, 255}
BAR_HP_FG     :: rl.Color{220, 50, 50, 255}
BAR_HP_BG     :: rl.Color{80, 20, 20, 255}
BAR_XP_FG     :: rl.Color{50, 120, 220, 255}
BAR_XP_BG     :: rl.Color{20, 40, 80, 255}
PLAYER_COLOR   :: rl.Color{0, 220, 255, 255}
LOCKED_OVERLAY :: rl.Color{0, 0, 0, 140}
KEY_HIGHLIGHT  :: rl.Color{255, 200, 60, 255}
COMBAT_BG      :: rl.Color{25, 15, 20, 255}

// Base zone tile colors [bx][by] — tiled across the grid via x%3, y%3
// bx=0: Village/Plains/Ruins, bx=1: Forest/Cave/Shrine, bx=2: Swamp/Mountain/Castle
BASE_ZONE_COLORS := [3][3]rl.Color{
	{{139, 119, 101, 255}, {140, 160, 100, 255}, {110, 90, 75, 255}},   // bx=0: Village, Plains, Ruins
	{{85, 140, 85, 255},   {75, 75, 90, 255},    {170, 150, 80, 255}},  // bx=1: Forest, Cave, Shrine
	{{90, 75, 100, 255},   {120, 120, 140, 255}, {130, 50, 50, 255}},   // bx=2: Swamp, Mountain, Castle
}

// Enemy colors by tier (zone level 1-5)
ENEMY_COLORS := [qc.MAX_LEVEL]rl.Color{
	{100, 180, 100, 255},  // tier 1: green (slime)
	{180, 180, 100, 255},  // tier 2: yellow (skeleton)
	{160, 120, 80, 255},   // tier 3: brown (wolf)
	{140, 100, 180, 255},  // tier 4: purple (wraith)
	{200, 80, 80, 255},    // tier 5: red (dragon)
}

ENEMY_NAMES := [qc.MAX_LEVEL]string{"Slime", "Skeleton", "Wolf", "Wraith", "Dragon"}

// Unique trophy names per zone tier bit (0..4). Each grants +1 passive atk.
UNIQUE_DROP_NAMES := [5]string{
	"Slime Crown",      // tier 1 (slime)
	"Bone Standard",    // tier 2 (skeleton)
	"Alpha Pelt",       // tier 3 (wolf)
	"Wraith Veil",      // tier 4 (wraith)
	"Dragon Heart",     // tier 5 (dragon)
}

// Sword rarity tiers (0=common, 1=rare, 2=epic, 3=legendary)
SWORD_RARITY_NAMES := [4]string{"Sword", "Rare Sword", "Epic Sword", "Legendary Sword"}
SWORD_RARITY_COLORS := [4]rl.Color{
	TEXT_BRIGHT,                 // common
	{100, 180, 255, 255},        // rare: blue
	{200, 100, 255, 255},        // epic: purple
	{255, 200, 50, 255},         // legendary: gold
}

sword_rarity_name :: proc(r: int) -> string {
	if r < 0 || r >= len(SWORD_RARITY_NAMES) do return SWORD_RARITY_NAMES[0]
	return SWORD_RARITY_NAMES[r]
}

rarity_text_color :: proc(r: int) -> rl.Color {
	if r < 0 || r >= len(SWORD_RARITY_COLORS) do return SWORD_RARITY_COLORS[0]
	return SWORD_RARITY_COLORS[r]
}

// Enchantment names/colors (0=empty, 1=fire, 2=ice, 3=vampiric, 4=lightning)
ENCH_NAMES := [5]string{"Empty", "Fire", "Ice", "Vampiric", "Lightning"}
ENCH_COLORS := [5]rl.Color{
	TEXT_DIM,                    // empty
	{255, 100, 50, 255},        // fire
	{100, 180, 255, 255},       // ice
	{200, 50, 200, 255},        // vampiric
	{255, 255, 100, 255},       // lightning
}

// Element names/colors (0=none, 1=fire, 2=ice, 3=lightning, 4=earth)
ELEM_NAMES := [5]string{"None", "Fire", "Ice", "Lightning", "Earth"}
ELEM_COLORS := [5]rl.Color{
	TEXT_DIM,                    // none
	{255, 100, 50, 255},        // fire
	{100, 180, 255, 255},       // ice
	{255, 255, 100, 255},       // lightning
	{100, 200, 100, 255},       // earth
}

// Stamina bar
BAR_STAMINA_FG :: rl.Color{50, 200, 120, 255}
BAR_STAMINA_BG :: rl.Color{20, 60, 40, 255}

// Status effect colors
COLOR_POISON   :: rl.Color{100, 255, 100, 255}
COLOR_ATK_BUFF :: rl.Color{255, 100, 100, 255}
COLOR_DEF_BUFF :: rl.Color{100, 150, 255, 255}
COLOR_STRONG   :: rl.Color{100, 255, 100, 255}
COLOR_WEAK     :: rl.Color{255, 100, 100, 255}

// Screen transitions
TRANSITION_DURATION :: f32(0.3)  // total transition time (fade out + fade in)

// Victory rewards overlay
REWARDS_DURATION :: f32(2.0)     // time for counters to animate in
REWARDS_XP_DELAY :: f32(0.3)     // delay before XP counter starts
REWARDS_GOLD_DELAY :: f32(0.6)   // delay before gold counter starts
REWARDS_LEVEL_DELAY :: f32(1.0)  // delay before level-up appears
