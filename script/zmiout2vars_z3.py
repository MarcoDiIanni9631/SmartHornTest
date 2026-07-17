#!/usr/bin/env python3
"""
zmiout2vars.py
Usage: python3 zmiout2vars.py <contract.sol> <defs.txt> <analysis.zmiout>

For each Solidity variable, finds which predicate in the call trace carries it,
at which argument position, and what concrete value Z3 assigned.
Output is written to <analysis.zmiout>.vars.txt
Always also writes a .test_cases.json with structured test data.
"""
import re, sys, os


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


# ---- Z3 quantifier elimination projection ----

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

def _parse_z3_term(s, var_map):
    from z3 import Int, IntVal
    s = s.strip()
    if re.match(r'^-?\d+$', s):
        return IntVal(int(s))
    m = re.search(r'^(.+)\+(.+?)$', s)
    if m:
        return _parse_z3_term(m.group(1), var_map) + _parse_z3_term(m.group(2), var_map)
    m = re.search(r'^(.+)-(.+?)$', s)
    if m:
        return _parse_z3_term(m.group(1), var_map) - _parse_z3_term(m.group(2), var_map)
    if s not in var_map:
        var_map[s] = Int(s)
    return var_map[s]

def _parse_z3_atom(s, var_map):
    from z3 import Not, BoolVal
    s = s.strip()
    m = re.match(r'^not\((.+)\)$', s)
    if m:
        return Not(_parse_z3_atom(m.group(1), var_map))
    m = re.match(r'^(.+?)(>=|=<|<=|>|<|=)(.+)$', s)
    if m:
        lhs = _parse_z3_term(m.group(1), var_map)
        rhs = _parse_z3_term(m.group(3), var_map)
        op  = m.group(2)
        if op == '=':  return lhs == rhs
        if op == '>':  return lhs > rhs
        if op == '<':  return lhs < rhs
        if op == '>=': return lhs >= rhs
        if op in ('<=', '=<'): return lhs <= rhs
    return BoolVal(True)

def _parse_z3_constraint(s, var_map):
    from z3 import And
    atoms = []
    for a in _split_and_at_depth0(s):
        try:
            atoms.append(_parse_z3_atom(a, var_map))
        except Exception:
            pass
    if not atoms:
        from z3 import BoolVal; return BoolVal(True)
    return And(atoms) if len(atoms) > 1 else atoms[0]

def _expr_str(x):
    """Z3 expression or string → readable string with normalized notation."""
    s = str(x)
    s = re.sub(r'\+\s*-(\d+)\*', r'- \1*', s)
    s = re.sub(r'\+\s*-1\*', r'- ', s)
    return s.strip()


def _atoms_readable(result):
    """Split Z3 formula into a list of readable strings; merge ineq pairs into equalities."""
    from z3 import is_and, is_le, is_ge, simplify

    atoms = list(result.children()) if is_and(result) else [result]

    def to_le(atom):
        if is_le(atom): return atom.arg(0), atom.arg(1)
        if is_ge(atom): return atom.arg(1), atom.arg(0)
        return None

    used = set()
    out = []
    for i in range(len(atoms)):
        if i in used:
            continue
        ni = to_le(atoms[i])
        merged = False
        if ni is not None:
            la, ra = ni
            for j in range(i + 1, len(atoms)):
                if j in used:
                    continue
                nj = to_le(atoms[j])
                if nj is None:
                    continue
                lb, rb = nj
                try:
                    if str(simplify((la - ra) - (rb - lb))) == '0':
                        la_s = _expr_str(la)
                        ra_s = _expr_str(ra)
                        if re.match(r'^-?\d+$', la_s):
                            la_s, ra_s = ra_s, la_s
                        if ra_s == '0':
                            m = re.match(r'^(.+?)\s+-\s+(.+)$', la_s)
                            if m:
                                la_s, ra_s = m.group(1).strip(), m.group(2).strip()
                        out.append(f"{la_s} == {ra_s}")
                        used.update([i, j])
                        merged = True
                        break
                except Exception:
                    pass
        if not merged and i not in used:
            out.append(_expr_str(atoms[i]))

    return out


