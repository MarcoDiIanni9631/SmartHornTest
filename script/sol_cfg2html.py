#!/usr/bin/env python3
"""
sol_cfg2html.py <graph.dot> [--svg out.svg] [-o out.html]

Wraps a single slither `--print cfg` .dot file (one per Solidity function)
into a self-contained, pannable/zoomable HTML page, reusing the same
interaction chrome as dot2html.py (used for the CHC predicate graph) so both
graphs feel like the same tool. Unlike the CHC graph, slither's node labels
already carry the full Solidity statement + IR, so the side panel here just
echoes that label in a bigger, non-truncated form on click.

With --sol, also shows the original contract source in a panel next to the
graph (slither's own dot output carries no source line/offset info, so
without this a CFG node is just a floating statement with nothing to anchor
it to). Clicking a node then best-effort-highlights the matching source
line too, via plain text matching (not a real source map).
"""
import re
import os
import sys
import json
import html
import argparse
import subprocess

NODE_LABEL_RE = re.compile(r'^\s*(\d+)\s*\[label="(.*?)"\s*(?:,[^\]]*)?\];', re.DOTALL | re.MULTILINE)
EXPRESSION_RE = re.compile(r'EXPRESSION:\n(.*?)(?:\n\nIRs:|\Z)', re.DOTALL)


def load_node_labels(dot_path):
    text = open(dot_path, encoding='utf-8').read()
    return {node_id: label for node_id, label in NODE_LABEL_RE.findall(text)}


def _normalize(text):
    return re.sub(r'\s+', ' ', text).strip().rstrip(';')


def find_source_line(label, sol_lines):
    """Best-effort: does this node's EXPRESSION statement appear (as a
    normalized substring) on some line of the original .sol? No real source
    map to rely on (slither's --print cfg dot output carries no line/offset
    info), so this is plain text matching — good enough for the single-line
    statements slither's CFG nodes tend to be, not for anything spanning
    multiple source lines."""
    m = EXPRESSION_RE.search(label)
    if not m:
        return None
    needle = _normalize(m.group(1))
    if not needle:
        return None
    for i, line in enumerate(sol_lines, 1):
        if needle in _normalize(line):
            return i
    return None


