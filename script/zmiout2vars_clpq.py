#!/usr/bin/env python3
"""
zmiout2vars_clpq.py
Same pipeline as zmiout2vars.py but projects constraints via SWI-Prolog CLPQ dump/3.
Usage: python3 zmiout2vars_clpq.py <contract.sol> <defs.txt> <analysis.zmiout>
"""
import re, sys, subprocess, tempfile, os


# ---- Parsing helpers ----

def parse_state_vars(sol):
    contract_body = re.search(r'contract\s+\w+\s*\{(.*)', sol, re.DOTALL)
    if not contract_body:
        return []
    body = contract_body.group(1)
    before_funcs = re.split(r'\bfunction\b', body)[0]
    return re.findall(
        r'^\s+(?:uint\d*|int\d*|address|bool|bytes\d*)\s+(?:(?:public|private|internal|constant)\s+)*(\w+)\s*[=;]',
        before_funcs, re.MULTILINE)

def parse_func_args(sol, func):
    m = re.search(rf'function\s+{func}\s*\(([^)]*)\)', sol)
    if not m or not m.group(1).strip():
        return []
    args = []
    for part in m.group(1).split(','):
        tokens = part.strip().split()
        if tokens:
            args.append(tokens[-1])
    return args

def load_defs_blocks(defs):
    return re.split(r'\n(?=new\d+\()', defs)

def detect_func_and_entry(blocks):
    """Return (func_name, entry_pred_name): the function called and the CHC that calls it."""
    for block in blocks:
        m_pred = re.match(r'(new\d+)\(', block)
        if not m_pred:
            continue
        m_func = re.search(r'fun_call\(subO_fun_(\w+?)_\d+,', block)
        if m_func:
            return m_func.group(1), m_pred.group(1)
    return None, 'new2'

def get_param_list(block):
    m = re.match(r'new\d+\(([^)]+)\)', block)
    if not m:
        return []
    return [p.strip() for p in m.group(1).split(',')]

def parse_env_slots(block):
    start = re.split(r',cf\(', block)[0]
    m = re.search(r"\('msg\.value',\w+\)((?:,\(\d+,[A-Z]\d*\))*)\]", start)
    if not m:
        return {}
    return {int(s.group(1)): s.group(2)
            for s in re.finditer(r'\((\d+),([A-Z]\d*)\)', m.group(1))}

def find_block(blocks, name):
    for block in blocks:
        if re.match(rf'{name}\(', block):
            return block
    return None

def find_body_from_trace(trace_dict, blocks, n_args):
    for name in trace_dict:
        block = find_block(blocks, name)
        if block is None:
            continue
        if 'subO_' not in block:
            continue
        start = re.split(r',cf\(', block)[0]
        locals_ = {int(v): l for v, l in re.findall(r'\(v(\d+),([A-Z]\d*)\)', start)}
        if n_args == 0 or all(i in locals_ for i in range(n_args)):
            return name, locals_, get_param_list(block)
    return None, {}, []


# ---- CLPQ projection ----

def _remove_redundant_diseq(lines):
    """Remove A=\\=B lines when A>B or A<B (exact text) is also present."""
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
    """Split 's' on 'and' at parenthesis depth 0."""
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
    """Convert a constraint atom string to CLPQ Prolog syntax."""
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
    """Project constraints onto Solidity variables using SWI-Prolog CLPQ dump/3.
    Bound vars (unified to a value by CLPQ) are printed directly.
    Free vars get a joint dump so internal variables are fully eliminated.
    """
    text = ' and '.join(constraints)
    atoms = _split_and_at_depth0(text)
    clpq_atoms = [f'    {{{c}}}' for a in atoms for c in [_atom_to_clpq(a)] if c]

    if not clpq_atoms:
        return ["(nessun vincolo convertibile in CLPQ)"]

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
        return ["(timeout CLPQ)"]
    except FileNotFoundError:
        return ["(swipl non trovato nel PATH)"]
    finally:
        os.unlink(tmp)

    if not out or 'clpq_failed' in out:
        err = res.stderr.strip()
        return [f"(CLPQ fallito: {err[:300] if err else 'nessun output'})"]

    seen = set()
    result = []
    for l in out.split('\n'):
        l = l.strip()
        if l and l not in seen:
            seen.add(l); result.append(l)
    result = [l for l in result if not re.search(r'\b_\d+\b', l)]
    result = [l.replace('=\\=', '!=') for l in result]
    return result


