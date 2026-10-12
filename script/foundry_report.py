#!/usr/bin/env python3
"""
foundry_report.py — runs the Foundry witness tests (made by
witnesses2foundry.py) and writes a readable HTML report of the results.

For each test it shows: the contract, the values our tool found, what
happened when Foundry ran the contract with those values, and the contract
source.

  testimone reale   [PASS]  the call fails with Panic(0x01): the assert
                            really breaks with our values
  assert regge      [FAIL: next call did not revert as expected]
                            the call goes through: our witness is false
  fuori dominio     [FAIL: valore fuori dominio ...]  impossible value
                            for its type (e.g. -200 for a uint)
  altro errore      the call fails, but not on an assert (require,
                            overflow, ...)

Usage:
    python3 script/foundry_report.py <foundry_project> [-o report.html] [--use /path/to/solc]
"""
import argparse
import html
import json
import os
import re
import subprocess
from collections import Counter, defaultdict
from datetime import datetime

CATS = [
    ("reale", "testimone reale", "#0ca30c"),
    ("regge", "assert regge (testimone falso)", "#d03b3b"),
    ("dominio", "valore fuori dominio", "#e8a200"),
    ("altro", "altro errore", "#9e9e9e"),
]
LABEL = {k: l for k, l, _ in CATS}
COLOR = {k: c for k, _, c in CATS}


def category(status, reason):
    if status == "Success":
        return "reale"
    r = reason or ""
    if "did not revert" in r:
        return "regge"
    if "fuori dominio" in r:
        return "dominio"
    return "altro"


BENCH_ORDER = ["SolCMC", "SolTG", "TPLP", "Solidity reali", "Proprieta' sulle variabili"]


def bench_of(group):
    g = group.lower()
    if g.startswith("solcmc"):
        return "SolCMC"
    if g.startswith("soltg"):
        return "SolTG"
    if g.startswith("tplp"):
        return "TPLP"
    if g.startswith("proprieta"):
        return "Proprieta' sulle variabili"
    return "Solidity reali"


def pie_svg(title, counts, key):
    """Donut chart of the four outcome categories; slices and legend items
    are clickable (data-bench / data-cat) to filter the tables below."""
    import math
    total = sum(counts.values())
    if not total:
        return ""
    cx = cy = 90
    ro, ri = 80, 48
    out = [f"<figure class='pie'><figcaption><b>{html.escape(title)}</b><br>"
           f"<span class='muted'>{total} test</span></figcaption>",
           f"<svg viewBox='0 0 180 180' width='180' height='180' role='img' aria-label='{html.escape(title)}'>"]
    start = -math.pi / 2
    keys = [k for k, _, _ in CATS if counts.get(k)]
    for k in keys:
        frac = counts[k] / total
        tip = f"{LABEL[k]}: {counts[k]} su {total} - clicca per filtrare"
        attrs = f"class='slice' data-bench='{html.escape(key)}' data-cat='{k}'"
        if frac >= 0.9999:
            out.append(f"<circle {attrs} cx='{cx}' cy='{cy}' r='{(ro+ri)/2}' fill='none' "
                       f"stroke='{COLOR[k]}' stroke-width='{ro-ri}'><title>{tip}</title></circle>")
            break
        end = start + frac * 2 * math.pi
        large = 1 if end - start > math.pi else 0
        pt = lambda a, r: (cx + r * math.cos(a), cy + r * math.sin(a))
        x1, y1 = pt(start, ro); x2, y2 = pt(end, ro); x3, y3 = pt(end, ri); x4, y4 = pt(start, ri)
        out.append(f"<path {attrs} d='M{x1:.2f},{y1:.2f} A{ro},{ro} 0 {large} 1 {x2:.2f},{y2:.2f} "
                   f"L{x3:.2f},{y3:.2f} A{ri},{ri} 0 {large} 0 {x4:.2f},{y4:.2f} Z' "
                   f"fill='{COLOR[k]}' stroke='white' stroke-width='2'><title>{tip}</title></path>")
        start = end
    pct = counts.get("reale", 0) / total
    out.append(f"<text x='{cx}' y='{cy-2}' text-anchor='middle' class='pie-num'>{pct:.0%}</text>"
               f"<text x='{cx}' y='{cy+16}' text-anchor='middle' class='pie-sub'>testimoni reali</text></svg>")
    out.append("<ul class='pie-legend'>")
    for k in keys:
        out.append(f"<li class='slice' data-bench='{html.escape(key)}' data-cat='{k}'>"
                   f"<span class='sw' style='background:{COLOR[k]}'></span>{html.escape(LABEL[k])}: <b>{counts[k]}</b></li>")
    out.append("</ul></figure>")
    return "".join(out)


