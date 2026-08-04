#!/usr/bin/env python3
"""
dot2html.py <graph.dot> [--svg out.svg] [--tpl file.t.pl] [--defs file.t.pl-defs.txt] [-o out.html]

Wraps a chcviz-generated (optionally already highlighted by
zmiout2dot_highlight.py) .dot/.svg graph into a single self-contained HTML
page: the graph on the left (click to pan via scroll, buttons to zoom), and a
side panel on the right that fills in, on click of a node, whatever we know
about it:

  - its raw CHC clause, from the .t.pl file (same source zmiout2dot_highlight
    already uses for hover tooltips)
  - its block / Yul instruction / storage-memory-local variable mapping, from
    the .t.pl-defs.txt file generated alongside it

This turns the otherwise-static picture into something explorable without
having to re-derive by hand which node is which every time.

Example:
  python3 dot2html.py dot_dias/Foo.t_clean_object_xref_diagram_highlighted.dot
"""
import re
import os
import sys
import json
import html
import argparse
import subprocess
import importlib.util


def _load_highlight_module():
    here = os.path.dirname(os.path.abspath(__file__))
    spec = importlib.util.spec_from_file_location(
        '_hl', os.path.join(here, 'zmiout2dot_highlight.py'))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


_hl = _load_highlight_module()


def related_paths_for_dot(dot_path):
    """chcviz names the graph
    <Base>[_clean]_object_xref_diagram[_testN_kind][_highlighted].dot inside
    dot_dias/, next to the original <Base>.pl and <Base>.pl-defs.txt it was
    generated from (the _testN_kind infix comes from zmiout2dot_highlight.py
    --all, one highlighted file per test)."""
    base = re.sub(r'(_clean)?_object_xref_diagram(_test\d+_\w+)?(_highlighted)?\.dot$', '',
                  os.path.basename(dot_path))
    root_dir = os.path.dirname(os.path.dirname(dot_path))
    stem = re.sub(r'\.t$', '', base)  # SplitterFaulty_vgood.t -> SplitterFaulty_vgood
    return (os.path.join(root_dir, base + '.pl'),
            os.path.join(root_dir, base + '.pl-defs.txt'),
            os.path.join(root_dir, stem + '.sol'))


SOL_DECL_RE = re.compile(
    r'\bfunction\s+([A-Za-z_]\w*)\s*\('
    r'|\b(?:uint|int|bool|address|string|bytes)\d*(?:\[\])?\s+public\s+([A-Za-z_]\w*)\s*[;=]'
)


def parse_sol_declarations(sol_path):
    """{identifier: (line_no, line_text)} for every function and public state
    variable declared in the contract, so nodes whose GREY block label
    mentions that identifier can be linked back to a real line of Solidity.
    Deliberately shallow (regex over lines, not a real Solidity parser) —
    good enough to catch user-written functions/public vars, which is exactly
    the part of the graph that GREY's own IR carries no source-location for."""
    decls = {}
    if not os.path.isfile(sol_path):
        return decls
    for i, line in enumerate(open(sol_path, encoding='utf-8'), 1):
        for m in SOL_DECL_RE.finditer(line):
            name = m.group(1) or m.group(2)
            decls.setdefault(name, (i, line.strip()))
    return decls


def sol_link_for(defs_text, decls):
    """Best-effort: does this node's defs text mention one of the contract's
    own declared identifiers? Longest match wins (so e.g. 'released0' isn't
    shadowed by a coincidental shorter name). Substring-based, not a real
    tokenizer — fine for the specific, deliberately-named identifiers a
    Solidity author writes, which is the only case we're trying to catch."""
    if not defs_text or not decls:
        return None
    best = None
    for name, (line_no, line_text) in decls.items():
        if name in defs_text:
            if best is None or len(name) > len(best[0]):
                best = (name, line_no, line_text)
    if not best:
        return None
    name, line_no, line_text = best
    return {'name': name, 'line': line_no, 'text': line_text}


