#!/usr/bin/env python3
"""
solcmc_assume_asserts.py: makes the paths of a SolCMC CHC query (solc
--model-checker-print-query) stop at a failing assert.

In SolCMC's encoding an assert gives two rules:
    ... (not expr_N) ... (= error_k K)  -> error block      (the assert fails)
    ... (= error_k error_j) ...         -> next block       (no condition!)
The second rule does not assume that the assert holds: a path that breaks
assert 1 can go on and reach assert 2. SolCMC checks every assert on its
own, so this is fine for it, but for us a test that reaches the `vgood`
marker assert must pass all the real asserts before it.

This script collects the assert conditions (the variables under (not ...) in
the rules that set the error code) and, in every rule where such a variable
is defined, (= expr_N ...), but not negated, it adds the variable as an
assumption:  (=> BODY HEAD)  becomes  (=> (and expr_N BODY) HEAD).

Usage:
    python3 script/solcmc_assume_asserts.py IN.smt2 OUT.smt2
"""
import re
import sys


def sexprs(text):
    """Top-level s-expressions of text, as (start, end) spans."""
    spans, depth, start, i, n = [], 0, None, 0, len(text)
    while i < n:
        c = text[i]
        if c == ";":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c == "|":
            i = text.index("|", i + 1) + 1
            continue
        if c == "(":
            if depth == 0:
                start = i
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                spans.append((start, i + 1))
        i += 1
    return spans


def implication_body(rule):
    """Span (start, end) of BODY inside the first (=> BODY HEAD) of rule."""
    i = rule.index("(=> ") + 4
    while rule[i].isspace():
        i += 1
    if rule[i] != "(":
        m = re.match(r"[^\s()]+", rule[i:])
        return i, i + m.end()
    depth = 0
    for j in range(i, len(rule)):
        if rule[j] == "(":
            depth += 1
        elif rule[j] == ")":
            depth -= 1
            if depth == 0:
                return i, j + 1


def main(src, dst):
    text = open(src).read()
    spans = sexprs(text)
    rules = [(s, e) for s, e in spans if text[s:e].startswith("(assert") and "(=> " in text[s:e]]

    conds = set()
    for s, e in rules:
        r = text[s:e]
        if re.search(r"\(= error_\d+ [1-9]\d*\)", r):
            conds.update(re.findall(r"\(not (expr_\d+_\d+)\)", r))

    out, last, added = [], 0, 0
    for s, e in rules:
        r = text[s:e]
        extra = [c for c in sorted(conds)
                 if f"(= {c} " in r and f"(not {c})" not in r]
        if not extra:
            continue
        bs, be = implication_body(r)
        new_body = "(and " + " ".join(extra) + " " + r[bs:be] + ")"
        out.append(text[last:s])
        out.append(r[:bs] + new_body + r[be:])
        last = e
        added += len(extra)
    out.append(text[last:])
    with open(dst, "w") as f:
        f.write("".join(out))
    print(f"[solcmc_assume_asserts] {len(conds)} assert condition(s), "
          f"{added} assumption(s) added -> {dst}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
