#!/usr/bin/env python3
"""step4b_fix_branch_constraints.py <contract>.t_constr.pl

Post-processing patch that runs AFTER step4 (constr) and BEFORE step5
(analysis). It does NOT touch the transformation engine or strategy files
(rem_int.pl / yul_multistep.pl / gen.pl) -- it only edits the already
generated <contract>.t_constr.pl in place.

Background (see docs/branches_bug notes): when a straight-line `if/else`
(a `cj` in the raw Yul-CHC facts) gets folded into a reusable generalized
predicate by candidate_def/2 (yul-chc/lib/yul/strategies/rem_int.pl:131),
the predicate's alternative clauses each commit to one branch (e.g.
`P=0`/`P=1` for the branch-selector variable P) but nothing ties P back to
the real condition it came from (e.g. "the function's own argument is 0").
Z3 is then free to pick whichever clause it likes regardless of the actual
argument value -- a false positive (or, in principle, a false negative).

This script re-derives that missing link directly from the raw CHC facts
(<contract>.pl, step2 output) and the candidate-definition records
(<contract>.t.pl-defs.txt, step3 output), and injects it back into the
matching clauses of <contract>.t_constr.pl as an extra constr(...) conjunct.

Safety / scope, by design:
  - Only touches a `cj` whose two targets do NOT lead back to it through
    the raw at/nextlab/goto/cj graph (i.e. not a loop back-edge). Loop
    conditions are left completely untouched -- this script never changes
    how loops are folded, so it cannot break loop verification.
  - Only computes a constraint when it can be expressed as a plain
    conjunction of equalities/inequalities over variables it can trace
    back to either a head variable of the candidate definition or a
    compile-time literal. Anything that would need a disjunction (e.g. an
    `and`/`or` whose derivation isn't a straight conjunction) or an
    unrecognized operator is silently skipped for that one predicate --
    never patched with a guess.

A second, related bug (see branches_merge_variables_3 notes): once a branch
predicate like new3 above is recognized, some OTHER clause (often the query
predicate itself, e.g. `incorrect`) can call it while ALSO independently
pre-binding that exact same branch-selector argument to a bare 0/1 literal
in its OWN leading constr(...) -- typically a leftover of how the outer
unfold duplicated the same source-level condition instead of just calling
into the already-folded predicate. That pre-binding is always redundant
(the callee already fully and correctly re-derives the same variable from
scratch) and, when it happens to be wrong -- inverted relative to what the
caller's own condition actually means -- silently prunes away an entire,
otherwise-correct counterexample as UNSAT (observed: only the single
boundary input where both the caller's and the callee's ranges happen to
overlap was ever found, everything else got contradicted away).
patch_caller_prebindings() finds and drops such pre-bindings. Dropping is
safe either way: a no-op if it was already correct, a fix if it was wrong --
never a guess, since the callee's own body is what actually determines the
variable in the end.
"""
import argparse
import os
import re
import sys
from collections import Counter


# ---------------------------------------------------------------------------
# Parsing the raw <contract>.pl (step2/yul2chc output)
# ---------------------------------------------------------------------------

def parse_arg_tuple(tok):
    tok = tok.strip()
    m = re.fullmatch(r"var\((\w+)\)", tok)
    if m:
        return ('var', m.group(1))
    m = re.fullmatch(r"num\((0[xX][0-9a-fA-F]+|\d+)\)", tok)
    if m:
        return ('num', int(m.group(1), 0))
    return None


def split_top_level(s):
    """Split a comma-separated arg list; args here are always flat
    var(X)/num(N) tokens with no nested commas, so a plain split is safe."""
    return [a for a in s.split(',') if a.strip()]


CJ_RE = re.compile(r"at\('([^']+)',\s*cj\(var\((\w+)\),\s*'([^']+)',\s*'([^']+)'\)\)\.")
GOTO_RE = re.compile(r"at\('([^']+)',\s*goto\('([^']+)'\)\)\.")
NEXTLAB_RE = re.compile(r"nextlab\('([^']+)',\s*'([^']+)'\)\.")
ASGN_OP_RE = re.compile(r"at\('([^']+)',\s*asgn\(var\((\w+)\),\s*expr\((\w+)\(\[([^\]]*)\]\)\)\)\)\.")
ASGN_COPY_RE = re.compile(r"at\('([^']+)',\s*asgn\(var\((\w+)\),\s*expr\((var\(\w+\)|num\([^)]+\))\)\)\)\.")
FUNCALL_RE = re.compile(r"at\('([^']+)',\s*fun_call\((\w+),\s*\[([^\]]*)\],\s*\[([^\]]*)\]\)\)\.")
FUN_RE = re.compile(r"fun\((\w+),")


