#!/usr/bin/env python3
"""
zmiout2vars_clpq.py
Usage: python3 zmiout2vars_clpq.py <contract.sol> <defs.txt> <analysis.zmiout>

Projects constraints onto Solidity variable names via SWI-Prolog CLP(Q) dump/3.
Output written to <analysis.zmiout>.vars_clpq.txt
"""
import re, sys, os, subprocess, tempfile, importlib.util


def _load_parse():
    here = os.path.dirname(os.path.abspath(__file__))
    spec = importlib.util.spec_from_file_location('_parse', os.path.join(here, 'zmiout_parse.py'))
    mod  = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

_parse = _load_parse()


# ---- CLP(Q) projection ----

def _remove_redundant_diseq(lines):
    strict = set()
    for l in lines:
        m = re.match(r'^(.+?)>(?!=)(.+)$', l.strip())
        if m:
            strict.add((m.group(1).strip(), m.group(2).strip(), '>'))
        m = re.match(r'^(.+?)<(?!=)(.+)$', l.strip())
        if m:
            strict.add((m.group(1).strip(), m.group(2).strip(), '<'))
    result = []
    for l in lines:
        m = re.match(r'^(.+?)=\\=(.+)$', l.strip())
        if m:
            a, b = m.group(1).strip(), m.group(2).strip()
            if (a, b, '>') in strict or (a, b, '<') in strict \
               or (b, a, '>') in strict or (b, a, '<') in strict:
                continue
        result.append(l)
    return result

def _split_and_at_depth0(s):
    s = re.sub(r'\s*\band\b\s*', ' and ', s)
    parts, current, depth = [], [], 0
    i = 0
    while i < len(s):
        if s[i] == '(':
            depth += 1; current.append(s[i])
        elif s[i] == ')':
            depth -= 1; current.append(s[i])
        elif depth == 0 and s[i:i+5] == ' and ':
            parts.append(''.join(current).strip())
            current = []; i += 5; continue
        else:
            current.append(s[i])
        i += 1
    if current:
        parts.append(''.join(current).strip())
    return [p for p in parts if p]

def _atom_to_clpq(s):
    s = s.strip()
    m = re.match(r'^not\((.+)\)$', s)
    if m:
        inner = m.group(1).strip()
        m2 = re.match(r'^(.+?)=(.+)$', inner)
        if m2:
            return f'{m2.group(1).strip()} =\\= {m2.group(2).strip()}'
        return None
    for pat, tmpl in [
        (r'^(.+?)=<(.+)$', '{0} =< {1}'),
        (r'^(.+?)>=(.+)$', '{0} >= {1}'),
        (r'^(.+?)>(.+)$',  '{0} > {1}'),
        (r'^(.+?)<(.+)$',  '{0} < {1}'),
    ]:
        m = re.match(pat, s)
        if m:
            return tmpl.format(m.group(1).strip(), m.group(2).strip())
    m = re.match(r'^(.+?)=(.+)$', s)
    if m:
        return f'{m.group(1).strip()} = {m.group(2).strip()}'
    return None