FILTER_JS = """<script>
(function () {
  var info = document.getElementById('filtro');
  function apply(bench, cat) {
    var n = 0;
    document.querySelectorAll('tr.row').forEach(function (tr) {
      var ok = (bench === '*' || tr.dataset.bench === bench) && tr.dataset.cat === cat;
      tr.style.display = ok ? '' : 'none';
      if (ok) n++;
    });
    document.querySelectorAll('.bench-section').forEach(function (sec) {
      sec.style.display = sec.querySelector('tr.row:not([style*="none"])') ? '' : 'none';
    });
    info.innerHTML = 'Filtro attivo: <b>' + (bench === '*' ? 'tutti i benchmark' : bench) + '</b>, <b>' +
      document.querySelector('.slice[data-cat="' + cat + '"]').textContent.split(':')[0] + '</b> (' + n +
      ' test) <button type="button" id="reset">mostra tutto</button>';
    info.hidden = false;
    document.getElementById('reset').onclick = function () {
      document.querySelectorAll('tr.row, .bench-section').forEach(function (e) { e.style.display = ''; });
      info.hidden = true;
    };
    info.scrollIntoView({behavior: 'smooth', block: 'start'});
  }
  document.querySelectorAll('.slice').forEach(function (el) {
    el.addEventListener('click', function () { apply(el.dataset.bench, el.dataset.cat); });
  });
})();
</script>"""