class RawFacts:
    """Yul temp variables (v0, v1, ...) are local to each function -- every
    function restarts its own numbering -- so every lookup table here is
    keyed by (function_prefix, var), never by var alone, to avoid conflating
    e.g. branches()'s own v3 with some unrelated function's v3."""

    def __init__(self, pl_path):
        self.successors = {}   # label -> list of successor labels (for loop back-edge detection)
        self.asgn_defs = {}    # (prefix,var) -> (op, [arg_tuple, ...])   (comparison/boolean ops)
        self.const_defs = {}   # (prefix,var) -> int   (compile-time literal)
        self.copy_defs = {}    # (prefix,var) -> arg_tuple   (identity pass-through)
        self.cjs = {}          # label -> (cond_var, true_label, false_label)
        self.func_prefixes = []
        self.phi_smuggled_vars = set()  # (prefix,var) ever passed as the sole
                                         # arg of a phiFunction -- see
                                         # is_short_circuit_var. Tracked as its
                                         # own set (not via asgn_defs, which
                                         # keeps only the LAST definition of
                                         # each output var and would silently
                                         # drop this when the same phi output
                                         # has one single-source arm per
                                         # predecessor, each redefining it)

        with open(pl_path, encoding='utf-8') as f:
            lines = f.readlines()

        for line in lines:
            m = FUN_RE.match(line.strip())
            if m:
                self.func_prefixes.append(m.group(1))
        # longest first, so a label matches its most specific owning function
        self.func_prefixes.sort(key=len, reverse=True)

        for line in lines:
            line = line.strip()
            self._try_cj(line)
            self._try_goto(line)
            self._try_nextlab(line)
            self._try_asgn_op(line)
            self._try_asgn_copy(line)
            self._try_funcall(line)

    def prefix_of(self, label):
        for p in self.func_prefixes:
            if label == p or label.startswith(p + '_'):
                return p
        return None

    def _add_succ(self, a, b):
        self.successors.setdefault(a, []).append(b)

    def _try_cj(self, line):
        m = CJ_RE.match(line)
        if not m:
            return
        label, cond, t1, t2 = m.groups()
        self.cjs[label] = (cond, t1, t2)
        self._add_succ(label, t1)
        self._add_succ(label, t2)

    def _try_goto(self, line):
        m = GOTO_RE.match(line)
        if not m:
            return
        label, target = m.groups()
        self._add_succ(label, target)

    def _try_nextlab(self, line):
        m = NEXTLAB_RE.match(line)
        if not m:
            return
        a, b = m.groups()
        self._add_succ(a, b)

    def _try_asgn_op(self, line):
        m = ASGN_OP_RE.match(line)
        if not m:
            return
        label, outvar, op, argstext = m.groups()
        prefix = self.prefix_of(label)
        if prefix is None:
            return
        args = []
        for tok in split_top_level(argstext):
            parsed = parse_arg_tuple(tok)
            if parsed is None:
                return  # unrecognized arg shape -- don't record a partial/broken def
            args.append(parsed)
        self.asgn_defs[(prefix, outvar)] = (op, args)
        if op == 'phiFunction' and len(args) == 1 and args[0][0] == 'var':
            self.phi_smuggled_vars.add((prefix, args[0][1]))

    def _try_asgn_copy(self, line):
        m = ASGN_COPY_RE.match(line)
        if not m:
            return
        label, outvar, rhs = m.groups()
        prefix = self.prefix_of(label)
        if prefix is None:
            return
        arg = parse_arg_tuple(rhs)
        if arg is not None:
            self.copy_defs[(prefix, outvar)] = arg

    def _try_funcall(self, line):
        m = FUNCALL_RE.match(line)
        if not m:
            return
        label, funcname, inargs_text, outargs_text = m.groups()
        prefix = self.prefix_of(label)
        if prefix is None:
            return
        inargs = [parse_arg_tuple(t) for t in split_top_level(inargs_text)]
        outargs = [parse_arg_tuple(t) for t in split_top_level(outargs_text)]
        if any(a is None for a in inargs) or any(a is None for a in outargs):
            return
        if len(outargs) != 1 or outargs[0][0] != 'var':
            return
        outvar = outargs[0][1]
        # a) exactly one literal input arg -> the output is that compile-time constant
        if len(inargs) == 1 and inargs[0][0] == 'num':
            self.const_defs[(prefix, outvar)] = inargs[0][1]
            return
        # b) a known identity/pass-through helper with exactly one var input
        #    (cleanup_*, identity, ...) -> output equals input
        if len(inargs) == 1 and inargs[0][0] == 'var' and \
           re.search(r'cleanup|identity', funcname, re.IGNORECASE):
            self.copy_defs[(prefix, outvar)] = inargs[0]
            return
        # otherwise: opaque call, not traceable -- leave unresolved on purpose

    def is_short_circuit_var(self, prefix, var):
        """True if `var` (within function `prefix`) is ever passed as the sole
        argument of a phiFunction -- e.g. `asgn(var(v10), expr(phiFunction([var(v6)])))`.

        This is the signature Yul leaves behind when lowering a short-circuit
        `A && B` / `A || B`: the block reached when A alone already decides
        the overall result carries A's own raw boolean value forward into the
        merge with B's result, instead of consuming it as an ordinary
        standalone if-condition. A candidate_def built from such a cj encodes
        only one leg of that merge -- verified on two real contracts
        (AuctionOffer's `require(newBid > bid && payment > 0)`,
        Operation's `require(x > 0 && y > 0 && x != y)`) where re-deriving
        and injecting "the" condition for that cj turned a real bug into a
        false negative. Checked against every cond_var in every validated
        SolTG fix from today: none of them are ever phi-smuggled this way."""
        return (prefix, var) in self.phi_smuggled_vars

    def is_loop_cj(self, label):
        """A cj is a loop back-edge iff either of its two targets can reach
        this cj's own label again through the raw control-flow graph."""
        _cond, t1, t2 = self.cjs[label]
        for start in (t1, t2):
            if self._can_reach(start, label):
                return True
        return False

    def _can_reach(self, start, target, limit=5000):
        seen = set()
        stack = [start]
        steps = 0
        while stack:
            steps += 1
            if steps > limit:
                # pathological/huge graph -- refuse to guess, treat as loop (safe: skip fix)
                return True
            node = stack.pop()
            if node == target:
                return True
            if node in seen:
                continue
            seen.add(node)
            stack.extend(self.successors.get(node, []))
        return False


# ---------------------------------------------------------------------------
# Symbolic derivation of the missing constraint
# ---------------------------------------------------------------------------

BOOLEAN_OPS = {'eq', 'lt', 'gt', 'slt', 'sgt', 'iszero', 'and', 'or', 'not'}


def is_boolean_defined(prefix, var, facts):
    key = (prefix, var)
    return key in facts.asgn_defs and facts.asgn_defs[key][0] in BOOLEAN_OPS


def resolve_leaf(arg, prefix, before_map, facts, depth=0):
    """Resolve a plain arithmetic leaf (NOT a boolean/comparison result) to
    either ('const', n) or ('var', head_letter). Returns None if it can't
    be traced all the way back to a literal or a head variable."""
    if depth > 20:
        return None
    if arg[0] == 'num':
        return ('const', arg[1])
    v = arg[1]
    key = (prefix, v)
    if key in facts.const_defs:
        return ('const', facts.const_defs[key])
    if key in facts.copy_defs:
        return resolve_leaf(facts.copy_defs[key], prefix, before_map, facts, depth + 1)
    if v in before_map:
        return ('var', before_map[v])
    return None


