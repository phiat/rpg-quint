package quint_crawl_game

import rl "vendor:raylib"

// Window
WINDOW_W :: 960
WINDOW_H :: 720

// Map area (left side)
MAP_X :: 0
MAP_Y :: 0
MAP_SIZE :: 720
TILE_SIZE :: 232
TILE_PAD :: 8
TILE_OFFSET :: TILE_PAD  // offset from top-left of map area

// HUD (right sidebar)
HUD_X :: 720
HUD_W :: 240
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

// Zone tile colors [x][y]
ZONE_COLORS := [3][3]rl.Color{
	// x=0              x=1                x=2
	{{139, 119, 101, 255}, {85, 140, 85, 255},  {90, 75, 100, 255}},   // y=0: Village, Forest, Swamp
	{{140, 160, 100, 255}, {75, 75, 90, 255},   {120, 120, 140, 255}}, // y=1: Plains, Cave, Mountain
	{{110, 90, 75, 255},   {170, 150, 80, 255}, {130, 50, 50, 255}},   // y=2: Ruins, Shrine, Castle
}

// Enemy colors by tier (zone level 1, 2, 3)
ENEMY_COLORS := [3]rl.Color{
	{100, 180, 100, 255},  // tier 1: green (slime)
	{180, 180, 100, 255},  // tier 2: yellow (skeleton)
	{200, 80, 80, 255},    // tier 3: red (dragon)
}

ENEMY_NAMES := [3]string{"Slime", "Skeleton", "Dragon"}

// Day/night cycle (temporary - will be driven by game state later)
DAY_CYCLE_SPEED :: f32(0.03)  // full cycle in ~33 seconds for testing

// Screen transitions
TRANSITION_DURATION :: f32(0.3)  // total transition time (fade out + fade in)

// Victory rewards overlay
REWARDS_DURATION :: f32(2.0)     // time for counters to animate in
REWARDS_XP_DELAY :: f32(0.3)     // delay before XP counter starts
REWARDS_GOLD_DELAY :: f32(0.6)   // delay before gold counter starts
REWARDS_LEVEL_DELAY :: f32(1.0)  // delay before level-up appears