def parse_test_file(path):
    """{test_function: values comment}, plus the 'group/contract' header."""
    src = open(path, encoding="utf-8").read()
    header = re.search(r"// Witnesses found by our tool for (\S+)", src)
    values, last = {}, ""
    for line in src.splitlines():
        m = re.match(r"\s*// values found by the tool: (.*)", line)
        if m:
            last = m.group(1)
        m = re.match(r"\s*function (test_\w+)\(", line)
        if m:
            values[m.group(1)] = last
            last = ""
    call = {m.group(1): m.group(2) for m in re.finditer(
        r"function (test_\w+)\(\) public \{.*?(c\.\w+\([^;]*\));", src, re.S)}
    return (header.group(1) if header else ""), values, call


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("project")
    ap.add_argument("-o", "--output")
    ap.add_argument("--use", help="solc da usare (es. ~/bin/solc sul server)")
    args = ap.parse_args()
    project = os.path.abspath(args.project)
    out_html = args.output or os.path.join(project, "report_foundry.html")

    cmd = ["forge", "test", "--match-contract", "^Test_", "--json"]
    if args.use:
        cmd += ["--use", os.path.expanduser(args.use)]
    res = subprocess.run(cmd, cwd=project, capture_output=True, text=True)
    start = res.stdout.find("{")
    if start < 0:
        raise SystemExit("forge non ha prodotto risultati JSON:\n" + res.stderr[-2000:])
    data = json.loads(res.stdout[start:])
    with open(os.path.join(project, "forge_results.json"), "w") as f:
        json.dump(data, f, indent=1)

    rows = []
    for suite, v in data.items():
        tfile = os.path.join(project, suite.split(":")[0])
        origin, values, calls = parse_test_file(tfile)
        group, _, contract = origin.rpartition("/")
        src_file = os.path.join(project, "src", os.path.basename(tfile).replace(".t.sol", ".sol"))
        src = open(src_file, encoding="utf-8", errors="replace").read() if os.path.exists(src_file) else ""
        for tname, r in v["test_results"].items():
            fn = tname.split("(")[0]
            cat = category(r.get("status"), r.get("reason"))
            rows.append({
                "bench": bench_of(group), "group": group, "contract": contract,
                "test": fn, "values": values.get(fn, ""), "call": calls.get(fn, ""),
                "cat": cat, "reason": r.get("reason") or "", "src": src,
            })
    rows.sort(key=lambda x: (BENCH_ORDER.index(x["bench"]), x["group"], x["contract"],
                             int(re.sub(r"\D", "", x["test"]) or 0)))

    total = Counter(r["cat"] for r in rows)
    by_bench = defaultdict(Counter)
    for r in rows:
        by_bench[r["bench"]][r["cat"]] += 1
    n = len(rows)
    now = datetime.now().strftime("%Y-%m-%d %H:%M")

    p = [f"""<!doctype html><html lang="it"><head><meta charset="utf-8">
<title>Verifica testimoni con Foundry</title>
<style>
 body {{ font-family: -apple-system, Segoe UI, Helvetica, Arial, sans-serif; margin: 2rem; color: #1a1a1a; background: #fafafa; }}
 .meta {{ color: #555; margin: 0.3rem 0 1rem; }}
 .cmd {{ background: #e9e9e9; padding: 0.5rem 0.8rem; border-radius: 6px; font-family: ui-monospace, monospace; font-size: 0.85rem; word-break: break-all; }}
 .cards {{ display: flex; gap: 1rem; flex-wrap: wrap; margin: 1rem 0 2rem; }}
 .card {{ background: white; border-radius: 8px; padding: 0.8rem 1.2rem; box-shadow: 0 1px 3px rgba(0,0,0,.1); border-left: 6px solid; }}
 .card b {{ font-size: 1.6rem; display: block; }}
 table {{ border-collapse: collapse; width: 100%; background: white; box-shadow: 0 1px 3px rgba(0,0,0,.1); margin-bottom: 2rem; }}
 th, td {{ border: 1px solid #e0e0e0; padding: 0.45rem 0.6rem; text-align: left; vertical-align: top; font-size: 0.86rem; }}
 th {{ background: #f0f0f0; }}
 .badge {{ color: white; padding: 0.1rem 0.5rem; border-radius: 4px; font-weight: 600; white-space: nowrap; }}
 code, pre {{ font-family: ui-monospace, monospace; font-size: 0.8rem; }}
 pre {{ background: #f6f8fa; border: 1px solid #e5e5e5; border-radius: 6px; padding: 0.6rem; overflow-x: auto; }}
 details summary {{ cursor: pointer; color: #2a78d6; }}
 h2 {{ border-bottom: 2px solid #ddd; padding-bottom: 0.3rem; margin-top: 2rem; }}
 .pies {{ display: flex; flex-wrap: wrap; gap: 1.2rem; margin: 1rem 0 1.5rem; }}
 .pie {{ margin: 0; background: white; padding: 1rem; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,.1); width: 210px; }}
 .pie figcaption {{ font-size: 0.9rem; margin-bottom: 0.4rem; }}
 .muted {{ color: #666; font-size: 0.8rem; }}
 .pie-num {{ font-size: 26px; font-weight: 700; fill: #1a1a1a; }}
 .pie-sub {{ font-size: 10px; fill: #666; }}
 .pie-legend {{ list-style: none; padding: 0; margin: 0.4rem 0 0; font-size: 0.8rem; }}
 .pie-legend li {{ margin: 0.2rem 0; }}
 .sw {{ display: inline-block; width: 10px; height: 10px; border-radius: 2px; margin-right: 6px; }}
 .slice {{ cursor: pointer; }}
 path.slice:hover, circle.slice:hover {{ opacity: 0.8; }}
 li.slice:hover {{ text-decoration: underline; }}
 #filtro {{ background: #fff8e1; border: 1px solid #f0d58a; padding: 0.5rem 0.8rem; border-radius: 6px; margin-bottom: 1rem; }}
 #filtro button {{ margin-left: 0.8rem; cursor: pointer; }}
</style></head><body>
<h1>Verifica dei testimoni con Foundry</h1>
<div class="meta">Generato il {now} &mdash; {n} test (un test per ogni valore concreto trovato dal nostro tool), {len(data)} contratti.
Ogni test deploya il contratto, chiama la funzione analizzata con i nostri valori e si aspetta che l'assert fallisca (Panic 0x01).</div>
<div class="cmd"><b>COMANDO:</b> cd {html.escape(os.path.relpath(project))} &amp;&amp; forge test --match-contract '^Test_'</div>
"""]
    p.append("<h2>Esito dei test</h2><div class='pies'>")
    p.append(pie_svg("Totale", total, "*"))
    for b in BENCH_ORDER:
        if by_bench.get(b):
            p.append(pie_svg(b, by_bench[b], b))
    p.append("</div><div id='filtro' hidden></div>")

    for b in [x for x in BENCH_ORDER if x in by_bench]:
        p.append(f"<div class='bench-section'><h2>{html.escape(b)}</h2><table><tr><th>Contratto</th><th>Test</th>"
                 "<th>Valori trovati dal tool</th><th>Chiamata fatta da Foundry</th><th>Esito</th><th>Dettaglio</th></tr>")
        for r in rows:
            if r["bench"] != b:
                continue
            det = "" if r["cat"] == "reale" else html.escape(r["reason"])
            p.append(
                f"<tr class='row' data-bench='{html.escape(r['bench'])}' data-cat='{r['cat']}'><td><b>{html.escape(r['contract'])}</b><br><span class='meta'>{html.escape(r['group'])}</span>"
                f"<details><summary>codice</summary><pre>{html.escape(r['src'])}</pre></details></td>"
                f"<td>{html.escape(r['test'])}</td><td><code>{html.escape(r['values'] or '(nessuno)')}</code></td>"
                f"<td><code>{html.escape(r['call'])}</code></td>"
                f"<td><span class='badge' style='background:{COLOR[r['cat']]}'>{html.escape(LABEL[r['cat']])}</span></td>"
                f"<td>{det}</td></tr>")
        p.append("</table></div>")
    p.append(FILTER_JS)
    p.append("</body></html>")
    with open(out_html, "w", encoding="utf-8") as f:
        f.write("\n".join(p))
    print(f"{n} test: " + ", ".join(f"{total[k]} {LABEL[k]}" for k, _, _ in CATS if total[k]))
    print(f"Report scritto in: {out_html}")


if __name__ == "__main__":
    main()
