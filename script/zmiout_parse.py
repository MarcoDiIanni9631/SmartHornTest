#!/usr/bin/env python3
"""
zmiout_parse.py — shared parsing utilities for the zmiout pipeline.

Not intended to be run directly. Imported by:
  zmiout2vars_z3.py, zmiout2vars_clpq.py, zmiout2json.py
"""
import os
import re


# ---- Solidity source parsing ----

def parse_contract_name(sol):
    # strip comments first: a header like "... the contract name ..." would
    # otherwise be taken for a declaration (seen on Missing.sol, Rubixi.sol)
    code = re.sub(r'//.*', '', re.sub(r'/\*.*?\*/', '', sol, flags=re.S))
    m = re.search(r'\bcontract\s+(\w+)', code)
    return m.group(1) if m else None

def parse_state_vars(sol):
    contract_body = re.search(r'contract\s+\w+\s*\{(.*)', sol, re.DOTALL)
    if not contract_body:
        return []
    body = contract_body.group(1)
    before_funcs = re.split(r'\bfunction\b', body)[0]
    # constant / immutable declarations take no storage slot: skipping them
    # keeps every real state variable on its own slot position
    decls = re.findall(
        r'^\s+(?:uint\d*|int\d*|address|bool|bytes\d*)\s+((?:(?:public|private|internal|constant|immutable)\s+)*)(\w+)\s*[=;]',
        before_funcs, re.MULTILINE)
    return [name for mods, name in decls if not re.search(r'\b(constant|immutable)\b', mods)]

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

def parse_func_arg_types(sol, func):
    """{param_name: solidity_type} for func's own parameters, e.g.
    {'b': 'bool', 'n': 'uint256'} -- used only to format a bool
    parameter's concrete value as true/false instead of a raw 0/1."""
    m = re.search(rf'function\s+{func}\s*\(([^)]*)\)', sol)
    if not m or not m.group(1).strip():
        return {}
    types = {}
    for part in m.group(1).split(','):
        tokens = part.strip().split()
        if len(tokens) >= 2:
            types[tokens[-1]] = tokens[0]
    return types

def _format_concrete_value(val, sol_type):
    if sol_type == 'bool' and str(val) in ('0', '1'):
        return 'true' if str(val) == '1' else 'false'
    return val

def build_func_signature(sol, func):
    m = re.search(rf'function\s+{func}\s*\(([^)]*)\)', sol)
    if not m or not m.group(1).strip():
        return f"{func}()"
    types = [p.strip().split()[0] for p in m.group(1).split(',') if p.strip()]
    return f"{func}({','.join(types)})"


# ---- Defs file parsing ----

def load_defs_blocks(defs):
    return re.split(r'\n(?=new\d+\()', defs)

def detect_func_and_entry(blocks, aux_path=None):
    """Return (func_name, entry_pred_name): the function called and the CHC that calls it.

    Normally the top-level function still shows up as an unresolved
    fun_call(subO_fun_<name>_<N>, ...) inside one of the generalized
    definitions in blocks (from <contract>.t.pl-defs.txt). For a small
    contract where that function gets fully inlined instead of
    generalized (nothing left to fold), no block mentions it and this
    scan finds nothing. <contract>.aux.pl always names the entry point
    explicitly (that's its only job), so fall back to it when given."""
    for block in blocks:
        m_pred = re.match(r'(new\d+)\(', block)
        if not m_pred:
            continue
        m_func = re.search(r'fun_call\(subO_fun_(\w+?)_\d+,', block)
        if m_func:
            return m_func.group(1), m_pred.group(1)
    if aux_path and os.path.isfile(aux_path):
        aux = open(aux_path, encoding='utf-8').read()
        m_func = re.search(r'fun_call\(subO_fun_(\w+?)_\d+,', aux)
        if m_func:
            return m_func.group(1), 'new2'
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

