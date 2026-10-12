#!/usr/bin/env python3
"""
zmiout2vars_z3.py
Usage: python3 zmiout2vars_z3.py <contract.sol> <defs.txt> <analysis.zmiout>

Projects constraints onto Solidity variable names via Z3 quantifier elimination.
Output written to <analysis.zmiout>.vars_z3.txt
"""
import re, sys, os, importlib.util


def _load_parse():
    here = os.path.dirname(os.path.abspath(__file__))
    spec = importlib.util.spec_from_file_location('_parse', os.path.join(here, 'zmiout_parse.py'))
    mod  = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

_parse = _load_parse()


# ---- Z3 quantifier elimination projection ----

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
    s = str(x)
    s = re.sub(r'\+\s*-(\d+)\*', r'- \1*', s)
    s = re.sub(r'\+\s*-1\*', r'- ', s)
    return s.strip()

def _atoms_readable(result):
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
                            # "A + C - B == 0" -> "A + C == B", only when B is
                            # the last term: in "A - B + C" moving B alone
                            # would flip C's sign
                            m = re.match(r'^(.+)\s+-\s+(\S+)$', la_s)
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
    sv = set(state_var_names) if state_var_names else set()
    best_lower = {}
    best_upper = {}
    eq_vals    = {}

    def _collect(s):
        m = re.match(r'^(\w+)\s*>=\s*(-?\d+)$', s)
        if m:
            v, k = m.group(1), int(m.group(2))
            best_lower[v] = max(best_lower.get(v, k), k); return
        m = re.match(r'^(-?\d+)\s*>=\s*(\w+)$', s)
        if m:
            k, v = int(m.group(1)), m.group(2)
            best_upper[v] = min(best_upper.get(v, k), k); return
        m = re.match(r'^(\w+)\s*<=\s*(-?\d+)$', s)
        if m:
            v, k = m.group(1), int(m.group(2))
            best_upper[v] = min(best_upper.get(v, k), k); return
        m = re.match(r'^(\w+)\s*==\s*(-?\d+)$', s)
        if m:
            eq_vals[m.group(1)] = int(m.group(2))

    for s in atom_strs:
        _collect(s)

    def _atom_implied(atom_s):
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
        m = re.match(r'^Or\((.+),\s*(.+)\)$', s)
        if m:
            return 'Or(' + ', '.join(sorted([m.group(1).strip(), m.group(2).strip()])) + ')'
        return s

    def _normalize(s):
        m = re.match(r'^(-?\d+)\s*==\s*(\w+)$', s)
        if m: s = f"{m.group(2)} == {m.group(1)}"
        m = re.match(r'^Not\(0\s*==\s*(\w+)\)$', s)
        if m: return f"{m.group(1)} != 0"
        m = re.match(r'^Not\((\w+)\s*==\s*0\)$', s)
        if m: return f"{m.group(1)} != 0"
        m = re.match(r'^Or\((\w+)\s*>=\s*1,\s*(\w+)\s*<=\s*-1\)$', s)
        if m and m.group(1) == m.group(2): return f"{m.group(1)} != 0"
        m = re.match(r'^Or\((\w+)\s*<=\s*-1,\s*(\w+)\s*>=\s*1\)$', s)
        if m and m.group(1) == m.group(2): return f"{m.group(1)} != 0"
        return s

    def _neq_implied(v):
        return (v in eq_vals and eq_vals[v] != 0) \
            or best_lower.get(v, 0) >= 1 \
            or best_upper.get(v, 0) <= -1

    seen_atoms = set()
    seen_or    = set()
    result = []
    for s in atom_strs:
        s = _normalize(s)
        is_sv = any(v in s for v in sv)

        m_neq = re.match(r'^(\w+)\s*!=\s*0$', s)
        if m_neq:
            v = m_neq.group(1)
            if _neq_implied(v) or s in seen_atoms:
                continue
            seen_atoms.add(s); result.append(s); continue

        if s.startswith('Or('):
            canon = _or_canonical(s)
            if canon in seen_or:
                continue
            seen_or.add(canon)
            m = re.match(r'^Or\((.+),\s*(.+)\)$', s)
            if m:
                a1, a2 = m.group(1).strip(), m.group(2).strip()
                if _atom_implied(a1) or _atom_implied(a2):
                    continue
            result.append(s); continue

        m0 = re.match(r'^0\s*<=\s*(\w+)$', s)
        if m0:
            v = m0.group(1)
            if best_lower.get(v, -1) >= 0 or v in eq_vals:
                continue
            result.append(s); continue

        if is_sv:
            if s not in seen_atoms:
                seen_atoms.add(s); result.append(s)
            continue

        m = re.match(r'^(\w+)\s*>=\s*(-?\d+)$', s)
        if m:
            v, k = m.group(1), int(m.group(2))
            if v in eq_vals or best_lower.get(v, k) > k:
                continue
            result.append(s); continue

        m = re.match(r'^(-?\d+)\s*>=\s*(\w+)$', s)
        if m:
            k, v = int(m.group(1)), m.group(2)
            if v in eq_vals or best_upper.get(v, k) < k:
                continue
            result.append(s); continue

        m = re.match(r'^(\w+)\s*<=\s*(-?\d+)$', s)
        if m:
            v, k = m.group(1), int(m.group(2))
            if v in eq_vals or best_upper.get(v, k) < k:
                continue
            result.append(s); continue

        if s not in seen_atoms:
            seen_atoms.add(s); result.append(s)

    return result

