// Quint specification for a Quest/Objective tracking system
// Models 3 quests with prerequisite chains and multi-step objectives.
// Quest states: "locked", "active", "complete", "failed"
// Objectives must be completed in order within each quest.
// Quests unlock when their prerequisite quest is complete.
module quest {
  // --- State ---
  var quest1_status: str   // no prereqs, starts active
  var quest2_status: str   // prereq: quest1 complete
  var quest3_status: str   // prereq: quest2 complete
  var quest1_step: int     // 0..2 objectives
  var quest2_step: int     // 0..3 objectives
  var quest3_step: int     // 0..2 objectives

  // --- Init ---
  action init = all {
    quest1_status' = "active",
    quest2_status' = "locked",
    quest3_status' = "locked",
    quest1_step' = 0,
    quest2_step' = 0,
    quest3_step' = 0,
  }

  // --- Actions ---

  // Unlock quest2 when quest1 is complete
  action unlock_quest2 = all {
    quest1_status == "complete",
    quest2_status == "locked",
    quest2_status' = "active",
    quest1_status' = quest1_status,
    quest3_status' = quest3_status,
    quest1_step' = quest1_step,
    quest2_step' = quest2_step,
    quest3_step' = quest3_step,
  }

  // Unlock quest3 when quest2 is complete
  action unlock_quest3 = all {
    quest2_status == "complete",
    quest3_status == "locked",
    quest3_status' = "active",
    quest1_status' = quest1_status,
    quest2_status' = quest2_status,
    quest1_step' = quest1_step,
    quest2_step' = quest2_step,
    quest3_step' = quest3_step,
  }

  // Advance quest1: increment step, complete at 2
  action advance_quest1 = all {
    quest1_status == "active",
    quest1_step < 2,
    quest1_step' = quest1_step + 1,
    quest1_status' = if (quest1_step + 1 == 2) "complete" else quest1_status,
    quest2_status' = quest2_status,
    quest3_status' = quest3_status,
    quest2_step' = quest2_step,
    quest3_step' = quest3_step,
  }

  // Advance quest2: increment step, complete at 3
  action advance_quest2 = all {
    quest2_status == "active",
    quest2_step < 3,
    quest2_step' = quest2_step + 1,
    quest2_status' = if (quest2_step + 1 == 3) "complete" else quest2_status,
    quest1_status' = quest1_status,
    quest3_status' = quest3_status,
    quest1_step' = quest1_step,
    quest3_step' = quest3_step,
  }

  // Advance quest3: increment step, complete at 2
  action advance_quest3 = all {
    quest3_status == "active",
    quest3_step < 2,
    quest3_step' = quest3_step + 1,
    quest3_status' = if (quest3_step + 1 == 2) "complete" else quest3_status,
    quest1_status' = quest1_status,
    quest2_status' = quest2_status,
    quest1_step' = quest1_step,
    quest2_step' = quest2_step,
  }

  // Fail quest1: active quest can fail
  action fail_quest1 = all {
    quest1_status == "active",
    quest1_status' = "failed",
    quest2_status' = quest2_status,
    quest3_status' = quest3_status,
    quest1_step' = quest1_step,
    quest2_step' = quest2_step,
    quest3_step' = quest3_step,
  }

  // Blocked: try to advance a locked quest — no state change
  action blocked_advance_locked = all {
    quest1_status == "locked" or quest2_status == "locked" or quest3_status == "locked",
    quest1_status' = quest1_status,
    quest2_status' = quest2_status,
    quest3_status' = quest3_status,
    quest1_step' = quest1_step,
    quest2_step' = quest2_step,
    quest3_step' = quest3_step,
  }

  // Nondeterministic step
  action step = any {
    advance_quest1,
    advance_quest2,
    advance_quest3,
    unlock_quest2,
    unlock_quest3,
    fail_quest1,
    blocked_advance_locked,
  }

  // --- Invariants ---

  // Prerequisites are always respected
  val prereqs_respected = and {
    (quest2_status == "active" or quest2_status == "complete") implies quest1_status == "complete",
    (quest3_status == "active" or quest3_status == "complete") implies quest2_status == "complete",
  }

  // No quest can be both complete and failed (structural)
  val no_complete_and_failed = and {
    not(quest1_status == "complete" and quest1_status == "failed"),
    not(quest2_status == "complete" and quest2_status == "failed"),
    not(quest3_status == "complete" and quest3_status == "failed"),
  }

  // Step counts stay within bounds
  val steps_bounded = and {
    quest1_step >= 0 and quest1_step <= 2,
    quest2_step >= 0 and quest2_step <= 3,
    quest3_step >= 0 and quest3_step <= 2,
  }

  // Completion implies all objectives are done
  val complete_means_done = and {
    quest1_status == "complete" implies quest1_step == 2,
    quest2_status == "complete" implies quest2_step == 3,
    quest3_status == "complete" implies quest3_step == 2,
  }

  // Once complete, a quest stays complete (no revert)
  // This is structural: no action changes a "complete" status to anything else
  val monotonic_completion = and {
    quest1_status == "complete" implies quest1_status == "complete",
    quest2_status == "complete" implies quest2_status == "complete",
    quest3_status == "complete" implies quest3_status == "complete",
  }
}

// Runner module
module quest_run {
  import quest.*
}
