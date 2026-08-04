#!/usr/bin/env python3
"""
zmiout2dot_highlight.py
Usage:
  python3 zmiout2dot_highlight.py <graph.dot> <analysis.zmiout> [-o out.dot]
  python3 zmiout2dot_highlight.py <graph.dot> <analysis.zmiout> [zmiout2] [-o out.dot]
      [--test1 N] [--test2 N] [--single]

Highlights, on a chcviz-generated .dot graph, the derivation path(s) actually
walked by one or two tests found in a .zmiout analysis output:

  - one test given (or --single): that test's path is drawn in bold over a
    dimmed graph (red for a violation/"negative" test, green for a
    "testVerimapGood"/"positive" test).
  - two tests given (explicitly via a second zmiout file / --test1 --test2,
    or auto-picked as first negative + first positive test in one zmiout):
    both paths are drawn together — shared trunk in blue, the parts where
    they diverge in red/green, and the branch node(s) where they split
    outlined in orange.

Output: <graph>_highlighted.dot next to the input .dot, unless -o is given.
"""
import re, sys, os, argparse, importlib.util
from collections import Counter


def _load_parse():
    here = os.path.dirname(os.path.abspath(__file__))
    spec = importlib.util.spec_from_file_location('_parse', os.path.join(here, 'zmiout_parse.py'))
    mod  = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

_parse = _load_parse()


# ---- call trace -> dot node ids ----

def extract_call_trace(test_block):
    """Return the CALL TRACE of a test block as an ordered list of 'name/arity' node ids."""
    nodes = []
    in_trace = False
    for line in test_block.split('\n'):
        s = line.strip()
        if 'CALL TRACE' in s:
            in_trace = True
            continue
        if not in_trace:
            continue
        if not s or s.startswith('MODELLO') or s.startswith('model{'):
            break
        m = re.match(r'(\w+)\((.*)\)\s*$', s)
        if not m:
            continue
        name, argstr = m.group(1), m.group(2)
        arity = 0 if argstr.strip() == '' else len(_parse.split_clauses(argstr))
        nodes.append(f"{name}/{arity}")
    return nodes


def classify(test_block):
    return 'positive' if 'testVerimapGood' in test_block else 'negative'


def load_tests(zmiout_path):
    text = open(zmiout_path).read()
    blocks = _parse.split_tests(text)
    if not blocks:
        blocks = [text]
    tests = []
    for b in blocks:
        trace = extract_call_trace(b)
        if trace:
            tests.append({'trace': trace, 'kind': classify(b)})
    return tests


# ---- reconstruct the walked path against the static call graph ----

def reconstruct_path(node_seq, edges):
    """Walk node_seq (a CALL TRACE) as a DFS over the static graph `edges`
    (set of (src,dst) pairs), returning (visited_nodes, edge_counts) where
    edge_counts maps each (src,dst) edge actually used to how many times the
    trace traversed it (>1 means a loop was unrolled through that edge)."""
    if not node_seq:
        return set(), Counter()
    stack = [node_seq[0]]
    visited = {node_seq[0]}
    edge_counts = Counter()
    for nxt in node_seq[1:]:
        idx = None
        for i in range(len(stack) - 1, -1, -1):
            if (stack[i], nxt) in edges:
                idx = i
                break
        if idx is None:
            # no static edge matches (shouldn't normally happen); keep going anyway
            stack.append(nxt)
            visited.add(nxt)
            continue
        edge_counts[(stack[idx], nxt)] += 1
        stack = stack[:idx + 1]
        stack.append(nxt)
        visited.add(nxt)
    return visited, edge_counts


# ---- Prolog clause lookup (for hover tooltips) ----

def split_prolog_clauses(text):
    """Split a .t.pl file into individual clauses/directives (depth-aware,
    splitting only on a top-level '.' followed by whitespace)."""
    clauses, current, depth = [], [], 0
    i, n = 0, len(text)
    while i < n:
        ch = text[i]
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
        current.append(ch)
        if ch == '.' and depth == 0 and (i + 1 == n or text[i + 1] in ' \t\r\n'):
            clause = ''.join(current).strip()
            if clause:
                clauses.append(clause)
            current = []
        i += 1
    tail = ''.join(current).strip()
    if tail:
        clauses.append(tail)
    return clauses


