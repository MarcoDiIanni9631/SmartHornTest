#!/usr/bin/env python3
# wrap_constraints_in_constr.py
#
# Usage:
#   python3 wrap_constraints_in_constr.py file.pl
#
# Output:
#   file_constr.pl (same folder as input)
#
# Behaviour:
# - Directives untouched
# - Facts untouched
# - If a clause has constraint-like goals (Var OP Expr),
#   they are wrapped into constr((...)) with commas
# - If no constraints, clause unchanged (no constr(true))
# - No constr/1 declarations added

import re
import sys
import os
from typing import List

CONSTR_RE = re.compile(
    r"^\s*([A-Z_][A-Za-z0-9_]*|\d+)\s*(=\\==|\\==|=\\\\=|\\\\=|=:=|=<|>=|<|>|=)\s*(.+?)\s*$"
)

def split_top_level_commas(s: str) -> List[str]:
    parts, buf, depth = [], [], 0
    for ch in s:
        if ch == '(':
            depth += 1
            buf.append(ch)
        elif ch == ')':
            depth = max(0, depth - 1)
            buf.append(ch)
        elif ch == ',' and depth == 0:
            part = ''.join(buf).strip()
            if part:
                parts.append(part)
            buf = []
        else:
            buf.append(ch)
    tail = ''.join(buf).strip()
    if tail:
        parts.append(tail)
    return parts

def extract_statements(text: str) -> List[str]:
    stmts, buf, depth = [], [], 0
    for ch in text:
        buf.append(ch)
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth = max(0, depth - 1)
        elif ch == '.' and depth == 0:
            stmt = ''.join(buf).strip()
            if stmt:
                stmts.append(stmt)
            buf = []
    tail = ''.join(buf).strip()
    if tail:
        stmts.append(tail)
    return stmts

def is_constraint_goal(goal: str) -> bool:
    return CONSTR_RE.match(goal) is not None

def transform_clause(stmt: str) -> str:
    s = stmt.strip()
    if not s.endswith('.'):
        return stmt

    core = s[:-1].strip()

    # directives unchanged (:- pred, :- dynamic, etc.)
    if core.lstrip().startswith(":-"):
        return stmt

    # facts → convert to constr(true)
    if ":-" not in core:
        head = core
        return f"{head} :- constr((true))."

    # normal clauses
    head, body = core.split(":-", 1)
    head, body = head.strip(), body.strip()

    goals = split_top_level_commas(body)
    constrs, calls = [], []

    for g in goals:
        g = g.strip()
        if not g:
            continue
        if is_constraint_goal(g):
            constrs.append(g)
        else:
            calls.append(g)

    # no constraints → unchanged
    if not constrs:
        return stmt

    constr_inside = ", ".join(constrs)
    if calls:
        new_body = f"constr(({constr_inside})), " + ", ".join(calls)
    else:
        new_body = f"constr(({constr_inside}))"

    return f"{head} :- {new_body}."

def make_output_name(input_path: str, suffix: str = "_constr") -> str:
    # Keeps same directory; adds suffix before extension
    d = os.path.dirname(input_path)
    base = os.path.basename(input_path)
    stem, ext = os.path.splitext(base)
    if not ext:
        ext = ".pl"
    out_base = stem + suffix + ext
    return os.path.join(d, out_base) if d else out_base

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 wrap_constraints_in_constr.py file.pl", file=sys.stderr)
        sys.exit(1)

    input_path = sys.argv[1]
    if not os.path.isfile(input_path):
        print(f"File not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    output_path = make_output_name(input_path, suffix="_constr")

    with open(input_path, "r", encoding="utf-8") as f:
        text = f.read()

    stmts = extract_statements(text)
    transformed = [transform_clause(st) for st in stmts]

    with open(output_path, "w", encoding="utf-8") as f:
        for st in transformed:
            f.write(st.rstrip() + "\n")

    print(f"[OK] Created: {output_path}")

if __name__ == "__main__":
    main()
