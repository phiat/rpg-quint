// Quint specification for an Alliance/Betrayal faction system.
// Models 3 factions: Guild, Crown, Rebels.
// Player has standing [-100, 100] with each faction.
// Actions: join, do quests, betray current faction.
// All factions are rivals of each other.
// Alliance threshold: 75+, Enemy threshold: -50 or below.
module faction {
    pure def clamp(v: int, lo: int, hi: int): int =
        if (v < lo) lo else if (v > hi) hi else v

    // State variables
    var standing_guild: int    // [-100, 100]
    var standing_crown: int    // [-100, 100]
    var standing_rebels: int   // [-100, 100]
    var allied_faction: int    // 0=none, 1=guild, 2=crown, 3=rebels

    // Init: no alliances, neutral standing
    action init = all {
        standing_guild'  = 0,
        standing_crown'  = 0,
        standing_rebels' = 0,
        allied_faction'  = 0,
    }

    // Join the Guild: set standing to 50, rivals (Crown and Rebels) drop by 25
    action join_guild = all {
        standing_guild'  = 50,
        standing_crown'  = clamp(standing_crown - 25, -100, 100),
        standing_rebels' = clamp(standing_rebels - 25, -100, 100),
        allied_faction'  = 1,
    }

    // Join the Crown: set standing to 50, rivals drop by 25
    action join_crown = all {
        standing_guild'  = clamp(standing_guild - 25, -100, 100),
        standing_crown'  = 50,
        standing_rebels' = clamp(standing_rebels - 25, -100, 100),
        allied_faction'  = 2,
    }

    // Join the Rebels: set standing to 50, rivals drop by 25
    action join_rebels = all {
        standing_guild'  = clamp(standing_guild - 25, -100, 100),
        standing_crown'  = clamp(standing_crown - 25, -100, 100),
        standing_rebels' = 50,
        allied_faction'  = 3,
    }

    // Do a quest for the Guild: gain 10, rival factions (Crown, Rebels) lose 5
    action quest_guild = all {
        standing_guild'  = clamp(standing_guild + 10, -100, 100),
        standing_crown'  = clamp(standing_crown - 5, -100, 100),
        standing_rebels' = clamp(standing_rebels - 5, -100, 100),
        allied_faction'  = allied_faction,
    }

    // Do a quest for the Crown: gain 10, rivals lose 5
    action quest_crown = all {
        standing_guild'  = clamp(standing_guild - 5, -100, 100),
        standing_crown'  = clamp(standing_crown + 10, -100, 100),
        standing_rebels' = clamp(standing_rebels - 5, -100, 100),
        allied_faction'  = allied_faction,
    }

    // Do a quest for the Rebels: gain 10, rivals lose 5
    action quest_rebels = all {
        standing_guild'  = clamp(standing_guild - 5, -100, 100),
        standing_crown'  = clamp(standing_crown - 5, -100, 100),
        standing_rebels' = clamp(standing_rebels + 10, -100, 100),
        allied_faction'  = allied_faction,
    }

    // Betray current faction: negate standing with that faction (swap sign), clear alliance.
    // If no faction (allied_faction == 0), this is a stutter.
    action betray_current = all {
        standing_guild'  = if (allied_faction == 1) clamp(-standing_guild, -100, 100)   else standing_guild,
        standing_crown'  = if (allied_faction == 2) clamp(-standing_crown, -100, 100)   else standing_crown,
        standing_rebels' = if (allied_faction == 3) clamp(-standing_rebels, -100, 100)  else standing_rebels,
        allied_faction'  = 0,
    }

    action step = any {
        join_guild,
        join_crown,
        join_rebels,
        quest_guild,
        quest_crown,
        quest_rebels,
        betray_current,
    }

    // Invariants

    val standings_bounded: bool =
        standing_guild >= -100 and standing_guild <= 100 and
        standing_crown >= -100 and standing_crown <= 100 and
        standing_rebels >= -100 and standing_rebels <= 100

    val allied_faction_valid: bool =
        allied_faction >= 0 and allied_faction <= 3

    // Alliance and enemy derived predicates
    val is_allied_guild: bool   = standing_guild >= 75
    val is_allied_crown: bool   = standing_crown >= 75
    val is_allied_rebels: bool  = standing_rebels >= 75

    val is_enemy_guild: bool    = standing_guild <= -50
    val is_enemy_crown: bool    = standing_crown <= -50
    val is_enemy_rebels: bool   = standing_rebels <= -50

    // Cannot be both allied and enemy simultaneously
    val rivalry_consistent: bool =
        not(is_allied_guild and is_enemy_guild) and
        not(is_allied_crown and is_enemy_crown) and
        not(is_allied_rebels and is_enemy_rebels)
}

module faction_run {
    import faction.*
}