def constraint_for(var, target, prefix, before_map, facts, depth=0):
    """Returns a list of CLPQ conjunct strings (e.g. ["J=0"]) that must all
    hold for `var` to equal `target` (0 or 1), expressed purely in terms of
    the candidate definition's head variables and literals -- or None if it
    can't be determined without a disjunction / unsupported construct
    (in which case the caller must skip the fix rather than guess)."""
    if depth > 15:
        return None
    key = (prefix, var)
    if key not in facts.asgn_defs:
        leaf = resolve_leaf(('var', var), prefix, before_map, facts, depth)
        if leaf is None:
            return None
        kind, val = leaf
        if kind == 'const':
            return [] if val == target else None  # None = provably impossible: bail out, don't patch
        return [f"{val}={target}"]

    op, args = facts.asgn_defs[key]

    if op == 'iszero' and len(args) == 1:
        return constraint_for_eq(args[0], ('num', 0), target, prefix, before_map, facts, depth)

    if op == 'eq' and len(args) == 2:
        return constraint_for_eq(args[0], args[1], target, prefix, before_map, facts, depth)

    if op in ('lt', 'gt', 'slt', 'sgt') and len(args) == 2:
        ra = resolve_leaf(args[0], prefix, before_map, facts, depth)
        rb = resolve_leaf(args[1], prefix, before_map, facts, depth)
        if ra is None or rb is None:
            return None
        sa = ra[1]
        sb = rb[1]
        lt_like = op in ('lt', 'slt')
        if target == 1:
            return [f"{sa}<{sb}"] if lt_like else [f"{sa}>{sb}"]
        else:
            # Prolog's "less-or-equal" operator is =< , not <= (which is
            # not a defined operator at all and is a syntax error)
            return [f"{sa}>={sb}"] if lt_like else [f"{sa}=<{sb}"]

    if op == 'not' and len(args) == 1 and args[0][0] == 'var':
        return constraint_for(args[0][1], 1 - target, prefix, before_map, facts, depth + 1)

    if op == 'and' and target == 1 and len(args) == 2:
        c1 = constraint_for_arg(args[0], 1, prefix, before_map, facts, depth)
        c2 = constraint_for_arg(args[1], 1, prefix, before_map, facts, depth)
        if c1 is None or c2 is None:
            return None
        return c1 + c2

    if op == 'or' and target == 0 and len(args) == 2:
        c1 = constraint_for_arg(args[0], 0, prefix, before_map, facts, depth)
        c2 = constraint_for_arg(args[1], 0, prefix, before_map, facts, depth)
        if c1 is None or c2 is None:
            return None
        return c1 + c2

    # unsupported op, or a shape that would require a disjunction we don't
    # emit (and/target=0, or/target=1) -- refuse to guess
    return None


def constraint_for_arg(arg, target, prefix, before_map, facts, depth):
    if arg[0] == 'var':
        return constraint_for(arg[1], target, prefix, before_map, facts, depth + 1)
    # a literal used where a boolean was expected: trivial/contradictory
    return [] if arg[1] == target else None


def constraint_for_eq(a, b, target, prefix, before_map, facts, depth):
    # Prefer recursing through a nested boolean if one side is a
    # comparison-defined variable and the other is the literal 0/1.
    for boolarg, litarg in ((a, b), (b, a)):
        if boolarg[0] == 'var' and is_boolean_defined(prefix, boolarg[1], facts) and \
           litarg[0] == 'num' and litarg[1] in (0, 1):
            want = target if litarg[1] == 1 else (1 - target)
            return constraint_for(boolarg[1], want, prefix, before_map, facts, depth + 1)
    # otherwise: plain arithmetic (in)equality between two resolvable leaves
    ra = resolve_leaf(a, prefix, before_map, facts, depth)
    rb = resolve_leaf(b, prefix, before_map, facts, depth)
    if ra is None or rb is None:
        return None
    sa, sb = ra[1], rb[1]
    return [f"{sa}={sb}"] if target == 1 else [f"{sa}=\\={sb}"]


# ---------------------------------------------------------------------------
# Parsing <contract>.t.pl-defs.txt for candidate definitions with a cj
# ---------------------------------------------------------------------------

DEF_ENTRY_RE = re.compile(
    r"^(\w+)\([^)]*\)\s*:-\s*"
    r"reachable\(cf\(cmd\(([^,]+),\s*cj\(var\((\w+)\),\s*[^,]+,\s*[^)]+\)\),"
    r"\s*\(\[[^\]]*\],\s*\[[^\]]*\],\s*\[([^\]]*)\]\)\),",
)


def normalize_defs_text(text):
    """Join each candidate-definition entry back onto one line. Entries span
    a variable number of physical lines but always end with a lone clause-
    terminating '.'; keep accumulating lines until one does."""
    out = []
    buf = ''
    for line in text.split('\n'):
        stripped = line.strip()
        if not stripped:
            continue
        buf = (buf + ' ' + stripped) if buf else stripped
        if buf.endswith('.'):
            out.append(buf)
            buf = ''
    if buf:
        out.append(buf)
    return '\n'.join(out)


def parse_pair_list(text):
    """Parse a flat "(yulvar,HeadLetter),(yulvar,HeadLetter),..." list into
    a dict. Last occurrence wins if a name repeats (shouldn't normally)."""
    out = {}
    for m in re.finditer(r"\((\w+),(\w+)\)", text):
        out[m.group(1)] = m.group(2)
    return out


def find_candidate_defs(defs_path):
    """Yields (pred_name, cj_label, cond_var, before_map) for every candidate
    definition whose folded body starts with a `cj`."""
    with open(defs_path, encoding='utf-8') as f:
        raw = f.read()
    text = normalize_defs_text(raw)
    for line in text.split('\n'):
        line = line.strip()
        if not line:
            continue
        m = DEF_ENTRY_RE.match(line)
        if not m:
            continue
        pred_name, cj_label, cond_var, pairs_text = m.groups()
        before_map = parse_pair_list(pairs_text)
        yield pred_name, cj_label.strip(), cond_var, before_map


# ---------------------------------------------------------------------------
# Patching <contract>.t_constr.pl
# ---------------------------------------------------------------------------

CLAUSE_RE_TMPL = r"^(\s*{pred}\([^)]*\)\s*:-\s*constr\(\()(.*?)(\)\)\s*,.*)$"


def patch_t_constr(t_constr_path, patches, log):
    """patches: {pred_name: (cond_letter, cond_var, func_prefix, facts, before_map)}"""
    with open(t_constr_path, encoding='utf-8') as f:
        lines = f.readlines()

    out_lines = []
    n_patched = 0
    for line in lines:
        stripped_nl = line.rstrip('\n')
        patched_line = stripped_nl
        for pred_name, (cond_letter, cond_var, func_prefix, facts, before_map) in patches.items():
            m = re.match(CLAUSE_RE_TMPL.format(pred=re.escape(pred_name)), stripped_nl)
            if not m:
                continue
            line_prefix, constr_body, suffix = m.groups()
            # find "CondLetter=<digit>" among the top-level comma-separated
            # conjuncts of constr_body
            conjuncts = [c.strip() for c in constr_body.split(',')]
            value = None
            for c in conjuncts:
                cm = re.fullmatch(rf"{re.escape(cond_letter)}=(\d+)", c)
                if cm:
                    value = int(cm.group(1))
                    break
            if value is None or value not in (0, 1):
                log.append(f"  {pred_name}: clause pins {cond_letter} to a non-0/1 value or not at all -- skipped")
                continue
            extra = constraint_for(cond_var, value, func_prefix, before_map, facts)
            if extra is None:
                log.append(f"  {pred_name}: clause with {cond_letter}={value} -- could not derive a safe constraint, skipped")
                continue
            if not extra:
                log.append(f"  {pred_name}: clause with {cond_letter}={value} -- condition already trivially satisfied, nothing to add")
                continue
            if all(e in conjuncts for e in extra):
                log.append(f"  {pred_name}: clause with {cond_letter}={value} -- already patched, skipped")
                continue
            new_body = constr_body + ', ' + ', '.join(extra)
            patched_line = line_prefix + new_body + suffix
            n_patched += 1
            log.append(f"  {pred_name}: clause with {cond_letter}={value} -> added constr({', '.join(extra)})")
            break
        out_lines.append(patched_line + '\n')

    with open(t_constr_path, 'w', encoding='utf-8') as f:
        f.writelines(out_lines)
    return n_patched


