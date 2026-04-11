package skill_tree_mbt

Skill_Tree :: struct {
	skill_points:  int,
	total_earned:  int,
	strength:      bool,
	agility:       bool,
	power_strike:  bool,
	quick_dodge:   bool,
	whirlwind:     bool,
	shadow_step:   bool,
}

unlock_strength :: proc(st: ^Skill_Tree) -> bool {
	if st.strength || st.skill_points < 1 do return false
	st.skill_points -= 1
	st.strength = true
	return true
}

unlock_agility :: proc(st: ^Skill_Tree) -> bool {
	if st.agility || st.skill_points < 1 do return false
	st.skill_points -= 1
	st.agility = true
	return true
}

unlock_power_strike :: proc(st: ^Skill_Tree) -> bool {
	if st.power_strike || !st.strength || st.skill_points < 2 do return false
	st.skill_points -= 2
	st.power_strike = true
	return true
}

unlock_quick_dodge :: proc(st: ^Skill_Tree) -> bool {
	if st.quick_dodge || !st.agility || st.skill_points < 2 do return false
	st.skill_points -= 2
	st.quick_dodge = true
	return true
}

unlock_whirlwind :: proc(st: ^Skill_Tree) -> bool {
	if st.whirlwind || !st.power_strike || st.skill_points < 3 do return false
	st.skill_points -= 3
	st.whirlwind = true
	return true
}

unlock_shadow_step :: proc(st: ^Skill_Tree) -> bool {
	if st.shadow_step || !st.quick_dodge || st.skill_points < 3 do return false
	st.skill_points -= 3
	st.shadow_step = true
	return true
}

earn_points :: proc(st: ^Skill_Tree, amount: int) {
	st.skill_points += amount
	st.total_earned += amount
}

respec :: proc(st: ^Skill_Tree) -> bool {
	spent := 0
	if st.strength     do spent += 1
	if st.agility      do spent += 1
	if st.power_strike do spent += 2
	if st.quick_dodge  do spent += 2
	if st.whirlwind    do spent += 3
	if st.shadow_step  do spent += 3
	if spent == 0 do return false
	st.skill_points += spent
	st.strength = false
	st.agility = false
	st.power_strike = false
	st.quick_dodge = false
	st.whirlwind = false
	st.shadow_step = false
	return true
}
