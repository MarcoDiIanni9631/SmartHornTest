#!/usr/bin/env python3
"""Writes experiments/report.html, an interactive page with the results of the
benchmark: one pie chart per tool and benchmark (click a slice to see its
contracts) and, for every contract, the outcome of each tool, the test cases
found by the two routes with the result of forge test, and the source code.
Uses only experiments/ (summary.csv, foundry.csv and the contract folders).
Usage (from the repo root): python3 script/build_report_html.py"""
import csv, json, os

E = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "experiments")


def tests(path, foundry, key):
    try:
        data = json.load(open(path))
    except (OSError, ValueError):
        return None
    out = []
    for fn in data.get("functions", []):
        for tc in fn.get("test_cases", []):
            kind = tc.get("kind", "")
            res, why = foundry.get(key + (f"test_{kind}_{len(out) + 1}()",), ("", ""))
            out.append({"f": fn.get("signature", ""), "k": kind, "a": tc.get("failed_assert", ""),
                        "v": tc.get("concrete_values", []),
                        "c": tc.get("constraints_clpq_start", tc.get("constraints_clpq", [])),
                        "fd": res, "fw": why})
    return out


def main():
    rows = []
    foundry = {(t["benchmark"], t["category"], t["contract"], t["route"], t["test"]): (t["result"], t["reason"])
               for t in csv.DictReader(open(os.path.join(E, "foundry.csv")))}
    for r in csv.DictReader(open(os.path.join(E, "summary.csv"))):
        d = os.path.join(E, r["benchmark"], r["category"], r["contract"])
        rows.append({"b": r["benchmark"], "cat": r["category"], "n": r["contract"], "fn": r["function"],
                     "exp": r["expected"], "calls": r["calls_needed"],
                     "out": {t: r[t] for t in ("solcmc", "yul2chc", "mythril", "manticore")},
                     "src": open(os.path.join(d, r["contract"] + ".sol"), errors="replace").read(),
                     "tests": {t: tests(os.path.join(d, t + ".test_cases.json"), foundry,
                                        (r["benchmark"], r["category"], r["contract"], t)) for t in ("solcmc", "yul2chc")}})
    data = json.dumps(rows, separators=(",", ":")).replace("</", "<\\/")
    with open(os.path.join(E, "report.html"), "w") as f:
        f.write(PAGE.replace("__DATA__", data))
    print(len(rows), "contracts, written", os.path.join(E, "report.html"))


