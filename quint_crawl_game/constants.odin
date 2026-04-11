package quint_crawl_game

import qc "../quint_crawl"
import rl "vendor:raylib"

// Window
WINDOW_W :: 960
WINDOW_H :: 720

// Map area (left side)
MAP_X :: 0
MAP_Y :: 0
MAP_SIZE :: 720
TILE_PAD :: 4
TILE_OFFSET :: TILE_PAD  // offset from top-left of map area
TILE_SIZE :: (MAP_SIZE - TILE_OFFSET - TILE_PAD * (qc.WORLD_SIZE - 1)) / qc.WORLD_SIZE

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

// Screen transitions
TRANSITION_DURATION :: f32(0.3)  // total transition time (fade out + fade in)

// Victory rewards overlay
REWARDS_DURATION :: f32(2.0)     // time for counters to animate in
REWARDS_XP_DELAY :: f32(0.3)     // delay before XP counter starts
REWARDS_GOLD_DELAY :: f32(0.6)   // delay before gold counter starts
REWARDS_LEVEL_DELAY :: f32(1.0)  // delay before level-up appears