def _minimize_and(formula):
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
                atoms.pop(i); changed = True; break
    if not atoms:
        from z3 import BoolVal; return BoolVal(True)
    return And(atoms) if len(atoms) > 1 else atoms[0]

_TOKEN_RE = re.compile(r'\b[A-Za-z_][A-Za-z0-9_]*\b')
_NUM_RE = re.compile(r'^-?\d+$')
_VAR_EQ_NUM_RE = re.compile(r'(\w+)=(-?\d+)')
_NUM_EQ_VAR_RE = re.compile(r'(-?\d+)=(\w+)')
_VAR_EQ_VAR_RE = re.compile(r'(\w+)=(\w+)')
_NOT_WRAP_RE = re.compile(r'not\((.*)\)')


def _split_and_atoms(text):
    """Split on the top-level ' and ' separators (respecting parens) -- the
    REAL conjunction delimiter in how the "INCORRECT/FF FOUND" formula gets
    printed. The comma-based split done upstream (extract_var_constraints)
    only breaks the formula into a handful of coarser fragments collected
    along the derivation; each fragment is itself a whole ' and '-joined
    conjunction of many individual atoms, not one atom. Feeding those
    coarse fragments straight into fullmatch-based atom parsing below would
    never match anything (they're not single "var=num"-shaped atoms), so
    every binding discovery would silently fail and everything downstream
    would look unresolved -- this is what actually produces true atoms."""
    s = re.sub(r'\s*\band\b\s*', ' and ', text)
    parts, current, depth = [], [], 0
    i = 0
    while i < len(s):
        if s[i] == '(':
            depth += 1; current.append(s[i])
        elif s[i] == ')':
            depth -= 1; current.append(s[i])
        elif depth == 0 and s[i:i + 5] == ' and ':
            parts.append(''.join(current).strip())
            current = []; i += 5; continue
        else:
            current.append(s[i])
        i += 1
    if current:
        parts.append(''.join(current).strip())
    return [p for p in parts if p]


