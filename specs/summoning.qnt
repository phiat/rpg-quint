module summoning {
  var slot1_active: bool
  var slot1_hp: int
  var slot1_dur: int
  var slot2_active: bool
  var slot2_hp: int
  var slot2_dur: int
  var slot3_active: bool
  var slot3_hp: int
  var slot3_dur: int
  var active_count: int

  action init = all {
    slot1_active' = false,
    slot1_hp' = 0,
    slot1_dur' = 0,
    slot2_active' = false,
    slot2_hp' = 0,
    slot2_dur' = 0,
    slot3_active' = false,
    slot3_hp' = 0,
    slot3_dur' = 0,
    active_count' = 0,
  }

  action summon_slot1(hp: int, dur: int): bool = all {
    not(slot1_active),
    slot1_active' = true,
    slot1_hp' = hp,
    slot1_dur' = dur,
    slot2_active' = slot2_active,
    slot2_hp' = slot2_hp,
    slot2_dur' = slot2_dur,
    slot3_active' = slot3_active,
    slot3_hp' = slot3_hp,
    slot3_dur' = slot3_dur,
    active_count' = active_count + 1,
  }

  action summon_slot2(hp: int, dur: int): bool = all {
    not(slot2_active),
    slot2_active' = true,
    slot2_hp' = hp,
    slot2_dur' = dur,
    slot1_active' = slot1_active,
    slot1_hp' = slot1_hp,
    slot1_dur' = slot1_dur,
    slot3_active' = slot3_active,
    slot3_hp' = slot3_hp,
    slot3_dur' = slot3_dur,
    active_count' = active_count + 1,
  }

  action summon_slot3(hp: int, dur: int): bool = all {
    not(slot3_active),
    slot3_active' = true,
    slot3_hp' = hp,
    slot3_dur' = dur,
    slot1_active' = slot1_active,
    slot1_hp' = slot1_hp,
    slot1_dur' = slot1_dur,
    slot2_active' = slot2_active,
    slot2_hp' = slot2_hp,
    slot2_dur' = slot2_dur,
    active_count' = active_count + 1,
  }

  action tick_duration: bool = all {
    slot1_active' = if (slot1_active and slot1_dur - 1 <= 0) false else slot1_active,
    slot1_hp' = if (slot1_active and slot1_dur - 1 <= 0) 0 else slot1_hp,
    slot1_dur' = if (not(slot1_active)) 0 else if (slot1_dur - 1 <= 0) 0 else slot1_dur - 1,
    slot2_active' = if (slot2_active and slot2_dur - 1 <= 0) false else slot2_active,
    slot2_hp' = if (slot2_active and slot2_dur - 1 <= 0) 0 else slot2_hp,
    slot2_dur' = if (not(slot2_active)) 0 else if (slot2_dur - 1 <= 0) 0 else slot2_dur - 1,
    slot3_active' = if (slot3_active and slot3_dur - 1 <= 0) false else slot3_active,
    slot3_hp' = if (slot3_active and slot3_dur - 1 <= 0) 0 else slot3_hp,
    slot3_dur' = if (not(slot3_active)) 0 else if (slot3_dur - 1 <= 0) 0 else slot3_dur - 1,
    active_count' = {
      val c1 = if (slot1_active and slot1_dur - 1 > 0) 1 else 0
      val c2 = if (slot2_active and slot2_dur - 1 > 0) 1 else 0
      val c3 = if (slot3_active and slot3_dur - 1 > 0) 1 else 0
      c1 + c2 + c3
    },
  }

  action dismiss_slot1: bool = all {
    slot1_active,
    slot1_active' = false,
    slot1_hp' = 0,
    slot1_dur' = 0,
    slot2_active' = slot2_active,
    slot2_hp' = slot2_hp,
    slot2_dur' = slot2_dur,
    slot3_active' = slot3_active,
    slot3_hp' = slot3_hp,
    slot3_dur' = slot3_dur,
    active_count' = active_count - 1,
  }

  action dismiss_slot2: bool = all {
    slot2_active,
    slot2_active' = false,
    slot2_hp' = 0,
    slot2_dur' = 0,
    slot1_active' = slot1_active,
    slot1_hp' = slot1_hp,
    slot1_dur' = slot1_dur,
    slot3_active' = slot3_active,
    slot3_hp' = slot3_hp,
    slot3_dur' = slot3_dur,
    active_count' = active_count - 1,
  }

  action dismiss_slot3: bool = all {
    slot3_active,
    slot3_active' = false,
    slot3_hp' = 0,
    slot3_dur' = 0,
    slot1_active' = slot1_active,
    slot1_hp' = slot1_hp,
    slot1_dur' = slot1_dur,
    slot2_active' = slot2_active,
    slot2_hp' = slot2_hp,
    slot2_dur' = slot2_dur,
    active_count' = active_count - 1,
  }

  action blocked_summon_full: bool = all {
    active_count >= 3,
    slot1_active' = slot1_active,
    slot1_hp' = slot1_hp,
    slot1_dur' = slot1_dur,
    slot2_active' = slot2_active,
    slot2_hp' = slot2_hp,
    slot2_dur' = slot2_dur,
    slot3_active' = slot3_active,
    slot3_hp' = slot3_hp,
    slot3_dur' = slot3_dur,
    active_count' = active_count,
  }

  action step: bool = {
    nondet hp = 10.to(30).oneOf()
    nondet dur = 2.to(5).oneOf()
    any {
      summon_slot1(hp, dur),
      summon_slot2(hp, dur),
      summon_slot3(hp, dur),
      tick_duration,
      dismiss_slot1,
      dismiss_slot2,
      dismiss_slot3,
      blocked_summon_full,
    }
  }

  val count_consistent: bool = {
    val c1 = if (slot1_active) 1 else 0
    val c2 = if (slot2_active) 1 else 0
    val c3 = if (slot3_active) 1 else 0
    active_count == c1 + c2 + c3
  }

  val slots_bounded: bool = active_count <= 3

  val inactive_zeroed: bool = and {
    not(slot1_active) implies (slot1_hp == 0 and slot1_dur == 0),
    not(slot2_active) implies (slot2_hp == 0 and slot2_dur == 0),
    not(slot3_active) implies (slot3_hp == 0 and slot3_dur == 0),
  }

  val durations_non_negative: bool = and {
    slot1_dur >= 0,
    slot2_dur >= 0,
    slot3_dur >= 0,
  }
}

module summoning_run {
  import summoning.*
}