def find_body_from_trace(trace_dict, blocks, n_args, func=None):
    """Find the call-trace entry whose "before" state is inside the target
    function's own body, so its v0..v(n_args-1) can be read as that
    function's own parameters.

    v0, v1, ... are SSA-local names that RESET inside every function/helper
    (see generate_facts.py) -- a converter/cleanup helper invoked before the
    target function even starts (e.g. subO_convert_..._to_t_uint256 for a
    literal like "uint a = 3") has its own unrelated v0. Checking only for
    "some subO_ block with v0..v(n_args-1) defined" (dropped here) would
    happily match that helper's v0 instead of the target function's actual
    argument, silently mislabeling the wrong Z3 variable as e.g. "x". Requiring
    the block's own location label to start with subO_fun_<func>_<id>_
    (the naming convention generate_facts.py always uses for a function's own
    blocks) pins this down to the right function; other functions/helpers
    never share that exact prefix."""
    func_prefix_re = re.compile(rf"^'?subO_fun_{re.escape(func)}_\d+_") if func else None
    for name in trace_dict:
        block = find_block(blocks, name)
        if block is None:
            continue
        start = re.split(r',cf\(', block)[0]
        if func_prefix_re is not None:
            m_label = re.search(r'cmd\(([^,]+),', start)
            if not m_label or not func_prefix_re.match(m_label.group(1)):
                continue
        elif 'subO_' not in block:
            continue
        locals_ = {int(v): l for v, l in re.findall(r'\(v(\d+),([A-Z]\d*)\)', start)}
        if n_args == 0 or all(i in locals_ for i in range(n_args)):
            return name, locals_, get_param_list(block)
    return None, {}, []


# ---- Zmiout parsing ----

def split_tests(zmiout):
    parts = re.split(r'={3,}\s*TEST #\d+\s*={3,}', zmiout)
    return [p for p in parts if 'CALL TRACE' in p or 'model{' in p]


def no_test_message(zmiout_path):
    """The json of a contract with no test: only this line, with the
    reason taken from the verdict in the .zmiout file name."""
    name = os.path.basename(zmiout_path)
    if ".TimeoutReached." in name:
        why = "timeout reached before a test was found"
    elif ".MaxDepthReached." in name:
        why = "max depth reached before a test was found"
    elif ".nonDerivable." in name:
        why = "all paths explored, none reaches a failing assert"
    else:
        why = "the analysis gave no counterexample"
    return f"no test found ({why})"


def dedupe_tests_by_shape(tests):
    """Multiple SAT witnesses can be genuinely redundant, not wrong: two of
    the interpreter's top-level query clauses can independently reach the
    very same branch at a single overlapping boundary input (see the
    branches_merge_variables_3 notes -- e.g. x=10 satisfies both "x>10" and
    "x<=10"-rooted derivations that both end up in the same if-branch as
    some other x>10 witness already found). Both are valid counterexamples,
    but reporting the same branch twice is just noise. Two tests are
    considered the same branch when they are both positive or both negative
    AND call the exact same sequence of predicates (ignoring the concrete
    argument values) -- keep the first, drop the rest."""
    seen = set()
    out = []
    for block in tests:
        shape = tuple(name for name, _args in parse_call_trace(block))
        key = ('testVerimapGood' in block, shape)
        if key in seen:
            continue
        seen.add(key)
        out.append(block)
    return out

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

def parse_incorrect_line(block):
    m = re.search(r'INCORRECT/FF FOUND:\s*(.*)', block)
    return m.group(1) if m else ""

def split_clauses(text):
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
    return [c for c in clauses if ':int=' not in c and c != 'true']


# ---- Fallback: reading a function-parameter value directly out of the
# `incorrect` clause, for a function the transform fully inlined (no
# dedicated subO_fun_<name> block survives in <contract>.t.pl-defs.txt for
# find_body_from_trace to find -- see its docstring). This happens for a
# small function called from a single site, e.g. one that reads/writes
# storage itself via inline assembly (sstore/sload) rather than through the
# usual per-function candidate_def. Verified on OwnableFaulty: `incorrect`'s
# own constr(...) conjuncts and the runtime "INCORRECT/FF FOUND" line's own
# derivation chain line up ONE FOR ONE, conjunct by conjunct, in the same
# left-to-right order (both are just the same clause, before vs. after SWI
# instantiates its named variables to fresh runtime ones) -- so pairing them
# positionally recovers, for any clause letter, the concrete runtime
# variable holding its value.