def _project_constraints_fallback(constraints, rv_to_sol):
    """No Z3 Python bindings available (the real, exact projection in
    project_constraints() above needs them for quantifier elimination) --
    this is a dependency-free, more conservative substitute: propagate
    known literal/alias bindings through the raw constraint atoms by
    simple fixpoint substitution, then keep only the atoms that end up
    expressed PURELY in terms of the known Solidity names (function
    args / state vars) plus integer literals -- dropping (never
    guessing) any atom that still mentions an internal Prolog variable
    (be it plumbing like msg.value/globals, or a Solidity-level LOCAL
    that isn't itself a param or state var) once substitution is done.
    """
    constraints = _split_and_atoms(' and '.join(constraints))
    bindings = dict(rv_to_sol)  # raw Prolog var -> resolved Solidity name
    for _ in range(6):  # small fixpoint; these formulas are shallow
        changed = False
        for atom in constraints:
            m = _VAR_EQ_NUM_RE.fullmatch(atom) or _NUM_EQ_VAR_RE.fullmatch(atom)
            if m:
                a, b = m.groups()
                var, lit = (a, b) if not _NUM_RE.match(a) else (b, a)
                if var not in bindings:
                    bindings[var] = lit
                    changed = True
                continue
            m = _VAR_EQ_VAR_RE.fullmatch(atom)
            if m:
                a, b = m.groups()
                if a in bindings and b not in bindings:
                    bindings[b] = bindings[a]; changed = True
                elif b in bindings and a not in bindings:
                    bindings[a] = bindings[b]; changed = True
        if not changed:
            break

    sol_names = set(rv_to_sol.values())
    results, seen = [], set()
    for atom in constraints:
        s = atom
        for var, val in bindings.items():
            s = re.sub(rf'\b{re.escape(var)}\b', str(val), s)
        m_not = _NOT_WRAP_RE.fullmatch(s)
        inner = m_not.group(1) if m_not else s
        toks = set(_TOKEN_RE.findall(inner)) - {'not'}
        if any(not _NUM_RE.match(t) and t not in sol_names for t in toks):
            continue  # an internal/unresolved variable survived -- drop, don't guess
        if not any(name in toks for name in sol_names):
            continue  # nothing Solidity-relevant left to say
        if re.fullmatch(r'(\S+)=\1', s):
            continue  # trivial identity, left over from substitution
        if s in seen:
            continue
        seen.add(s)
        results.append(s)
    return results if results else ["(no Solidity-variable constraints found)"]

def project_constraints(constraints, rv_to_sol, state_var_names=None):
    """Project constraints onto Solidity variables via Z3 quantifier elimination."""
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


# ---- Main ----

def main():
    if len(sys.argv) != 4:
        print("Usage: zmiout2vars_z3.py <contract.sol> <defs.txt> <analysis.zmiout>")
        sys.exit(1)

    sol_path    = sys.argv[1]
    defs_path   = sys.argv[2]
    zmiout_path = sys.argv[3]

    sol    = open(sol_path).read()
    defs   = open(defs_path).read()
    zmiout = open(zmiout_path).read()

    sol_stem = os.path.splitext(os.path.basename(sol_path))[0]
    out_path = os.path.join(os.path.dirname(zmiout_path), sol_stem + ".vars_z3.txt")
    aux_path = os.path.join(os.path.dirname(sol_path), sol_stem + ".aux.pl")
    t_constr_path = os.path.join(os.path.dirname(sol_path), sol_stem + ".t_constr.pl")
    t_constr_text = open(t_constr_path).read() if os.path.isfile(t_constr_path) else None

    blocks           = _parse.load_defs_blocks(defs)
    func, entry_pred = _parse.detect_func_and_entry(blocks, aux_path)
    if not func:
        print("ERROR: function name not found")
        sys.exit(1)

    state_vars = _parse.parse_state_vars(sol)
    func_args  = _parse.parse_func_args(sol, func)
    arg_types  = _parse.parse_func_arg_types(sol, func)

    tests = _parse.split_tests(zmiout)
    if not tests:
        tests = [zmiout]

    all_lines = []
    for i, test_block in enumerate(tests, 1):
        if len(tests) > 1:
            all_lines.append(f"================ TEST #{i} ================")
        is_pos, concrete, rv_to_sol, raw_constrs = _parse.resolve_test(
            test_block, blocks, state_vars, func_args, entry_pred, func, t_constr_text,
            arg_types=arg_types)
        if is_pos:
            all_lines.append("[POSITIVE WITNESS — verimapGood]")
        all_lines.append("=== CONCRETE VALUES ===")
        all_lines.extend(f"  {v}" for v in concrete)
        all_lines.append("")
        all_lines.append("=== PROJECTED CONSTRAINTS (Z3) ===")
        if rv_to_sol:
            for p in project_constraints(raw_constrs, rv_to_sol, state_vars):
                all_lines.append(f"  {p}")
        else:
            all_lines.append("  (no Solidity variables identified)")
        all_lines.append("")

    with open(out_path, 'w') as f:
        f.write("\n".join(all_lines) + "\n")
    print(f"Output written to: {out_path} ({len(tests)} test cases found)")


if __name__ == '__main__':
    main()
