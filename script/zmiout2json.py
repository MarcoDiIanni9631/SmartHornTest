#!/usr/bin/env python3
"""
zmiout2json.py
Usage: python3 zmiout2json.py <contract.sol> <defs.txt> <analysis.zmiout>

Generates .test_cases.json combining Z3 and CLP(Q) projections.
"""
import sys, os, json, importlib.util


def _load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod  = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main():
    if len(sys.argv) != 4:
        print("Usage: zmiout2json.py <contract.sol> <defs.txt> <analysis.zmiout>")
        sys.exit(1)

    sol_path    = sys.argv[1]
    defs_path   = sys.argv[2]
    zmiout_path = sys.argv[3]

    here      = os.path.dirname(os.path.abspath(__file__))
    parse_mod = _load_module('_parse',   os.path.join(here, 'zmiout_parse.py'))
    z3_mod    = _load_module('_z3mod',   os.path.join(here, 'zmiout2vars_z3.py'))
    clpq_mod  = _load_module('_clpqmod', os.path.join(here, 'zmiout2vars_clpq.py'))

    sol    = open(sol_path).read()
    defs   = open(defs_path).read()
    zmiout = open(zmiout_path).read()

    sol_stem = os.path.splitext(os.path.basename(sol_path))[0]
    aux_path = os.path.join(os.path.dirname(sol_path), sol_stem + ".aux.pl")
    t_constr_path = os.path.join(os.path.dirname(sol_path), sol_stem + ".t_constr.pl")
    t_constr_text = open(t_constr_path).read() if os.path.isfile(t_constr_path) else None

    blocks           = parse_mod.load_defs_blocks(defs)
    func, entry_pred = parse_mod.detect_func_and_entry(blocks, aux_path)
    if not func:
        print("ERROR: function name not found")
        sys.exit(1)

    contract_name = parse_mod.parse_contract_name(sol)
    state_vars    = parse_mod.parse_state_vars(sol)
    func_args     = parse_mod.parse_func_args(sol, func)
    func_sig      = parse_mod.build_func_signature(sol, func)
    arg_types     = parse_mod.parse_func_arg_types(sol, func)

    # no test (nonDerivable, timeout): the json only says "no test found"
    tests = parse_mod.split_tests(zmiout)

    test_cases = []
    for i, test_block in enumerate(tests, 1):
        is_pos, concrete, rv_to_sol, raw_constrs, rv_start = parse_mod.resolve_test(
            test_block, blocks, state_vars, func_args, entry_pred, func, t_constr_text,
            arg_types=arg_types, with_start=True)

        z3_proj = z3_mod.project_constraints(raw_constrs, rv_to_sol, state_vars) \
                  if rv_to_sol else []
        try:
            clpq_proj = clpq_mod.project_constraints(raw_constrs, rv_to_sol) \
                        if rv_to_sol else []
        except Exception as e:
            clpq_proj = [f"(CLP(Q) error: {e})"]

        # the same constraints, with the state variables at the start of
        # the call (the fields above have them where the assert fails)
        z3_start = z3_mod.project_constraints(raw_constrs, rv_start, state_vars) \
                   if rv_start else []
        try:
            clpq_start = clpq_mod.project_constraints(raw_constrs, rv_start) \
                         if rv_start else []
        except Exception as e:
            clpq_start = [f"(CLP(Q) error: {e})"]

        test_cases.append({
            "id":                i,
            "kind":              "positive" if is_pos else "negative",
            "concrete_values":   concrete,
            "constraints_z3":    z3_proj,
            "constraints_clpq":  clpq_proj,
            "constraints_z3_start":   z3_start,
            "constraints_clpq_start": clpq_start,
        })

    json_data = {
        "contractName":   contract_name,
        "stateVariables": state_vars,
        "functions": [{
            "signature":  func_sig,
            "params":     func_args,
            "test_cases": test_cases,
        }],
    }

    if not test_cases:
        json_data = {"result": parse_mod.no_test_message(zmiout_path)}

    json_path = os.path.join(os.path.dirname(zmiout_path), sol_stem + ".test_cases.json")
    with open(json_path, 'w') as f:
        json.dump(json_data, f, indent=2)
    print(f"JSON written to: {json_path}")


if __name__ == '__main__':
    main()
