#!/bin/bash
# Runs the evaluation again on the contracts of experiments/: the two routes on
# every <name>_vgood.sol (depth bound 100, timeout 600 s, four contracts in
# parallel for each route), then the Foundry tests and the coverage.
# Usage (from the repo root): bash experiments/run_all.sh [OUT_DIR] [FILTER]
#   OUT_DIR  where the results go (default experiments/rerun)
#   FILTER   only the contracts whose benchmark/category/name contains it,
#            e.g. soltg/sanity
# Results: OUT_DIR/yul/<benchmark>/<category>/<name>/,
#          OUT_DIR/solcmc/<benchmark>/<category>/solcmc/<name>/,
#          OUT_DIR/foundry/ (forge test and forge coverage output),
#          OUT_DIR/report.csv with one row per contract and route.
set -u
R=$(cd "$(dirname "$0")/.." && pwd); E=$R/experiments
OUT=${1:-$E/rerun}; mkdir -p "$OUT"; OUT=$(readlink -f "$OUT")
J=4
export R E OUT PATH=$HOME/bin:$HOME/.foundry/bin:$PATH

# benchmark category contract function
tail -n +2 "$E/summary.csv" | cut -d, -f1-4 | tr , ' ' | awk -v p="${2:-}" 'index($1 "/" $2 "/" $3, p)' > "$OUT/list.txt"
echo "$(wc -l < "$OUT/list.txt") contracts, results in $OUT"
[ -s "$OUT/list.txt" ] || exit 1

run_solcmc() {
  local d=$OUT/solcmc/$1/$2 a=$(date +%s)
  mkdir -p "$d"; cp "$E/$1/$2/$3/$3_vgood.sol" "$d/$3.sol"
  timeout 700 bash "$R/script/solcmc_route.sh" "$d/$3.sol" --maxdepth 100 --timeout 600 > "$d/$3.log" 2>&1
  local z=$(ls "$d/solcmc/$3/"*.zmiout 2>/dev/null | head -1)
  local t=no; [ -n "$z" ] && t=$(grep -c 'TEST #' "$z")
  echo "$1/$2/$3: $t tests ($(( $(date +%s)-a )) s)" >> "$OUT/solcmc/status.txt"
}

convert_yul() {
  local d=$OUT/yul/$1/$2/$3
  mkdir -p "$d"; cp "$E/$1/$2/$3/$3_vgood.sol" "$d/$3.sol"
  (cd "$R" && flock "$R/.yul.lock" timeout 600 bash script/sol2analysis.sh --until-tpl --gen-aux --aux-hint "_$4_" "$d/$3.sol" < /dev/null 2>&1 | head -c 50000000 > "$d/convert.log")
  ls "$d"/*.t_constr.pl > /dev/null 2>&1 || echo "$1/$2/$3: conversion failed" >> "$OUT/yul/status.txt"
}

run_yul() {
  local d=$OUT/yul/$1/$2/$3 a=$(date +%s)
  ls "$d"/*.t_constr.pl > /dev/null 2>&1 || return 0
  (cd "$R" && timeout 700 bash script/sol2analysis.sh --skip-convert --maxdepth 100 --varz3 --varclpq --timeout 600 "$d/$3.sol" incorrect > "$d/analysis.log" 2>&1)
  local z=$(ls "$d"/*.zmiout 2>/dev/null | head -1)
  local t=no; [ -n "$z" ] && t=$(grep -c 'TEST #' "$z")
  echo "$1/$2/$3: $t tests ($(( $(date +%s)-a )) s)" >> "$OUT/yul/status.txt"
}
export -f run_solcmc convert_yul run_yul

rm -rf "$OUT/solcmc" "$OUT/yul" "$OUT/foundry"; mkdir -p "$OUT/solcmc" "$OUT/yul"
xargs -r -P $J -L 1 bash -c 'run_solcmc "$@"' _ < "$OUT/list.txt" &
# the yul2chc conversion runs one contract at a time (shared grey/ folder)
while read b c n f; do convert_yul $b $c $n $f; done < "$OUT/list.txt"
xargs -r -P $J -L 1 bash -c 'run_yul "$@"' _ < "$OUT/list.txt"
wait
echo "analysis done"

# the tests are written from the vgood runs, but src/ gets the original contracts:
# a negative test is confirmed if it fails with panic 0x01, a positive one if it passes
originals() {  # $1 forge project, $2 route
  find "$OUT/$2" -name '*.test_cases.json' | while read j; do
    local f=$(dirname "$j"); local n=$(basename "$f"); local g=$(dirname "${f#$OUT/}")
    local b=$(echo "$g" | sed 's/\W/_/g')__$(echo "$n" | sed 's/\W/_/g')
    local rel=${f#$OUT/$2/}
    case $2 in solcmc) rel=${rel%/solcmc/$n} ;; *) rel=${rel%/$n} ;; esac
    [ -f "$1/src/$b.sol" ] && cp "$E/$rel/$n/$n.sol" "$1/src/$b.sol"
  done
}

drop_not_compiling() {  # $1 forge project: forge builds all or nothing
  mkdir -p "$1/not_compiling"
  for i in $(seq 1 20); do
    local out
    out=$(cd "$1" && forge build --offline 2>&1) && return
    local t=$(echo "$out" | grep -o "test/[A-Za-z0-9_]*\.t\.sol" | head -1)
    local s=$(echo "$out" | grep -o "src/[A-Za-z0-9_]*\.sol" | head -1)
    [ -z "$t" ] && [ -n "$s" ] && t=test/$(basename "$s" .sol).t.sol
    [ -z "$t" ] && { echo "$out" | tail -20; return; }
    echo "not compiling: $t"; mv "$1/$t" "$1/not_compiling/"
  done
}

F=$OUT/foundry; mkdir -p "$F"
for k in yul solcmc; do
  python3 "$R/script/witnesses2foundry.py" --forge-std "$F/$k" "$OUT/$k" | head -1
  originals "$F/$k" $k
  drop_not_compiling "$F/$k"
  (cd "$F/$k" && forge test --offline --match-path "test/*" > "$F/forge_test_$k.txt" 2>&1)
  python3 "$R/script/witnesses2foundry.py" --coverage "$F/cov_$k" "$OUT/$k" | head -1
  originals "$F/cov_$k" $k
  for t in "$F/$k"/not_compiling/*.t.sol; do [ -f "$t" ] && rm -f "$F/cov_$k/test/$(basename "$t")"; done
  (cd "$F/cov_$k" && forge coverage --offline --match-path "test/*" --no-match-coverage "test/" --report summary > "$F/coverage_$k.txt" 2>&1)
  echo "$k: $(grep -o '[0-9]* tests passed.*' "$F/forge_test_$k.txt" | tail -1)"
done
python3 "$R/script/report.py" "$OUT" > /dev/null && echo "report in $OUT/report.csv"
echo "done"