def _split_top_level_atoms(text, sep_word=False):
    """Split text on top-level ',' (sep_word=False) or 'and' (sep_word=True),
    not inside parentheses. The Z3Final printer doesn't always put a space
    before 'and' when the previous atom ends in ')' (e.g. `not(X=0)and Y=0`)
    -- normalize spacing around every 'and' token first so the word-boundary
    scan below sees it consistently."""
    if sep_word:
        text = re.sub(r'\s*\band\b\s*', ' and ', text)
    parts, current, depth, i = [], [], 0, 0
    n = len(text)
    while i < n:
        ch = text[i]
        if ch == '(':
            depth += 1
            current.append(ch); i += 1
            continue
        if ch == ')':
            depth -= 1
            current.append(ch); i += 1
            continue
        if depth == 0:
            if sep_word and text[i:i + 5] == ' and ':
                parts.append(''.join(current).strip())
                current = []
                i += 5
                continue
            if not sep_word and ch == ',':
                parts.append(''.join(current).strip())
                current = []
                i += 1
                continue
        current.append(ch)
        i += 1
    if current:
        parts.append(''.join(current).strip())
    return [p for p in parts if p]


def parse_incorrect_clauses(t_constr_text):
    """Yield (constr_conjuncts, call_names) for every top-level `incorrect :-
    constr((...)), new1(...), new2(...), ...` clause in a .t_constr.pl file.
    constr_conjuncts is the ',' -split list of that clause's own leading
    constr((...)) (not the sub-calls' own bodies); call_names is the ordered
    list of predicate names it calls (e.g. ['new1','new2','new3'])."""
    for m in re.finditer(r'^incorrect\s*:-\s*constr\(\((.*?)\)\),(.*)\.\s*$', t_constr_text, re.MULTILINE):
        constr_text, rest = m.groups()
        conjuncts = _split_top_level_atoms(constr_text, sep_word=False)
        call_names = re.findall(r'\b(new\d+)\(', rest)
        yield conjuncts, call_names


def _is_subsequence(needle, haystack):
    """True if every element of needle appears in haystack, in the same
    relative order (not necessarily contiguous)."""
    it = iter(haystack)
    return all(x in it for x in needle)


def pick_matching_incorrect_clause(t_constr_text, trace_names):
    """The `incorrect` clause among parse_incorrect_clauses() whose own
    call_names form a subsequence of trace_names (the predicates actually
    seen in this test's CALL TRACE) -- there is one alternative clause per
    top-level case split, each directly calling a different combination of
    new*/N predicates. Subsequence, not equality: trace_names is the FLAT
    list of every predicate seen anywhere in the derivation, so it also
    includes predicates called indirectly (by one of incorrect's own direct
    callees, not by incorrect itself) interspersed among incorrect's own
    direct calls."""
    trace_names = list(trace_names)
    for conjuncts, call_names in parse_incorrect_clauses(t_constr_text):
        if call_names == trace_names:
            return conjuncts
    best = None
    for conjuncts, call_names in parse_incorrect_clauses(t_constr_text):
        if _is_subsequence(call_names, trace_names):
            if best is None or len(call_names) > len(best[1]):
                best = (conjuncts, call_names)
    return best[0] if best else None


_LETTER_TOKEN_RE = re.compile(r'^[A-Z][A-Za-z0-9]*$')
_CMP_RE = re.compile(r'^([A-Za-z0-9]+)\s*(>=|=<|>|<)\s*([A-Za-z0-9]+)$')


