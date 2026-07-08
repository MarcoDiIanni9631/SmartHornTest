#!/usr/bin/env python3
"""
zmiout2json.py
Usage: python3 zmiout2json.py <contract.sol> <defs.txt> <analysis.zmiout>

Generates .test_cases.json combining Z3 and CLPQ projections.
Each script (zmiout2vars_z3.py, zmiout2vars_clpq.py) keeps its own responsibility;
this script only produces the JSON.
"""
import sys, os, json, importlib.util


def _load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod  = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _extract(test_block, blocks, state_vars, func_args, entry_pred, z3_mod, clpq_mod):
    n_args      = len(func_args)
    call_trace  = z3_mod.parse_call_trace(test_block)
    z3_model    = z3_mod.parse_z3_model(test_block)
    is_positive = 'testVerimapGood' in test_block

    trace_dict = {}
    for name, args in call_trace:
        if name not in trace_dict:
            trace_dict[name] = args

    new2_args = trace_dict.get(entry_pred)

    ref_env, ref_params = {}, []
    for cname in trace_dict:
        blk = z3_mod.find_block(blocks, cname)
        if blk and 'subO_' in blk:
            env = z3_mod.parse_env_slots(blk)
            if env:
                ref_env    = env
                ref_params = z3_mod.get_param_list(blk)
                break

    concrete_values = []
    rv_to_sol = {}

    chosen_name, chosen_locals, chosen_params = z3_mod.find_body_from_trace(
        trace_dict, blocks, n_args)
    if chosen_name is not None:
        body_args = trace_dict.get(chosen_name)
        for j, arg in enumerate(func_args):
            letter = chosen_locals.get(j)
            if letter and letter in chosen_params:
                pos = chosen_params.index(letter)
                if body_args and pos < len(body_args):
                    rv = body_args[pos]
                    rv_to_sol[rv] = arg
                    val = z3_model.get(rv)
                    if val is not None:
                        concrete_values.append(f"{arg} == {val}")

    if new2_args is not None and ref_env:
        offset = (len(new2_args) - n_args) // 2
        for i, var in enumerate(state_vars):
            letter = ref_env.get(i)
            if letter and letter in ref_params:
                pre_pos  = ref_params.index(letter)
                post_pos = pre_pos + offset
                if pre_pos < len(new2_args):
                    val = z3_model.get(new2_args[pre_pos])
                    if val is not None:
                        concrete_values.append(f"{var} == {val}")
                if post_pos < len(new2_args):
                    rv_to_sol[new2_args[post_pos]] = var

    raw         = z3_mod.parse_incorrect_line(test_block)
    clauses     = z3_mod.split_clauses(raw)
    raw_constrs = z3_mod.extract_var_constraints(clauses, rv_to_sol)

    z3_proj = z3_mod.project_constraints(raw_constrs, rv_to_sol, state_vars) if rv_to_sol else []

    try:
        clpq_proj = clpq_mod.project_constraints(raw_constrs, rv_to_sol) if rv_to_sol else []
    except Exception as e:
        clpq_proj = [f"(errore CLPQ: {e})"]

    return is_positive, concrete_values, z3_proj, clpq_proj


def main():
    if len(sys.argv) != 4:
        print("Usage: zmiout2json.py <contract.sol> <defs.txt> <analysis.zmiout>")
        sys.exit(1)

    sol_path    = sys.argv[1]
    defs_path   = sys.argv[2]
    zmiout_path = sys.argv[3]

    here     = os.path.dirname(os.path.abspath(__file__))
    z3_mod   = _load_module('_z3mod',   os.path.join(here, 'zmiout2vars_z3.py'))
    clpq_mod = _load_module('_clpqmod', os.path.join(here, 'zmiout2vars_clpq.py'))

    sol    = open(sol_path).read()
    defs   = open(defs_path).read()
    zmiout = open(zmiout_path).read()

    sol_stem = os.path.splitext(os.path.basename(sol_path))[0]

    blocks           = z3_mod.load_defs_blocks(defs)
    func, entry_pred = z3_mod.detect_func_and_entry(blocks)
    if not func:
        print("ERROR: function name not found")
        sys.exit(1)

    state_vars = z3_mod.parse_state_vars(sol)
    func_args  = z3_mod.parse_func_args(sol, func)
    func_sig   = z3_mod.build_func_signature(sol, func)

    tests = z3_mod.split_tests(zmiout)
    if not tests:
        tests = [zmiout]

    test_cases = []
    for i, test_block in enumerate(tests, 1):
        is_pos, concrete, z3_proj, clpq_proj = _extract(
            test_block, blocks, state_vars, func_args, entry_pred,
            z3_mod, clpq_mod)
        test_cases.append({
            "id": i,
            "kind": "positive" if is_pos else "negative",
            "concrete_values": concrete,
            "constraints_z3": z3_proj,
            "constraints_clpq": clpq_proj,
        })

    json_data = {
        "stateVariables": state_vars,
        "functions": [{
            "signature": func_sig,
            "params": func_args,
            "test_cases": test_cases,
        }],
    }
    json_path = os.path.join(os.path.dirname(zmiout_path), sol_stem + ".test_cases.json")
    with open(json_path, 'w') as f:
        json.dump(json_data, f, indent=2)
    print(f"JSON scritto in: {json_path}")


if __name__ == '__main__':
    main()
