#!/usr/bin/env python3
"""Builds experiments/: the benchmark of the evaluation, with for every
contract the original source, the source with the vgood marker (positive tests)
and the test_cases.json of the two routes: SolCMC route from the run of
3/11/2026 (test3Novembre, converter fixed), yul2chc route from the run of
21/10/2026 (test21Ottobre). summary.csv has the expected answer and the outcome
of each tool, as in the comparison report (test20Ottobre/_report_confronto.py,
SolTG = official version, run of 5/11/2026); foundry.csv has one row per test
case with the result of forge test on the original contract. Contracts with
tuples or casts are excluded (NON_APPLICABILI in the report script).
Usage (on the server, from the repo root): python3 script/build_experiments.py"""
import csv, glob, importlib.util, json, os, shutil

P = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
T20, T21, T3 = os.path.join(P, "test20Ottobre"), os.path.join(P, "test21Ottobre"), os.path.join(P, "test3Novembre")
# folder of the run with vgood (test cases) and of the Foundry project, per route
VG = {"solcmc": os.path.join(T3, "solcmc"), "yul": os.path.join(T21, "yul")}
FD = {"solcmc": T3, "yul": T21}
OUT = os.path.join(P, "experiments")
spec = importlib.util.spec_from_file_location("rep", os.path.join(T20, "_report_confronto.py"))
rep = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rep)
spec = importlib.util.spec_from_file_location("vg", os.path.join(T21, "_report_vgood.py"))
vg = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vg)

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
    st = {"solcmc": rep.stato(rep.SOLCMC), "yul": rep.stato(os.path.join(T20, "yul_maxdepth100")),
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
        r = {"solcmc": rep.nostri(rep.SOLCMC, rel, st["solcmc"]), "soltg": rep.soltg(rel),
             "yul": rep.nostri(os.path.join(T20, "yul_maxdepth100"), rel, st["yul"]),
             "myth": rep.mythril(rel, st["myth"]), "mcore": rep.manticore(rel, st["mcore"])}
        yield rel, src_path, att, {k: rep.esito(att, r[k]) for k in r}


def functions():
    """function analyzed with the yul2chc route (the --aux-hint of the run of 21/10)"""
    f = {}
    for l in rep.leggi(os.path.join(T21, "_lista.txt")).splitlines():
        if l.strip():
            _, rel, hint = l.split()
            f[rel] = hint.strip("_")
    return f


FOUNDRY = {"conf": "confirmed", "nonfall": "not confirmed: no assertion fails",
           "assert_violato": "not confirmed: a real assertion fails", "revert": "not confirmed: other revert",
           "dominio": "not confirmed: value out of the type", "manca": "not run"}


def foundry_rows(rel, bench, cat, name, fg):
    """one row per test case of the two routes, with the result of forge test"""
    out = []
    for route, short in (("solcmc", "solcmc"), ("yul", "yul2chc")):
        res = fg[route].get(vg.base(route, rel), {})
        i = 0
        for j in glob.glob(os.path.join(VG[route], rel, "*.test_cases.json")):
            for fn in json.load(open(j)).get("functions", []):
                for tc in fn.get("test_cases", []):
                    i += 1
                    kind = tc.get("kind", "negative")
                    t = f"test_{kind}_{i}()"
                    x = res.get(t) if res else None
                    out.append({"benchmark": bench, "category": cat, "contract": name, "route": short,
                                "function": fn.get("signature", ""), "test": t, "kind": kind,
                                "values": ", ".join(tc.get("concrete_values") or []),
                                "forge": "" if x is None else ("PASS" if x["status"] == "Success" else "FAIL"),
                                "reason": "" if x is None else " ".join((x.get("reason") or "").split()),
                                "result": FOUNDRY[vg.esito_test(kind, x)]})
    return out


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
    rows, seen, fun = [], set(), functions()
    fg, ftests = {}, []
    for k in ("solcmc", "yul"):
        vg.T = FD[k]
        fg[k] = vg.forge(k)
    for rel, src_path, att, es in contracts():
        bench, cat, name = target(rel)
        d = os.path.join(OUT, bench, cat, name)
        assert d not in seen, d
        seen.add(d)
        os.makedirs(d)
        shutil.copy2(src_path, os.path.join(d, name + ".sol"))
        row = {"benchmark": bench, "category": cat, "contract": name,
               "function": fun[rel], "expected": "bug" if att[0] == "bug" else "safe", "calls_needed": att[1]}
        for route, short in (("solcmc", "solcmc"), ("yul", "yul2chc")):
            vgood = os.path.join(VG[route], rel, name + ".sol")
            if os.path.exists(vgood) and not os.path.exists(os.path.join(d, name + "_vgood.sol")):
                shutil.copy2(vgood, os.path.join(d, name + "_vgood.sol"))
            js = glob.glob(os.path.join(VG[route], rel, "*.test_cases.json"))
            neg = pos = ""
            if js:
                shutil.copy2(js[0], os.path.join(d, short + ".test_cases.json"))
                neg, pos = count_tests(js[0])
            row[short] = OUTCOME[es[route]]
            row[short + "_negative_tests"], row[short + "_positive_tests"] = neg, pos
        row["mythril"], row["manticore"], row["soltg"] = OUTCOME[es["myth"]], OUTCOME[es["mcore"]], OUTCOME[es["soltg"]]
        rows.append(row)
        ftests += foundry_rows(rel, bench, cat, name, fg)
    rows.sort(key=lambda x: (x["benchmark"] != "soltg", x["category"], x["contract"]))
    with open(os.path.join(OUT, "summary.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    ftests.sort(key=lambda x: (x["benchmark"] != "soltg", x["category"], x["contract"], x["route"], x["test"]))
    with open(os.path.join(OUT, "foundry.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(ftests[0]))
        w.writeheader()
        w.writerows(ftests)
    for r in ("solcmc", "yul2chc"):
        for k in ("negative", "positive"):
            ts = [t for t in ftests if t["route"] == r and t["kind"] == k]
            print("foundry", r, k, sum(t["result"] == "confirmed" for t in ts), "/", len(ts), "confirmed")
    for b in ("soltg", "smtchecker"):
        rs = [x for x in rows if x["benchmark"] == b]
        print(b, len(rs), "contracts,", sum(x["expected"] == "bug" for x in rs), "with a bug")
        for t in ("solcmc", "yul2chc", "mythril", "manticore", "soltg"):
            c = {}
            for x in rs:
                c[x[t]] = c.get(x[t], 0) + 1
            print("  ", t.ljust(10), c)


if __name__ == "__main__":
    main()
