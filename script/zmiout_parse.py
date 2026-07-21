#!/usr/bin/env python3
"""
zmiout_parse.py — shared parsing utilities for the zmiout pipeline.

Not intended to be run directly. Imported by:
  zmiout2vars_z3.py, zmiout2vars_clpq.py, zmiout2json.py
"""
import re


# ---- Solidity source parsing ----

def parse_contract_name(sol):
    m = re.search(r'contract\s+(\w+)', sol)
    return m.group(1) if m else None

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

def build_func_signature(sol, func):
    m = re.search(rf'function\s+{func}\s*\(([^)]*)\)', sol)
    if not m or not m.group(1).strip():
        return f"{func}()"
    types = [p.strip().split()[0] for p in m.group(1).split(',') if p.strip()]
    return f"{func}({','.join(types)})"


# ---- Defs file parsing ----

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


# ---- Zmiout parsing ----

def split_tests(zmiout):
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


# ---- Shared resolution logic ----

def resolve_test(test_block, blocks, state_vars, func_args, entry_pred):
    """Parse one test block.

    Returns (is_positive, concrete_values, rv_to_sol, raw_constraints):
      - is_positive:     True if this is a verimapGood (safe) witness
      - concrete_values: list of "var == value" strings from the Z3 model
      - rv_to_sol:       dict mapping runtime variable names to Solidity names
      - raw_constraints: list of raw constraint strings from the INCORRECT/FF line
    """
    n_args = len(func_args)
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

    chosen_name, chosen_locals, chosen_params = find_body_from_trace(
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

    raw = parse_incorrect_line(test_block)
    clauses = split_clauses(raw)
    raw_constraints = extract_var_constraints(clauses, rv_to_sol)

    return is_positive, concrete_values, rv_to_sol, raw_constraints
