#!/usr/bin/env python3
"""
solcmc_zmiout2json.py: writes the .test_cases.json of a contract analysed
through the SolCMC route (solc CHC query -> smt2map -> smt2pl_to_constr.pl ->
interpreter), with Solidity names, in the same format as zmiout2json.py.

Where the names come from: in the SMT-LIB query every argument of the
function summary predicate has the Solidity name with a suffix, e.g.
    (summary_4_function_withdraw__82_83_0 error_0 this_0 abi_0 crypto_0 tx_0
       state_0 paidOut_3_0 pending_5_0 amount_7_0 chunk_9_0 state_1 ...)
The arguments are: error, this, abi, crypto, tx, state, state variables,
parameters, then the same after the call (and the return values). The state
variables are the ones of the interface predicate.

smt2pl_to_constr.pl turns the tx argument into one int per field (listed in
the "% tx_fields:" comment of the .chc.pl): their values (block.timestamp,
msg.sender, ...) are written too, when the model fixes them.

For every test of the .zmiout:
  - the function is the first summary_<k>_function_<name> of the call trace
    (with --single-tx it is the only public call after the constructor);
  - the values of its arguments come from the Z3 model (an argument missing
    from the model is unconstrained and is not written);
  - the error code says which assert fails: k = the k-th assert of the
    function in the source. If it is the `vgood` marker assert, the test is
    positive (the path passes every real assert), otherwise negative.

Usage:
    python3 script/solcmc_zmiout2json.py <folder>
(the folder holds <name>.sol, <name>.smt2 and one .zmiout)
"""
import glob
import importlib.util
import json
import os
import re
import sys


def _load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


HERE = os.path.dirname(os.path.abspath(__file__))
# same parsing and projections as zmiout2json.py (Yul route)
parse_mod = _load_module("_parse", os.path.join(HERE, "zmiout_parse.py"))
z3_mod = _load_module("_z3mod", os.path.join(HERE, "zmiout2vars_z3.py"))
clpq_mod = _load_module("_clpqmod", os.path.join(HERE, "zmiout2vars_clpq.py"))


def base_name(smt_var):
    # amount_7_0 -> amount; tx_0 -> tx
    m = re.match(r"(.+?)_\d+_\d+$", smt_var)
    if m:
        return m.group(1)
    return re.sub(r"_\d+$", "", smt_var)


def summary_layout(smt, pred):
    """Solidity names of the state variables and parameters of a summary."""
    # smt2map writes predicate names in lower case
    m = re.search(r"\((" + re.escape(pred) + r") ([^()]*)\)", smt, re.I)
    if not m:
        return None, None
    args = m.group(2).split()
    names = [base_name(a) for a in args]
    # error this abi crypto tx state | vars... | state' vars'...
    assert names[:6] == ["error", "this", "abi", "crypto", "tx", "state"], names[:6]
    after = names.index("state", 6)
    return m.group(1), names[6:after]


def interface_state_vars(smt):
    m = re.search(r"\((interface_0_\w+) ([^()]*)\)", smt)
    if not m:
        return []
    names = [base_name(a) for a in m.group(2).split()]
    # this abi crypto state | state variables
    return names[4:]


def function_asserts(src, func):
    """The assert conditions of a function, in source order."""
    m = re.search(r"\bfunction\s+" + re.escape(func) + r"\s*\(", src)
    if not m:
        return []
    i = src.index("{", m.end())
    depth, j = 0, i
    while j < len(src):
        if src[j] == "{":
            depth += 1
        elif src[j] == "}":
            depth -= 1
            if depth == 0:
                break
        j += 1
    body = re.sub(r"//[^\n]*", "", src[i:j])
    return [a.strip() for a in re.findall(r"\bassert\s*\((.*?)\)\s*;", body, re.S)]


def params_of(src, func):
    m = re.search(r"\bfunction\s+" + re.escape(func) + r"\s*\(([^)]*)\)", src)
    if not m or not m.group(1).strip():
        return []
    out = []
    for p in m.group(1).split(","):
        toks = p.split()
        out.append((toks[0], toks[-1]))
    return out


def parse_tests(zmiout):
    text = open(zmiout, errors="replace").read()
    tests = []
    for blk in text.split("TEST #")[1:]:
        trace = re.search(r"CALL TRACE :\n(.*?)\n\n", blk, re.S)
        model = re.search(r"model\{constants:\[(.*?)\]", blk, re.S)
        if not trace or not model:
            continue
        call = None
        for line in trace.group(1).splitlines():
            mm = re.match(r"\s*(summary_\d+_function_\w+?)\((.*)\)\s*$", line)
            if mm:
                call = (mm.group(1), [a.strip() for a in mm.group(2).split(",")])
                break
        values = dict(re.findall(r"(_\d+)=(-?\d+)", model.group(1)))
        # the path constraints, as in zmiout2json.py
        raw = parse_mod.extract_var_constraints(
            parse_mod.split_clauses(parse_mod.parse_incorrect_line(blk)), {})
        tests.append((call, values, raw))
    return tests


