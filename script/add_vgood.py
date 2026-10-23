#!/usr/bin/env python3
"""
add_vgood.py: adds the `vgood` marker assert to the public/external functions
of a Solidity file, so that the analysis also produces positive tests.

As in the hand-written *_vgood contracts, each function gets
    uint256 vgood = 42;                       at its start
    vgood = 1042; assert(vgood < 20);         before every return and at its end
A path that reaches the marker has passed every real assert before it, and the
interpreter labels it positive (a model value 1042, see
classify_test_from_vmapgood_consts in src/core/main.pl).

Each `return ...;` becomes `{ vgood = 1042; assert(vgood < 20); return ...; }`,
which is a valid statement also after an `if` without braces.
Skipped: constructors, internal/private functions, functions without a body,
and public functions also called inside the contract (their marker would fire
before the caller's own asserts).

Usage:
    python3 script/add_vgood.py IN.sol OUT.sol
"""
import re
import sys

MARK = "vgood = 1042; assert(vgood < 20);"


def skip_noncode(src, i):
    """If src[i] starts a comment or string, return the index after it, else i."""
    if src.startswith("//", i):
        j = src.find("\n", i)
        return len(src) if j < 0 else j
    if src.startswith("/*", i):
        j = src.find("*/", i + 2)
        return len(src) if j < 0 else j + 2
    if src[i] in "\"'":
        q, j = src[i], i + 1
        while j < len(src) and src[j] != q:
            j += 2 if src[j] == "\\" else 1
        return j + 1
    return i


def match_brace(src, i):
    """Index of the } that closes the { at src[i]."""
    depth = 0
    while i < len(src):
        j = skip_noncode(src, i)
        if j != i:
            i = j
            continue
        if src[i] == "{":
            depth += 1
        elif src[i] == "}":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def code_only(src):
    """src with comments and strings blanked out (same length)."""
    out, i = list(src), 0
    while i < len(src):
        j = skip_noncode(src, i)
        if j != i:
            for k in range(i, j):
                if out[k] != "\n":
                    out[k] = " "
            i = j
        else:
            i += 1
    return "".join(out)


def functions(src):
    """(name, header_start, body_open, body_close) of every function with a body."""
    code = code_only(src)
    for m in re.finditer(r"\bfunction\s+(\w+)\s*\(", code):
        i = m.end()
        depth = 1
        while depth:
            depth += {"(": 1, ")": -1}.get(code[i], 0)
            i += 1
        j = i
        while j < len(code) and code[j] not in "{;":
            j += 1
        if j < len(code) and code[j] == "{":
            yield m.group(1), m.start(), code[i:j], j, match_brace(src, j)


def instrument(src):
    code = code_only(src)
    edits = []  # (position, text to insert, or (start, end, replacement))
    done = []
    for name, start, header, op, cl in functions(src):
        if not re.search(r"\b(public|external)\b", header):
            continue
        # called inside the contract (not as this.f or a declaration)
        calls = [c for c in re.finditer(rf"(?<![\w.]){re.escape(name)}\s*\(", code)
                 if not code[max(0, c.start() - 9):c.start()].rstrip().endswith("function")]
        if calls:
            continue
        body = code[op:cl]
        for r in re.finditer(r"(?<!\w)return\b[^;]*;", body):
            a, b = op + r.start(), op + r.end()
            edits.append((a, b, "{ " + MARK + " " + src[a:b] + " }"))
        edits.append((op + 1, op + 1, " uint256 vgood = 42;"))
        edits.append((cl, cl, MARK + "\n    "))
        done.append(name)
    for a, b, text in sorted(edits, key=lambda e: (e[0], e[1]), reverse=True):
        src = src[:a] + text + src[b:]
    return src, done


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    src = open(sys.argv[1], encoding="utf-8", errors="replace").read()
    out, done = instrument(src)
    with open(sys.argv[2], "w", encoding="utf-8") as f:
        f.write(out)
    print("vgood in:", ", ".join(done) if done else "(nessuna funzione)")


if __name__ == "__main__":
    main()
