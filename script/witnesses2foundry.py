#!/usr/bin/env python3
"""
witnesses2foundry.py — turns every concrete test found by the analysis into a
Foundry test, so anyone can check with `forge test` whether the inputs we found
really break the assert.

For every contract folder under the given roots that has a "derivable"
.zmiout, a .test_cases.json and a .aux.pl, it writes:
  <project>/src/<group>__<contract>.sol      a copy of the contract
  <project>/test/<group>__<contract>.t.sol   one test function per witness

Each test function:
  1. deploys a fresh copy of the contract (constructor arguments all zero);
  2. pretends to be a caller different from the deployer (vm.prank);
  3. says it expects the next call to fail with Panic(0x01) = assert failed;
  4. calls the analysed function with the values our tool found
     (parameters missing from the witness are unconstrained: 0 / false).

Reading `forge test`:
  [PASS]  the call really fails with Panic(0x01): the witness is real
  [FAIL: next call did not revert as expected]
          the call does not fail: the assert holds, the witness is false
  [FAIL: ...Error != expected error...]
          the call fails, but not on an assert (require, overflow, ...)
  [FAIL: valore fuori dominio ...]
          a value is impossible for its type (e.g. -200 for a uint), so the
          call cannot even be written

No internet needed: it uses the solc in PATH and Foundry's cheatcodes through
a tiny Vm interface (no forge-std).

Usage:
    python3 script/witnesses2foundry.py [--forge-std] <project_dir> <root> [<root> ...]
    cd <project_dir> && forge test

--forge-std writes the tests with the standard forge-std library (Test,
vm.prank, ...) and without expectRevert. Each test file has one Target
contract, deployed again before every test in setUp(), and one test function
per witness, named after its kind and number (test_negative_1, ...).
Reading `forge test`:
  [FAIL: panic: assertion failed (0x01)]  the assert is really violated
  [PASS]                                  the witness does not break the assert
  [FAIL: other reason]                    the call reverts for another reason
forge-std is taken from $FORGE_STD, or from a copy already on disk.

--coverage writes the same tests (implies --forge-std) for `forge coverage`:
each call is wrapped in try/catch, so the expected assert failure does not
stop the coverage run, and the lines run by the call are still counted.
Run it with: forge coverage --match-path "test/*" --no-match-coverage "test/"
"""
import glob
import json
import os
import re
import subprocess
import sys

SKIP_DIRS = ("_rimossi_dal_report", "_duplicati", "_timeout60",
             "_vecchio_su_f", "_11set_incompleto", "_riprova_bmv5", "_esclusi")

FOUNDRY_TOML = """[profile.default]
src = "src"
test = "test"
out = "out"
libs = []
solc = "{solc}"
offline = true
"""

VM_INTERFACE = """interface Vm {
    function prank(address) external;
    function expectRevert(bytes calldata) external;
    function warp(uint256) external;
    function roll(uint256) external;
}
"""


def strip_comments(src):
    src = src.split("// ====")[0]
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    return re.sub(r"//.*", "", src)


def params_of(src, signature_regex):
    m = re.search(signature_regex, strip_comments(src))
    if not m:
        return None
    out = []
    for p in [x.strip() for x in m.group(1).split(",") if x.strip()]:
        toks = [t for t in p.split() if t not in ("memory", "calldata", "storage", "payable")]
        typ = {"uint": "uint256", "int": "int256"}.get(toks[0], toks[0])
        out.append((typ, toks[1] if len(toks) > 1 else ""))
    return out


def literal(typ, value):
    """Solidity literal for `value` of type `typ`, or (None, reason)."""
    v = "0" if value is None else str(value).strip()
    if typ == "bool":
        if v in ("true", "1"):
            return "true", None
        if v in ("false", "0"):
            return "false", None
        return None, f"{v} non e' un bool"
    try:
        n = int(v)
    except ValueError:
        return None, f"valore non numerico {v}"
    if typ.startswith("uint"):
        bits = int(typ[4:] or 256)
        if not 0 <= n < 2 ** bits:
            return None, f"{n} fuori dal range di {typ}"
        return (f"{typ}({n})" if bits < 256 else str(n)), None
    if typ.startswith("int"):
        bits = int(typ[3:] or 256)
        if not -(2 ** (bits - 1)) <= n < 2 ** (bits - 1):
            return None, f"{n} fuori dal range di {typ}"
        return f"{typ}({n})", None
    if typ == "address":
        if not 0 <= n < 2 ** 160:
            return None, f"{n} fuori dal range di address"
        return f"address(uint160({n}))", None
    return None, f"tipo {typ} non gestito"


