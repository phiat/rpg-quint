module skill_tree {
  var skill_points: int
  var total_earned: int
  var strength: bool
  var agility: bool
  var power_strike: bool
  var quick_dodge: bool
  var whirlwind: bool
  var shadow_step: bool

  action init = all {
    skill_points' = 3,
    total_earned' = 3,
    strength' = false,
    agility' = false,
    power_strike' = false,
    quick_dodge' = false,
    whirlwind' = false,
    shadow_step' = false,
  }

  action unlock_strength = all {
    not(strength),
    skill_points >= 1,
    skill_points' = skill_points - 1,
    total_earned' = total_earned,
    strength' = true,
    agility' = agility,
    power_strike' = power_strike,
    quick_dodge' = quick_dodge,
    whirlwind' = whirlwind,
    shadow_step' = shadow_step,
  }

  action unlock_agility = all {
    not(agility),
    skill_points >= 1,
    skill_points' = skill_points - 1,
    total_earned' = total_earned,
    strength' = strength,
    agility' = true,
    power_strike' = power_strike,
    quick_dodge' = quick_dodge,
    whirlwind' = whirlwind,
    shadow_step' = shadow_step,
  }

  action unlock_power_strike = all {
    not(power_strike),
    strength,
    skill_points >= 2,
    skill_points' = skill_points - 2,
    total_earned' = total_earned,
    strength' = strength,
    agility' = agility,
    power_strike' = true,
    quick_dodge' = quick_dodge,
    whirlwind' = whirlwind,
    shadow_step' = shadow_step,
  }

  action unlock_quick_dodge = all {
    not(quick_dodge),
    agility,
    skill_points >= 2,
    skill_points' = skill_points - 2,
    total_earned' = total_earned,
    strength' = strength,
    agility' = agility,
    power_strike' = power_strike,
    quick_dodge' = true,
    whirlwind' = whirlwind,
    shadow_step' = shadow_step,
  }

  action unlock_whirlwind = all {
    not(whirlwind),
    power_strike,
    skill_points >= 3,
    skill_points' = skill_points - 3,
    total_earned' = total_earned,
    strength' = strength,
    agility' = agility,
    power_strike' = power_strike,
    quick_dodge' = quick_dodge,
    whirlwind' = true,
    shadow_step' = shadow_step,
  }

  action unlock_shadow_step = all {
    not(shadow_step),
    quick_dodge,
    skill_points >= 3,
    skill_points' = skill_points - 3,
    total_earned' = total_earned,
    strength' = strength,
    agility' = agility,
    power_strike' = power_strike,
    quick_dodge' = quick_dodge,
    whirlwind' = whirlwind,
    shadow_step' = true,
  }

  action earn_points(amount: int): bool = all {
    amount > 0,
    skill_points' = skill_points + amount,
    total_earned' = total_earned + amount,
    strength' = strength,
    agility' = agility,
    power_strike' = power_strike,
    quick_dodge' = quick_dodge,
    whirlwind' = whirlwind,
    shadow_step' = shadow_step,
  }

  val spent_points = (if (strength) 1 else 0)
              + (if (agility) 1 else 0)
              + (if (power_strike) 2 else 0)
              + (if (quick_dodge) 2 else 0)
              + (if (whirlwind) 3 else 0)
              + (if (shadow_step) 3 else 0)

  action respec = all {
    spent_points > 0,
    skill_points' = skill_points + spent_points,
    total_earned' = total_earned,
    strength' = false,
    agility' = false,
    power_strike' = false,
    quick_dodge' = false,
    whirlwind' = false,
    shadow_step' = false,
  }

  action blocked_no_prereq = any {
    // Try to unlock power_strike without strength
    all {
      not(power_strike),
      not(strength),
      skill_points >= 2,
      skill_points' = skill_points,
      total_earned' = total_earned,
      strength' = strength,
      agility' = agility,
      power_strike' = power_strike,
      quick_dodge' = quick_dodge,
      whirlwind' = whirlwind,
      shadow_step' = shadow_step,
    },
    // Try to unlock quick_dodge without agility
    all {
      not(quick_dodge),
      not(agility),
      skill_points >= 2,
      skill_points' = skill_points,
      total_earned' = total_earned,
      strength' = strength,
      agility' = agility,
      power_strike' = power_strike,
      quick_dodge' = quick_dodge,
      whirlwind' = whirlwind,
      shadow_step' = shadow_step,
    },
    // Try to unlock whirlwind without power_strike
    all {
      not(whirlwind),
      not(power_strike),
      skill_points >= 3,
      skill_points' = skill_points,
      total_earned' = total_earned,
      strength' = strength,
      agility' = agility,
      power_strike' = power_strike,
      quick_dodge' = quick_dodge,
      whirlwind' = whirlwind,
      shadow_step' = shadow_step,
    },
    // Try to unlock shadow_step without quick_dodge
    all {
      not(shadow_step),
      not(quick_dodge),
      skill_points >= 3,
      skill_points' = skill_points,
      total_earned' = total_earned,
      strength' = strength,
      agility' = agility,
      power_strike' = power_strike,
      quick_dodge' = quick_dodge,
      whirlwind' = whirlwind,
      shadow_step' = shadow_step,
    },
  }

  action step = any {
    unlock_strength,
    unlock_agility,
    unlock_power_strike,
    unlock_quick_dodge,
    unlock_whirlwind,
    unlock_shadow_step,
    nondet amount = oneOf(1.to(3))
    earn_points(amount),
    respec,
    blocked_no_prereq,
  }

  /// Prerequisites are always respected
  val prereqs_respected = and {
    power_strike.implies(strength),
    quick_dodge.implies(agility),
    whirlwind.implies(power_strike),
    shadow_step.implies(quick_dodge),
  }

  /// Points are conserved: available + spent == total earned
  val points_conserved = skill_points + spent_points == total_earned

  /// Skill points never go negative
  val points_non_negative = skill_points >= 0
}

module skill_tree_run {
  import skill_tree.*
}