def find_interesting_free_letter(constr_conjuncts):
    """Best-effort pick of the one clause letter most likely to be the
    informative free value in this clause: the operand of an inequality
    comparison (>, <, >=, =<) whose OTHER side resolves, through this
    clause's own chain of plain `Letter=Letter2` aliases and `Letter=Number`
    pins, to a non-zero numeric literal -- the shape of an assert/require
    bound (e.g. `N1=<U1` with `U1=O1` and `O1=<uint160 max literal>`
    elsewhere in the very same clause). Returns None if no such comparison
    is found, or if the free side doesn't resolve to a single letter --
    callers must not guess further."""
    equal_to = {}
    pinned = {}
    has_lhs = set()
    for c in constr_conjuncts:
        m = re.fullmatch(r'([A-Za-z0-9]+)=(-?\d+)', c)
        if m and _LETTER_TOKEN_RE.match(m.group(1)):
            pinned.setdefault(m.group(1), int(m.group(2)))
            has_lhs.add(m.group(1))
            continue
        m = re.fullmatch(r'([A-Za-z0-9]+)=([A-Za-z0-9]+)', c)
        if m and _LETTER_TOKEN_RE.match(m.group(1)) and _LETTER_TOKEN_RE.match(m.group(2)):
            equal_to.setdefault(m.group(1), m.group(2))
            has_lhs.add(m.group(1))

    def resolve_fully(letter, depth=0):
        """Follow equal_to all the way to its terminal representative (used
        only to test whether a side is pinned to a number)."""
        while letter in equal_to and letter not in pinned and depth < 50:
            letter = equal_to[letter]
            depth += 1
        return letter

    def resolve_to_lhs(letter, depth=0):
        """Follow equal_to only as far as needed to land on a letter that is
        itself the LHS of some conjunct (so letter_to_runtime_value's
        position-indexing, keyed on conjunct LHS, can find it) -- letter
        itself if it already qualifies, since a plain `Letter=Letter2`
        conjunct's LHS carries the exact same runtime value as its RHS."""
        while letter not in has_lhs and letter in equal_to and depth < 50:
            letter = equal_to[letter]
            depth += 1
        return letter

    def resolved_number(letter):
        return pinned.get(resolve_fully(letter))

    candidates = []
    for c in constr_conjuncts:
        m = _CMP_RE.match(c)
        if not m:
            continue
        a, b = m.group(1), m.group(3)
        for side, other in ((a, b), (b, a)):
            if not _LETTER_TOKEN_RE.match(side) or not _LETTER_TOKEN_RE.match(other):
                continue
            num = resolved_number(other)
            if num is not None and num != 0:
                candidates.append((abs(num), resolve_to_lhs(side)))
    if not candidates:
        return None
    # A clause can carry more than one such bound (e.g. two separate
    # asserts, as in the *_vgood variants). Prefer the one compared against
    # the LARGEST literal: type-range bounds (uint160 max, etc.) are always
    # far bigger than a small hand-picked threshold like `vgood < 1000`, so
    # this reliably picks the bound tied to the actual function argument
    # over an unrelated later assert's own constant.
    candidates.sort(key=lambda t: t[0], reverse=True)
    return candidates[0][1]


_TYPE_ANNOT_ATOM_RE = re.compile(r'^_\d+:int=_\d+:int$')
_MEMPTR_CONJUNCT_RE = re.compile(r'^([A-Za-z0-9]+)=128$')
_RUNTIME_ASSIGN_RE = re.compile(r'^(_\d+)=(.+)$')


def letter_to_runtime_var(t_constr_text, test_block, trace_names, target_letter):
    """Runtime variable (e.g. `_284`) bound to `target_letter` in the `incorrect`
    clause matching trace_names, found by pairing that clause's own
    constr(...) conjuncts with the runtime derivation chain in this test's
    "INCORRECT/FF FOUND" line (see module comment above
    parse_incorrect_clauses -- both are the very same clause, just before vs.
    after SWI instantiates its named variables to fresh runtime ones, so
    corresponding conjuncts line up one for one in the same order).

    The chain isn't quite a clean 1:1 slice of the FF line: type-annotation
    atoms (`_N:int=_N:int`, always self-referential, dropped here) are
    interleaved in with it, AND a handful of already-resolved bindings are
    echoed again right at the very start (verified: exactly as many entries
    as the offset below). Anchor on `Letter=128` -- every function's own
    clause carries this (the free-memory-pointer constant Solidity always
    initializes first) -- to find that leading offset empirically instead of
    assuming it's zero, then index every other conjunct relative to it.
    Returns None if anything doesn't line up cleanly -- never guess a value
    from a partial/mismatched pairing."""
    conjuncts = pick_matching_incorrect_clause(t_constr_text, trace_names)
    if conjuncts is None:
        return None

    anchor_conj_idx = None
    for i, c in enumerate(conjuncts):
        if _MEMPTR_CONJUNCT_RE.match(c):
            anchor_conj_idx = i
            break
    target_idx = None
    for i, c in enumerate(conjuncts):
        lhs = c.split('=', 1)[0].strip() if '=' in c else None
        if lhs == target_letter:
            target_idx = i
            break
    if anchor_conj_idx is None or target_idx is None:
        return None

    raw = parse_incorrect_line(test_block)
    all_atoms = []
    for coarse in split_clauses(raw):
        all_atoms.extend(_split_top_level_atoms(coarse, sep_word=True))
    chain_atoms = [a for a in all_atoms if not _TYPE_ANNOT_ATOM_RE.match(a)]

    anchor_atom_idx = None
    for i, a in enumerate(chain_atoms):
        m = _RUNTIME_ASSIGN_RE.match(a)
        if m and m.group(2) == '128':
            anchor_atom_idx = i
            break
    if anchor_atom_idx is None:
        return None

    offset = anchor_atom_idx - anchor_conj_idx
    idx = target_idx + offset
    if idx < 0 or idx >= len(chain_atoms):
        return None
    m = _RUNTIME_ASSIGN_RE.match(chain_atoms[idx])
    if not m:
        return None
    return m.group(1)


