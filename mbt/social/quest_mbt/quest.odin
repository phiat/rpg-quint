package quest_mbt

// Quest system with 3 sequential quests, each with status and step tracking.

Quest_System :: struct {
	quest1_status: string,
	quest2_status: string,
	quest3_status: string,
	quest1_step:   int,
	quest2_step:   int,
	quest3_step:   int,
	quest1_max:    int,
	quest2_max:    int,
	quest3_max:    int,
}

unlock_quest :: proc(qs: ^Quest_System, quest: int) {
	switch quest {
	case 2:
		if qs.quest1_status == "complete" {
			qs.quest2_status = "active"
		}
	case 3:
		if qs.quest2_status == "complete" {
			qs.quest3_status = "active"
		}
	}
}

// Advance a quest's step. Returns true if the quest was active and advanced.
advance_quest :: proc(qs: ^Quest_System, quest: int) -> bool {
	switch quest {
	case 1:
		if qs.quest1_status != "active" do return false
		qs.quest1_step += 1
		if qs.quest1_step >= qs.quest1_max {
			qs.quest1_status = "complete"
		}
		return true
	case 2:
		if qs.quest2_status != "active" do return false
		qs.quest2_step += 1
		if qs.quest2_step >= qs.quest2_max {
			qs.quest2_status = "complete"
		}
		return true
	case 3:
		if qs.quest3_status != "active" do return false
		qs.quest3_step += 1
		if qs.quest3_step >= qs.quest3_max {
			qs.quest3_status = "complete"
		}
		return true
	}
	return false
}

fail_quest :: proc(qs: ^Quest_System, quest: int) {
	switch quest {
	case 1:
		if qs.quest1_status == "active" {
			qs.quest1_status = "failed"
		}
	case 2:
		if qs.quest2_status == "active" {
			qs.quest2_status = "failed"
		}
	case 3:
		if qs.quest3_status == "active" {
			qs.quest3_status = "failed"
		}
	}
}
