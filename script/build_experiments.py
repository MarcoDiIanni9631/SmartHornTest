#!/usr/bin/env python3
"""Builds experiments/: the benchmark of the thesis evaluation (SolTG 81,
SMTChecker 151), with for every contract the original source, the source with
the vgood marker (positive tests) and the test_cases.json of the two routes
from the run of 21/10/2026 (test21Ottobre). summary.csv has the expected answer
and the outcome of each tool from the report of 20/10/2026 (test20Ottobre).
Usage (on the server, from the repo root): python3 script/build_experiments.py"""
import csv, glob, importlib.util, os, shutil

P = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
T20, T21 = os.path.join(P, "test20Ottobre"), os.path.join(P, "test21Ottobre")
OUT = os.path.join(P, "experiments")
spec = importlib.util.spec_from_file_location("rep", os.path.join(T20, "_report_confronto.py"))
rep = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rep)

OUTCOME = {"ok": "correct", "fn": "bug missed", "fn_multi": "bug needs several calls",
           "fp": "false alarm", "timeout": "timeout", "nonanalizzato": "not analyzed",
           "nonconfr": "no expected answer", "attesa": "not run"}


def target(rel):
    """benchmark/category/name of a contract"""
    parts = rel.split("/")
    name = parts[-1]
    if rel in rep.UFFICIALE:  # the 15 originals of SolTG regression/
        return "soltg", os.path.basename(os.path.dirname(rep.UFFICIALE[rel])), name
    # our folder names: "radice" = files at the top of regression/, "_cicli" = split of loops
    cat = {"radice": "misc"}.get(parts[1], parts[1].replace("_cicli", ""))
    return ("soltg" if parts[0] == "soltg_reg" else "smtchecker"), cat, name


def contracts():
    mano = rep.atteso_mano()
    st = {"solcmc": rep.stato(os.path.join(T20, "solcmc_maxdepth100")), "yul": rep.stato(os.path.join(T20, "yul_maxdepth100")),
          "myth": rep.stato(os.path.join(T20, "_tool", "mythril")), "mcore": rep.stato(os.path.join(T20, "_tool", "manticore"))}
    lista = [l.split()[1] for f in ("_lista.txt", "_lista_soltg_reg.txt")
             for l in rep.leggi(os.path.join(T20, f)).splitlines() if l.strip()]
    for rel in lista:
        if rel.startswith("soltg/") and rel not in rep.SOLTG_ORIG or rel in rep.NON_APPLICABILI:
            continue
        nome = os.path.basename(rel)
        src_path = os.path.join(T20, "solcmc_maxdepth100", rel, nome + ".sol")
        if not os.path.exists(src_path):
            src_path = os.path.join(T20, "_tool", "mythril", rel, nome + ".sol")
        src = rep.leggi(src_path)
        att = rep.atteso(rel, rep.leggi(rep.UFFICIALE[rel]) if rel in rep.UFFICIALE else src, mano)
        r = {"solcmc": rep.nostri(os.path.join(T20, "solcmc_maxdepth100"), rel, st["solcmc"]),
             "yul": rep.nostri(os.path.join(T20, "yul_maxdepth100"), rel, st["yul"]),
             "myth": rep.mythril(rel, st["myth"]), "mcore": rep.manticore(rel, st["mcore"])}
        yield rel, src_path, att, {k: rep.esito(att, r[k]) for k in r}


def count_tests(path):
    import json
    try:
        fns = json.load(open(path)).get("functions", [])
    except (OSError, ValueError):
        return 0, 0
    kinds = [tc.get("kind", "") for fn in fns for tc in fn.get("test_cases", [])]
    return kinds.count("negative"), kinds.count("positive")


def main():
    if os.path.isdir(OUT):
        shutil.rmtree(os.path.join(OUT, "soltg"), ignore_errors=True)
        shutil.rmtree(os.path.join(OUT, "smtchecker"), ignore_errors=True)
    rows, seen = [], set()
    for rel, src_path, att, es in contracts():
        bench, cat, name = target(rel)
        d = os.path.join(OUT, bench, cat, name)
        assert d not in seen, d
        seen.add(d)
        os.makedirs(d)
        shutil.copy2(src_path, os.path.join(d, name + ".sol"))
        row = {"benchmark": bench, "category": cat, "contract": name,
               "expected": "bug" if att[0] == "bug" else "safe", "calls_needed": att[1]}
        for route, short in (("solcmc", "solcmc"), ("yul", "yul2chc")):
            vg = os.path.join(T21, route, rel, name + ".sol")
            if os.path.exists(vg) and not os.path.exists(os.path.join(d, name + "_vgood.sol")):
                shutil.copy2(vg, os.path.join(d, name + "_vgood.sol"))
            js = glob.glob(os.path.join(T21, route, rel, "*.test_cases.json"))
            neg = pos = ""
            if js:
                shutil.copy2(js[0], os.path.join(d, short + ".test_cases.json"))
                neg, pos = count_tests(js[0])
            row[short] = OUTCOME[es[route]]
            row[short + "_negative_tests"], row[short + "_positive_tests"] = neg, pos
        row["mythril"], row["manticore"] = OUTCOME[es["myth"]], OUTCOME[es["mcore"]]
        rows.append(row)
    rows.sort(key=lambda x: (x["benchmark"] != "soltg", x["category"], x["contract"]))
    with open(os.path.join(OUT, "summary.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    for b in ("soltg", "smtchecker"):
        rs = [x for x in rows if x["benchmark"] == b]
        print(b, len(rs), "contracts,", sum(x["expected"] == "bug" for x in rs), "with a bug")
        for t in ("solcmc", "yul2chc", "mythril", "manticore"):
            c = {}
            for x in rs:
                c[x[t]] = c.get(x[t], 0) + 1
            print("  ", t.ljust(10), c)


if __name__ == "__main__":
    main()