def letter_to_runtime_value(t_constr_text, test_block, trace_names, target_letter):
    """Concrete Z3-model value of letter_to_runtime_var (see there)."""
    rv = letter_to_runtime_var(t_constr_text, test_block, trace_names, target_letter)
    if rv is None:
        return None
    return parse_z3_model(test_block).get(rv)


def find_param_letters(t_constr_text, trace_names):
    """Letters holding the entry function's own parameters, in order of
    appearance in the clause (= REVERSE declaration order, see resolve_test),
    for a function the transform fully inlined into `incorrect`.

    A parameter is a free input: aux.pl passes it as a fresh variable
    (fun_call(subO_fun_f_N, [num(_V_v0), ...])), so in the matching
    `incorrect` clause it shows up as one conjunct `M=N` where N occurs
    NOWHERE else in the whole clause, and M is the letter the body uses.
    Checked on P01..P05 (proprieta_variabili, 28 Sep), including a
    two-argument function."""
    trace_names = list(trace_names)
    best = None
    for m in re.finditer(r'^incorrect\s*:-\s*constr\(\((.*?)\)\),(.*)\.\s*$', t_constr_text, re.MULTILINE):
        call_names = re.findall(r'\b(new\d+)\(', m.group(2))
        if call_names == trace_names:
            best = m
            break
        if _is_subsequence(call_names, trace_names):
            if best is None or len(call_names) > len(re.findall(r'\b(new\d+)\(', best.group(2))):
                best = m
    if best is None:
        return []
    whole = best.group(0)
    letters = []
    for c in _split_top_level_atoms(best.group(1), sep_word=False):
        mm = re.fullmatch(r'([A-Z][A-Za-z0-9]*)=([A-Z][A-Za-z0-9]*)', c)
        if not mm:
            continue
        occ = re.findall(rf'(?<![A-Za-z0-9_]){mm.group(2)}(?![A-Za-z0-9_])', whole)
        if len(occ) == 1:
            letters.append(mm.group(1))
    return letters


# ---- Shared resolution logic ----


def state_slots_from_body(trace_dict, blocks, func, n_state):
    """[(pre_rv, post_rv)] per state variable (storage slot i <-> i-th state
    variable), read from the first predicate in the trace whose own label is
    subO_fun_<func>_<id>_..., or None if there is no such predicate or it
    carries no storage slots."""
    if not func:
        return None
    label_re = re.compile(rf"^'?subO_fun_{re.escape(func)}_\d+_")
    # 1st choice: the function's own body predicate. 2nd choice, when the
    # function is fully inlined and no predicate carries its label
    # (OwnableFaulty, LotteryFaulty on 1/10): the LAST predicate of the trace
    # -- typically the assert helper -- whose "after" storage is exactly the
    # state at the failing assert.
    names = list(trace_dict.items())
    body = [(n, a) for n, a in names
            if find_block(blocks, n) is not None
            and re.search(r'cmd\(([^,]+),', find_block(blocks, n))
            and label_re.match(re.search(r'cmd\(([^,]+),', find_block(blocks, n)).group(1))]
    candidates = body if body else list(reversed(names))
    for name, args in candidates:
        block = find_block(blocks, name)
        if block is None:
            continue
        params = get_param_list(block)
        cfs = re.split(r',cf\(', block)
        if len(cfs) < 2:
            continue
        def storage(part):
            m = re.search(r"\(\[\('msg\.value',\w+\)((?:,\(\d+,[A-Z]\d*\))*)\]", part)
            return {int(a): b for a, b in re.findall(r'\((\d+),([A-Z]\d*)\)', m.group(1))} if m else {}
        pre, post = storage(cfs[0]), storage(cfs[1])
        if not pre:
            continue
        out = []
        for i in range(n_state):
            def rv(letter):
                if letter in params and params.index(letter) < len(args):
                    return args[params.index(letter)]
                return None
            out.append((rv(pre.get(i)) if pre.get(i) else None, rv(post.get(i)) if post.get(i) else None))
        if any(p or q for p, q in out):
            return out
    return None