def _prune_weak_bounds(atom_strs, state_var_names):
    """Remove redundant atoms from Z3 QE output:
    - Weak lower/upper bounds on func-args implied by tighter ones or equalities
    - Or(x >= k1, x <= k2) when one disjunct is already implied
    - Duplicate Or constraints (regardless of argument order)
    - "0 <= x" duplicate of "x >= 0"
    State variable constraints are protected from tightness-based removal.
    """
    sv = set(state_var_names) if state_var_names else set()

    # Collect bounds from ALL atoms (state vars too, for Or-pruning)
    best_lower = {}   # var -> max k from "var >= k"
    best_upper = {}   # var -> min k from "k >= var" / "var <= k"
    eq_vals    = {}   # var -> k from "var == k"

    def _collect(s):
        m = re.match(r'^(\w+)\s*>=\s*(-?\d+)$', s)
        if m:
            v, k = m.group(1), int(m.group(2))
            best_lower[v] = max(best_lower.get(v, k), k)
            return
        m = re.match(r'^(-?\d+)\s*>=\s*(\w+)$', s)
        if m:
            k, v = int(m.group(1)), m.group(2)
            best_upper[v] = min(best_upper.get(v, k), k)
            return
        m = re.match(r'^(\w+)\s*<=\s*(-?\d+)$', s)
        if m:
            v, k = m.group(1), int(m.group(2))
            best_upper[v] = min(best_upper.get(v, k), k)
            return
        m = re.match(r'^(\w+)\s*==\s*(-?\d+)$', s)
        if m:
            eq_vals[m.group(1)] = int(m.group(2))

    for s in atom_strs:
        _collect(s)

    def _atom_implied(atom_s):
        """Check if simple atom var >= k / var <= k is implied by collected bounds."""
        m = re.match(r'^(\w+)\s*>=\s*(-?\d+)$', atom_s)
        if m:
            v, k = m.group(1), int(m.group(2))
            return (v in eq_vals and eq_vals[v] >= k) or best_lower.get(v, -10**9) >= k
        m = re.match(r'^(-?\d+)\s*>=\s*(\w+)$', atom_s)
        if m:
            k, v = int(m.group(1)), m.group(2)
            return (v in eq_vals and eq_vals[v] <= k) or best_upper.get(v, 10**9) <= k
        m = re.match(r'^(\w+)\s*<=\s*(-?\d+)$', atom_s)
        if m:
            v, k = m.group(1), int(m.group(2))
            return (v in eq_vals and eq_vals[v] <= k) or best_upper.get(v, 10**9) <= k
        return False

    def _or_canonical(s):
        """Canonical key for Or(a, b) ignoring argument order."""
        m = re.match(r'^Or\((.+),\s*(.+)\)$', s)
        if m:
            return 'Or(' + ', '.join(sorted([m.group(1).strip(), m.group(2).strip()])) + ')'
        return s

    def _normalize(s):
        """Normalize common ugly Z3 forms to cleaner equivalents."""
        # "0 == x"  →  "x == 0"  (put variable on left)
        m = re.match(r'^(-?\d+)\s*==\s*(\w+)$', s)
        if m: s = f"{m.group(2)} == {m.group(1)}"
        # Not(0 == x) or Not(x == 0)  →  x != 0
        m = re.match(r'^Not\(0\s*==\s*(\w+)\)$', s)
        if m: return f"{m.group(1)} != 0"
        m = re.match(r'^Not\((\w+)\s*==\s*0\)$', s)
        if m: return f"{m.group(1)} != 0"
        # Or(x >= 1, x <= -1) / Or(x <= -1, x >= 1)  →  x != 0  (integer semantics)
        m = re.match(r'^Or\((\w+)\s*>=\s*1,\s*(\w+)\s*<=\s*-1\)$', s)
        if m and m.group(1) == m.group(2): return f"{m.group(1)} != 0"
        m = re.match(r'^Or\((\w+)\s*<=\s*-1,\s*(\w+)\s*>=\s*1\)$', s)
        if m and m.group(1) == m.group(2): return f"{m.group(1)} != 0"
        return s

    def _neq_implied(v):
        """True if x != 0 is redundant (x has a non-zero equality, or a bound >= 1 or <= -1)."""
        return (v in eq_vals and eq_vals[v] != 0) \
            or best_lower.get(v, 0) >= 1 \
            or best_upper.get(v, 0) <= -1

    seen_atoms = set()
    seen_or    = set()
    result = []
    for s in atom_strs:
        s = _normalize(s)
        is_sv = any(v in s for v in sv)

        # --- x != 0 ---
        m_neq = re.match(r'^(\w+)\s*!=\s*0$', s)
        if m_neq:
            v = m_neq.group(1)
            if _neq_implied(v):
                continue
            if s in seen_atoms:
                continue
            seen_atoms.add(s)
            result.append(s)
            continue

        # --- Or constraints ---
        if s.startswith('Or('):
            canon = _or_canonical(s)
            if canon in seen_or:
                continue          # duplicate (possibly different arg order)
            seen_or.add(canon)
            # Remove if one disjunct is already implied by a simple bound
            m = re.match(r'^Or\((.+),\s*(.+)\)$', s)
            if m:
                a1, a2 = m.group(1).strip(), m.group(2).strip()
                if _atom_implied(a1) or _atom_implied(a2):
                    continue
            result.append(s)
            continue

        # --- "0 <= x" is same as "x >= 0" ---
        m0 = re.match(r'^0\s*<=\s*(\w+)$', s)
        if m0:
            v = m0.group(1)
            if best_lower.get(v, -1) >= 0 or v in eq_vals:
                continue
            result.append(s)
            continue

        # --- State variable atoms: always keep, no tightness pruning ---
        if is_sv:
            if s not in seen_atoms:
                seen_atoms.add(s)
                result.append(s)
            continue

        # --- Func-arg lower bound: keep only if it's the tightest ---
        m = re.match(r'^(\w+)\s*>=\s*(-?\d+)$', s)
        if m:
            v, k = m.group(1), int(m.group(2))
            if v in eq_vals or best_lower.get(v, k) > k:
                continue
            result.append(s)
            continue

        # --- Func-arg upper bound "k >= var" ---
        m = re.match(r'^(-?\d+)\s*>=\s*(\w+)$', s)
        if m:
            k, v = int(m.group(1)), m.group(2)
            if v in eq_vals or best_upper.get(v, k) < k:
                continue
            result.append(s)
            continue

        # --- Func-arg upper bound "var <= k" ---
        m = re.match(r'^(\w+)\s*<=\s*(-?\d+)$', s)
        if m:
            v, k = m.group(1), int(m.group(2))
            if v in eq_vals or best_upper.get(v, k) < k:
                continue
            result.append(s)
            continue

        if s not in seen_atoms:
            seen_atoms.add(s)
            result.append(s)

    return result