def ensure_svg(dot_path, svg_path):
    if os.path.isfile(svg_path) and os.path.getmtime(svg_path) >= os.path.getmtime(dot_path):
        return
    subprocess.run(['dot', '-Tsvg', dot_path, '-o', svg_path], check=True)


def build_node_info(node_ids, clauses_by_name, defs_by_name, sol_decls):
    """{node_id: {'clause': str|None, 'defs': str|None, 'sol': {...}|None}}"""
    info = {}
    for node_id in node_ids:
        name = node_id.split('/', 1)[0]
        clauses = clauses_by_name.get(name)
        defs = defs_by_name.get(name)
        if not clauses and not defs:
            continue
        defs_text = '\n\n'.join(defs) if defs else None
        info[node_id] = {
            'clause': '\n\n'.join(clauses) if clauses else None,
            'defs': defs_text,
            'sol': sol_link_for(defs_text, sol_decls),
        }
    return info


NODE_G_RE = re.compile(r'(<g id="node\d+" class="node")>')


def wire_up_clicks(svg_text):
    return NODE_G_RE.sub(r'\1 onclick="showInfo(this)" style="cursor:pointer">', svg_text)


PAGE_TEMPLATE = """<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>{title}</title>
<style>
  html, body {{ margin: 0; height: 100%; font-family: -apple-system, Segoe UI, sans-serif; }}
  #app {{ display: flex; height: 100vh; }}
  #graph-wrap {{ flex: 1 1 auto; overflow: auto; background: #fafafa; position: relative;
                 cursor: grab; user-select: none; -webkit-user-select: none; }}
  #graph-wrap.panning {{ cursor: grabbing; }}
  #graph-zoom {{ transform-origin: 0 0; display: inline-block; padding: 12px; }}
  #zoom-controls {{ position: sticky; top: 8px; left: 8px; z-index: 10; display: inline-flex;
                     gap: 4px; background: white; border: 1px solid #ccc; border-radius: 6px;
                     padding: 4px; margin: 8px; box-shadow: 0 1px 3px rgba(0,0,0,.15); }}
  #zoom-controls button {{ width: 28px; height: 28px; cursor: pointer; }}
  #panel {{ flex: 0 0 420px; overflow: auto; border-left: 1px solid #ddd; padding: 16px;
            background: white; }}
  #panel h3 {{ margin-top: 0; font-family: monospace; word-break: break-all; }}
  #panel h4 {{ margin: 14px 0 4px; font-size: 13px; color: #555; text-transform: uppercase; }}
  #panel pre {{ background: #f4f4f4; border: 1px solid #e0e0e0; border-radius: 4px;
                padding: 8px; white-space: pre-wrap; word-break: break-word;
                font-size: 12.5px; line-height: 1.4; }}
  #panel .placeholder {{ color: #888; }}
  .node {{ transition: opacity .15s; }}
  .search-hit polygon, .search-hit ellipse, .search-hit path {{ stroke: orange !important; stroke-width: 5px !important; }}
  #search-box {{ width: 160px; border: 1px solid #ccc; border-radius: 4px; padding: 0 6px;
                 font-size: 13px; height: 26px; }}
</style>
</head>
<body>
<div id="app">
  <div id="graph-wrap">
    <div id="zoom-controls">
      <button onclick="setZoom(0.2)">+</button>
      <button onclick="setZoom(-0.2)">-</button>
      <button onclick="fitToScreen()">fit</button>
      <input id="search-box" type="text" placeholder="find node...">
    </div>
    <div id="graph-zoom">
{svg}
    </div>
  </div>
  <div id="panel"><p class="placeholder">Click a node in the graph to see its CHC clause
  and (when available) the block / Yul instruction / variable mapping behind it.</p></div>
</div>
<script>
const NODE_INFO = {node_info_json};

function showInfo(g) {{
  if (dragMoved) {{ dragMoved = false; return; }}
  const titleEl = g.querySelector('title');
  const panel = document.getElementById('panel');
  if (!titleEl) {{ panel.innerHTML = '<p class="placeholder">(no id found for this node)</p>'; return; }}
  const key = titleEl.textContent;
  const data = NODE_INFO[key];
  let out = '<h3>' + key.replace(/&/g,'&amp;').replace(/</g,'&lt;') + '</h3>';
  if (!data) {{
    out += '<p class="placeholder">No .t.pl / .t.pl-defs.txt entry found for this predicate.</p>';
  }} else {{
    if (data.sol) {{
      out += '<h4>Solidity source (' + data.sol.name + ', line ' + data.sol.line + ')</h4><pre>' + data.sol.text + '</pre>';
    }} else {{
      out += '<h4>Solidity source</h4><p class="placeholder">Not traceable to a specific line — likely compiler-generated support code, not user-written Solidity.</p>';
    }}
    if (data.clause) out += '<h4>CHC clause (.t.pl)</h4><pre>' + data.clause + '</pre>';
    if (data.defs) out += '<h4>Block / instruction / variable mapping (.t.pl-defs.txt)</h4><pre>' + data.defs + '</pre>';
  }}
  panel.innerHTML = out;
}}

const wrap = document.getElementById('graph-wrap');
const zoomEl = document.getElementById('graph-zoom');
const svgEl = zoomEl.querySelector('svg');
const svgNativeW = svgEl.getBoundingClientRect().width || 1000;
const svgNativeH = svgEl.getBoundingClientRect().height || 1000;

let scale = 1;
function applyZoom() {{ zoomEl.style.transform = 'scale(' + scale + ')'; }}
function setZoom(delta) {{ scale = Math.max(0.05, Math.min(4, scale + delta)); applyZoom(); }}
function resetZoom() {{ scale = 1; applyZoom(); }}
function fitToScreen() {{
  const availW = wrap.clientWidth - 24, availH = wrap.clientHeight - 24;
  scale = Math.max(0.05, Math.min(availW / svgNativeW, availH / svgNativeH, 1));
  applyZoom();
  wrap.scrollLeft = 0; wrap.scrollTop = 0;
}}
fitToScreen();

// drag-to-pan (grab the background OR a node; a real click still works
// because dragMoved only becomes true past a small movement threshold)
let panning = false, dragMoved = false, startX = 0, startY = 0, startLeft = 0, startTop = 0;
wrap.addEventListener('mousedown', (e) => {{
  panning = true; dragMoved = false;
  startX = e.clientX; startY = e.clientY;
  startLeft = wrap.scrollLeft; startTop = wrap.scrollTop;
  wrap.classList.add('panning');
}});
window.addEventListener('mousemove', (e) => {{
  if (!panning) return;
  const dx = e.clientX - startX, dy = e.clientY - startY;
  if (Math.abs(dx) > 4 || Math.abs(dy) > 4) dragMoved = true;
  wrap.scrollLeft = startLeft - dx;
  wrap.scrollTop = startTop - dy;
}});
window.addEventListener('mouseup', () => {{ panning = false; wrap.classList.remove('panning'); }});

// wheel-zoom, centered on the cursor position
wrap.addEventListener('wheel', (e) => {{
  e.preventDefault();
  const rect = wrap.getBoundingClientRect();
  const pointX = e.clientX - rect.left + wrap.scrollLeft;
  const pointY = e.clientY - rect.top + wrap.scrollTop;
  const prevScale = scale;
  scale = Math.max(0.05, Math.min(4, scale + (e.deltaY < 0 ? 0.1 : -0.1)));
  const ratio = scale / prevScale;
  applyZoom();
  wrap.scrollLeft = pointX * ratio - (e.clientX - rect.left);
  wrap.scrollTop = pointY * ratio - (e.clientY - rect.top);
}}, {{ passive: false }});

// node search: substring match against every node's title, scroll it into
// view, flash an orange outline, and populate the side panel for it
const searchBox = document.getElementById('search-box');
let lastHit = null;
searchBox.addEventListener('keydown', (e) => {{
  if (e.key !== 'Enter') return;
  const q = searchBox.value.trim().toLowerCase();
  if (!q) return;
  if (lastHit) lastHit.classList.remove('search-hit');
  const nodes = zoomEl.querySelectorAll('.node');
  let hit = null;
  for (const g of nodes) {{
    const t = g.querySelector('title');
    if (t && t.textContent.toLowerCase().includes(q)) {{ hit = g; break; }}
  }}
  if (!hit) {{ searchBox.style.background = '#fdd'; setTimeout(() => searchBox.style.background = '', 400); return; }}
  hit.classList.add('search-hit');
  lastHit = hit;
  hit.scrollIntoView({{behavior: 'smooth', block: 'center', inline: 'center'}});
  showInfo(hit);
}});
</script>
</body>
</html>
"""


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('dot_file')
    ap.add_argument('--svg', default=None, help='pre-rendered .svg to reuse (default: <dot_file>.svg, rendered if missing/stale)')
    ap.add_argument('--tpl', default=None, help='.t.pl file to pull CHC clauses from (auto-detected by default)')
    ap.add_argument('--defs', default=None, help='.t.pl-defs.txt file to pull block/instruction info from (auto-detected by default)')
    ap.add_argument('--sol', default=None, help='.sol file to link nodes back to (auto-detected by default)')
    ap.add_argument('-o', '--output', default=None)
    args = ap.parse_args()

    dot_path = args.dot_file
    svg_path = args.svg or (dot_path + '.svg')
    ensure_svg(dot_path, svg_path)

    default_tpl, default_defs, default_sol = related_paths_for_dot(dot_path)
    tpl_path = args.tpl or default_tpl
    defs_path = args.defs or default_defs
    sol_path = args.sol or default_sol

    lines = open(dot_path).readlines()
    node_ids, _edges = _hl.parse_dot(lines)

    clauses_by_name = _hl.load_predicate_clauses(tpl_path) if os.path.isfile(tpl_path) else {}
    defs_by_name = _hl.load_predicate_clauses(defs_path) if os.path.isfile(defs_path) else {}
    sol_decls = parse_sol_declarations(sol_path)
    if not clauses_by_name:
        print(f"(no .t.pl found at {tpl_path}, clauses will be missing from the panel)")
    if not defs_by_name:
        print(f"(no .t.pl-defs.txt found at {defs_path}, block/instruction info will be missing from the panel)")
    if not sol_decls:
        print(f"(no .sol found at {sol_path}, Solidity source links will be missing from the panel)")

    def esc_value(v):
        if v is None:
            return None
        if isinstance(v, dict):
            return {kk: (html.escape(vv) if isinstance(vv, str) else vv) for kk, vv in v.items()}
        return html.escape(v)

    node_info = build_node_info(node_ids, clauses_by_name, defs_by_name, sol_decls)
    node_info_escaped = {
        k: {kk: esc_value(vv) for kk, vv in v.items()}
        for k, v in node_info.items()
    }

    svg_text = open(svg_path, encoding='utf-8').read()
    svg_text = _hl.promote_tooltips_to_title_elements(svg_text)
    svg_text = wire_up_clicks(svg_text)
    # drop the XML prolog/doctype: we're embedding the <svg> inline in an HTML page
    svg_text = re.sub(r'^.*?(<svg)', r'\1', svg_text, count=1, flags=re.DOTALL)

    title = os.path.basename(dot_path)
    page = PAGE_TEMPLATE.format(
        title=html.escape(title),
        svg=svg_text,
        node_info_json=json.dumps(node_info_escaped),
    )

    out_path = args.output or re.sub(r'\.dot$', '.html', dot_path)
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(page)
    print(f"Interactive HTML written to: {out_path}")
    print(f"  nodes with extra info: {len(node_info)}/{len(node_ids)}")


if __name__ == '__main__':
    main()