def main(folder):
    folder = os.path.abspath(folder)
    name = os.path.basename(folder)
    sol = os.path.join(folder, name + ".sol")
    smt = open(os.path.join(folder, name + ".smt2")).read()
    src = open(sol, errors="replace").read()
    zs = glob.glob(os.path.join(folder, "*.zmiout"))
    if not zs:
        sys.exit(f"no .zmiout in {folder}")
    contracts = re.findall(r"\bcontract\s+(\w+)", src)
    # solc >= 0.8.29 drops the last _0 of the predicate names
    m = re.search(r"\(interface_0_([A-Za-z0-9_]+?)_\d+(?:_\d+)? ", smt)
    cname = next((c for c in contracts if m and c.lower() == m.group(1)), contracts[-1] if contracts else name)
    state_vars = interface_state_vars(smt)

    tx_fields = []
    chc = os.path.join(folder, name + ".chc.pl")
    if os.path.exists(chc):
        m = re.match(r"% tx_fields: \[(.*)\]", open(chc).readline())
        if m:
            tx_fields = re.findall(r"'([^']+)'", m.group(1))
    k = len(tx_fields) if tx_fields else 1

    funcs = {}
    for i, (call, values, raw) in enumerate(parse_tests(zs[0]), 1):
        if call is None:
            continue
        pred, args = call
        smt_pred, layout = summary_layout(smt, pred)
        func = re.match(r"summary_\d+_function_(\w+?)__\d+_\d+(?:_\d+)?$", smt_pred).group(1)
        params = params_of(src, func)
        asserts = function_asserts(src, func)
        err = int(values.get(args[0], "0"))
        cond = asserts[err - 1] if 0 < err <= len(asserts) else None
        kind = "positive" if cond and "vgood" in cond else "negative"
        concrete = []
        rv_to_sol = {}
        # error this abi crypto | tx (k ints) | state | state variables, parameters
        # (the values at the start of the call)
        for nm, var in zip(layout, args[5 + k:]):
            rv_to_sol[var] = nm
            if var in values:
                concrete.append(f"{nm} == {values[var]}")
        for nm, var in zip(tx_fields, args[4:4 + k]):
            # a tx field the contract never reads only adds range noise
            if nm not in src:
                continue
            rv_to_sol[var] = nm
            if var in values:
                concrete.append(f"{nm} == {values[var]}")
        # Prolog cannot read a dotted name: block.timestamp -> block_timestamp
        rv_start = {v: n.replace(".", "_") for v, n in rv_to_sol.items()}
        # Same layout as the json of the Yul route (zmiout2json.py):
        # constraints_*       state variables where the assert fails (after
        #                     state' in the summary), parameters as they are;
        # constraints_*_start state variables when the call starts.
        rv_end = {v: n for v, n in rv_start.items() if n not in state_vars}
        post = args[5 + k + len(layout) + 1:]
        for nm, var in zip(state_vars, post):
            rv_end[var] = nm

        def project(rvs):
            if not raw:
                return [], []
            z3p = z3_mod.project_constraints(raw, rvs, state_vars)
            try:
                clpqp = clpq_mod.project_constraints(raw, rvs)
            except Exception as e:
                clpqp = [f"(CLP(Q) error: {e})"]
            return z3p, clpqp
        z3_proj, clpq_proj = project(rv_end)
        z3_start, clpq_start = project(rv_start)
        f = funcs.setdefault(func, {
            "signature": f"{func}({','.join(t for t, _ in params)})",
            "params": [p for _, p in params],
            "test_cases": [],
        })
        f["test_cases"].append({
            "id": len(f["test_cases"]) + 1,
            "kind": kind,
            "error_code": err,
            "failed_assert": cond,
            "concrete_values": concrete,
            "constraints_z3": z3_proj,
            "constraints_clpq": clpq_proj,
            "constraints_z3_start": z3_start,
            "constraints_clpq_start": clpq_start,
        })

    out = {
        "contractName": cname,
        "stateVariables": state_vars,
        "source": "SolCMC route (solc CHC query + smt2map + smt2pl_to_constr.pl)",
        "functions": list(funcs.values()),
    }
    if not funcs:
        out = {"result": parse_mod.no_test_message(zs[0])}
    path = os.path.join(folder, name + ".test_cases.json")
    with open(path, "w") as fh:
        json.dump(out, fh, indent=2)
    print("JSON written to:", path)
    if "result" in out:
        print(out["result"])
    for f in out.get("functions", []):
        for tc in f["test_cases"]:
            print(f"  {f['signature']} #{tc['id']} {tc['kind']:8s} {', '.join(tc['concrete_values'])}")
            print(f"      z3:   {', '.join(tc['constraints_z3'])}")
            print(f"      clpq: {', '.join(tc['constraints_clpq'])}")
            print(f"      clpq (inizio chiamata): {', '.join(tc['constraints_clpq_start'])}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    main(sys.argv[1])