def project_constraints(constraints, rv_to_sol):
    """Project constraints onto Solidity variables via SWI-Prolog CLP(Q) dump/3."""
    text = ' and '.join(constraints)
    atoms = _split_and_at_depth0(text)
    clpq_atoms = [f'    {{{c}}}' for a in atoms for c in [_atom_to_clpq(a)] if c]

    if not clpq_atoms:
        return ["(no constraints convertible to CLP(Q))"]

    interesting = list(rv_to_sol.keys())
    sol_names   = [rv_to_sol[v] for v in interesting]
    pairs_str   = '[' + ', '.join(f"{rv}-'{sol}'" for rv, sol in zip(interesting, sol_names)) + ']'

    script = (
        ':- style_check(-singleton).\n'
        ':- use_module(library(clpq)).\n'
        ':- use_module(library(apply)).\n'
        ':- use_module(library(pairs)).\n\n'

        'replace_all(S, [], [], S).\n'
        'replace_all(S, [NV|NVs], [Name|Names], Result) :-\n'
        '    term_string(NV, NVS),\n'
        '    atomic_list_concat(Parts, NVS, S),\n'
        '    atomic_list_concat(Parts, Name, S2),\n'
        '    replace_all(S2, NVs, Names, Result).\n\n'

        'project :-\n'
        + ',\n'.join(clpq_atoms) + ',\n'
        f'    Pairs = {pairs_str},\n'
        '    partition([P]>>(P=V-_,number(V)), Pairs, BoundPairs, FreePairs),\n'
        '    forall(member(V-N, BoundPairs), format("~w=~w~n", [N, V])),\n'
        '    (FreePairs = [] -> true ;\n'
        '        pairs_keys(FreePairs, FreeVars),\n'
        '        pairs_values(FreePairs, FreeNames),\n'
        '        length(FreeVars, NF), length(NewVars, NF),\n'
        '        dump(FreeVars, NewVars, Cs),\n'
        '        forall(member(C, Cs), (\n'
        '            term_string(C, CS),\n'
        '            replace_all(CS, NewVars, FreeNames, Result),\n'
        '            writeln(Result)\n'
        '        ))\n'
        '    ).\n\n'
        ':- (project -> true ; write(clpq_failed), nl), halt.\n'
    )

    with tempfile.NamedTemporaryFile(mode='w', suffix='.pl', delete=False) as f:
        f.write(script); tmp = f.name

    try:
        res = subprocess.run(['swipl', '-q', tmp],
                             capture_output=True, text=True, timeout=30)
        out = res.stdout.strip()
    except subprocess.TimeoutExpired:
        return ["(CLP(Q) timeout)"]
    except FileNotFoundError:
        return ["(swipl not found in PATH)"]
    finally:
        os.unlink(tmp)

    if not out or 'clpq_failed' in out:
        err = res.stderr.strip()
        return [f"(CLP(Q) failed: {err[:300] if err else 'no output'})"]

    seen = set()
    result = []
    for l in out.split('\n'):
        l = l.strip()
        if l and l not in seen:
            seen.add(l); result.append(l)
    result = [l for l in result if not re.search(r'\b_\d+\b', l)]
    result = [l.replace('=\\=', '!=') for l in result]
    return result


# ---- Main ----

def main():
    if len(sys.argv) != 4:
        print("Usage: zmiout2vars_clpq.py <contract.sol> <defs.txt> <analysis.zmiout>")
        sys.exit(1)

    sol_path    = sys.argv[1]
    defs_path   = sys.argv[2]
    zmiout_path = sys.argv[3]

    sol    = open(sol_path).read()
    defs   = open(defs_path).read()
    zmiout = open(zmiout_path).read()

    sol_stem = os.path.splitext(os.path.basename(sol_path))[0]
    out_path = os.path.join(os.path.dirname(zmiout_path), sol_stem + ".vars_clpq.txt")

    blocks           = _parse.load_defs_blocks(defs)
    func, entry_pred = _parse.detect_func_and_entry(blocks)
    if not func:
        print("ERROR: function name not found")
        sys.exit(1)

    state_vars = _parse.parse_state_vars(sol)
    func_args  = _parse.parse_func_args(sol, func)

    tests = _parse.split_tests(zmiout)
    if not tests:
        tests = [zmiout]

    all_lines = []
    for i, test_block in enumerate(tests, 1):
        if len(tests) > 1:
            all_lines.append(f"================ TEST #{i} ================")
        is_pos, concrete, rv_to_sol, raw_constrs = _parse.resolve_test(
            test_block, blocks, state_vars, func_args, entry_pred)
        if is_pos:
            all_lines.append("[POSITIVE WITNESS — verimapGood]")
        all_lines.append("=== CONCRETE VALUES ===")
        all_lines.extend(f"  {v}" for v in concrete)
        all_lines.append("")
        all_lines.append("=== PROJECTED CONSTRAINTS (CLP(Q)) ===")
        if rv_to_sol:
            for p in project_constraints(raw_constrs, rv_to_sol):
                all_lines.append(f"  {p}")
        else:
            all_lines.append("  (no Solidity variables identified)")
        all_lines.append("")

    with open(out_path, 'w') as f:
        f.write("\n".join(all_lines) + "\n")
    print(f"Output written to: {out_path} ({len(tests)} test cases found)")


if __name__ == '__main__':
    main()
