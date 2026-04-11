package quint_mbt

import "core:encoding/json"
import "core:os"
import "core:strconv"
import "core:strings"

// ITF value types — mirrors the tagged-value encoding in Apalache ITF format
ITF_Value :: union {
	ITF_Int,
	ITF_Str,
	ITF_Bool,
	ITF_List,
	ITF_None,
}

ITF_Int :: struct {
	value: int,
}
ITF_Str :: struct {
	value: string,
}
ITF_Bool :: struct {
	value: bool,
}
ITF_List :: struct {
	items: [dynamic]ITF_Value,
}
ITF_None :: struct {}

// A single state in the trace
ITF_State :: struct {
	index:        int,
	action_taken: string,
	nondet_picks: map[string]ITF_Value,
	vars:         map[string]ITF_Value,
}

// Top-level trace
ITF_Trace :: struct {
	states: [dynamic]ITF_State,
}

Parse_Error :: enum {
	None,
	File_Read_Failed,
	JSON_Parse_Failed,
	Invalid_Structure,
}

// Parse an ITF trace from a file path
parse_itf_file :: proc(path: string, allocator := context.allocator) -> (ITF_Trace, Parse_Error) {
	data, err := os.read_entire_file(path, allocator)
	if err != nil {
		return {}, .File_Read_Failed
	}
	defer delete(data, allocator)
	return parse_itf_bytes(data, allocator)
}

// Parse ITF trace from raw bytes
parse_itf_bytes :: proc(data: []byte, allocator := context.allocator) -> (ITF_Trace, Parse_Error) {
	root, err := json.parse(data, .JSON, false, allocator)
	if err != .None {
		return {}, .JSON_Parse_Failed
	}
	defer json.destroy_value(root)

	root_obj, ok := root.(json.Object)
	if !ok {
		return {}, .Invalid_Structure
	}

	states_val, has_states := root_obj["states"]
	if !has_states {
		return {}, .Invalid_Structure
	}

	states_arr, states_ok := states_val.(json.Array)
	if !states_ok {
		return {}, .Invalid_Structure
	}

	trace: ITF_Trace
	trace.states = make([dynamic]ITF_State, 0, len(states_arr), allocator)

	for state_val in states_arr {
		state_obj, is_obj := state_val.(json.Object)
		if !is_obj do continue

		state := parse_state(state_obj, allocator)
		append(&trace.states, state)
	}

	return trace, .None
}

// Parse a single state object from the ITF JSON
parse_state :: proc(obj: json.Object, allocator := context.allocator) -> ITF_State {
	state: ITF_State
	state.vars = make(map[string]ITF_Value, allocator = allocator)
	state.nondet_picks = make(map[string]ITF_Value, allocator = allocator)

	// Extract index from #meta
	if meta_val, has_meta := obj["#meta"]; has_meta {
		if meta_obj, meta_ok := meta_val.(json.Object); meta_ok {
			if idx_val, has_idx := meta_obj["index"]; has_idx {
				if idx_int, idx_ok := idx_val.(json.Integer); idx_ok {
					state.index = int(idx_int)
				}
			}
		}
	}

	// Extract action taken
	if action_val, has_action := obj["mbt::actionTaken"]; has_action {
		if action_str, action_ok := action_val.(json.String); action_ok {
			state.action_taken = strings.clone(action_str, allocator)
		}
	}

	// Extract nondet picks
	if picks_val, has_picks := obj["mbt::nondetPicks"]; has_picks {
		if picks_obj, picks_ok := picks_val.(json.Object); picks_ok {
			for key, val in picks_obj {
				itf_val := convert_json_value(val, allocator)
				state.nondet_picks[strings.clone(key, allocator)] = itf_val
			}
		}
	}

	// Extract state variables (skip mbt:: and #meta keys)
	for key, val in obj {
		if strings.has_prefix(key, "mbt::") do continue
		if key == "#meta" do continue

		// Strip namespace prefix: "rpg_run::rpg::hp" -> "hp"
		short_key := strip_namespace(key)
		state.vars[strings.clone(short_key, allocator)] = convert_json_value(val, allocator)
	}

	return state
}

