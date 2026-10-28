#!/usr/bin/env python3
"""Prints the function to analyze with the yul2chc route when none is given:
the first public or external function that contains an assert, otherwise the
first public or external function, otherwise the first function.
Usage: python3 script/default_function.py FILE.sol"""
import re, sys

src = open(sys.argv[1], errors="replace").read()
src = re.sub(r"/\*.*?\*/", "", re.sub(r"//.*", "", src), flags=re.S)
funs = list(re.finditer(r"function\s+(\w+)\s*\([^)]*\)([^{;]*)\{", src))
public, with_assert = [], []
for i, m in enumerate(funs):
    body = src[m.end():funs[i + 1].start() if i + 1 < len(funs) else len(src)]
    if re.search(r"\b(public|external)\b", m.group(2)):
        public.append(m.group(1))
        if "assert(" in body:
            with_assert.append(m.group(1))
names = with_assert or public or [m.group(1) for m in funs]
print(names[0] if names else "f")