# ---- constraint extraction ----

def parse_incorrect_line(block):
    """Return the raw constraint string from the INCORRECT/FF FOUND line."""
    m = re.search(r'INCORRECT/FF FOUND:\s*(.*)', block)
    return m.group(1) if m else ""

def split_clauses(text):
    """Split comma-separated constraint clauses respecting parentheses depth."""
    clauses, current, depth = [], [], 0
    for ch in text:
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
        if ch == ',' and depth == 0:
            clauses.append(''.join(current).strip())
            current = []
        else:
            current.append(ch)
    if current:
        clauses.append(''.join(current).strip())
    return clauses

def extract_var_constraints(clauses, rv_to_sol):
    """Return all non-trivial clauses (skip type annotations and 'true')."""
    results = []
    for clause in clauses:
        if ':int=' in clause or clause == 'true':
            continue
        results.append(clause)
    return results


# ---- zmiout parsing ----

def split_tests(zmiout):
    """Split zmiout into individual test blocks by TEST #N marker."""
    parts = re.split(r'={3,}\s*TEST #\d+\s*={3,}', zmiout)
    return [p for p in parts if 'CALL TRACE' in p or 'model{' in p]

def parse_call_trace(block):
    trace = []
    in_trace = False
    for line in block.split('\n'):
        s = line.strip()
        if 'CALL TRACE' in s:
            in_trace = True
            continue
        if in_trace:
            if 'MODELLO Z3' in s or s.startswith('model{'):
                break
            m = re.match(r'(new\d+)\((.+)\)\s*$', s)
            if m:
                args = [a.strip() for a in m.group(2).split(',')]
                trace.append((m.group(1), args))
    return trace

def parse_z3_model(block):
    m = re.search(r'model\{constants:\[([^\]]+)\]', block)
    if not m:
        return {}
    model = {}
    for item in m.group(1).split(','):
        kv = item.strip().split('=', 1)
        if len(kv) == 2:
            key, val = kv[0].strip(), kv[1].strip()
            if re.match(r'^-?\d+$', val):
                model[key] = int(val)
    return model

