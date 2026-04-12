# Quint Crawl — Asset Design Guide

The game currently renders everything procedurally (colored shapes, rectangles, text). This document specifies the sprite assets needed for a V2 visual upgrade. The only asset currently shipped is `quint_crawl_game/assets/effects.fs` (post-processing shader).

## Art Style

- **Pixel art**, 16-color palette per asset
- Top-down perspective for tiles, front-facing for characters/enemies
- Dark fantasy RPG aesthetic — muted earth tones with accent highlights
- Consistent 1px outline on all sprites

## World Layout

The world is a **9x9 grid** (81 zones). The 9 biomes below tile across it in a repeating 3x3 pattern (`biome_x = x%3`, `biome_y = y%3`). Zone difficulty scales with distance from origin: level = `(x+y)/3 + 1`, capped at `MAX_LEVEL=5`. The player starts at (0,0); the Castle Boss lives at Castle zones on level 5.

```
         biome_x=0      biome_x=1     biome_x=2
biome_y=0  Village        Forest        Swamp
biome_y=1  Plains         Cave          Mountain
biome_y=2  Ruins          Shrine        Castle
```

## Tile Backgrounds (240x240 each)

9 biome tiles, reused across every level. Level variation is handled by per-zone shader tints (`u_zone_tint` in `effects.fs`) plus a fog-of-war mask overlay, so the base tile art stays neutral.

| File | Biome | Description | Palette Notes |
|------|-------|-------------|---------------|
| `tile_village.png` | Village | Small inn, market stalls, cobblestone path, warm lantern glow | Warm browns, tan, orange lantern light |
| `tile_forest.png` | Forest | Dense trees, dirt path winding through, dappled light, logs on ground | Dark and mid greens, brown trunks |
| `tile_swamp.png` | Swamp | Murky water, dead trees, fog wisps, lily pads, eerie glow | Purple-greens, murky browns, pale fog |
| `tile_plains.png` | Plains | Rolling grassland, wildflowers, clear sky, stone marker | Light greens, yellows, sky blue accent |
| `tile_cave.png` | Cave | Rocky cave entrance, stalactites, glowing crystals, dark interior | Dark grays, blue crystal glow |
| `tile_mountain.png` | Mountain | Craggy peaks, snow caps, iron ore veins visible, narrow path | Gray-blue rock, white snow, rust ore |
| `tile_ruins.png` | Ruins | Crumbling stone walls, overgrown vines, broken pillars, mossy floor | Dark tan, gray stone, green moss |
| `tile_shrine.png` | Shrine | Golden altar, glowing runes, mystical energy, ornate floor tiles | Gold, amber, warm white glow |
| `tile_castle.png` | Castle | Dark fortress gates, banners, torches, imposing walls, red sky | Dark red, black iron, flame orange |

### World Overlays

| File | Size | Description |
|------|------|-------------|
| `overlay_fog_of_war.png` | 240x240 | Dark unrevealed-zone mask, semi-transparent edges for adjacent reveals |
| `icon_waypoint.png` | 32x32 | Waypoint marker drawn on village tiles once unlocked (fast-travel target) |
| `icon_lock.png` | 32x32 | Lock icon for level-gated zones |
| `icon_chest.png` | 32x32 | Treasure chest marker — world-placed persistent reward, tier-scaled gold |

## Character Sprites (64x64)

| File | Description |
|------|-------------|
| `player.png` | Front-facing adventurer, light armor, empty weapon hand. Reads clearly on any tile. Cyan accent to match in-game marker `#00DCFF`. |
| `player_sword.png` | Same with sword equipped |
| `player_dagger.png` | Same with dagger equipped (fast blade, shares blade-combat paths with sword) |
| `player_pistol.png` | Same with battery-powered pistol equipped (sci-fantasy contrast) |
| `player_staff.png` | Same with staff equipped (caster stance) |
| `player_hurt.png` | Damage frame (red tint / stagger pose) |

## Enemy Sprites (128x128)

The bestiary is **data-driven**: 20 archetypes × 5 tiers = 200 named enemies, keyed by 6 trait tags (Undead / Beast / Elemental / Construct / Humanoid / Aberration). For V2 minimum we ship one silhouette per archetype; tier variation is handled via color-tint + size-up in rendering.