def resolve_test(test_block, blocks, state_vars, func_args, entry_pred, func=None, t_constr_text=None, arg_types=None, with_start=False):
    """Parse one test block.

    Returns (is_positive, concrete_values, rv_to_sol, raw_constraints):
      - is_positive:     True if this is a verimapGood (safe) witness
      - concrete_values: list of "var == value" strings from the Z3 model
      - rv_to_sol:       dict mapping runtime variable names to Solidity names
      - raw_constraints: list of raw constraint strings from the INCORRECT/FF line

    func: the target function's name (from detect_func_and_entry), passed
    through to find_body_from_trace so it can tell that function's own
    parameters apart from an unrelated helper's identically-named locals.

    t_constr_text: <contract>.t_constr.pl's own content, used ONLY as a
    fallback (see letter_to_runtime_value) when find_body_from_trace finds no
    dedicated block for `func` at all -- i.e. the transform fully inlined it
    into `incorrect` itself (a small, single-call-site function; see that
    function's docstring). Optional: callers that don't have it yet (or a
    multi-argument func_args, where this fallback can't safely tell which
    argument it found) simply don't get this fallback.

    with_start: also return a fifth value, rv_start, the same as rv_to_sol
    but with every state variable mapped to its value when the call STARTS
    (the one the concrete values show), not where the assert fails. This is
    what a gas analysis needs: conditions on the inputs of the call. The
    other four values do not change.
    """
    n_args = len(func_args)
    arg_types = arg_types or {}
    call_trace = parse_call_trace(test_block)
    z3_model   = parse_z3_model(test_block)
    is_positive = 'testVerimapGood' in test_block

    trace_dict = {}
    for name, args in call_trace:
        if name not in trace_dict:
            trace_dict[name] = args

    new2_args = trace_dict.get(entry_pred)

    ref_env, ref_params = {}, []
    for cname in trace_dict:
        blk = find_block(blocks, cname)
        if blk and 'subO_' in blk:
            env = parse_env_slots(blk)
            if env:
                ref_env    = env
                ref_params = get_param_list(blk)
                break

    concrete_values = []
    rv_to_sol = {}

    param_rvs = {}
    state_start = {}

    def _add(arg, rv):
        rv_to_sol[rv] = arg
        param_rvs[rv] = arg
        val = z3_model.get(rv)
        if val is not None:
            val = _format_concrete_value(val, arg_types.get(arg))
            concrete_values.append(f"{arg} == {val}")

    # (1) parameters read from the function's own body block in the trace
    body_map = []
    chosen_name, chosen_locals, chosen_params = find_body_from_trace(
        trace_dict, blocks, n_args, func)
    if chosen_name is not None:
        body_args = trace_dict.get(chosen_name)
        for j, arg in enumerate(func_args):
            letter = chosen_locals.get(j)
            if letter and letter in chosen_params:
                pos = chosen_params.index(letter)
                if body_args and pos < len(body_args):
                    body_map.append((arg, body_args[pos]))

    # (2) parameters as free inputs of the `incorrect` clause. Keep
    # duplicates in the trace: `incorrect` can call the same predicate twice
    # (e.g. a literal-conversion helper used by both a require and an
    # assert), and a deduped trace would no longer contain that clause's
    # call list as a subsequence.
    seen_names = [n for n, _a in call_trace if n != 'incorrect']
    free_map = []
    if n_args >= 1 and t_constr_text:
        param_letters = find_param_letters(t_constr_text, seen_names)
        if len(param_letters) == n_args:
            rvs = [letter_to_runtime_var(t_constr_text, test_block, seen_names, L)
                   for L in param_letters]
            if all(rv is not None for rv in rvs):
                # the free inputs appear in REVERSE declaration order (Yul
                # evaluates call arguments right to left, so the last
                # parameter is decoded first). Checked on P26/P27/P28
                # (proprieta_variabili_3_ordine, 28 Sep): forced distinct
                # values x=10,y=3 and a=1,b=2,c=3 came out exactly reversed.
                free_map = list(zip(func_args, reversed(rvs)))

    # A body-block variable that occurs in no constraint at all is a stale,
    # never-unified trace variable (seen on P13_max_of_two_bug: x mapped to
    # _294, while the constrained x is _296) -- prefer the free-input map then.
    # drop the `_N:int=_N:int` type annotations: they list every variable
    # and are not constraints
    ff_line = re.sub(r'_\d+:int=_\d+:int', '', parse_incorrect_line(test_block) or "")
    def _in_constraints(rv):
        return re.search(rf'(?<![0-9]){re.escape(rv)}(?![0-9])', ff_line) is not None
    body_ok = len(body_map) == n_args and all(_in_constraints(rv) for _a, rv in body_map)

    if body_map and (body_ok or not free_map):
        for arg, rv in body_map:
            _add(arg, rv)
    elif free_map:
        for arg, rv in free_map:
            _add(arg, rv)
    elif n_args == 1 and t_constr_text:
        conjuncts = pick_matching_incorrect_clause(t_constr_text, seen_names)
        letter = find_interesting_free_letter(conjuncts) if conjuncts is not None else None
        if letter is not None:
            val = letter_to_runtime_value(t_constr_text, test_block, seen_names, letter)
            if val is not None:
                val = _format_concrete_value(val, arg_types.get(func_args[0]))
                concrete_values.append(f"{func_args[0]} == {val}")

    # State variables. Concrete values: storage when the call starts, from
    # the entry predicate (unchanged, same values as on 25/8). Constraints:
    # projected on the storage at the point where the assert fails, read
    # from the function's OWN body predicate (subO_fun_<func>_...) when it is
    # in the trace -- as on 25/8 (e.g. AuctionOffer: bid = newBid,
    # cash = payment). Without this, when the transform inlines the function
    # entry_pred falls back to 'new2', which can be an unrelated helper whose
    # "after" storage is just the deployed one (1/10: AuctionOffer gave
    # bid = 0, cash = 0). Only the "after" side of the body predicate is
    # used: its "before" side can be a point in the middle of the function
    # (short_circuit_*: x == 1 instead of the starting x == 0).
    body_state = state_slots_from_body(trace_dict, blocks, func, len(state_vars)) if state_vars else None
    if new2_args is not None and ref_env:
        offset = (len(new2_args) - n_args) // 2
        for i, var in enumerate(state_vars):
            letter = ref_env.get(i)
            if letter and letter in ref_params:
                pre_pos  = ref_params.index(letter)
                post_pos = pre_pos + offset
                if pre_pos < len(new2_args):
                    state_start[new2_args[pre_pos]] = var
                    val = z3_model.get(new2_args[pre_pos])
                    if val is not None:
                        concrete_values.append(f"{var} == {val}")
                if post_pos < len(new2_args) and not (body_state and body_state[i][1]):
                    rv_to_sol[new2_args[post_pos]] = var
    if body_state:
        for var, (_pre_rv, post_rv) in zip(state_vars, body_state):
            if post_rv is not None:
                rv_to_sol[post_rv] = var

    raw = parse_incorrect_line(test_block)
    clauses = split_clauses(raw)
    raw_constraints = extract_var_constraints(clauses, rv_to_sol)

    if with_start:
        rv_start = dict(param_rvs)
        rv_start.update(state_start)
        return is_positive, concrete_values, rv_to_sol, raw_constraints, rv_start
    return is_positive, concrete_values, rv_to_sol, raw_constraints