def process_test(test_block, blocks, state_vars, func, func_args, entry_pred='new2'):
    n_args = len(func_args)
    call_trace = parse_call_trace(test_block)
    z3_model   = parse_z3_model(test_block)

    trace_dict = {}
    for name, args in call_trace:
        if name not in trace_dict:
            trace_dict[name] = args

    lines = []
    new2_args = trace_dict.get(entry_pred)

    lines.append("=== STATE VARIABLES (valori POST-chiamata) ===")

    ref_name, ref_env, ref_params = None, {}, []
    for cname in trace_dict:
        block = find_block(blocks, cname)
        if block is None:
            continue
        if 'subO_' not in block:
            continue
        env = parse_env_slots(block)
        if env:
            ref_name   = cname
            ref_env    = env
            ref_params = get_param_list(block)
            break

    if new2_args is None:
        lines.append("  (new2 not found in call trace)")
    elif ref_name is None:
        lines.append("  (no subO_ predicate with env slots found in trace)")
    else:
        offset = (len(new2_args) - n_args) // 2
        for i, var in enumerate(state_vars):
            letter = ref_env.get(i)
            if letter is None:
                lines.append(f"  {var:<12}  slot {i}  ->  slot not found in env")
                continue
            if letter not in ref_params:
                lines.append(f"  {var:<12}  slot {i}  ->  letter {letter} not in param list")
                continue
            pre_pos  = ref_params.index(letter)
            post_pos = pre_pos + offset
            rv  = new2_args[post_pos] if post_pos < len(new2_args) else '?'
            val = z3_model.get(rv, '?')
            lines.append(f"  {var:<12}  slot {i}  ->  pos {post_pos} in new2  ->  {rv}  =  {val}")

    lines.append("")
    lines.append(f"=== FUNCTION ARGS: {func}({', '.join(func_args)}) ===")

    chosen_name, chosen_locals, chosen_params = find_body_from_trace(
        trace_dict, blocks, n_args
    )

    if chosen_name is None:
        lines.append("  (no body predicate found)")
    else:
        body_args = trace_dict.get(chosen_name)
        for j, arg in enumerate(func_args):
            letter = chosen_locals.get(j)
            if letter is None:
                lines.append(f"  {arg:<12}  v{j}  ->  letter NOT FOUND in defs")
                continue
            if letter not in chosen_params:
                lines.append(f"  {arg:<12}  v{j} = {letter}  ->  not in param list of {chosen_name}")
                continue
            pos = chosen_params.index(letter)
            if body_args and pos < len(body_args):
                rv  = body_args[pos]
                val = z3_model.get(rv, '?')
                lines.append(f"  {arg:<12}  v{j} = {letter}  ->  pos {pos} in {chosen_name}  ->  {rv}  =  {val}")
            else:
                lines.append(f"  {arg:<12}  v{j} = {letter}  ->  pos {pos} in {chosen_name}  ->  NOT IN TRACE")

    # ---- constraint section ----
    # Build runtime_var -> solidity_name map from what we resolved above
    rv_to_sol = {}

    if new2_args is not None and ref_name is not None:
        offset = (len(new2_args) - n_args) // 2
        for i, var in enumerate(state_vars):
            letter = ref_env.get(i)
            if letter and letter in ref_params:
                post_pos = ref_params.index(letter) + offset
                if post_pos < len(new2_args):
                    rv_to_sol[new2_args[post_pos]] = var

    if chosen_name is not None:
        body_args = trace_dict.get(chosen_name)
        for j, arg in enumerate(func_args):
            letter = chosen_locals.get(j)
            if letter and letter in chosen_params:
                pos = chosen_params.index(letter)
                if body_args and pos < len(body_args):
                    rv_to_sol[body_args[pos]] = arg

    raw = parse_incorrect_line(test_block)
    clauses = split_clauses(raw)
    constraints = extract_var_constraints(clauses, rv_to_sol)
    lines.append("")
    lines.append("=== VINCOLI ===")
    if constraints:
        for c in constraints:
            lines.append(f"  {c}")
    else:
        lines.append("  (nessun vincolo trovato)")

    lines.append("")
    lines.append("=== VINCOLI PROIETTATI CLPQ (solo variabili Solidity) ===")
    if rv_to_sol:
        projected = project_constraints(constraints, rv_to_sol)
        for p in projected:
            lines.append(f"  {p}")
    else:
        lines.append("  (nessuna variabile Solidity identificata)")

    return lines


# ---- Main ----

def main():
    if len(sys.argv) != 4:
        print("Usage: zmiout2vars.py <contract.sol> <defs.txt> <analysis.zmiout>")
        sys.exit(1)

    sol_path    = sys.argv[1]
    defs_path   = sys.argv[2]
    zmiout_path = sys.argv[3]

    sol    = open(sol_path).read()
    defs   = open(defs_path).read()
    zmiout = open(zmiout_path).read()

    sol_stem = os.path.splitext(os.path.basename(sol_path))[0]
    out_path = os.path.join(os.path.dirname(zmiout_path), sol_stem + ".vars_clpq.txt")

    blocks           = load_defs_blocks(defs)
    func, entry_pred = detect_func_and_entry(blocks)
    if not func:
        print("ERROR: function name not found (no fun_call with subO_fun_ in any predicate)")
        sys.exit(1)

    state_vars = parse_state_vars(sol)
    func_args  = parse_func_args(sol, func)

    tests = split_tests(zmiout)
    if not tests:
        tests = [zmiout]  # single test, no markers

    all_lines = []
    for i, test_block in enumerate(tests, 1):
        if len(tests) > 1:
            all_lines.append(f"================ TEST #{i} ================")
        if 'testVerimapGood' in test_block:
            all_lines.append("[POSITIVE WITNESS — verimapGood]")
        all_lines.extend(process_test(test_block, blocks, state_vars, func, func_args, entry_pred))
        all_lines.append("")

    output = "\n".join(all_lines) + "\n"

    with open(out_path, 'w') as f:
        f.write(output)

    print(f"Output scritto in: {out_path} ({len(tests)} test trovati)")


if __name__ == '__main__':
    main()