def _minimize_and(formula):
    """Remove every atom that is implied by the conjunction of all others."""
    from z3 import And, Not, Solver, unsat, is_and, BoolVal
    if not is_and(formula):
        return formula
    atoms = list(formula.children())
    changed = True
    while changed:
        changed = False
        for i in range(len(atoms)):
            rest = [atoms[j] for j in range(len(atoms)) if j != i]
            if not rest:
                continue
            s = Solver()
            s.add(And(rest) if len(rest) > 1 else rest[0])
            s.add(Not(atoms[i]))
            if s.check() == unsat:
                atoms.pop(i)
                changed = True
                break
    if not atoms:
        from z3 import BoolVal; return BoolVal(True)
    return And(atoms) if len(atoms) > 1 else atoms[0]


def _project_constraints_fallback(constraints, rv_to_sol):
    """Fallback: string substitution of runtime vars → Solidity names."""
    results = []
    for c in constraints:
        s = c
        for rv, name in rv_to_sol.items():
            s = re.sub(r'\b' + re.escape(rv) + r'\b', name, s)
        if any(name in s for name in rv_to_sol.values()):
            results.append(s)
    return results if results else ["(nessun vincolo con variabili Solidity)"]

def project_constraints(constraints, rv_to_sol, state_var_names=None):
    """Apply Z3 qe to project constraints onto Solidity variables only.

    state_var_names: if provided, their constraints are always kept even if
    logically redundant (e.g. currentBalance >= 5 from assertion violation).
    """
    try:
        from z3 import And, Exists, Tactic, Goal, Int, substitute
    except ImportError:
        return _project_constraints_fallback(constraints, rv_to_sol)

    var_map = {}
    z3_exprs = []
    for c in constraints:
        try:
            z3_exprs.append(_parse_z3_constraint(c, var_map))
        except Exception:
            pass

    if not z3_exprs:
        return _project_constraints_fallback(constraints, rv_to_sol)

    formula = And(z3_exprs) if len(z3_exprs) > 1 else z3_exprs[0]
    interesting = set(rv_to_sol.keys())
    vars_to_elim = [v for k, v in var_map.items() if k not in interesting]

    if vars_to_elim:
        try:
            g = Goal(); g.add(Exists(vars_to_elim, formula))
            result = Tactic('qe')(g).as_expr()
        except Exception:
            return _project_constraints_fallback(constraints, rv_to_sol)
    else:
        result = formula

    subst = [(var_map[rv], Int(name)) for rv, name in rv_to_sol.items() if rv in var_map]
    if subst:
        result = substitute(result, subst)

    atoms = _atoms_readable(result)
    atoms = _prune_weak_bounds(atoms, state_var_names or [])
    return atoms


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
    lines.append("=== VINCOLI PROIETTATI (solo variabili Solidity) ===")
    if rv_to_sol:
        projected = project_constraints(constraints, rv_to_sol, state_vars)
        for p in projected:
            lines.append(f"  {p}")
    else:
        lines.append("  (nessuna variabile Solidity identificata)")

    return lines


def build_func_signature(sol, func):
    """Build Solidity signature like 'claimRewards(uint256)'."""
    m = re.search(rf'function\s+{func}\s*\(([^)]*)\)', sol)
    if not m or not m.group(1).strip():
        return f"{func}()"
    types = [p.strip().split()[0] for p in m.group(1).split(',') if p.strip()]
    return f"{func}({','.join(types)})"


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
    out_path = os.path.join(os.path.dirname(zmiout_path), sol_stem + ".vars_z3.txt")

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

    print(f"Output written to: {out_path} ({len(tests)} test cases found)")


if __name__ == '__main__':
    main()