def load_predicate_clauses(tpl_path):
    """Return {predicate_name: [clause_text, ...]} for every predicate defined
    in a .t.pl file (in source order, one entry per clause)."""
    text = open(tpl_path).read()
    by_name = {}
    for clause in split_prolog_clauses(text):
        m = re.match(r'(\w+)\s*\(', clause)
        if not m:
            continue
        by_name.setdefault(m.group(1), []).append(clause)
    return by_name


def tpl_path_for_dot(dot_path):
    """chcviz names the graph <Base>_clean_object_xref_diagram.dot inside
    dot_dias/, next to the original <Base>.pl it was generated from."""
    base = re.sub(r'_clean_object_xref_diagram\.dot$', '', os.path.basename(dot_path))
    return os.path.join(os.path.dirname(os.path.dirname(dot_path)), base + '.pl')


TOOLTIP_RE = re.compile(r'tooltip="(?:[^"\\]|\\.)*"')
MAX_TOOLTIP_CHARS = 4000


def escape_tooltip(text):
    text = text.replace('\\', '\\\\').replace('"', '\\"')
    return text.replace('\n', '\\l') + '\\l'


def add_clause_tooltips(lines, clauses_by_name):
    out = []
    for line in lines:
        m = NODE_RE.match(line.strip())
        if not m:
            out.append(line)
            continue
        node_id = m.group(1)[1:-1]
        name = node_id.split('/', 1)[0]
        clauses = clauses_by_name.get(name)
        if not clauses:
            out.append(line)
            continue
        body = '\n\n'.join(clauses)
        if len(body) > MAX_TOOLTIP_CHARS:
            body = body[:MAX_TOOLTIP_CHARS] + '\n... (truncated)'
        new_tooltip = f'tooltip="{escape_tooltip(body)}"'
        if TOOLTIP_RE.search(line):
            out.append(TOOLTIP_RE.sub(lambda _m: new_tooltip, line, count=1))
        else:
            out.append(line.rstrip('\n').rstrip()[:-1] + ',' + new_tooltip + ']\n')
    return out


# ---- .dot parsing/rewriting ----

NODE_RE = re.compile(r'^("(?:[^"\\]|\\.)+")\s*\[(.*)\]\s*$')
EDGE_RE = re.compile(r'^("(?:[^"\\]|\\.)+")\s*->\s*("(?:[^"\\]|\\.)+")\s*\[(.*)\]\s*$')


def parse_dot(lines):
    """Return (node_ids, edges) found in a chcviz .dot file's lines."""
    node_ids = set()
    edges = set()
    for line in lines:
        m = EDGE_RE.match(line.strip())
        if m:
            edges.add((m.group(1)[1:-1], m.group(2)[1:-1]))
            continue
        m = NODE_RE.match(line.strip())
        if m:
            node_ids.add(m.group(1)[1:-1])
    return node_ids, edges


# graphviz emits a node's `tooltip=` attribute as xlink:title on the <a>
# wrapper, which browsers only reliably show as a hover tooltip when the <a>
# also has a real href. Since these nodes aren't links, we post-process the
# rendered .svg to also add a <title> child (the one tooltip mechanism SVG
# viewers support unconditionally, link or not).
A_XLINK_TITLE_RE = re.compile(r'(<a [^>]*\bxlink:title="([^"]*)"[^>]*>)')


def promote_tooltips_to_title_elements(svg_text):
    return A_XLINK_TITLE_RE.sub(lambda m: f'{m.group(1)}<title>{m.group(2)}</title>', svg_text)


DIM_NODE = 'fillcolor="gainsboro",color="gray75",fontcolor="gray55"'
DIM_EDGE = 'color="gray85",fontcolor="gray75"'