# ---------------------------------------------------------------------------
# Restoring the uintN range on the analysis entry point's own parameters
# ---------------------------------------------------------------------------
#
# --gen-aux's aux.pl (see sol2tpl.py's generate_aux_pl) injects each of the
# analyzed function's own parameters as a bare, completely free Prolog
# variable (num(_V_v0), num(_V_v1), ...) -- nothing upstream ever reads real
# calldata, so nothing constrains it to the range its declared Solidity type
# actually guarantees at the EVM level: a uintN value read from calldata is a
# fixed-width machine word, it can never be negative or exceed 2**N-1. That
# guarantee is implicit in fixed-width bytecode and is never re-asserted in
# our CHC translation, whose values are unbounded integers. Left alone,
# Z3/CLP(Q) is free to pick an impossible value like -1 for it, which can
# make an assert look violated when no real call could ever trigger it.
# Verified false positive: Math.max(uint256,uint256)'s own asserts restate
# their branch condition exactly (so can never actually fail) yet the tool
# reports "derivable" with a == -1.
#
# Injecting the range directly into aux.pl's prop/3 body was tried and does
# NOT work: the transform engine executes a bare comparison goal there
# immediately, as a real Prolog call, and instantiation-errors out on the
# still-free variable -- the constraint is silently dropped rather than
# carried through symbolically. This patches it in afterwards instead, the
# same way patch_t_constr does: find a candidate_def whose before_map still
# carries the function's own v0..v(n-1) (any cj inside the function that
# uses a parameter directly -- exactly the shape that causes the false
# positive in the first place -- keeps it there), and add the range as an
# unconditional extra conjunct to every one of that predicate's clauses.

FUN_DECL_RE_TMPL = r"^fun\({pred}\s*,\s*\[([^\]]*)\]\s*,"
AUX_ENTRY_RE = re.compile(r"fun_call\(\s*(\w+)\s*,")
UINT_PARAM_RE = re.compile(r'\buint(\d*)\b')
BOOL_PARAM_RE = re.compile(r'\bbool\b')


def find_target_func(aux_path):
    """Mangled entry-point function name (e.g. 'subO_fun_max_34') that
    aux.pl's prop/3 calls, or None."""
    if not os.path.isfile(aux_path):
        return None
    with open(aux_path, encoding='utf-8') as f:
        m = AUX_ENTRY_RE.search(f.read())
    return m.group(1) if m else None


def find_fun_params(pl_path, mangled_name):
    """Raw v-names (v0, v1, ...) of mangled_name's own declared parameters,
    in order, from its fun(...) fact in the raw .pl. None if not found."""
    pat = re.compile(FUN_DECL_RE_TMPL.format(pred=re.escape(mangled_name)))
    with open(pl_path, encoding='utf-8') as f:
        for line in f:
            m = pat.match(line.strip())
            if m:
                return re.findall(r'var\((\w+)\)', m.group(1))
    return None


def clean_function_name(mangled_name):
    m = re.match(r'^subO_fun_(\w+?)_\d+$', mangled_name)
    return m.group(1) if m else None


def solidity_param_bit_widths(sol_path, clean_name, n_params):
    """Effective bit-width of each of clean_name's parameters, in
    declaration order, read from the .sol source; None per-entry for a
    parameter this can't derive a range for, or the whole result None if
    the signature can't be found or its arity doesn't match n_params.
    Assumes the Yul-level input order matches the Solidity declaration
    order (true for the simple, non-struct/array signatures this is meant
    for). `bool` is treated as an effective 1-bit width (range 0..1): a
    bool parameter decoded from calldata is ABI-guaranteed to be exactly 0
    or 1, but nothing upstream re-asserts that either -- same missing-range
    gap as uintN, just for a different type. Verified: a raw bool
    parameter left unconstrained could take a model value like 3, which a
    real call could never produce (caught while investigating
    while_nested_continue_fail.sol -- didn't change that particular
    verdict since the same bug was also reachable through the valid b=1,
    but a different contract could have the impossible value actually
    drive the result)."""
    if not os.path.isfile(sol_path):
        return None
    with open(sol_path, encoding='utf-8') as f:
        sol = f.read()
    sig = re.search(rf'function\s+{re.escape(clean_name)}\s*\(([^)]*)\)', sol)
    if not sig:
        return None
    raw_params = [p.strip() for p in sig.group(1).split(',') if p.strip()]
    if len(raw_params) != n_params:
        return None
    widths = []
    for part in raw_params:
        um = UINT_PARAM_RE.search(part)
        if um:
            widths.append(int(um.group(1)) if um.group(1) else 256)
        elif BOOL_PARAM_RE.search(part):
            widths.append(1)
        elif re.search(r'\baddress\b', part):
            # an ABI-decoded address is always < 2^160, same missing-range
            # gap as uintN (seen: newOwner = 2^160 + ... style witnesses)
            widths.append(160)
        else:
            widths.append(None)
    return widths


PARAM_CLAUSE_RE_TMPL = r"^(\s*{pred}\([^)]*\)\s*:-\s*constr\(\()(.*?)(\)\).*)$"


INCORRECT_CLAUSE_RE = re.compile(r"^(incorrect\s*:-\s*constr\(\()(.*?)(\)\),.*)$")


def _split_top_level(text):
    parts, cur, depth = [], [], 0
    for ch in text:
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
        if ch == ',' and depth == 0:
            parts.append(''.join(cur).strip())
            cur = []
        else:
            cur.append(ch)
    if cur:
        parts.append(''.join(cur).strip())
    return [p for p in parts if p]