| File | Archetype | Trait | Description |
|------|-----------|-------|-------------|
| `enemy_slime.png` | Slime | Aberration | Amorphous blob, simple eyes, non-threatening |
| `enemy_skeleton.png` | Skeleton | Undead | Angular bones, hollow sockets, rusty weapon |
| `enemy_wolf.png` | Wolf | Beast | Feral, red eyes, snarling |
| `enemy_wraith.png` | Wraith | Undead | Ghostly cloaked figure, glowing purple eyes |
| `enemy_drake.png` | Drake | Beast | Small winged reptile |
| `enemy_golem.png` | Golem | Construct | Stone/iron automaton |
| `enemy_imp.png` | Imp | Elemental | Fire sprite |
| `enemy_bandit.png` | Bandit | Humanoid | Hooded rogue with knife |
| `enemy_lich.png` | Lich | Undead | Robed skeletal caster |
| `enemy_oozeling.png` | Oozeling | Aberration | Tentacled ooze |
| *(10 more archetypes)* | | | Shield dwarf, bog witch, spider queen, etc. — author as demand grows; rendering falls back to procedural. |

### Castle Boss (256x256)

| File | Description |
|------|-------------|
| `boss_castle.png` | Unique large sprite for the Castle Boss encounter (`BOSS_HP=80`, `BOSS_ATK=12`, element Fire). Distinct silhouette from the tier-5 drake; should telegraph "final fight". |

### Optional Enemy Variants

| File | Description |
|------|-------------|
| `enemy_*_hurt.png` | Damage flash frame (white tint) |
| `enemy_*_dead.png` | Defeat animation frame (fading/dissolving) |

## Item Icons (32x32)

Used in the HUD sidebar inventory and shop/loot panels.

### Core items

| File | Item | Description |
|------|------|-------------|
| `icon_potion.png` | Health Potion | Red flask, +20 HP |
| `icon_sword.png` | Sword (Common) | Steel blade, +5 ATK |
| `icon_sword_rare.png` | Sword (Rare) | Blue-hilt variant, higher ATK scaling |
| `icon_sword_legendary.png` | Sword (Legendary) | Gold-hilt variant with glow, highest ATK scaling |
| `icon_sword_broken.png` | Broken Sword | Cracked/dimmed blade, 0 durability |
| `icon_dagger.png` | Dagger | Short blade, fast attacks, lower stamina cost |
| `icon_pistol.png` | Pistol | Battery-powered sidearm (alt weapon type) |
| `icon_battery.png` | Battery | Pistol ammo cell |
| `icon_staff.png` | Staff | Caster weapon, gates spell actions |
| `icon_venom_sac.png` | Venom Sac | Green bulbous sac, poison ingredient |
| `icon_wood.png` | Wood | Bundle of logs, crafting mat |
| `icon_iron.png` | Iron Ore | Gray metallic chunk, crafting mat |
| `icon_gold.png` | Gold | Coin pouch for the gold counter |

### Consumables

Bought at the village or looted. All respect the 30-item inventory cap.

| File | Item | Description |
|------|------|-------------|
| `icon_bomb.png` | Bomb | Lit fuse sphere — flat damage in combat, bypasses enemy DEF |
| `icon_smoke_bomb.png` | Smoke Bomb | Gray puff canister — guaranteed flee from combat |
| `icon_ration.png` | Ration | Wrapped bread — restores stamina out of combat |
| `icon_holy_water.png` | Holy Water | Glowing vial — crafted from holy_dust + wood, out-of-combat full heal |
| `icon_fire_scroll.png` | Fire Scroll | Sealed parchment with flame sigil — bypasses mana gate for fire spell |

### Trait-keyed loot materials

Dropped by enemies based on their trait tag (see Bestiary section).

| File | Material | Trait | Notes |
|------|----------|-------|-------|
| `icon_holy_dust.png` | Holy Dust | Undead | Glowing mote, used in anti-undead crafting |
| `icon_pelt.png` | Pelt | Beast | Rolled hide with claw trim |
| `icon_core.png` | Core | Construct | Glowing mechanical cube |
| `icon_essence.png` | Essence | Elemental | Swirling vial of colored mist |
| `icon_coin.png` | Trophy Coin | Humanoid | Stamped faction token (distinct from gold) |
| `icon_ichor.png` | Ichor | Aberration | Black viscous droplet |

### Unique trophy drops (32x32)

One-of-a-kind drops from a tier's signature archetype. Each grants a permanent ATK bonus and is displayed in the inventory overlay's trophy panel. There are 5 (one per level tier).