// Convert a json.Value to an ITF_Value, handling ITF-specific encodings
convert_json_value :: proc(val: json.Value, allocator := context.allocator) -> ITF_Value {
	switch v in val {
	case json.Null:
		return ITF_None{}
	case json.Boolean:
		return ITF_Bool{bool(v)}
	case json.Integer:
		return ITF_Int{int(v)}
	case json.Float:
		return ITF_Int{int(v)}
	case json.String:
		return ITF_Str{strings.clone(string(v), allocator)}
	case json.Array:
		list := ITF_List{}
		list.items = make([dynamic]ITF_Value, 0, len(v), allocator)
		for elem in v {
			append(&list.items, convert_json_value(elem, allocator))
		}
		return list
	case json.Object:
		obj := json.Object(v)
		// Check for #bigint encoding: {"#bigint": "25"}
		if bigint_val, has_bigint := obj["#bigint"]; has_bigint {
			if bigint_str, str_ok := bigint_val.(json.String); str_ok {
				n, parse_ok := strconv.parse_int(string(bigint_str))
				if parse_ok {
					return ITF_Int{n}
				}
			}
		}
		// Check for tagged variant: {"tag": "Some", "value": ...} or {"tag": "None", ...}
		if tag_val, has_tag := obj["tag"]; has_tag {
			if tag_str, tag_ok := tag_val.(json.String); tag_ok {
				if string(tag_str) == "None" {
					return ITF_None{}
				}
				if string(tag_str) == "Some" {
					if inner_val, has_inner := obj["value"]; has_inner {
						return convert_json_value(inner_val, allocator)
					}
				}
			}
		}
		// Check for #tup encoding: {"#tup": [...]}
		if tup_val, has_tup := obj["#tup"]; has_tup {
			if tup_arr, tup_ok := tup_val.(json.Array); tup_ok {
				list := ITF_List{}
				list.items = make([dynamic]ITF_Value, 0, len(tup_arr), allocator)
				for elem in tup_arr {
					append(&list.items, convert_json_value(elem, allocator))
				}
				return list
			}
		}
		// Check for #set encoding: {"#set": [...]}
		if set_val, has_set := obj["#set"]; has_set {
			if set_arr, set_ok := set_val.(json.Array); set_ok {
				list := ITF_List{}
				list.items = make([dynamic]ITF_Value, 0, len(set_arr), allocator)
				for elem in set_arr {
					append(&list.items, convert_json_value(elem, allocator))
				}
				return list
			}
		}
		// Fallback: unknown object, return None
		return ITF_None{}
	}
	return ITF_None{}
}

// Strip namespace prefixes: "rpg_run::rpg::hp" -> "hp"
strip_namespace :: proc(key: string) -> string {
	last_sep := strings.last_index(key, "::")
	if last_sep >= 0 && last_sep + 2 < len(key) {
		return key[last_sep + 2:]
	}
	return key
}

// Helper: extract int from ITF_Value
value_as_int :: proc(v: ITF_Value) -> (int, bool) {
	if val, ok := v.(ITF_Int); ok {
		return val.value, true
	}
	return 0, false
}

// Helper: extract string from ITF_Value
value_as_str :: proc(v: ITF_Value) -> (string, bool) {
	if val, ok := v.(ITF_Str); ok {
		return val.value, true
	}
	return "", false
}

// Helper: extract list from ITF_Value
value_as_list :: proc(v: ITF_Value) -> ([]ITF_Value, bool) {
	if val, ok := v.(ITF_List); ok {
		return val.items[:], true
	}
	return nil, false
}

// Helper: check if value is None
value_is_none :: proc(v: ITF_Value) -> bool {
	_, ok := v.(ITF_None)
	return ok
}