def patch_param_range_on_incorrect(t_constr_path, params, widths):
    """Fallback for a function the transform fully inlined into `incorrect`
    (no candidate_def of its own survives, so there is no predicate head to
    attach the range to -- seen on P28_order_range_bug and
    OwnableFaulty_vgood, where Z3 then picked x = -200 / newOwner = -1).

    A parameter is a free input of the `incorrect` clause: one conjunct
    `M=N` where N occurs nowhere else in the clause (same rule as
    zmiout_parse.find_param_letters). The free inputs appear in REVERSE
    declaration order (Yul evaluates call arguments right to left; checked
    on P26/P27/P28 with forced distinct values). The range is added on M
    only when the number of free inputs equals the number of parameters,
    otherwise that clause is left untouched -- never a guess."""
    with open(t_constr_path, encoding='utf-8') as f:
        lines = f.readlines()
    n_patched = 0
    out = []
    for line in lines:
        m = INCORRECT_CLAUSE_RE.match(line.rstrip('\n'))
        if not m:
            out.append(line)
            continue
        prefix, body, rest = m.groups()
        whole = m.group(0)
        conj = _split_top_level(body)
        letters = []
        for c in conj:
            mm = re.fullmatch(r'([A-Z][A-Za-z0-9]*)=([A-Z][A-Za-z0-9]*)', c)
            if mm and len(re.findall(rf'(?<![A-Za-z0-9_]){mm.group(2)}(?![A-Za-z0-9_])', whole)) == 1:
                letters.append(mm.group(1))
        if len(letters) != len(params):
            out.append(line)
            continue
        new = []
        for letter, w in zip(reversed(letters), widths):
            if w:
                for c in (f"0=<{letter}", f"{letter}=<{(1 << w) - 1}"):
                    if c not in conj:
                        new.append(c)
        if not new:
            out.append(line)
            continue
        out.append(f"{prefix}{body}, {', '.join(new)}{rest}\n")
        n_patched += 1
    if n_patched:
        with open(t_constr_path, 'w', encoding='utf-8') as f:
            f.writelines(out)
    return n_patched