NEG_NODE = 'fillcolor="lightpink",color="crimson",penwidth="3"'
NEG_EDGE = 'color="crimson",penwidth="3"'

POS_NODE = 'fillcolor="palegreen",color="forestgreen",penwidth="3"'
POS_EDGE = 'color="forestgreen",penwidth="3"'

# node/edge used by BOTH paths: half red, half green (Graphviz "striped" fill
# for nodes, parallel-colored strokes for edges) instead of picking a winner
BOTH_NODE = 'style="filled,striped",fillcolor="lightpink:palegreen",color="black",penwidth="2.5"'
BOTH_EDGE = 'color="crimson:forestgreen",penwidth="3"'

DIVERGE_NODE = 'fillcolor="gold",color="darkorange",penwidth="5"'


LABEL_RE = re.compile(r'label=<([^>]*)>')


def style_line(line, node_style_of, edge_style_of, edge_label_of=None):
    stripped = line.strip()
    m = EDGE_RE.match(stripped)
    if m:
        key = (m.group(1)[1:-1], m.group(2)[1:-1])
        out = line
        if edge_label_of is not None:
            suffix = edge_label_of(key)
            if suffix:
                out = LABEL_RE.sub(lambda lm: f'label=<{lm.group(1)}{suffix}>', out, count=1)
        style = edge_style_of(key)
        if style:
            out = out.rstrip('\n').rstrip()[:-1] + ',' + style + ']\n'
        return out
    m = NODE_RE.match(stripped)
    if m:
        key = m.group(1)[1:-1]
        style = node_style_of(key)
        if style:
            return line.rstrip('\n').rstrip()[:-1] + ',' + style + ']\n'
        return line
    return line


def highlight_single(lines, nodes_used, edge_counts, kind):
    node_style = NEG_NODE if kind == 'negative' else POS_NODE
    edge_style = NEG_EDGE if kind == 'negative' else POS_EDGE

    def node_style_of(n):
        return node_style if n in nodes_used else DIM_NODE

    def edge_style_of(e):
        return edge_style if e in edge_counts else DIM_EDGE

    def edge_label_of(e):
        n = edge_counts.get(e, 0)
        return f' &#215;{n}' if n > 1 else None

    return [style_line(l, node_style_of, edge_style_of, edge_label_of) for l in lines]


def highlight_dual(lines, nodesA, edge_countsA, nodesB, edge_countsB):
    """A (negative) and B (positive) both stay visible end-to-end: anything
    only A does is solid red, anything only B does is solid green, and
    anything BOTH do is striped red+green (rather than picking one color and
    hiding the other). Orange marks the exact node where their next hop
    actually differs."""
    edgesA, edgesB = set(edge_countsA), set(edge_countsB)
    common_nodes = nodesA & nodesB
    common_edges = edgesA & edgesB
    onlyA_nodes = nodesA - nodesB
    onlyA_edges = edgesA - edgesB
    onlyB_nodes = nodesB - nodesA
    onlyB_edges = edgesB - edgesA

    # divergence points: a node common to both paths whose next hop differs
    diverge_nodes = set()
    for (src, dst) in onlyA_edges:
        if src in common_nodes:
            diverge_nodes.add(src)
    for (src, dst) in onlyB_edges:
        if src in common_nodes:
            diverge_nodes.add(src)

    def node_style_of(n):
        if n in diverge_nodes:
            return DIVERGE_NODE
        if n in common_nodes:
            return BOTH_NODE
        if n in onlyA_nodes:
            return NEG_NODE
        if n in onlyB_nodes:
            return POS_NODE
        return DIM_NODE

    def edge_style_of(e):
        if e in common_edges:
            return BOTH_EDGE
        if e in onlyA_edges:
            return NEG_EDGE
        if e in onlyB_edges:
            return POS_EDGE
        return DIM_EDGE

    def edge_label_of(e):
        a, b = edge_countsA.get(e, 0), edge_countsB.get(e, 0)
        if e in common_edges:
            return f' A&#215;{a} B&#215;{b}' if (a > 1 or b > 1) else None
        if e in onlyA_edges:
            return f' &#215;{a}' if a > 1 else None
        if e in onlyB_edges:
            return f' &#215;{b}' if b > 1 else None
        return None

    return [style_line(l, node_style_of, edge_style_of, edge_label_of) for l in lines], diverge_nodes


