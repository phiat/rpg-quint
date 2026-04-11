# Quint Crawl — Asset Design Guide

The game currently renders everything procedurally (colored shapes, rectangles, text). This document specifies the sprite assets needed for a V2 visual upgrade.

## Art Style

- **Pixel art**, 16-color palette per asset
- Top-down perspective for tiles, front-facing for characters/enemies
- Dark fantasy RPG aesthetic — muted earth tones with accent highlights
- Consistent 1px outline on all sprites

## Tile Backgrounds (240x240 each)

9 tiles for the 3x3 world grid. Each should fill the full 240x240 area and convey the zone's identity at a glance.

| File | Zone | Level | Description | Palette Notes |
|------|------|-------|-------------|---------------|
| `tile_village.png` | Village (0,0) | 1 | Small inn, market stalls, cobblestone path, warm lantern glow | Warm browns, tan, orange lantern light |
| `tile_forest.png` | Forest (1,0) | 1 | Dense trees, dirt path winding through, dappled light, logs on ground | Dark and mid greens, brown trunks |
| `tile_swamp.png` | Swamp (2,0) | 1 | Murky water, dead trees, fog wisps, lily pads, eerie glow | Purple-greens, murky browns, pale fog |
| `tile_plains.png` | Plains (0,1) | 1 | Rolling grassland, wildflowers, clear sky, stone marker | Light greens, yellows, sky blue accent |
| `tile_cave.png` | Cave (1,1) | 2 | Rocky cave entrance, stalactites, glowing crystals, dark interior | Dark grays, blue crystal glow |
| `tile_mountain.png` | Mountain (2,1) | 2 | Craggy peaks, snow caps, iron ore veins visible, narrow path | Gray-blue rock, white snow, rust ore |
| `tile_ruins.png` | Ruins (0,2) | 2 | Crumbling stone walls, overgrown vines, broken pillars, mossy floor | Dark tan, gray stone, green moss |
| `tile_shrine.png` | Shrine (1,2) | 2 | Golden altar, glowing runes, mystical energy, ornate floor tiles | Gold, amber, warm white glow |
| `tile_castle.png` | Castle (2,2) | 3 | Dark fortress gates, banners, torches, imposing walls, red sky | Dark red, black iron, flame orange |

### Grid Layout Reference

```
         x%3=0         x%3=1         x%3=2
y%3=0  Village        Forest        Swamp
y%3=1  Plains         Cave          Mountain
y%3=2  Ruins          Shrine        Castle
```

This 3x3 biome pattern tiles across the full 9x9 world grid. Zone level = `(x+y)/3 + 1` (capped at 5). The player starts at (0,0) and must reach level 5 to access the highest-level Castle zones and claim victory.

## Character Sprites (64x64)

| File | Description | Notes |
|------|-------------|-------|
| `player.png` | Player character, front-facing | Adventurer with light armor, visible sword slot (empty by default). Needs to read clearly at 64x64 on top of any tile color. Bright cyan accent to match the in-game player marker color `#00DCFF`. |

### Optional Player Variants

| File | Description |
|------|-------------|
| `player_sword.png` | Player with sword equipped (visible weapon) |
| `player_hurt.png` | Player taking damage (red tint / stagger pose) |

## Enemy Sprites (128x128)

One enemy per zone tier. Displayed centered in the combat screen.

| File | Tier | Name | HP | ATK | Description | Color Key |
|------|------|------|----|-----|-------------|-----------|
| `enemy_tier1.png` | 1 | Slime | 20 | 6 | Amorphous green blob with simple eyes, non-threatening | Green `#64B464` |
| `enemy_tier2.png` | 2 | Skeleton | 40 | 10 | Undead warrior, angular bones, hollow eye sockets, rusty weapon | Yellow `#B4B464` |
| `enemy_tier3.png` | 3 | Wolf | 60 | 14 | Feral gray wolf, red eyes, snarling, hunched posture | Gray `#808090` |
| `enemy_tier4.png` | 4 | Wraith | 80 | 18 | Ghostly floating figure, dark cloak, glowing purple eyes | Purple `#9050B4` |
| `enemy_tier5.png` | 5 | Dragon | 100 | 22 | Winged dragon, menacing, red scales, glowing yellow eyes | Red `#C85050`, eyes `#FFFF00` |

### Optional Enemy Variants

| File | Description |
|------|-------------|
| `enemy_tier*_hurt.png` | Damage flash frame (white tint) |
| `enemy_tier*_dead.png` | Defeat animation frame (fading/dissolving) |

## Item Icons (32x32)

Used in the HUD sidebar inventory display.

| File | Item | Description |
|------|------|-------------|
| `icon_potion.png` | Health Potion | Red liquid in a round flask, +20 HP | 
| `icon_sword.png` | Sword | Steel blade, +5 ATK when equipped |
| `icon_sword_broken.png` | Broken Sword | Cracked/dimmed blade, 0 durability |
| `icon_wood.png` | Wood | Bundle of logs/sticks, crafting material |
| `icon_iron.png` | Iron Ore | Gray metallic chunk, crafting material |
| `icon_venom_sac.png` | Venom Sac | Green bulbous sac, poison crafting ingredient |
| `icon_gold.png` | Gold (optional) | Gold coin/pouch for the gold counter |

## Weather Icons (32x32)

Displayed in HUD zone info section. Show current weather for the player's zone.