def patch_param_range_constraints(t_constr_path, pl_path, defs_path, sol_path, aux_path, facts, log):
    func = find_target_func(aux_path)
    if not func:
        return 0
    params = find_fun_params(pl_path, func)
    if not params:
        return 0
    widths = solidity_param_bit_widths(sol_path, clean_function_name(func) or '', len(params))
    if not widths or not any(widths):
        return 0

    range_by_var = {}
    for v, w in zip(params, widths):
        if w:
            range_by_var[v] = (1 << w) - 1

    # Collect EVERY candidate_def predicate belonging to `func` whose
    # before_map retains all of its own parameters -- not just the first
    # one found. A loop-free function normally has exactly one such
    # reachability point (its own entry), but a loop-bearing one can have
    # several distinct ones (e.g. the function's own entry check AND,
    # separately, the loop's own exit-condition check deeper in the CFG,
    # each becoming its own candidate_def/predicate) -- patching only the
    # first left the others completely unconstrained, and a value read
    # through one of those other predicates could still be picked
    # impossible (verified false positive: LoopSumFaultySmall, n == -1,
    # even though `new5` -- the function's entry predicate -- was
    # correctly patched; `new32`, a separate predicate rooted at the
    # loop's own exit-condition cj, was not).
    targets = []
    seen_preds = set()
    for pred_name, cj_label, _cond_var, before_map in find_candidate_defs(defs_path):
        if pred_name in seen_preds:
            continue
        if cj_label not in facts.cjs:
            continue
        if facts.prefix_of(cj_label) != func:
            continue
        if not all(v in before_map for v in range_by_var):
            continue
        conjuncts = []
        for v, max_val in range_by_var.items():
            letter = before_map[v]
            conjuncts.append(f"0=<{letter}")
            conjuncts.append(f"{letter}=<{max_val}")
        targets.append((pred_name, conjuncts))
        seen_preds.add(pred_name)

    if not targets:
        n = patch_param_range_on_incorrect(t_constr_path, params, widths)
        if n:
            log.append(f"  [param-range] {func}: no candidate_def retains its own parameters, "
                       f"function inlined into `incorrect` -- range added on its free inputs "
                       f"in {n} incorrect clause(s)")
            return n
        log.append(f"  [param-range] {func}: no candidate_def retains its own parameters "
                   f"({', '.join(range_by_var)}) -- could not attach the range constraint")
        return 0

    with open(t_constr_path, encoding='utf-8') as f:
        lines = f.readlines()

    total_patched = 0
    for chosen_pred, chosen_conjuncts in targets:
        pat = re.compile(PARAM_CLAUSE_RE_TMPL.format(pred=re.escape(chosen_pred)))
        out_lines = []
        n_patched = 0
        for line in lines:
            stripped_nl = line.rstrip('\n')
            m = pat.match(stripped_nl)
            if not m:
                out_lines.append(line)
                continue
            prefix, constr_body, rest = m.groups()
            existing = {c.strip() for c in constr_body.split(',')}
            missing = [c for c in chosen_conjuncts if c not in existing]
            if not missing:
                out_lines.append(line)
                continue
            new_body = constr_body + ', ' + ', '.join(missing)
            out_lines.append(f"{prefix}{new_body}{rest}\n")
            n_patched += 1
        lines = out_lines
        if n_patched:
            log.append(f"  [param-range] {chosen_pred}: added {', '.join(chosen_conjuncts)} "
                       f"to {n_patched} clause(s) -- restores the uintN range {func}'s own "
                       f"parameters have at the real EVM level")
            total_patched += n_patched

    if total_patched:
        with open(t_constr_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
    return total_patched


# ---------------------------------------------------------------------------
# Dropping redundant/wrong caller-side pre-bindings of a branch-selector arg
# ---------------------------------------------------------------------------

CALLER_CLAUSE_RE = re.compile(
    r"^(\s*)(\w+)(?:\(([^)]*)\))?\s*:-\s*constr\(\((.*?)\)\),(.*)$"
)


MAX_SAFE_CLAUSE_COUNT = 15

# patch_t_constr / patch_caller_prebindings re-derive a branch condition from
# before_map and re-inject it into every clause of a candidate_def predicate,
# on the assumption that find_candidate_defs' single recorded cj occurrence
# is valid for ALL of that predicate's clauses. That assumption can be false
# even under MAX_SAFE_CLAUSE_COUNT and even with matching merge shapes across
# cj-siblings: two genuinely distinct call sites can still fold into clauses
# of the SAME predicate name, and before_map derived from only one of them
# then gets misapplied to the other. Verified false positives this caused,
# on contracts with no other explanation for the discrepancy (confirmed by
# re-running the very same .t_constr.pl with this flag off): Math.max
# (both branches restate their own branch condition exactly, so neither
# assert can ever fail) and simple_if (the "if" branch has no assert at
# all, the "else" branch's assert restates its own condition tautologically
# -- confirmed against an independent earlier run of the identical source).
# A systematic cross-check on 2026-09-10 across every "derivable" result in
# that day's full regeneration found patch_t_constr responsible for 0 of the
# 20 real detections and at least 1 confirmed false positive -- so it is
# disabled by default here pending a safe, general fix (a first attempt,
# requiring identical head-argument layouts across a predicate's own
# clauses, was tried and reverted: it broke branches_merge_variables_3's own
# validated new3, whose legitimately single-origin clauses happen to diverge
# in head shape from nested folding). patch_caller_prebindings' own premise
# ("the callee already re-derives this, so the caller's copy is redundant")
# depends entirely on patch_t_constr actually doing that re-derivation, so
# it is disabled together with it, not independently. This does NOT disable
# patch_param_range_constraints or patch_identity_aliasing, which are
# separate, independently-validated mechanisms.
DISABLE_PATCH_T_CONSTR = True


def count_pred_clauses(t_constr_path, pred_name):
    """Number of alternative clauses pred_name has in t_constr_path."""
    n = 0
    with open(t_constr_path, encoding='utf-8') as f:
        for line in f:
            if re.match(rf"^\s*{re.escape(pred_name)}\(", line):
                n += 1
    return n


def find_pred_head_params(t_constr_path, pred_name):
    """Head parameter list (as written) of pred_name's first clause in
    t_constr_path, or None. The branch-selector's position within it is the
    same across all of pred_name's own alternative clauses -- they all share
    the same predicate arity/signature from the single candidate_def call
    site that generated them; only the clause-internal helper variables
    after that shared prefix differ per clause -- so the first clause found
    is enough."""
    with open(t_constr_path, encoding='utf-8') as f:
        for line in f:
            m = re.match(rf"^\s*{re.escape(pred_name)}\(([^)]*)\)\s*:-", line.strip())
            if m:
                return [p.strip() for p in m.group(1).split(',')]
    return None


QUERY_DIRECTIVE_RE = re.compile(r"^\s*:-\s*query\s+(\w+)\s*/\s*\d+\s*\.\s*$")


def find_query_pred(t_constr_path):
    """Name of the top-level query predicate (e.g. 'incorrect'), from the
    ':- query Name/Arity.' directive that yul-chc always emits."""
    with open(t_constr_path, encoding='utf-8') as f:
        for line in f:
            m = QUERY_DIRECTIVE_RE.match(line)
            if m:
                return m.group(1)
    return None


def patch_caller_prebindings(t_constr_path, patches, log):
    """patches: {pred_name: (cond_letter, cond_var, func_prefix, facts, before_map)}

    Only the top-level query predicate's own clauses are eligible: that's
    the one scenario this was verified against (branches_merge_variables_3:
    incorrect's alternative clauses pre-bound a branch-selector argument to
    an inverted value relative to their own x-range condition). A generic
    internal predicate calling one of `patches`' targets can legitimately
    need to keep its own pre-binding -- e.g. under Solidity 0.8 checked
    arithmetic, a require()-guarded function generates many internal
    overflow-check predicates, each called from exactly one real context;
    dropping their caller's pre-binding there let Z3 pick branch
    combinations the require() would have reverted, producing bogus
    negative-uint counterexamples (seen on AuctionOffer: newBid == -1)."""
    query_pred = find_query_pred(t_constr_path)
    if query_pred is None:
        return 0
    positions = {}
    for pred_name, (cond_letter, *_rest) in patches.items():
        head_params = find_pred_head_params(t_constr_path, pred_name)
        if head_params is None or cond_letter not in head_params:
            continue
        positions[pred_name] = head_params.index(cond_letter)

    if not positions:
        return 0

    call_re_by_pred = {p: re.compile(rf"\b{re.escape(p)}\(([^()]*)\)") for p in positions}

    with open(t_constr_path, encoding='utf-8') as f:
        lines = f.readlines()

    out_lines = []
    n_patched = 0
    for line in lines:
        stripped_nl = line.rstrip('\n')
        m = CALLER_CLAUSE_RE.match(stripped_nl)
        if not m:
            out_lines.append(line)
            continue
        _ws, caller_pred, caller_head, constr_body, rest = m.groups()
        if caller_pred != query_pred:
            out_lines.append(line)
            continue
        conjuncts = [c.strip() for c in constr_body.split(',')]
        removed_any = False
        for callee, idx in positions.items():
            if callee == caller_pred:
                continue  # that predicate's own branch-value conjuncts, not a caller pre-binding
            for call_m in call_re_by_pred[callee].finditer(rest):
                call_args = [a.strip() for a in call_m.group(1).split(',')]
                if idx >= len(call_args):
                    continue
                call_arg_var = call_args[idx]
                if not re.fullmatch(r'[A-Za-z][A-Za-z0-9]*', call_arg_var):
                    continue  # not a plain variable -- nothing to strip
                for i, c in enumerate(conjuncts):
                    if re.fullmatch(rf"{re.escape(call_arg_var)}=[01]", c):
                        log.append(f"  {caller_pred}: dropped redundant/incorrect pre-binding '{c}' "
                                   f"on its call to {callee} (branch-selector arg) -- "
                                   f"{callee} already re-derives it from scratch")
                        conjuncts.pop(i)
                        removed_any = True
                        break
        if removed_any:
            head_text = f"({caller_head})" if caller_head is not None else ""
            new_body = ', '.join(conjuncts)
            patched_line = f"{caller_pred}{head_text} :- constr(({new_body})),{rest}"
            out_lines.append(patched_line + '\n')
            n_patched += 1
        else:
            out_lines.append(line)

    if n_patched:
        with open(t_constr_path, 'w', encoding='utf-8') as f:
            f.writelines(out_lines)
    return n_patched


# ---------------------------------------------------------------------------
# Eagerly asserting hard Prolog aliases from "identity" (pass-through)
# predicates, so Z3 sees them before the call, not only after
# ---------------------------------------------------------------------------

SINGLE_CLAUSE_TRUE_RE_TMPL = r"^\s*{pred}\(([^)]*)\)\s*:-\s*constr\(\(true\)\)\.\s*$"


def find_identity_predicates(t_constr_path):
    """A predicate with EXACTLY ONE clause, body constr((true)), whose head
    repeats the same variable name at more than one position, is a pure
    Prolog-unification pass-through: calling it FORCES those argument
    positions equal, unconditionally, by construction -- not a soft Z3
    constraint but a hard fact, true before Z3 is ever consulted.

    But the call site's own leading constr(...) (checked eagerly, straight
    away) has no way to know that yet -- it only becomes true once this
    predicate's own clause is actually resolved, which (per how these CHC
    clauses are written: constr(...) first, calls after) happens AFTER the
    caller's own constr(...) is already checked. A caller can therefore
    eagerly "prove" something using two of this predicate's argument
    positions as if they were independent free variables, when they are, in
    fact, guaranteed to end up equal -- exactly the kind of gap that let an
    impossible clause variant (see notes on branches_merge_variables_3)
    look satisfiable and produce a spurious extra counterexample for a
    branch that was already covered by another, valid witness.

    Returns {pred_name: [(pos_i, pos_j), ...]} -- pairs of 0-based
    argument positions that any call to pred_name forces equal.
    """
    # First, find every predicate name with a clause at all, then check it
    # has EXACTLY one and that one is this trivial shape.
    clause_count = {}
    single_clause_heads = {}
    with open(t_constr_path, encoding='utf-8') as f:
        for line in f:
            m = re.match(r"^\s*(\w+)\(([^)]*)\)\s*:-", line)
            if not m:
                continue
            pred_name = m.group(1)
            clause_count[pred_name] = clause_count.get(pred_name, 0) + 1
            tm = re.match(SINGLE_CLAUSE_TRUE_RE_TMPL.format(pred=re.escape(pred_name)), line)
            if tm:
                single_clause_heads[pred_name] = [p.strip() for p in tm.group(1).split(',')]

    identities = {}
    for pred_name, head_params in single_clause_heads.items():
        if clause_count.get(pred_name) != 1:
            continue  # some OTHER clause of the same name exists elsewhere -- not a pure identity
        groups = {}
        for pos, var in enumerate(head_params):
            groups.setdefault(var, []).append(pos)
        pairs = []
        for var, positions in groups.items():
            if len(positions) < 2:
                continue
            first = positions[0]
            pairs.extend((first, p) for p in positions[1:])
        if pairs:
            identities[pred_name] = pairs
    return identities


def patch_identity_aliasing(t_constr_path, log, unreliable_callers=frozenset()):
    """For every identity predicate found (see find_identity_predicates),
    inject the equalities its calls are guaranteed to force into the
    CALLER's own leading constr(...), eagerly.

    unreliable_callers: predicate names to leave untouched as callers (not
    as identity targets). These are predicates patch_t_constr itself refused
    to patch because they're one of several sibling forks of the same cj
    that merge variables differently from each other (see main()) -- i.e.
    forks whose exact semantics per-clause aren't trustworthy. Asserting an
    identity-forced equality INTO one of those callers is just as unsound as
    injecting a re-derived branch condition into it, for the same reason:
    it treats a context-specific fork as if it were the single, general
    truth. Verified on Operation_faulty_vgood, where new2 is a genuine
    identity predicate but 4 of its callers (new16/21/78/83, the same
    mismatched-merge group patch_t_constr already skips) were exactly the
    ones whose eager-aliasing turned a real bug into a false negative."""
    identities = find_identity_predicates(t_constr_path)
    if not identities:
        return 0

    call_re_by_pred = {p: re.compile(rf"\b{re.escape(p)}\(([^()]*)\)") for p in identities}

    with open(t_constr_path, encoding='utf-8') as f:
        lines = f.readlines()

    out_lines = []
    n_patched = 0
    for line in lines:
        stripped_nl = line.rstrip('\n')
        m = CALLER_CLAUSE_RE.match(stripped_nl)
        if not m:
            out_lines.append(line)
            continue
        _ws, caller_pred, caller_head, constr_body, rest = m.groups()
        if caller_pred in unreliable_callers:
            out_lines.append(line)
            continue
        conjuncts = [c.strip() for c in constr_body.split(',')]
        existing = set(conjuncts)
        added = []
        for callee, pairs in identities.items():
            if callee == caller_pred:
                continue  # a pure identity predicate's own clause has nothing to alias-inject into itself
            for call_m in call_re_by_pred[callee].finditer(rest):
                call_args = [a.strip() for a in call_m.group(1).split(',')]
                for i, j in pairs:
                    if i >= len(call_args) or j >= len(call_args):
                        continue
                    vi, vj = call_args[i], call_args[j]
                    if vi == vj:
                        continue  # caller already passes the identical variable -- nothing to add
                    conj = f"{vi}={vj}"
                    conj_rev = f"{vj}={vi}"
                    if conj in existing or conj_rev in existing or conj in added:
                        continue
                    added.append(conj)
        if added:
            new_body = ', '.join(conjuncts + added)
            head_text = f"({caller_head})" if caller_head is not None else ""
            patched_line = f"{caller_pred}{head_text} :- constr(({new_body})),{rest}"
            out_lines.append(patched_line + '\n')
            n_patched += 1
            log.append(f"  {caller_pred}: asserted {', '.join(added)} eagerly (forced by its call to "
                       f"identity predicate) -- was only knowable after the call, letting an impossible "
                       f"case look satisfiable")
        else:
            out_lines.append(line)

    if n_patched:
        with open(t_constr_path, 'w', encoding='utf-8') as f:
            f.writelines(out_lines)
    return n_patched


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('t_constr_pl', help='<contract>.t_constr.pl (patched in place)')
    args = ap.parse_args()

    t_constr_path = os.path.abspath(args.t_constr_pl)
    if not t_constr_path.endswith('.t_constr.pl'):
        print(f"Usage: {sys.argv[0]} <contract>.t_constr.pl")
        sys.exit(1)
    base_dir = os.path.dirname(t_constr_path)
    base = os.path.basename(t_constr_path)[:-len('.t_constr.pl')]
    pl_path = os.path.join(base_dir, base + '.pl')
    defs_path = os.path.join(base_dir, base + '.t.pl-defs.txt')
    sol_path = os.path.join(base_dir, base + '.sol')
    aux_path = os.path.join(base_dir, base + '.aux.pl')

    for p in (pl_path, defs_path):
        if not os.path.isfile(p):
            print(f"[step4b] required file not found: {p} -- skipping (no patch applied)")
            sys.exit(0)

    facts = RawFacts(pl_path)

    log0 = []
    n0 = patch_param_range_constraints(t_constr_path, pl_path, defs_path, sol_path, aux_path, facts, log0)
    for l in log0:
        print(f"[step4b] {l}")

    patches = {}
    pred_cj_label = {}
    unreliable_preds = set()
    log = []
    for pred_name, cj_label, cond_var, before_map in find_candidate_defs(defs_path):
        if cj_label not in facts.cjs:
            log.append(f"  {pred_name}: cj label {cj_label} not found in raw facts -- skipped")
            continue
        if facts.is_loop_cj(cj_label):
            log.append(f"  {pred_name}: cj at {cj_label} is a loop back-edge -- left untouched (by design)")
            continue
        func_prefix = facts.prefix_of(cj_label)
        if func_prefix is None:
            log.append(f"  {pred_name}: could not determine the owning function for {cj_label} -- skipped")
            continue
        cond_letter = before_map.get(cond_var)
        if cond_letter is None:
            log.append(f"  {pred_name}: condition var {cond_var} not found in the candidate def's state mapping -- skipped")
            continue
        if facts.is_short_circuit_var(func_prefix, cond_var):
            log.append(f"  {pred_name}: condition var {cond_var} is threaded through a phiFunction "
                       f"(part of a short-circuit && / || chain, e.g. a multi-term require()) -- "
                       f"re-deriving a single condition for it is unsafe -- skipped")
            unreliable_preds.add(pred_name)
            continue
        # find_candidate_defs records ONE cj occurrence per predicate name
        # (the first fold that created it), and constraint_for's derived
        # condition is only valid for clauses that trace back to THAT same
        # occurrence. A predicate built from a single, modest if/else fold
        # (the validated scenario -- branches_merge_variables_*, 7-11
        # clauses) stays within one semantic meaning per clause. A predicate
        # reused generically across many structurally-similar but distinct
        # original branch points (seen on AuctionOffer's `new3`: 39 clauses,
        # Solidity 0.8 checked-arithmetic helpers) can end up with clauses
        # that share the same cond_letter position for an UNRELATED
        # condition -- injecting the one derived formula into those clauses
        # is wrong and can turn a real bug into a false negative (verified:
        # forcing just the "X=1" derived condition alone on AuctionOffer
        # already flips derivable -> nonDerivable). Bail out rather than
        # guess when the clause count is high enough to suggest that reuse.
        n_clauses = count_pred_clauses(t_constr_path, pred_name)
        if n_clauses > MAX_SAFE_CLAUSE_COUNT:
            log.append(f"  {pred_name}: has {n_clauses} alternative clauses (> {MAX_SAFE_CLAUSE_COUNT}) -- "
                       f"likely a generically-reused predicate, not a single-origin branch fold -- skipped")
            unreliable_preds.add(pred_name)
            continue
        # patch_caller_prebindings' whole premise is "the callee already
        # re-derives this value from scratch, so the caller's own copy is
        # redundant" -- only true when the callee actually HAS more than one
        # alternative to choose between. A single-clause predicate (seen on
        # OwnableFaulty: subO_require_helper/subO_assert_helper both fold to
        # ONE unconditional clause, e.g. `new2(...) :- constr((L=0)).`) makes
        # no choice at all; dropping the caller's pre-binding on a call to it
        # deletes real information with nothing re-derived to replace it --
        # verified: this alone took OwnableFaulty from 1 correct test to 3
        # spurious ones. branches_merge_variables_3's new3 (the validated
        # scenario for the drop) has 7 clauses, never just one.
        if n_clauses < 2:
            log.append(f"  {pred_name}: has only {n_clauses} clause -- makes no choice between "
                       f"alternatives, so a caller's pre-binding on a call to it is real information, "
                       f"not redundancy -- left untouched")
            unreliable_preds.add(pred_name)
            continue
        patches[pred_name] = (cond_letter, cond_var, func_prefix, facts, before_map)
        pred_cj_label[pred_name] = cj_label

    # The same cj can be folded into more than one candidate_def predicate
    # (different unfolding contexts reaching it). before_map sometimes merges
    # two distinct raw variables onto the same head letter when they're
    # provably equal in that context (e.g. a `cleanup_*`-style copy) -- safe
    # on its own. But if sibling predicates built from the SAME cj disagree
    # on *which* variables merge (or how many), that's a sign at least one of
    # them comes from a genuinely different context that isn't safe to treat
    # identically. Verified: AuctionOffer's new12/new46 (same cj) both merge
    # {L:2,M:2} -- identical, and patching both is correct. Operation's
    # new16/new21/new50/new55 (same cj) merge {J:2,K:2} / {J:3,K:3} / {K:2} /
    # {J:2,K:3} respectively -- all different, and patching them (verified by
    # excluding one at a time) turns a real bug into a false negative.
    groups = {}
    for pred_name, cj_label in pred_cj_label.items():
        groups.setdefault(cj_label, []).append(pred_name)
    for cj_label, members in groups.items():
        if len(members) < 2:
            continue
        shapes = set()
        for pred_name in members:
            _cl, _cv, _fp, _facts, before_map = patches[pred_name]
            merge_shape = tuple(sorted(
                c for c in Counter(before_map.values()).values() if c > 1
            ))
            shapes.add(merge_shape)
        if len(shapes) > 1:
            for pred_name in members:
                log.append(f"  {pred_name}: shares cj {cj_label} with {[m for m in members if m != pred_name]}, "
                           f"but they merge variables onto head letters differently -- "
                           f"not safe to treat as the same condition -- skipped")
                del patches[pred_name]
                unreliable_preds.add(pred_name)

    n3 = patch_identity_aliasing(t_constr_path, log, unreliable_callers=unreliable_preds)

    if DISABLE_PATCH_T_CONSTR:
        print(f"[step4b] patch_t_constr/patch_caller_prebindings disabled (DISABLE_PATCH_T_CONSTR) -- "
              f"{len(patches)} candidate predicate(s) would have been eligible but were left untouched; "
              f"{n3} identity-predicate alias(es) asserted eagerly, "
              f"{n0} parameter-range constraint(s) restored")
        for l in log:
            print(l)
        return

    if not patches:
        print(f"[step4b] no eligible non-loop branch definitions found in {defs_path}; "
              f"{n3} identity-predicate alias(es) asserted eagerly, "
              f"{n0} parameter-range constraint(s) restored")
        for l in log:
            print(l)
        return

    n = patch_t_constr(t_constr_path, patches, log)
    n2 = patch_caller_prebindings(t_constr_path, patches, log)
    print(f"[step4b] {t_constr_path}: {n} clause(s) patched, {n2} caller pre-binding(s) dropped, "
          f"{n3} identity-predicate alias(es) asserted eagerly, "
          f"{n0} parameter-range constraint(s) restored")
    for l in log:
        print(l)


if __name__ == '__main__':
    main()