| File | Trophy | Tier | Notes |
|------|--------|------|-------|
| `icon_trophy_slime_crown.png`    | Slime Crown    | 1 | Gel crown with jewel inclusion |
| `icon_trophy_bone_standard.png`  | Bone Standard  | 2 | Tattered banner on femur pole |
| `icon_trophy_alpha_pelt.png`     | Alpha Pelt     | 3 | Oversized scarred pelt |
| `icon_trophy_wraith_veil.png`    | Wraith Veil    | 4 | Translucent ghostly shroud |
| `icon_trophy_dragon_heart.png`   | Dragon Heart   | 5 | Pulsing ember-cored heart |

## Weapon & Enchantment Icons (32x32)

The sword has 3 enchantment slots and 4 enchant types. Fire and ice are mutually exclusive per sword.

| File | Enchantment | Effect |
|------|-------------|--------|
| `icon_ench_fire.png` | Fire | Attacks count as Fire element |
| `icon_ench_ice.png` | Ice | Attacks count as Ice element |
| `icon_ench_lightning.png` | Lightning | Attacks count as Lightning element |
| `icon_ench_vampiric.png` | Vampiric | Heal on hit (element-neutral) |

Displayed as small slot indicators on the sword icon in the HUD.

## Elemental VFX (64x64 each)

4-element damage cycle (`Fire > Ice > Lightning > Earth > Fire`, 2x/1x/0.5x multipliers). Shown as a brief flash overlay on combat-hit frames.

| File | Element | Color Key |
|------|---------|-----------|
| `vfx_fire.png` | Fire | Orange-red |
| `vfx_ice.png` | Ice | Pale cyan |
| `vfx_lightning.png` | Lightning | Yellow-white |
| `vfx_earth.png` | Earth | Brown-green |

## Weather Icons & Overlays

### HUD icons (32x32)

| File | Weather | Effect |
|------|---------|--------|
| `icon_weather_clear.png` | Clear | Bright sun, warm yellow |
| `icon_weather_rain.png` | Rain | Cloud with raindrops, blue tint. +1 gather bonus |
| `icon_weather_fog.png` | Fog | Swirling gray mist. -2 ATK for **both** player and enemy |
| `icon_weather_storm.png` | Storm | Lightning bolt. 4 dmg on movement |

### Tile overlays (240x240, semi-transparent, alpha 40-80)

| File | Weather | Description |
|------|---------|-------------|
| `overlay_rain.png` | Rain | Diagonal rain streaks, loopable |
| `overlay_fog.png` | Fog | Soft white-gray clouds drifting across, low opacity |
| `overlay_storm.png` | Storm | Dark clouds, occasional lightning flash |

## Status Effect Icons (24x24)

Displayed in combat when active. Readable on dark combat background.

| File | Status | Description |
|------|--------|-------------|
| `icon_status_poison.png` | Player Poison | Green skull/droplet, player DoT |
| `icon_status_atk_buff.png` | ATK Buff | Red upward arrow, +ATK |
| `icon_status_def_buff.png` | DEF Buff | Blue shield, incoming damage reduced |
| `icon_status_fortify.png` | Fortify | Gold shield with longer ring, extended DEF |
| `icon_status_enemy_poison.png` | Enemy Poison | Green droplet on red target |

## Cooldown Ability Icons (32x32)

Shown with a radial cooldown fill in the combat HUD.

| File | Ability | Key |
|------|---------|-----|
| `icon_ability_heavy_strike.png` | Heavy Strike (2x dmg) | H |
| `icon_ability_battle_cry.png` | Battle Cry (ATK buff) | Y |
| `icon_ability_fortify.png` | Fortify (ext DEF) | I |
| `icon_ability_counter_attack.png` | Counter-Attack | N |
| `icon_ability_shield_block.png` | Shield Block | Z |

## Combo Icons (24x24)

Combat combo indicator (3-hit chain). Shows current/next hit.

| File | Hit | Multiplier |
|------|-----|------------|
| `icon_combo_slash.png` | Slash | 1x — diagonal blade slash, white/silver |
| `icon_combo_thrust.png` | Thrust | 1.5x — forward stab, blue accent glow |
| `icon_combo_finisher.png` | Finisher | 2x — explosive double slash, gold/yellow glow |

## Skill Tree Icons (32x32)

Shown in the village skill panel (keys 1–7). 3 branches: Offense / Defense / Utility.

| File | Skill | Branch |
|------|-------|--------|
| `icon_skill_combo.png` | Combo chain | Offense |
| `icon_skill_heavy_strike.png` | Heavy Strike | Offense |
| `icon_skill_poison.png` | Poison Strike | Offense |
| `icon_skill_shield_block.png` | Shield Block | Defense |
| `icon_skill_counter_attack.png` | Counter-Attack | Defense |
| `icon_skill_fortify.png` | Fortify | Defense |
| `icon_skill_battle_cry.png` | Battle Cry | Utility |

