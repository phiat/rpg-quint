// Quint specification for a Dialogue Tree system.
// Models a 5-node dialogue tree: 0=start, 1-3=branches, 4=end.
// The player enters dialogue, chooses a branch, advances to the end, then exits.
// Each branch has a reputation effect: branch1 +5, branch2 -5, branch3 0.
module dialogue {

  // --- State ---
  var current_node:      int   // 0=start, 1=branch1, 2=branch2, 3=branch3, 4=end
  var in_dialogue:       bool  // whether the player is currently in dialogue
  var choices_made:      int   // total number of branch choices made (non-decreasing)
  var visited_1:         bool  // true if branch 1 was ever visited
  var visited_2:         bool  // true if branch 2 was ever visited
  var visited_3:         bool  // true if branch 3 was ever visited
  var reputation_change: int   // accumulated reputation delta

  // --- Init ---
  action init = all {
    current_node'      = 0,
    in_dialogue'       = false,
    choices_made'      = 0,
    visited_1'         = false,
    visited_2'         = false,
    visited_3'         = false,
    reputation_change' = 0,
  }

  // --- Actions ---

  // Enter dialogue at start node (node 0)
  action start_dialogue = all {
    not(in_dialogue),
    current_node'      = 0,
    in_dialogue'       = true,
    choices_made'      = choices_made,
    visited_1'         = visited_1,
    visited_2'         = visited_2,
    visited_3'         = visited_3,
    reputation_change' = reputation_change,
  }

  // Choose branch 1 from start node (node 0 -> node 1, reputation +5)
  action choose_branch_1 = all {
    in_dialogue,
    current_node == 0,
    current_node'      = 1,
    in_dialogue'       = in_dialogue,
    choices_made'      = choices_made + 1,
    visited_1'         = true,
    visited_2'         = visited_2,
    visited_3'         = visited_3,
    reputation_change' = reputation_change + 5,
  }

  // Choose branch 2 from start node (node 0 -> node 2, reputation -5)
  action choose_branch_2 = all {
    in_dialogue,
    current_node == 0,
    current_node'      = 2,
    in_dialogue'       = in_dialogue,
    choices_made'      = choices_made + 1,
    visited_1'         = visited_1,
    visited_2'         = true,
    visited_3'         = visited_3,
    reputation_change' = reputation_change - 5,
  }

  // Choose branch 3 from start node (node 0 -> node 3, reputation 0)
  action choose_branch_3 = all {
    in_dialogue,
    current_node == 0,
    current_node'      = 3,
    in_dialogue'       = in_dialogue,
    choices_made'      = choices_made + 1,
    visited_1'         = visited_1,
    visited_2'         = visited_2,
    visited_3'         = true,
    reputation_change' = reputation_change,
  }

  // Advance from a branch node (1, 2, or 3) to the end node (4)
  action advance_to_end = all {
    in_dialogue,
    current_node >= 1 and current_node <= 3,
    current_node'      = 4,
    in_dialogue'       = in_dialogue,
    choices_made'      = choices_made,
    visited_1'         = visited_1,
    visited_2'         = visited_2,
    visited_3'         = visited_3,
    reputation_change' = reputation_change,
  }

  // End dialogue from the end node (node 4), exit dialogue
  action end_dialogue = all {
    in_dialogue,
    current_node == 4,
    current_node'      = 0,
    in_dialogue'       = false,
    choices_made'      = choices_made,
    visited_1'         = visited_1,
    visited_2'         = visited_2,
    visited_3'         = visited_3,
    reputation_change' = reputation_change,
  }

  // Nondeterministic step
  action step = any {
    start_dialogue,
    choose_branch_1,
    choose_branch_2,
    choose_branch_3,
    advance_to_end,
    end_dialogue,
  }

  // --- Invariants ---

  // Node is always in valid range [0, 4]
  val node_bounded: bool =
    current_node >= 0 and current_node <= 4

  // choices_made is non-negative
  val choices_non_negative: bool =
    choices_made >= 0

  // Being at a non-zero node implies being in dialogue
  val in_dialogue_consistent: bool =
    (current_node > 0) implies in_dialogue

  // If we visited a branch, choices_made is at least 1
  val visited_implies_choice: bool =
    (visited_1 or visited_2 or visited_3) implies choices_made >= 1
}

// Runner module
module dialogue_run {
  import dialogue.*
}