def add_legend(lines, legend_lines):
    out = []
    for line in lines:
        m = re.match(r'^(label=")(.*)(\\l"\s*)$', line.strip())
        if m:
            extra = ''.join(f'{t}\\l' for t in legend_lines)
            out.append(f'{m.group(1)}{m.group(2)}\\l{extra}"\n')
            continue
        out.append(line)
    return out


def main():
    if len(sys.argv) >= 3 and sys.argv[1] == '--fix-svg-tooltips':
        svg_path = sys.argv[2]
        text = open(svg_path, encoding='utf-8').read()
        text = promote_tooltips_to_title_elements(text)
        open(svg_path, 'w', encoding='utf-8').write(text)
        print(f"Promoted hover tooltips to <title> elements in {svg_path}")
        return

    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('dot_file')
    ap.add_argument('zmiout1')
    ap.add_argument('zmiout2', nargs='?')
    ap.add_argument('--test1', type=int, default=None, help='1-based index of the test to use in zmiout1')
    ap.add_argument('--test2', type=int, default=None, help='1-based index of the test to use (zmiout2, or zmiout1 if no zmiout2)')
    ap.add_argument('--single', action='store_true', help='force single-path mode even if a positive/negative pair is found')
    ap.add_argument('--all', action='store_true', help='ignore dual-pick logic; write one highlighted .dot per test found in zmiout1, plus a manifest')
    ap.add_argument('-o', '--output', default=None)
    ap.add_argument('--tpl', default=None, help='.t.pl file to pull full clause text from for hover tooltips (auto-detected by default)')
    ap.add_argument('--no-tooltips', action='store_true', help="don't inject full clause text into node tooltips")
    args = ap.parse_args()

    lines = open(args.dot_file).readlines()
    node_ids, edges = parse_dot(lines)

    tests1 = load_tests(args.zmiout1)
    if not tests1:
        print(f"ERROR: no CALL TRACE found in {args.zmiout1}")
        sys.exit(1)

    if args.all:
        tpl_path = args.tpl or tpl_path_for_dot(args.dot_file)
        clauses_by_name = load_predicate_clauses(tpl_path) if os.path.isfile(tpl_path) else {}
        manifest_path = re.sub(r'\.dot$', '_alltests_manifest.txt', args.dot_file)
        manifest = []
        for idx, test in enumerate(tests1, 1):
            nodes, edge_counts = reconstruct_path(test['trace'], edges)
            out_lines = highlight_single(lines, nodes, edge_counts, test['kind'])
            color = 'red' if test['kind'] == 'negative' else 'green'
            out_lines = add_legend(out_lines, [
                f"Test #{idx}: {test['kind']} test ({color})",
                "x N on an edge = that edge was looped N times in the trace",
            ])
            if not args.no_tooltips and clauses_by_name:
                out_lines = add_clause_tooltips(out_lines, clauses_by_name)
            out_path = re.sub(r'\.dot$', f'_test{idx}_{test["kind"]}_highlighted.dot', args.dot_file)
            with open(out_path, 'w') as f:
                f.writelines(out_lines)
            manifest.append(f"{idx}\t{test['kind']}\t{len(test['trace'])}\t{out_path}")
            print(f"Test #{idx} ({test['kind']}, {len(test['trace'])} calls): {out_path}")
        with open(manifest_path, 'w') as f:
            f.write('\n'.join(manifest) + '\n')
        print(f"Manifest written to: {manifest_path}")
        return

    def pick(tests, idx):
        if idx is None:
            return tests[0]
        if not (1 <= idx <= len(tests)):
            print(f"ERROR: test index {idx} out of range (1..{len(tests)})")
            sys.exit(1)
        return tests[idx - 1]

    dual = False
    if args.zmiout2:
        testA = pick(tests1, args.test1)
        tests2 = load_tests(args.zmiout2)
        if not tests2:
            print(f"ERROR: no CALL TRACE found in {args.zmiout2}")
            sys.exit(1)
        testB = pick(tests2, args.test2)
        dual = True
    elif not args.single and (args.test1 is not None or args.test2 is not None):
        testA = pick(tests1, args.test1)
        testB = pick(tests1, args.test2)
        dual = True
    elif not args.single and len(tests1) >= 2:
        negs = [t for t in tests1 if t['kind'] == 'negative']
        poss = [t for t in tests1 if t['kind'] == 'positive']
        if negs and poss:
            testA, testB = negs[0], poss[0]
            dual = True
        else:
            testA = pick(tests1, args.test1)
    else:
        testA = pick(tests1, args.test1)

    if dual:
        nodesA, edgesA = reconstruct_path(testA['trace'], edges)
        nodesB, edgesB = reconstruct_path(testB['trace'], edges)
        out_lines, diverge_nodes = highlight_dual(lines, nodesA, edgesA, nodesB, edgesB)
        legend = [
            f"Path A ({testA['kind']}, red) vs Path B ({testB['kind']}, green)",
            "solid red = only A, solid green = only B, striped red/green = both, orange = where they diverge",
            "×N on an edge = that edge was looped N times in the trace",
        ]
        onlyA_nodes, onlyB_nodes = nodesA - nodesB, nodesB - nodesA
        if not onlyA_nodes and onlyB_nodes:
            legend.append(f"NOTE: every node A visits, B visits too (striped) — B just does "
                           f"{len(onlyB_nodes)} extra call(s) (solid green) that A skips entirely")
        elif not onlyB_nodes and onlyA_nodes:
            legend.append(f"NOTE: B never leaves A's path — A does {len(onlyA_nodes)} "
                           f"extra call(s) (solid red) beyond anything B does")
        out_lines = add_legend(out_lines, legend)
        loopsA = {e: n for e, n in edgesA.items() if n > 1}
        loopsB = {e: n for e, n in edgesB.items() if n > 1}
        print(f"Dual-path mode: A={testA['kind']} ({len(testA['trace'])} calls), "
              f"B={testB['kind']} ({len(testB['trace'])} calls), "
              f"{len(diverge_nodes)} divergence point(s): {sorted(diverge_nodes)}")
        if loopsA:
            print(f"  loop edges in A: {loopsA}")
        if loopsB:
            print(f"  loop edges in B: {loopsB}")
    else:
        nodesA, edgesA = reconstruct_path(testA['trace'], edges)
        out_lines = highlight_single(lines, nodesA, edgesA, testA['kind'])
        color = 'red' if testA['kind'] == 'negative' else 'green'
        out_lines = add_legend(out_lines, [
            f"Highlighted path: {testA['kind']} test ({color})",
            "×N on an edge = that edge was looped N times in the trace",
        ])
        loops = {e: n for e, n in edgesA.items() if n > 1}
        print(f"Single-path mode: {testA['kind']} test, {len(testA['trace'])} calls, "
              f"{len(nodesA)} nodes / {len(edgesA)} edges on the graph")
        if loops:
            print(f"  loop edges: {loops}")

    if not args.no_tooltips:
        tpl_path = args.tpl or tpl_path_for_dot(args.dot_file)
        if os.path.isfile(tpl_path):
            clauses_by_name = load_predicate_clauses(tpl_path)
            out_lines = add_clause_tooltips(out_lines, clauses_by_name)
            print(f"Hover tooltips: full clause(s) from {tpl_path} (open the .svg in a browser to see them)")
        else:
            print(f"(no .t.pl found at {tpl_path}, skipping hover tooltips — pass --tpl to set it explicitly)")

    out_path = args.output or re.sub(r'\.dot$', '_highlighted.dot', args.dot_file)
    with open(out_path, 'w') as f:
        f.writelines(out_lines)
    print(f"Highlighted dot written to: {out_path}")


if __name__ == '__main__':
    main()
