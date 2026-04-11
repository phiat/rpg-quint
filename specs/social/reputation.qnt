module reputation {
    pure def clamp(v: int, lo: int, hi: int): int =
        if (v < lo) lo else if (v > hi) hi else v

    var rep_warriors: int
    var rep_mages: int
    var rep_thieves: int

    action init = all {
        rep_warriors' = 0,
        rep_mages' = 0,
        rep_thieves' = 0,
    }

    action help_warriors(amount: int): bool = all {
        rep_warriors' = clamp(rep_warriors + amount, -100, 100),
        rep_mages' = rep_mages,
        rep_thieves' = clamp(rep_thieves - amount, -100, 100),
    }

    action help_mages(amount: int): bool = all {
        rep_warriors' = rep_warriors,
        rep_mages' = clamp(rep_mages + amount, -100, 100),
        rep_thieves' = rep_thieves,
    }

    action help_thieves(amount: int): bool = all {
        rep_warriors' = clamp(rep_warriors - amount, -100, 100),
        rep_mages' = rep_mages,
        rep_thieves' = clamp(rep_thieves + amount, -100, 100),
    }

    action betray_warriors: bool = all {
        rep_warriors' = clamp(rep_warriors - 50, -100, 100),
        rep_mages' = rep_mages,
        rep_thieves' = clamp(rep_thieves + 25, -100, 100),
    }

    action betray_thieves: bool = all {
        rep_warriors' = clamp(rep_warriors + 25, -100, 100),
        rep_mages' = rep_mages,
        rep_thieves' = clamp(rep_thieves - 50, -100, 100),
    }

    action step = {
        nondet amount = 5.to(20).oneOf()
        any {
            help_warriors(amount),
            help_mages(amount),
            help_thieves(amount),
            betray_warriors,
            betray_thieves,
        }
    }

    val standings_bounded: bool =
        rep_warriors >= -100 and rep_warriors <= 100 and
        rep_mages >= -100 and rep_mages <= 100 and
        rep_thieves >= -100 and rep_thieves <= 100
}

module reputation_run {
  import reputation.*
}
