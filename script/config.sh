#!/bin/bash
# config.sh — machine-specific paths for the SmartHornTest pipeline.
#
# Sourced by step1_grey.sh, step2_yul2chc.sh, step3_transform.sh and
# InterpreterAnalysis5.2.sh. Not meant to be run directly.
#
# Default layout assumes grey/, yul-chc/ and swi-prolog-z3/ are cloned as
# sibling folders of this repo:
#
#   <parent>/
#     swipl_z3_clpq_interpreter/   <- this repo (SCRIPT_DIR is its script/ dir)
#     grey/
#     yul-chc/
#     swi-prolog-z3/
#
# Every path below can be overridden with an environment variable of the
# same name, e.g.:
#   export GREY_DIR=/opt/grey
#   export SWIPL_BIN=/home/user/local/swipl-9.3.31/bin/swipl
#   export Z3_LIB_DIR=/home/user/local/z3-4.15.3/lib
# before calling any pipeline script.

[ -n "${SCRIPT_DIR:-}" ] || { echo "❌ config.sh: SCRIPT_DIR non impostata (non chiamarlo direttamente)"; exit 1; }

_PROJECTS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

: "${GREY_DIR:=$_PROJECTS_ROOT/grey}"
: "${YULCHC_DIR:=$_PROJECTS_ROOT/yul-chc}"
: "${SWIZ3_TURIBE_PATH:=$_PROJECTS_ROOT/swi-prolog-z3}"
: "${SWIPL_BIN:=$(command -v swipl || true)}"
: "${Z3_LIB_DIR:=$([ -d "$_PROJECTS_ROOT/z3/bin" ] && echo "$_PROJECTS_ROOT/z3/bin" || true)}"

export GREY_DIR YULCHC_DIR SWIZ3_TURIBE_PATH SWIPL_BIN Z3_LIB_DIR