def zero_literal(typ):
    if typ == "bool":
        return "false"
    if typ == "address":
        return "address(0)"
    if typ.startswith(("uint", "int")):
        return f"{typ}(0)"
    return None


def ident(s):
    return re.sub(r"\W", "_", s)


def make_test(folder, group, project):
    name = os.path.basename(folder)
    sol = os.path.join(folder, name + ".sol")
    if not os.path.exists(sol):
        # folder named differently from the contract (e.g. 26Jun_TPLP_X/X.sol)
        sols = glob.glob(os.path.join(folder, "*.sol"))
        if len(sols) != 1:
            return None, None
        sol = sols[0]
        name = os.path.basename(sol)[:-4]
    tcj = os.path.join(folder, name + ".test_cases.json")
    aux = os.path.join(folder, name + ".aux.pl")
    zs = [z for z in glob.glob(os.path.join(folder, "*.zmiout")) if ".derivable." in os.path.basename(z)]
    if not (os.path.exists(sol) and os.path.exists(tcj) and zs):
        return None, None
    src = open(sol, encoding="utf-8", errors="replace").read()
    data = json.load(open(tcj))
    if os.path.exists(aux):
        m = re.search(r"fun_call\(subO_fun_([A-Za-z0-9_]+?)_\d+,", open(aux).read())
        if not m:
            return None, "funzione analizzata non trovata in .aux.pl"
        func = m.group(1)
    elif data.get("functions"):
        # SolCMC route (solcmc_zmiout2json.py): no .aux.pl, the json has the signature
        func = data["functions"][0]["signature"].split("(")[0]
    else:
        return None, None
    cname = data.get("contractName")
    params = params_of(src, rf"\bfunction\s+{re.escape(func)}\s*\(([^)]*)\)")
    if params is None:
        return None, f"funzione {func} non trovata nel sorgente"
    # the contract must compile on its own with the local solc
    if subprocess.run(["solc", "--bin", sol], capture_output=True).returncode != 0:
        return None, "non compila con il solc locale"
    ctor = params_of(src, r"\bconstructor\s*\(([^)]*)\)") or []
    ctor_args = [zero_literal(t) for t, _ in ctor]
    if None in ctor_args:
        return None, "costruttore con parametri di tipo non gestito"

    base = f"{ident(group)}__{ident(name)}"
    with open(os.path.join(project, "src", base + ".sol"), "w") as f:
        f.write(src)

    state_vars = set(data.get("stateVariables") or [])
    lines = [
        "// SPDX-License-Identifier: UNLICENSED",
        f"// Witnesses found by our tool for {group}/{name}",
        f"// Analysed function: {func}({', '.join(t for t, _ in params)})",
        "pragma solidity ^0.8.0;",
        "",
        f'import {{{cname} as Target}} from "../src/{base}.sol";',
        "",
        VM_INTERFACE,
        f"contract Test_{base} {{",
        '    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));',
        "    // caller different from the deployer (this test contract)",
        "    address constant CALLER = address(0xBEEF);",
        "",
    ]
    n = 0
    for fn in data.get("functions", []):
        for tc in fn.get("test_cases", []):
            vals = {}
            for cv in tc.get("concrete_values") or []:
                mm = re.match(r"\s*([\w.]+)\s*==\s*(\S+)", cv)
                if mm:
                    vals[mm.group(1)] = mm.group(2)
            kind = tc.get("kind", "negative")
            fname = f"test_{kind}_{tc.get('id')}"
            lines.append(f"    // values found by the tool: {', '.join(tc.get('concrete_values') or []) or '(none)'}")
            if any(k in state_vars for k in vals):
                lines.append("    // note: state variables in the witness are NOT set; the contract starts from its deployed state")
            if kind == "positive":
                lines.append("    // positive witness: it must pass the real asserts and reach the always-failing 'vgood' marker assert")
            args, bad = [], None
            for typ, pname in params:
                lit, why = literal(typ, vals.get(pname))
                if why:
                    bad = f"{pname}: {why}"
                    break
                args.append(lit)
            lines.append(f"    function {fname}() public {{")
            if bad:
                lines.append(f'        revert("valore fuori dominio, la chiamata non si puo\' scrivere: {bad}");')
            else:
                lines.append(f"        Target c = new Target({', '.join(ctor_args)});")
                # block values found by the analysis (SolCMC route)
                if "block.timestamp" in vals:
                    lines.append(f"        vm.warp({vals['block.timestamp']});")
                if "block.number" in vals:
                    lines.append(f"        vm.roll({vals['block.number']});")
                lines += [
                    "        vm.prank(CALLER);",
                    '        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 1));',
                    f"        c.{func}({', '.join(args)});",
                ]
            lines += ["    }", ""]
            n += 1
    lines.append("}")
    with open(os.path.join(project, "test", base + ".t.sol"), "w") as f:
        f.write("\n".join(lines) + "\n")
    return n, None


