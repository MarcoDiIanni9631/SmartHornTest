#!/usr/bin/env python3
"""Writes DIR/report.csv with one row per contract analyzed under DIR (either
route, one contract or many), and prints it.

Columns: contract, route, functions, negative and positive tests (from the
.test_cases.json), how the analysis ended (from the .zmiout name) and, if
forge test was run (forge_test*.txt under DIR), how many tests Foundry
confirms: a negative test fails with panic 0x01, a positive test passes.

Usage: python3 script/report.py DIR"""
import csv, glob, json, os, re, sys


def ident(s):
    return re.sub(r"\W", "_", s)


def forge_results(root):
    """test file base name -> list of (test name, outcome line)"""
    res = {}
    for f in glob.glob(os.path.join(root, "**", "forge_test*.txt"), recursive=True):
        cur = None
        for l in open(f, errors="replace"):
            m = re.match(r"Ran \d+ tests? for test/(\w+)\.t\.sol:", l)
            if m:
                cur = res.setdefault(m.group(1), [])
            elif l.startswith("Suite result"):
                cur = None
            elif cur is not None and l.startswith("["):
                m = re.search(r"\] (test_\w+)\(", l)
                if m:
                    cur.append((m.group(1), l))
    return res


def contract_dirs(root):
    for d, subs, files in os.walk(root):
        subs[:] = [s for s in subs if s not in ("foundry", "lib", "out", "cache", "src", "test")
                   and not s.startswith("cov_")]
        name = os.path.basename(d)
        zs = [f for f in files if f.endswith(".zmiout")]
        if name + ".sol" not in files:
            if not zs:
                continue
            name = zs[0].split(".")[0]
        route = "solcmc" if os.path.basename(os.path.dirname(d)) == "solcmc" else "yul"
        logs = {"run.log", "analysis.log", "convert.log"} & set(files)
        if route == "yul" and not (zs or logs or any(f.endswith(".t_constr.pl") for f in files)):
            continue
        yield d, name, route, files, zs


def row(root, d, name, route, files, zs, forge):
    r = {"contract": name, "route": route, "functions": "", "negative": 0, "positive": 0,
         "analysis": "", "depth_bound_reached": "", "foundry_negative_confirmed": "",
         "foundry_positive_confirmed": "", "folder": os.path.relpath(d, root)}
    js = [f for f in files if f.endswith(".test_cases.json")]
    kinds = []
    if js:
        data = json.load(open(os.path.join(d, js[0])))
        r["functions"] = " ".join(fn.get("signature", "") for fn in data.get("functions", []))
        kinds = [tc.get("kind") for fn in data.get("functions", []) for tc in fn.get("test_cases", [])]
        r["negative"], r["positive"] = kinds.count("negative"), kinds.count("positive")
    if zs:
        z = zs[0]
        r["analysis"] = "timeout" if ".timeout." in z else ("all paths explored" if "totalExplored" in z else "stopped")
        r["depth_bound_reached"] = "yes" if "MaxDepthReached" in z else "no"
    elif route == "solcmc" and name + ".chc.pl" not in files or \
            route == "yul" and not any(f.endswith(".t_constr.pl") for f in files):
        r["analysis"] = "no CHCs"
    else:
        r["analysis"] = "no result"
    path = ident(os.path.abspath(os.path.dirname(d)))
    for base, tests in forge.items():
        g, _, n = base.rpartition("__")
        if n == ident(name) and (path.endswith("_" + g) or path == g):
            neg = sum(1 for t, l in tests if t.startswith("test_negative") and "panic: assertion failed (0x01)" in l)
            pos = sum(1 for t, l in tests if t.startswith("test_positive") and l.startswith("[PASS]"))
            r["foundry_negative_confirmed"] = f"{neg}/{r['negative']}"
            r["foundry_positive_confirmed"] = f"{pos}/{r['positive']}"
    return r


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    root = os.path.abspath(sys.argv[1])
    forge = forge_results(root)
    rows = sorted((row(root, *c, forge) for c in contract_dirs(root)), key=lambda x: (x["folder"], x["route"]))
    if not rows:
        print("no analyzed contracts in", root)
        sys.exit(1)
    out = os.path.join(root, "report.csv")
    with open(out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    cols = ["contract", "route", "negative", "positive", "analysis",
            "foundry_negative_confirmed", "foundry_positive_confirmed"]
    width = {c: max(len(c), *(len(str(x[c])) for x in rows)) for c in cols}
    for x in [dict(zip(cols, cols))] + rows:
        print("  ".join(str(x[c]).ljust(width[c]) for c in cols))
    print("written", out)


if __name__ == "__main__":
    main()