PAGE = r"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SmartHornTest benchmark</title>
<style>
  body { font-family: -apple-system, Segoe UI, Helvetica, Arial, sans-serif; margin: 2rem; color: #1a1a1a; background: #fafafa; }
  h1 { margin-bottom: 0.2rem; }
  h2 { margin-top: 2.5rem; border-bottom: 2px solid #ddd; padding-bottom: 0.3rem; }
  h4 { margin: 1rem 0 0.4rem; }
  .meta, .muted { color: #666; }
  .meta { margin-bottom: 1.5rem; max-width: 60rem; }
  .pies { display: flex; flex-wrap: wrap; gap: 1.5rem; margin: 1rem 0 1.5rem; }
  .pie { margin: 0; background: white; padding: 1rem; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); width: 220px; }
  .pie figcaption { font-size: 0.9rem; margin-bottom: 0.5rem; }
  .pie-num { font-size: 26px; font-weight: 700; fill: #1a1a1a; }
  .pie-sub { font-size: 11px; fill: #666; }
  .legend { list-style: none; padding: 0; margin: 0.5rem 0 0; font-size: 0.82rem; }
  .legend li { margin: 0.2rem 0; cursor: pointer; }
  .legend li:hover { text-decoration: underline; }
  .sw { display: inline-block; width: 10px; height: 10px; border-radius: 2px; margin-right: 6px; vertical-align: middle; }
  circle.slice { cursor: pointer; }
  circle.slice:hover { opacity: 0.8; }
  .panel { background: white; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.15); padding: 1rem 1.2rem; margin-bottom: 2rem; }
  .panel-head { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.8rem; }
  .close { margin-left: auto; border: 1px solid #ccc; background: #f5f5f5; border-radius: 4px; padding: 0.2rem 0.7rem; cursor: pointer; }
  .item { border-top: 1px solid #eee; padding: 0.4rem 0; }
  .item > summary { cursor: pointer; }
  .detail { margin: 0.5rem 0 0.5rem 1rem; font-size: 0.88rem; }
  .row { margin: 0.25rem 0; }
  .row > span:first-child { display: inline-block; min-width: 170px; color: #666; font-weight: 600; }
  .badge { font-weight: 700; padding: 0.1rem 0.45rem; border-radius: 4px; display: inline-block; white-space: nowrap; font-size: 0.8rem; margin-right: 0.3rem; }
  pre { background: #f6f8fa; border: 1px solid #e5e5e5; border-radius: 6px; padding: 0.7rem; font-size: 0.8rem; overflow-x: auto; }
  table { border-collapse: collapse; width: 100%; background: white; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
  th, td { border: 1px solid #e0e0e0; padding: 0.4rem 0.55rem; text-align: left; vertical-align: top; font-size: 0.85rem; }
  th { background: #f0f0f0; position: sticky; top: 0; }
  .scroll { overflow-x: auto; }
  tr.c { cursor: pointer; }
  tr.c:hover { background: #f3f6fa; }
  td.mono, .mono { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 0.78rem; }
  .filters { display: flex; gap: 0.8rem; flex-wrap: wrap; margin: 0.8rem 0; }
  .filters input, .filters select { padding: 0.35rem 0.5rem; border: 1px solid #ccc; border-radius: 4px; font-size: 0.9rem; }
  .neg { background: #fbe4e4; color: #a41818; }
  .pos { background: #e6f4ea; color: #1e7e34; }
  @media (max-width: 600px) { body { margin: 1rem; } .pie { width: 100%; } }
</style>
</head>
<body>
<h1>SmartHornTest benchmark</h1>
<div id="benchmarks"></div>
<h2>Foundry: test cases run on the original contracts</h2>
<p class="muted">A negative test case is confirmed if the call fails with panic 0x01 (assertion failed), a positive one if the call succeeds.</p>
<div id="foundry"></div>
<h2>All contracts</h2>
<div class="filters">
  <input id="q" type="search" placeholder="Search contract or category">
  <select id="fb"><option value="">All benchmarks</option><option value="soltg">SolTG</option><option value="smtchecker">SMTChecker</option></select>
  <select id="fe"><option value="">Bug and safe</option><option value="bug">With a bug</option><option value="safe">Safe</option></select>
</div>
<div class="scroll"><table>
  <thead><tr><th>Benchmark</th><th>Contract</th><th>Expected</th><th>SolCMC</th><th>yul2chc</th><th>Mythril</th><th>Manticore</th><th>Tests SolCMC<br>neg / pos</th><th>Tests yul2chc<br>neg / pos</th></tr></thead>
  <tbody id="tbody"></tbody>
</table></div>
<script id="data" type="application/json">__DATA__</script>
<script>
const DATA = JSON.parse(document.getElementById("data").textContent);
const TOOLS = [["solcmc", "SmartHornTest, SolCMC"], ["yul2chc", "SmartHornTest, yul2chc"], ["mythril", "Mythril"], ["manticore", "Manticore"]];
const OUT = [["correct", "#2f9e44"], ["bug missed", "#e03131"], ["bug needs several calls", "#f08c00"],
             ["false alarm", "#7048e8"], ["timeout", "#fab005"], ["not analyzed", "#adb5bd"], ["no expected answer", "#dee2e6"]];
const COLOR = Object.fromEntries(OUT);
const FD = [["confirmed", "#2f9e44"], ["not confirmed: no assertion fails", "#e03131"], ["not confirmed: a real assertion fails", "#7048e8"],
            ["not confirmed: other revert", "#f08c00"], ["not confirmed: value out of the type", "#adb5bd"], ["not run", "#495057"]];
const FCOLOR = Object.fromEntries(FD);
const BENCH = [["soltg", "SolTG regression benchmark"], ["smtchecker", "SMTChecker tests of the Solidity compiler"]];

const esc = s => String(s).replace(/[&<>"]/g, c => ({"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;"}[c]));
const big = s => String(s)
  .replaceAll("115792089237316195423570985008687907853269984665640564039457584007913129639935", "2^256-1")
  .replaceAll("57896044618658097711785492504343953926634992332820282019728792003956564819967", "2^255-1")
  .replaceAll("57896044618658097711785492504343953926634992332820282019728792003956564819968", "2^255")
  .replaceAll("=<", "<=").replace(/\s+/g, " ");
const badge = o => `<span class="badge" style="background:${COLOR[o] || "#eee"}33;color:#222;border:1px solid ${COLOR[o] || "#ccc"}">${esc(o)}</span>`;
const count = (ts, k) => ts ? ts.filter(t => t.k === k).length : "";
const negpos = ts => ts ? `${count(ts, "negative")} / ${count(ts, "positive")}` : "–";

function testsTable(ts) {
  if (!ts) return '<p class="muted">No test cases file for this route (see the outcome above).</p>';
  if (!ts.length) return '<p class="muted">No test cases.</p>';
  return `<table><tr><th>#</th><th>Function</th><th>Kind</th><th>Assertion reached</th><th>Test case (values at the start of the call)</th><th>Input constraint (start of the call)</th><th>Foundry</th></tr>` +
    ts.map((t, i) => `<tr><td>${i + 1}</td><td class="mono">${esc(t.f)}</td>
      <td><span class="badge ${t.k === "negative" ? "neg" : "pos"}">${esc(t.k)}</span></td>
      <td class="mono">${esc(t.a === "vgood < 20" ? "(end of the function)" : t.a || "–")}</td>
      <td class="mono">${esc(t.v.join(", ") || "any")}</td>
      <td class="mono">${esc(t.c.map(big).join(" ∧ ") || "true")}</td>
      <td>${t.fd ? `<span class="badge" style="background:${FCOLOR[t.fd]}33;border:1px solid ${FCOLOR[t.fd]}">${esc(t.fd.replace("not confirmed: ", "not confirmed, "))}</span>` +
        (t.fw ? `<br><span class="muted mono">${esc(t.fw)}</span>` : "") : "–"}</td></tr>`).join("") + "</table>";
}

function detail(c) {
  const exp = c.exp === "bug" ? "bug" + (c.calls > 1 ? ` (needs ${c.calls} calls)` : "") : "safe";
  const cut = c.src.indexOf("// ===="), code = (cut < 0 ? c.src : c.src.slice(0, cut)).trimEnd(), footer = cut < 0 ? "" : c.src.slice(cut);
  return `<div class="detail">
    <div class="row"><span>Benchmark / category</span>${esc(c.b)} / ${esc(c.cat)}</div>
    <div class="row"><span>Expected answer</span>${esc(exp)}</div>
    <div class="row"><span>Function (yul2chc route)</span><span class="mono">${esc(c.fn)}</span></div>
    <div class="row"><span>Outcomes</span>${TOOLS.map(([k, l]) => `${esc(l)}: ${badge(c.out[k])}`).join(" ")}</div>
    <h4>Source code</h4><pre>${esc(code)}</pre>
    ${footer ? `<details><summary>Expected answer comment (end of the file)</summary><pre>${esc(footer)}</pre></details>` : ""}
    <h4>Test cases, SolCMC route (${count(c.tests.solcmc, "negative") || 0} negative, ${count(c.tests.solcmc, "positive") || 0} positive)</h4>${testsTable(c.tests.solcmc)}
    <h4>Test cases, yul2chc route (${count(c.tests.yul2chc, "negative") || 0} negative, ${count(c.tests.yul2chc, "positive") || 0} positive)</h4>${testsTable(c.tests.yul2chc)}
    </div>`;
}

function pie(cs, tool, label, panel) {
  const r = 64, C = 2 * Math.PI * r, n = cs.length;
  let off = 0, svg = "", legend = "";
  const ok = cs.filter(c => c.out[tool] === "correct").length;
  for (const [o, col] of OUT) {
    const k = cs.filter(c => c.out[tool] === o).length;
    if (!k) continue;
    const len = C * k / n;
    svg += `<circle class="slice" data-o="${o}" cx="90" cy="90" r="${r}" fill="none" stroke="${col}" stroke-width="32"
      stroke-dasharray="${len} ${C - len}" stroke-dashoffset="${-off}" transform="rotate(-90 90 90)"><title>${o}: ${k} of ${n}</title></circle>`;
    legend += `<li data-o="${o}"><span class="sw" style="background:${col}"></span>${o}: <b>${k}</b></li>`;
    off += len;
  }
  const fig = document.createElement("figure");
  fig.className = "pie";
  fig.innerHTML = `<figcaption><b>${esc(label)}</b></figcaption>
    <svg viewBox="0 0 180 180" width="180" height="180" role="img" aria-label="${esc(label)}">${svg}
    <text x="90" y="92" text-anchor="middle" class="pie-num">${Math.round(100 * ok / n)}%</text>
    <text x="90" y="110" text-anchor="middle" class="pie-sub">correct</text></svg><ul class="legend">${legend}</ul>`;
  fig.querySelectorAll("[data-o]").forEach(el => el.addEventListener("click", () => show(panel, cs, tool, label, el.dataset.o)));
  return fig;
}

function show(panel, cs, tool, label, o) {
  const sel = cs.filter(c => c.out[tool] === o);
  panel.hidden = false;
  panel.innerHTML = `<div class="panel-head"><span class="sw" style="background:${COLOR[o]}"></span>
    <b>${esc(label)}: ${esc(o)}</b> <span class="muted">${sel.length} contracts</span><button class="close">close</button></div>` +
    sel.map(c => `<details class="item"><summary><b>${esc(c.n)}</b> <span class="muted">${esc(c.cat)}, expected ${esc(c.exp)}</span></summary>${detail(c)}</details>`).join("");
  panel.querySelector(".close").onclick = () => { panel.hidden = true; };
  panel.scrollIntoView({behavior: "smooth", block: "nearest"});
}

const root = document.getElementById("benchmarks");
for (const [b, title] of BENCH) {
  const cs = DATA.filter(c => c.b === b);
  const h = document.createElement("h2");
  h.textContent = `${title}: ${cs.length} contracts, ${cs.filter(c => c.exp === "bug").length} with a bug`;
  const pies = document.createElement("div");
  pies.className = "pies";
  const panel = document.createElement("div");
  panel.className = "panel";
  panel.hidden = true;
  TOOLS.forEach(([k, l]) => pies.appendChild(pie(cs, k, l, panel)));
  root.append(h, pies, panel);
}

function donut(label, groups, center, sub, onclick) {
  const r = 64, C = 2 * Math.PI * r, n = groups.reduce((a, g) => a + g[2], 0);
  let off = 0, svg = "", legend = "";
  for (const [o, col, k] of groups) {
    if (!k) continue;
    const len = C * k / n;
    svg += `<circle class="slice" data-o="${o}" cx="90" cy="90" r="${r}" fill="none" stroke="${col}" stroke-width="32"
      stroke-dasharray="${len} ${C - len}" stroke-dashoffset="${-off}" transform="rotate(-90 90 90)"><title>${o}: ${k} of ${n}</title></circle>`;
    legend += `<li data-o="${o}"><span class="sw" style="background:${col}"></span>${o}: <b>${k}</b></li>`;
    off += len;
  }
  const fig = document.createElement("figure");
  fig.className = "pie";
  fig.innerHTML = `<figcaption><b>${esc(label)}</b></figcaption>
    <svg viewBox="0 0 180 180" width="180" height="180" role="img" aria-label="${esc(label)}">${svg}
    <text x="90" y="92" text-anchor="middle" class="pie-num" style="font-size:${String(center).length > 5 ? 19 : 26}px">${center}</text>
    <text x="90" y="110" text-anchor="middle" class="pie-sub">${sub}</text></svg><ul class="legend">${legend}</ul>`;
  fig.querySelectorAll("[data-o]").forEach(el => el.addEventListener("click", () => onclick(el.dataset.o)));
  return fig;
}

{
  const froot = document.getElementById("foundry"), pies = document.createElement("div"), panel = document.createElement("div");
  pies.className = "pies";
  panel.className = "panel";
  panel.hidden = true;
  for (const [route, rl] of [["solcmc", "SolCMC"], ["yul2chc", "yul2chc"]]) {
    for (const kind of ["negative", "positive"]) {
      const ts = DATA.flatMap(c => (c.tests[route] || []).filter(t => t.k === kind).map(t => [c, t]));
      const ok = ts.filter(([, t]) => t.fd === "confirmed").length;
      const label = `${rl}, ${kind} test cases`;
      pies.appendChild(donut(label, FD.map(([o, col]) => [o, col, ts.filter(([, t]) => t.fd === o).length]),
        `${ok}/${ts.length}`, `confirmed (${Math.round(100 * ok / ts.length)}%)`, o => {
          const cs = [...new Set(ts.filter(([, t]) => t.fd === o).map(([c]) => c))];
          panel.hidden = false;
          panel.innerHTML = `<div class="panel-head"><span class="sw" style="background:${FCOLOR[o]}"></span>
            <b>${esc(label)}: ${esc(o)}</b> <span class="muted">${ts.filter(([, t]) => t.fd === o).length} test cases in ${cs.length} contracts</span><button class="close">close</button></div>` +
            cs.map(c => `<details class="item"><summary><b>${esc(c.n)}</b> <span class="muted">${esc(c.b)} / ${esc(c.cat)}, expected ${esc(c.exp)}</span></summary>${detail(c)}</details>`).join("");
          panel.querySelector(".close").onclick = () => { panel.hidden = true; };
          panel.scrollIntoView({behavior: "smooth", block: "nearest"});
        }));
    }
  }
  froot.append(pies, panel);
}

const tbody = document.getElementById("tbody");
function table() {
  const q = document.getElementById("q").value.toLowerCase(), fb = document.getElementById("fb").value, fe = document.getElementById("fe").value;
  tbody.innerHTML = "";
  DATA.filter(c => (!fb || c.b === fb) && (!fe || c.exp === fe) && (c.n + " " + c.cat).toLowerCase().includes(q)).forEach(c => {
    const tr = document.createElement("tr");
    tr.className = "c";
    tr.innerHTML = `<td>${esc(c.b)}</td><td><b>${esc(c.n)}</b><br><span class="muted">${esc(c.cat)}</span></td><td>${esc(c.exp)}</td>` +
      TOOLS.map(([k]) => `<td>${badge(c.out[k])}</td>`).join("") +
      `<td>${negpos(c.tests.solcmc)}</td><td>${negpos(c.tests.yul2chc)}</td>`;
    tr.onclick = () => {
      if (tr.nextSibling && tr.nextSibling.classList.contains("d")) { tr.nextSibling.remove(); return; }
      const d = document.createElement("tr");
      d.className = "d";
      d.innerHTML = `<td colspan="9">${detail(c)}</td>`;
      tr.after(d);
    };
    tbody.appendChild(tr);
  });
}
["q", "fb", "fe"].forEach(id => document.getElementById(id).addEventListener("input", table));
table();
</script>
</body>
</html>
"""

if __name__ == "__main__":
    main()
