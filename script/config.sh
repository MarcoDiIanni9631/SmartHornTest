#!/bin/bash
# config.sh — machine-specific paths for the SmartHornTest pipeline.
#
# Sourced by step1_grey.sh, step2_yul2chc.sh, step3_transform.sh and
# InterpreterAnalysis5.2.sh. Not meant to be run directly.
#
# Default layout assumes grey/, yul-chc/, swi-prolog-z3/ and slither/ are
# cloned as sibling folders of this repo:
#
#   <parent>/
#     smarthorntest/               <- this repo (SCRIPT_DIR is its script/ dir)
#     grey/
#     yul-chc/
#     swi-prolog-z3/
#     slither/                     <- cloned from github.com/crytic/slither,
#                                     installed into its own myenv/ (needs
#                                     Python >= 3.10)
#
# Every path below can be overridden with an environment variable of the
# same name, e.g.:
#   export GREY_DIR=/opt/grey
#   export SWIPL_BIN=/home/user/local/swipl-9.3.31/bin/swipl
#   export Z3_LIB_DIR=/home/user/local/z3-4.15.3/lib
# before calling any pipeline script.

[ -n "${SCRIPT_DIR:-}" ] || { echo "config.sh: SCRIPT_DIR is not set (do not call this file directly)"; exit 1; }

_PROJECTS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

: "${GREY_DIR:=$_PROJECTS_ROOT/grey}"
: "${YULCHC_DIR:=$_PROJECTS_ROOT/yul-chc}"
: "${SWIZ3_TURIBE_PATH:=$_PROJECTS_ROOT/swi-prolog-z3}"
: "${SWIPL_BIN:=$(command -v swipl || true)}"
: "${Z3_LIB_DIR:=$([ -d "$_PROJECTS_ROOT/z3/bin" ] && echo "$_PROJECTS_ROOT/z3/bin" \
    || ([ -f "$HOME/local/z3-4.15.3/lib/libz3.so" ] && echo "$HOME/local/z3-4.15.3/lib") \
    || true)}"
# compute-clai note (2026-09-02): the z3-4.15.3-x64-glibc-2.39 tarball's
# libz3.so needs GLIBC_2.38+, but this machine only has GLIBC 2.34 — it
# fails to load with "cannot open shared object file" (misleading: the file
# exists, it just can't be linked). $HOME/local/z3-4.15.3/lib is a
# from-source build that resolves cleanly against the system libc; the
# fallback above picks it automatically when the usual z3/bin sibling
# folder isn't present.
: "${SLITHER_DIR:=$_PROJECTS_ROOT/slither}"
# Invoked as "$SLITHER_PY -m slither" rather than via the myenv/bin/slither
# launcher script: that script's shebang bakes in the absolute path slither
# was installed from (e.g. compute-clai's own path), which breaks when this
# repo is accessed through a different mount/alias of the same filesystem
# (e.g. sshfs). The venv's python binary itself is a plain symlink to the
# system interpreter, so invoking it by path works from any alias.
: "${SLITHER_PY:=$([ -x "$SLITHER_DIR/myenv/bin/python3" ] && echo "$SLITHER_DIR/myenv/bin/python3" || true)}"
: "${SLITHER_BIN:=$([ -n "$SLITHER_PY" ] && echo "$SLITHER_PY -m slither" || command -v slither || true)}"

export GREY_DIR YULCHC_DIR SWIZ3_TURIBE_PATH SWIPL_BIN Z3_LIB_DIR SLITHER_DIR SLITHER_PY SLITHER_BIN
