package quint_mbt

import "core:fmt"
import "core:strings"

// Callback types for the MBT driver
Step_Handler :: #type proc(driver: rawptr, action: string, picks: map[string]ITF_Value) -> bool
State_Getter :: #type proc(driver: rawptr) -> map[string]ITF_Value

// A single mismatch between expected (spec) and actual (implementation) state
Mismatch :: struct {
	step:     int,
	var_name: string,
	expected: string, // string representation for reporting
	actual:   string,
}

// Result of replaying a trace
MBT_Result :: struct {
	total_steps: int,
	passed:      int,
	failed:      int,
	errors:      [dynamic]Mismatch,
}

// Replay an ITF trace against an implementation via callbacks
replay_trace :: proc(
	trace: ^ITF_Trace,
	driver: rawptr,
	on_step: Step_Handler,
	get_state: State_Getter,
) -> MBT_Result {
	result: MBT_Result
	result.errors = make([dynamic]Mismatch)

	for &state in trace.states {
		result.total_steps += 1

		// Execute the action
		on_step(driver, state.action_taken, state.nondet_picks)

		// Get implementation state
		actual := get_state(driver)
		defer delete(actual)

		// Compare each variable
		step_ok := true
		for var_name, expected_val in state.vars {
			actual_val, has_actual := actual[var_name]
			if !has_actual {
				append(&result.errors, Mismatch{
					step     = state.index,
					var_name = var_name,
					expected = format_value(expected_val),
					actual   = "<missing>",
				})
				step_ok = false
				continue
			}
			if !values_equal(expected_val, actual_val) {
				append(&result.errors, Mismatch{
					step     = state.index,
					var_name = var_name,
					expected = format_value(expected_val),
					actual   = format_value(actual_val),
				})
				step_ok = false
			}
		}

		if step_ok {
			result.passed += 1
		} else {
			result.failed += 1
		}
	}

	return result
}

// Compare two ITF values for equality
values_equal :: proc(a, b: ITF_Value) -> bool {
	switch va in a {
	case ITF_Int:
		if vb, ok := b.(ITF_Int); ok {
			return va.value == vb.value
		}
	case ITF_Str:
		if vb, ok := b.(ITF_Str); ok {
			return va.value == vb.value
		}
	case ITF_Bool:
		if vb, ok := b.(ITF_Bool); ok {
			return va.value == vb.value
		}
	case ITF_List:
		if vb, ok := b.(ITF_List); ok {
			if len(va.items) != len(vb.items) do return false
			for i in 0 ..< len(va.items) {
				if !values_equal(va.items[i], vb.items[i]) do return false
			}
			return true
		}
	case ITF_None:
		if _, ok := b.(ITF_None); ok {
			return true
		}
	}
	return false
}

// Format an ITF value as a human-readable string
format_value :: proc(v: ITF_Value) -> string {
	switch val in v {
	case ITF_Int:
		return fmt.aprintf("%d", val.value)
	case ITF_Str:
		return fmt.aprintf("\"%s\"", val.value)
	case ITF_Bool:
		return fmt.aprintf("%v", val.value)
	case ITF_List:
		parts := make([dynamic]string)
		defer delete(parts)
		for item in val.items {
			append(&parts, format_value(item))
		}
		joined := strings.join(parts[:], ", ")
		result := fmt.aprintf("[%s]", joined)
		delete(joined)
		return result
	case ITF_None:
		return "None"
	}
	return "<unknown>"
}

// Print a summary of the MBT result
print_result :: proc(result: ^MBT_Result) {
	fmt.printf("MBT Replay: %d steps, %d passed, %d failed\n",
		result.total_steps, result.passed, result.failed)
	for &err in result.errors {
		fmt.printf("  MISMATCH at step %d, var '%s': expected %s, got %s\n",
			err.step, err.var_name, err.expected, err.actual)
	}
}