FOUNDRY_TOML_FORGE_STD = """[profile.default]
src = "src"
test = "test"
out = "out"
libs = ["lib"]
remappings = ["forge-std/=lib/forge-std/src/"]
solc = "{solc}"
offline = true
"""

# copies of forge-std: the one cloned by install.sh next to this repo,
# then the ones already on the laptop and on the server
FORGE_STD_PLACES = (
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "forge-std"),
    "~/Desktop/solTg/SolTG/lib/forge-std",
    "~/soltg_server_run/solidity_testgen/lib/forge-std",
)


def find_forge_std():
    for p in [os.environ.get("FORGE_STD", "")] + [os.path.expanduser(x) for x in FORGE_STD_PLACES]:
        if p and os.path.isfile(os.path.join(p, "src", "Test.sol")):
            return p
    sys.exit("forge-std not found: set FORGE_STD=/path/to/forge-std")


def make_test_forge_std(folder, group, project):
    """Same tests as make_test, written with forge-std and without expectRevert."""
    name = os.path.basename(folder)
    sol = os.path.join(folder, name + ".sol")
    if not os.path.exists(sol):
        sols = glob.glob(os.path.join(folder, "*.sol"))
        if len(sols) != 1:
            return None, None
        sol = sols[0]
        name = os.path.basename(sol)[:-4]
    tcj = os.path.join(folder, name + ".test_cases.json")
    aux = os.path.join(folder, name + ".aux.pl")
    zs = [z for z in glob.glob(os.path.join(folder, "*.zmiout")) if ".derivable." in os.path.basename(z)]
    if not (os.path.exists(sol) and os.path.exists(tcj) and zs):
        return None, None
    src = open(sol, encoding="utf-8", errors="replace").read()
    data = json.load(open(tcj))
    if os.path.exists(aux):
        m = re.search(r"fun_call\(subO_fun_([A-Za-z0-9_]+?)_\d+,", open(aux).read())
        if not m:
            return None, "funzione analizzata non trovata in .aux.pl"
        func = m.group(1)
    elif data.get("functions"):
        func = data["functions"][0]["signature"].split("(")[0]
    else:
        return None, None
    cname = data.get("contractName")
    params = params_of(src, rf"\bfunction\s+{re.escape(func)}\s*\(([^)]*)\)")
    if params is None:
        return None, f"funzione {func} non trovata nel sorgente"
    if subprocess.run(["solc", "--bin", sol], capture_output=True).returncode != 0:
        return None, "non compila con il solc locale"
    ctor = params_of(src, r"\bconstructor\s*\(([^)]*)\)") or []
    ctor_args = [zero_literal(t) for t, _ in ctor]
    if None in ctor_args:
        return None, "costruttore con parametri di tipo non gestito"

    base = f"{ident(group)}__{ident(name)}"
    with open(os.path.join(project, "src", base + ".sol"), "w") as f:
        f.write(src)

    # SolCMC route: the json can hold several functions, each test calls its own one
    tests = []
    for fn in data.get("functions", []):
        f_i, p_i = func, params
        if not os.path.exists(aux):
            f_i = fn["signature"].split("(")[0]
            p_i = params_of(src, rf"\bfunction\s+{re.escape(f_i)}\s*\(([^)]*)\)")
            if p_i is None:
                return None, f"funzione {f_i} non trovata nel sorgente"
        tests += [(f_i, p_i, tc) for tc in fn.get("test_cases", [])]
    lines = [
        "// SPDX-License-Identifier: UNLICENSED",
        f"// Witnesses found by our analysis for {group}/{name}",
        f"// Function under test: {func}({', '.join(t for t, _ in params)})",
        "pragma solidity ^0.8.0;",
        "",
        'import {Test} from "forge-std/Test.sol";',
        f'import {{{cname} as Target}} from "../src/{base}.sol";',
        "",
        f"contract Witnesses_{ident(name)} is Test {{",
        "    Target internal target;",
        "    // caller different from the deployer (this test contract)",
        "    address internal constant CALLER = address(0xBEEF);",
        "",
        "    // forge runs setUp before every test: each test starts from a fresh contract",
        "    function setUp() public {",
        f"        target = new Target({', '.join(ctor_args)});",
        "    }",
    ]
    for i, (func, params, tc) in enumerate(tests, 1):
        vals = {}
        for cv in tc.get("concrete_values") or []:
            mm = re.match(r"\s*([\w.]+)\s*==\s*(\S+)", cv)
            if mm:
                vals[mm.group(1)] = mm.group(2)
        args, bad = [], None
        for typ, pname in params:
            lit, why = literal(typ, vals.get(pname))
            if why:
                bad = f"{pname}: {why}"
                break
            args.append(lit)
        cs = tc.get("constraints_clpq_start") or tc.get("constraints_clpq") or []
        cs = [c for c in cs if "1157920892373161954235709850086879078532699846656" not in c]
        # CLP(Q) writes rationals as 1r2
        cs = [re.sub(r"(\d+)r(\d+)", r"\1/\2", c) for c in cs]
        kind = tc.get("kind", "negative")
        lines += ["", f"    // {kind} #{i}, constraints at the start of the call: {', '.join(cs) or '(none)'}",
                  f"    function test_{kind}_{i}() public {{"]
        if bad:
            lines.append("        return; // valore fuori dominio: " + bad if COVERAGE else
                         f'        revert("valore fuori dominio, la chiamata non si puo\' scrivere: {bad}");')
        else:
            if "block.timestamp" in vals:
                lines.append(f"        vm.warp({vals['block.timestamp']});")
            if "block.number" in vals:
                lines.append(f"        vm.roll({vals['block.number']});")
            sender = vals.get("msg.sender")
            lines.append(f"        vm.prank({f'address(uint160({sender}))' if sender else 'CALLER'});")
            call = f"target.{func}({', '.join(args)})"
            # --coverage: the expected assert failure must not make forge coverage stop
            lines.append(f"        try {call} {{}} catch {{}}" if COVERAGE else f"        {call};")
        lines.append("    }")
    lines.append("}")
    with open(os.path.join(project, "test", base + ".t.sol"), "w") as f:
        f.write("\n".join(lines) + "\n")
    return len(tests), None