def ensure_svg(dot_path, svg_path):
    if os.path.isfile(svg_path) and os.path.getmtime(svg_path) >= os.path.getmtime(dot_path):
        return
    subprocess.run(['dot', '-Tsvg', dot_path, '-o', svg_path], check=True)


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
  #panel {{ flex: 0 0 480px; display: flex; flex-direction: column;
            border-left: 1px solid #ddd; background: white; overflow: hidden; }}
  #panel h3 {{ margin-top: 0; font-family: monospace; word-break: break-all; }}
  #panel pre {{ background: #f4f4f4; border: 1px solid #e0e0e0; border-radius: 4px;
                padding: 8px; white-space: pre-wrap; word-break: break-word;
                font-size: 12.5px; line-height: 1.4; }}
  #panel .placeholder {{ color: #888; }}
  #source-panel {{ flex: 0 0 45%; overflow: auto; border-bottom: 1px solid #ddd;
                    padding: 12px 16px; background: #fbfbfb; }}
  #source-panel h4 {{ margin: 0 0 6px; font-size: 12px; color: #555; text-transform: uppercase; }}
  #source-panel pre {{ margin: 0; background: none; border: none; padding: 0;
                        font-size: 12px; line-height: 1.45; white-space: pre; }}
  .src-line {{ display: block; padding: 0 4px; border-radius: 2px; }}
  .src-line.src-hit {{ background: #fff3a0; }}
  #click-info {{ flex: 1 1 auto; overflow: auto; padding: 16px; }}
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
  <div id="panel">
    {source_panel}
    <div id="click-info">
      {back_link}
      <p class="placeholder">Click a node to see its full statement / IR
      (useful once the graph is zoomed out and labels get too small to read).
      When the statement is found in the source above, the matching line is
      highlighted too.</p>
    </div>
  </div>
</div>
<script>
const NODE_LABELS = {node_labels_json};
const NODE_LINES = {node_lines_json};
let lastSrcHit = null;

function showInfo(g) {{
  if (dragMoved) {{ dragMoved = false; return; }}
  const titleEl = g.querySelector('title');
  const panel = document.getElementById('click-info');
  if (!titleEl) {{ panel.innerHTML = '<p class="placeholder">(no id found for this node)</p>'; return; }}
  const key = titleEl.textContent;
  const label = NODE_LABELS[key];
  let out = '<h3>Node ' + key.replace(/&/g,'&amp;').replace(/</g,'&lt;') + '</h3>';
  out += label ? '<pre>' + label + '</pre>' : '<p class="placeholder">No label found for this node.</p>';
  panel.innerHTML = out;

  if (lastSrcHit) {{ lastSrcHit.classList.remove('src-hit'); lastSrcHit = null; }}
  const lineNo = NODE_LINES[key];
  if (lineNo) {{
    const lineEl = document.querySelector('.src-line[data-line="' + lineNo + '"]');
    if (lineEl) {{
      lineEl.classList.add('src-hit');
      lastSrcHit = lineEl;
      lineEl.scrollIntoView({{behavior: 'smooth', block: 'center'}});
    }}
  }}
}}

const wrap = document.getElementById('graph-wrap');
const zoomEl = document.getElementById('graph-zoom');
const svgEl = zoomEl.querySelector('svg');
const svgNativeW = svgEl.getBoundingClientRect().width || 1000;
const svgNativeH = svgEl.getBoundingClientRect().height || 1000;

let scale = 1;
function applyZoom() {{ zoomEl.style.transform = 'scale(' + scale + ')'; }}
function setZoom(delta) {{ scale = Math.max(0.05, Math.min(4, scale + delta)); applyZoom(); }}
function fitToScreen() {{
  const availW = wrap.clientWidth - 24, availH = wrap.clientHeight - 24;
  scale = Math.max(0.05, Math.min(availW / svgNativeW, availH / svgNativeH, 1));
  applyZoom();
  wrap.scrollLeft = 0; wrap.scrollTop = 0;
}}
fitToScreen();

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
    ap.add_argument('--svg', default=None)
    ap.add_argument('-o', '--output', default=None)
    ap.add_argument('--back-href', default=None,
                     help='relative link to the corresponding CHC graph index, shown at the '
                          'top of the panel (set by step10_sol_cfg.sh when one exists)')
    ap.add_argument('--sol', default=None,
                     help='original .sol file, shown in a panel next to the graph so the CFG '
                          'is not floating disconnected from the source (slither\'s cfg dot has '
                          'no line/offset info to begin with)')
    args = ap.parse_args()

    dot_path = args.dot_file
    svg_path = args.svg or (dot_path + '.svg')
    ensure_svg(dot_path, svg_path)

    node_labels = load_node_labels(dot_path)

    svg_text = open(svg_path, encoding='utf-8').read()
    svg_text = wire_up_clicks(svg_text)
    svg_text = re.sub(r'^.*?(<svg)', r'\1', svg_text, count=1, flags=re.DOTALL)

    back_link = ''
    if args.back_href:
        back_link = (f'<p><a href="{html.escape(args.back_href)}">&larr; '
                     'back to the CHC graph</a></p>')

    source_panel = ''
    node_lines = {}
    if args.sol and os.path.isfile(args.sol):
        sol_lines = open(args.sol, encoding='utf-8').read().splitlines()
        node_lines = {node_id: find_source_line(label, sol_lines)
                      for node_id, label in node_labels.items()}
        node_lines = {k: v for k, v in node_lines.items() if v}
        src_html = ''.join(
            f'<span class="src-line" data-line="{i}">{html.escape(line) or " "}</span>\n'
            for i, line in enumerate(sol_lines, 1))
        source_panel = (f'<div id="source-panel"><h4>{html.escape(os.path.basename(args.sol))}'
                         f'</h4><pre>{src_html}</pre></div>')

    title = os.path.basename(dot_path)
    page = PAGE_TEMPLATE.format(
        title=html.escape(title),
        svg=svg_text,
        node_labels_json=json.dumps({k: html.escape(v) for k, v in node_labels.items()}),
        node_lines_json=json.dumps(node_lines),
        back_link=back_link,
        source_panel=source_panel,
    )

    out_path = args.output or re.sub(r'\.dot$', '.html', dot_path)
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(page)
    print(f"Interactive HTML written to: {out_path}")


if __name__ == '__main__':
    main()