| File | Weather | Description |
|------|---------|-------------|
| `icon_weather_clear.png` | Clear | Bright sun, warm yellow |
| `icon_weather_rain.png` | Rain | Cloud with raindrops, blue tint. Indicates +1 gather bonus |
| `icon_weather_fog.png` | Fog | Swirling gray mist. Indicates enemy ATK -2 penalty |
| `icon_weather_storm.png` | Storm | Lightning bolt through dark cloud. Indicates 2 dmg on movement |

## Status Effect Icons (24x24)

Displayed in combat screen when active. Should be clearly readable on dark combat background.

| File | Status | Description |
|------|--------|-------------|
| `icon_status_poison.png` | Poison | Green skull/droplet, player taking 3 DoT/turn |
| `icon_status_atk_buff.png` | ATK Buff | Red upward arrow/flame, +5 ATK |
| `icon_status_def_buff.png` | DEF Buff | Blue shield, enemy damage -3 |
| `icon_status_enemy_poison.png` | Enemy Poison | Green droplet on red target, enemy taking 3 DoT/turn |

## Combo Icons (24x24)

Displayed in the combat screen combo indicator. Show the current/next hit in the chain.

| File | Hit | Description |
|------|-----|-------------|
| `icon_combo_slash.png` | Slash (1x) | Diagonal blade slash, white/silver |
| `icon_combo_thrust.png` | Thrust (1.5x) | Forward stab, blue accent glow |
| `icon_combo_finisher.png` | Finisher (2x) | Explosive double slash, gold/yellow glow |

## Weather Tile Overlays (240x240, semi-transparent)

Applied on top of tile backgrounds when weather is active. Should be subtle (alpha 40-80).

| File | Weather | Description |
|------|---------|-------------|
| `overlay_rain.png` | Rain | Diagonal rain streaks, blue-tinted, loopable |
| `overlay_fog.png` | Fog | Soft white-gray clouds drifting across, low opacity |
| `overlay_storm.png` | Storm | Dark clouds, occasional lightning flash, ominous |

## UI Elements (optional)

| File | Size | Description |
|------|------|-------------|
| `font_pixel.png` | spritesheet | Custom pixel font atlas for consistent text rendering |
| `bar_hp.png` | 9-slice | HP bar frame (9-slice scalable) |
| `bar_xp.png` | 9-slice | XP bar frame |
| `bar_durability.png` | 9-slice | Sword durability bar frame (shorter, blue accent) |
| `frame_hud.png` | 240x720 | HUD sidebar background texture |
| `frame_combat.png` | 720x720 | Combat screen background |
| `icon_lock.png` | 32x32 | Lock icon for level-gated zones |
| `icon_star.png` | 32x32 | Level-up celebration icon |
| `icon_save.png` | 24x24 | Floppy disk / bookmark for save indicator |
| `icon_load.png` | 24x24 | Circular arrow / reload for load indicator |
| `frame_rewards.png` | 400x300 | Victory rewards panel background (9-slice or fixed) |

## Asset Summary

### Required (V2 minimum)

| Category | Count | Size Each |
|----------|-------|-----------|
| Tile backgrounds | 9 | 240x240 |
| Player sprite | 1 | 64x64 |
| Enemy sprites | 5 | 128x128 |
| Item icons | 6 | 32x32 |
| Weather icons | 4 | 32x32 |
| Status effect icons | 4 | 24x24 |
| Combo icons | 3 | 24x24 |
| **Total** | **33** | |

### Optional (polish)

| Category | Count | Size Each |
|----------|-------|-----------|
| Player variants | 2 | 64x64 |
| Enemy variants | 10 | 128x128 |
| Weather tile overlays | 3 | 240x240 |
| UI elements | 10 | various |
| Gold icon | 1 | 32x32 |
| **Total** | **26** | |

## Integration Notes

Assets should be placed in `quint_crawl_game/assets/` and loaded with:

```odin
texture := rl.LoadTexture("quint_crawl_game/assets/tile_village.png")
```

The rendering code in `rendering.odin` can be updated to check for asset files and fall back to procedural drawing if they're missing — allowing incremental art replacement without breaking the game.

### Shader Pipeline

The game already has a 2-pass post-processing shader pipeline (`quint_crawl_game/assets/daynight.fs` + `effects.fs`) that applies:
- Day/night color grading (time-based)
- Per-zone color tinting
- Chromatic aberration on combat hits
- Low-HP danger pulse (red vignette)
- Level-up bloom flash
- Poison green tint (driven by `player_poison_dur`)

Sprite assets will pass through these shaders automatically — they should be authored at neutral lighting and let the shaders handle atmospheric effects.

## Color Reference

Colors used in the procedural V1 renderer, for palette consistency:

| Element | Hex | RGB |
|---------|-----|-----|
| Background | `#12121C` | 18, 18, 28 |
| Player marker | `#00DCFF` | 0, 220, 255 |
| HP bar | `#DC3232` | 220, 50, 50 |
| XP bar | `#3278DC` | 50, 120, 220 |
| Gold text | `#FFD700` | 255, 215, 0 |
| Key highlight | `#FFC83C` | 255, 200, 60 |
| Text bright | `#E6E6F0` | 230, 230, 240 |
| Text dim | `#8C8CA0` | 140, 140, 160 |
| Tile border | `#3C3C50` | 60, 60, 80 |
| HUD background | `#1E1E2D` | 30, 30, 45 |
| Combat background | `#190F14` | 25, 15, 20 |