COVERAGE = False


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    args = sys.argv[1:]
    global COVERAGE
    COVERAGE = "--coverage" in args
    use_forge_std = "--forge-std" in args or COVERAGE
    args = [a for a in args if a not in ("--forge-std", "--coverage")]
    if len(args) < 2:
        print(__doc__)
        sys.exit(1)
    project, roots = args[0], args[1:]
    os.makedirs(os.path.join(project, "src"), exist_ok=True)
    os.makedirs(os.path.join(project, "test"), exist_ok=True)
    solc = subprocess.run(["which", "solc"], capture_output=True, text=True).stdout.strip() or "solc"
    with open(os.path.join(project, "foundry.toml"), "w") as f:
        f.write((FOUNDRY_TOML_FORGE_STD if use_forge_std else FOUNDRY_TOML).format(solc=solc))
    if use_forge_std:
        lib = os.path.join(project, "lib")
        os.makedirs(lib, exist_ok=True)
        if not os.path.exists(os.path.join(lib, "forge-std")):
            os.symlink(find_forge_std(), os.path.join(lib, "forge-std"))
    total, skipped = 0, []
    for root in roots:
        for tcj in sorted(glob.glob(os.path.join(root, "**", "*.test_cases.json"), recursive=True)):
            folder = os.path.dirname(tcj)
            if any(s in folder for s in SKIP_DIRS):
                continue
            group = os.path.relpath(os.path.dirname(folder), os.path.dirname(os.path.normpath(root)))
            n, why = (make_test_forge_std if use_forge_std else make_test)(folder, group, project)
            if why:
                skipped.append(f"{folder}: {why}")
            elif n:
                total += n
    print(f"{total} test generati in {project}/test")
    if skipped:
        print("saltati:")
        print("\n".join("  " + s for s in skipped))


if __name__ == "__main__":
    main()