## Companion Sprites (48x48)

Data-driven species catalog: 8 species × 3 rarity tiers (Common / Rare / Legendary). For V2 minimum, author one base sprite per species; rarity is handled by a palette-shift tint in the shader (Common neutral, Rare blue, Legendary gold).

| File | Species | Biome Affinity | Trait |
|------|---------|----------------|-------|
| `comp_wolf.png` | Wolf | Forest | Attacker |
| `comp_hawk.png` | Hawk | Plains | Scout |
| `comp_turtle.png` | Turtle | Swamp | Defender |
| `comp_fox.png` | Fox | Forest | Scout |
| `comp_bear.png` | Bear | Mountain | Attacker |
| `comp_owl.png` | Owl | Ruins | Support |
| `comp_lynx.png` | Lynx | Cave | Attacker |
| `comp_sprite.png` | Sprite | Shrine | Support |

## UI Elements

| File | Size | Description |
|------|------|-------------|
| `font_pixel.png` | spritesheet | Custom pixel font atlas for consistent text rendering |
| `bar_hp.png` | 9-slice | HP bar frame |
| `bar_xp.png` | 9-slice | XP bar frame |
| `bar_stamina.png` | 9-slice | Stamina bar frame (green accent) |
| `bar_durability.png` | 9-slice | Sword durability bar (short, blue accent) |
| `bar_loyalty.png` | 9-slice | Companion loyalty bar (purple accent) |
| `frame_hud.png` | 240x720 | HUD sidebar background |
| `frame_combat.png` | 720x720 | Combat screen background |
| `frame_rewards.png` | 400x300 | Victory rewards panel background |
| `frame_inventory.png` | 760x680 | Inventory overlay panel background (3-column layout) |
| `icon_quest_claim.png` | 32x32 | Glow ribbon for `[TAB] Claim reward` HUD hint |
| `banner_boss_defeated.png` | 720x120 | One-shot banner after Castle Boss kill |
| `icon_star.png` | 32x32 | Level-up celebration icon |
| `icon_save.png` | 24x24 | Save indicator |
| `icon_load.png` | 24x24 | Load indicator |

## Asset Summary

### Required (V2 minimum)

| Category | Count | Size Each |
|----------|-------|-----------|
| Tile backgrounds | 9 | 240x240 |
| Player sprite | 1 | 64x64 |
| Enemy archetype sprites | 10 | 128x128 |
| Castle Boss | 1 | 256x256 |
| Item icons (core) | 11 | 32x32 |
| Item icons (consumables) | 5 | 32x32 |
| Item icons (trait mats) | 6 | 32x32 |
| Item icons (unique trophies) | 5 | 32x32 |
| Sword rarity variants | 2 | 32x32 |
| Enchantment icons | 4 | 32x32 |
| Elemental VFX | 4 | 64x64 |
| Weather icons | 4 | 32x32 |
| Status effect icons | 5 | 24x24 |
| Cooldown ability icons | 5 | 32x32 |
| Combo icons | 3 | 24x24 |
| Skill tree icons | 7 | 32x32 |
| Companion sprites | 8 | 48x48 |
| Treasure chest marker | 1 | 32x32 |
| **Total** | **91** | |

### Optional (polish)

| Category | Count |
|----------|-------|
| Player variants (sword/dagger/pistol/staff/hurt) | 5 |
| Enemy hurt/dead frames | 20 |
| Remaining 10 enemy archetypes | 10 |
| Weather tile overlays | 3 |
| Fog-of-war + waypoint + lock overlays | 3 |
| UI elements (bars, frames, banners) | 14 |
| **Total** | **55** |

## Integration Notes

Assets should be placed in `quint_crawl_game/assets/` and loaded with:

```odin
texture := rl.LoadTexture("quint_crawl_game/assets/tile_village.png")
```

The rendering code in `rendering.odin` can be updated to check for asset files and fall back to procedural drawing if they're missing — allowing incremental art replacement without breaking the game.

### Shader Pipeline

The game already has a post-processing shader pipeline (`quint_crawl_game/assets/effects.fs`) that applies:
- Per-zone color tinting (`u_zone_tint`)
- Chromatic aberration + barrel distortion on combat hits (`u_aberration`)
- Low-HP danger pulse / red vignette (`u_danger`)
- Level-up bloom flash (`u_bloom`)
- Poison green tint driven by `player_poison_dur` (`u_poison`)
- Global time for animated effects (`u_time`)

Single off-screen render texture → shader pass → default framebuffer.

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
