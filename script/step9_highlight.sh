#!/bin/bash
# step9_highlight.sh [--svg-only|--all-tests] <contract.t.pl> [zmiout] [zmiout2]
# Evidenzia sul grafo CHC (prodotto da step7_graph.sh) il/i percorso/i di
# derivazione trovati nel .zmiout. Con un solo zmiout, se contiene sia un
# test "negative" (violazione) che uno "positive" (testVerimapGood) li
# mostra entrambi, evidenziando dove divergono.
#
# By default produces BOTH the highlighted .svg (suffisso _highlighted) AND
# the interactive .html (grafo + pannello laterale cliccabile, via
# dot2html.py), for one auto-picked test (or pair). Pass --svg-only to stop
# at the .svg, as before. Pass --all-tests to instead generate one .html per
# test found in the .zmiout, plus an index.html listing them all.
#
# Esempio:
#   bash script/step9_highlight.sh test/MyContract/MyContract.t.pl
#   bash script/step9_highlight.sh test/MyContract/MyContract.t.pl path/to/other.zmiout
#   bash script/step9_highlight.sh --svg-only test/MyContract/MyContract.t.pl
#   bash script/step9_highlight.sh --all-tests test/MyContract/MyContract.t.pl

set -euo pipefail

SVG_ONLY=0
ALL_TESTS=0
case "${1:-}" in
    --svg-only) SVG_ONLY=1; shift ;;
    --all-tests) ALL_TESTS=1; shift ;;
esac

[ $# -lt 1 ] && { echo "Usage: $0 [--svg-only|--all-tests] <contract.t.pl> [zmiout] [zmiout2]"; exit 1; }

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
HIGHLIGHT_PY="$SCRIPT_DIR/zmiout2dot_highlight.py"
DOT2HTML_PY="$SCRIPT_DIR/dot2html.py"

TPL="$(readlink -f "$1")"
BASE="$(basename "$TPL" .t.pl)"
DIR="$(dirname "$TPL")"

DOT="$DIR/dot_dias/${BASE}.t_clean_object_xref_diagram.dot"

# CHCViz's own venv, used as a fallback when the `chcviz` command isn't on PATH
CHCVIZ_FALLBACK_PY="/home/marco/remote_verimap/CHCViz/myenv/bin/python3"
CHCVIZ_FALLBACK_SCRIPT="/home/marco/remote_verimap/CHCViz/chcviz.py"

if [ ! -f "$DOT" ]; then
    echo "=== dot file not found, generating it with chcviz first ==="
    if command -v chcviz >/dev/null 2>&1; then
        ( cd "$DIR" && chcviz "$BASE.t.pl" )
    elif [ -x "$CHCVIZ_FALLBACK_PY" ] && [ -f "$CHCVIZ_FALLBACK_SCRIPT" ]; then
        ( cd "$DIR" && "$CHCVIZ_FALLBACK_PY" "$CHCVIZ_FALLBACK_SCRIPT" "$BASE.t.pl" )
    else
        echo "ERROR: chcviz not found (neither on PATH nor at $CHCVIZ_FALLBACK_PY)"; exit 1
    fi
    [ -f "$DOT" ] || { echo "ERROR: chcviz ran but $DOT still not found"; exit 1; }
fi

if [ $# -ge 2 ]; then
    ZMIOUT1="$(readlink -f "$2")"
else
    ZMIOUT1="$(ls "$DIR/${BASE}.t_constr.pl."*.zmiout 2>/dev/null | head -1 || true)"
    [ -n "$ZMIOUT1" ] || { echo "ERROR: no .zmiout found next to $TPL"; exit 1; }
fi

echo "=== STEP 9: highlight derivation path(s) on CHC graph ==="
echo "dot:    $DOT"
echo "zmiout: $ZMIOUT1"

if [ "$ALL_TESTS" -eq 1 ]; then
    python3 "$HIGHLIGHT_PY" --all "$DOT" "$ZMIOUT1"
    MANIFEST="${DOT%.dot}_alltests_manifest.txt"
    INDEX="$(dirname "$DOT")/${BASE}_alltests_index.html"
    {
        echo "<!doctype html><meta charset='utf-8'><title>${BASE} — all tests</title>"
        echo "<body style='font-family:sans-serif;max-width:640px;margin:40px auto'>"
        echo "<h2>${BASE} — all tests found</h2><ul>"
    } > "$INDEX"
    while IFS=$'\t' read -r idx kind ncalls dotpath; do
        svgpath="${dotpath}.svg"
        htmlpath="${dotpath%.dot}.html"
        dot -Tsvg "$dotpath" -o "$svgpath"
        python3 "$HIGHLIGHT_PY" --fix-svg-tooltips "$svgpath"
        python3 "$DOT2HTML_PY" "$dotpath" --svg "$svgpath" -o "$htmlpath"
        echo "<li><a href=\"$(basename "$htmlpath")\">Test #$idx — $kind ($ncalls calls)</a></li>" >> "$INDEX"
    done < "$MANIFEST"
    echo "</ul></body>" >> "$INDEX"
    echo "[OK] Index → $INDEX"
    exit 0
fi

if [ $# -ge 3 ]; then
    ZMIOUT2="$(readlink -f "$3")"
    echo "zmiout2: $ZMIOUT2"
    python3 "$HIGHLIGHT_PY" "$DOT" "$ZMIOUT1" "$ZMIOUT2"
else
    python3 "$HIGHLIGHT_PY" "$DOT" "$ZMIOUT1"
fi

OUT_DOT="${DOT%.dot}_highlighted.dot"
OUT_SVG="${OUT_DOT}.svg"
dot -Tsvg "$OUT_DOT" -o "$OUT_SVG"
python3 "$HIGHLIGHT_PY" --fix-svg-tooltips "$OUT_SVG"
echo "[OK] SVG → $OUT_SVG"

if [ "$SVG_ONLY" -eq 1 ]; then
    exit 0
fi

OUT_HTML="${OUT_DOT%.dot}.html"
python3 "$DOT2HTML_PY" "$OUT_DOT" --svg "$OUT_SVG" -o "$OUT_HTML"
echo "[OK] Interactive HTML → $OUT_HTML"
