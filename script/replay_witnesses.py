#!/usr/bin/env python3
"""
replay_witnesses.py — checks every concrete test the analysis produced by
actually RUNNING the contract on a local EVM (anvil, from Foundry).

For every contract folder under the given roots that has a .test_cases.json
and a "derivable" .zmiout, each test case is replayed like this:
  1. compile <contract>.sol with solc (the one in PATH);
  2. deploy a FRESH copy of the contract (constructor arguments all zero);
  3. call the analysed public function (the entry point in <contract>.aux.pl)
     with the test's concrete values (parameters missing from the witness
     are unconstrained, so 0 / false / address(0) is used);
  4. classify how the call ends.

Outcome of a negative test (the analysis says "this input breaks an assert"):
  valido        the call ends with Panic(0x01): the assert really fails
  regge         the call succeeds: the assert holds, the test is false
  require       plain revert: the values do not satisfy a require
  altro_panic   another Panic code (overflow 0x11, division by zero 0x12, ...)
  fuori_dominio a value is impossible for its type (e.g. -200 for a uint,
                256 for a uint8), so the call cannot even be made
  errore        could not compile / deploy / call (see "dettaglio")

Limits, written in each result as "nota" when they apply:
  - state variables are NOT set from the witness: the contract starts from
    its real deployed state, so a witness that needs a different initial
    state cannot be reproduced exactly;
  - the contract is deployed by anvil account 0 and called by account 1
    (msg.sender != deployer); msg.value is 0.

Results go to <contract>.replay.json next to the contract, plus one summary
line per contract on stdout.

Usage:
    python3 script/replay_witnesses.py testOrganizzati28Settembre/solcmc ...
"""
import glob
import json
import os
import re
import socket
import subprocess
import sys
import time

KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"  # anvil account 0
# caller of the replayed function: anvil account 1, a DIFFERENT address from
# the deployer (account 0). Without --from, `cast call` uses address(0) as
# msg.sender, which silently satisfies `msg.sender == owner` when owner was
# never set (Missing, Rubixi); calling from the deployer itself would satisfy
# it when the constructor sets owner = msg.sender (Unprotected). An access-
# control bug is exactly "someone else can call it", so the caller must be
# someone else.
SENDER = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
SKIP_DIRS = ("senza_step4b", "_rimossi_dal_report", "_duplicati", "_timeout60",
             "_vecchio_su_f", "_11set_incompleto", "_riprova_bmv5")


def free_port():
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    p = s.getsockname()[1]
    s.close()
    return p


def run(cmd, timeout=120):
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    return r.returncode, r.stdout, r.stderr


def strip_comments(src):
    src = src.split("// ====")[0]
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    return re.sub(r"//.*", "", src)


def entry_function(folder, name):
    aux = os.path.join(folder, name + ".aux.pl")
    if not os.path.exists(aux):
        return None
    m = re.search(r"fun_call\(subO_fun_([A-Za-z0-9_]+?)_\d+,", open(aux).read())
    return m.group(1) if m else None


def function_params(src, func):
    """[(type, name)] of `func`'s parameters, read from the source."""
    m = re.search(rf"\bfunction\s+{re.escape(func)}\s*\(([^)]*)\)", strip_comments(src))
    if not m:
        return None
    params = []
    for p in [x.strip() for x in m.group(1).split(",") if x.strip()]:
        toks = [t for t in p.split() if t not in ("memory", "calldata", "storage", "payable")]
        typ = toks[0]
        typ = {"uint": "uint256", "int": "int256"}.get(typ, typ)
        params.append((typ, toks[1] if len(toks) > 1 else ""))
    return params


def to_arg(typ, value):
    """Return (argument string for cast, None) or (None, reason) if the value
    cannot exist for that type."""
    if value is None:
        value = "0"
    v = str(value).strip()
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
        if n < 0 or n >= 2 ** bits:
            return None, f"{n} fuori dal range di {typ}"
        return str(n), None
    if typ.startswith("int"):
        bits = int(typ[3:] or 256)
        if not -(2 ** (bits - 1)) <= n < 2 ** (bits - 1):
            return None, f"{n} fuori dal range di {typ}"
        return str(n), None
    if typ == "address":
        if n < 0 or n >= 2 ** 160:
            return None, f"{n} fuori dal range di address"
        return "0x" + format(n, "040x"), None
    return None, f"tipo {typ} non gestito"


def classify(rc, out, err):
    text = out + err
    if rc == 0:
        return "regge", ""
    m = re.search(r"panic: [^,(]*\(0x([0-9a-f]+)\)", text)
    if m:
        code = int(m.group(1), 16)
        return ("valido" if code == 1 else "altro_panic"), f"Panic(0x{code:02x})"
    if "execution reverted" in text:
        return "require", "revert senza panic"
    return "errore", text.strip().splitlines()[-1][:200] if text.strip() else "?"


def replay_folder(folder, rpc):
    name = os.path.basename(folder)
    sol = os.path.join(folder, name + ".sol")
    tc = os.path.join(folder, name + ".test_cases.json")
    zs = [z for z in glob.glob(os.path.join(folder, "*.zmiout")) if ".derivable." in os.path.basename(z)]
    if not (os.path.exists(sol) and os.path.exists(tc) and zs):
        return None
    data = json.load(open(tc))
    src = open(sol, encoding="utf-8", errors="replace").read()
    func = entry_function(folder, name)
    params = function_params(src, func) if func else None
    result = {"contratto": data.get("contractName"), "funzione": func, "test": []}
    if params is None:
        result["errore"] = f"funzione {func} non trovata nel sorgente"
        return result
    sig = f"{func}({','.join(t for t, _ in params)})"
    result["firma"] = sig

    rc, out, err = run(["solc", "--combined-json", "bin,abi", sol])
    if rc != 0:
        result["errore"] = "compilazione fallita: " + err.strip().splitlines()[-1][:200]
        return result
    contracts = json.loads(out)["contracts"]
    key = next((k for k in contracts if k.endswith(":" + str(data.get("contractName")))), None)
    if key is None:
        # fall back to the deployable contract that has the analysed function
        key = next((k for k, c in contracts.items() if c["bin"] and any(
            e.get("name") == func for e in (json.loads(c["abi"]) if isinstance(c["abi"], str) else c["abi"]))), None)
    if key is None or not contracts[key]["bin"]:
        result["errore"] = f"contratto {data.get('contractName')} non deployabile (astratto o non trovato)"
        return result
    bytecode = contracts[key]["bin"]
    abi = contracts[key]["abi"]
    abi = json.loads(abi) if isinstance(abi, str) else abi
    ctor = next((e for e in abi if e.get("type") == "constructor"), None)
    ctor_args = "00" * 32 * len(ctor.get("inputs", [])) if ctor else ""
    state_vars = set(data.get("stateVariables") or [])

    for fn in data.get("functions", []):
        for t in fn.get("test_cases", []):
            vals = {}
            for cv in t.get("concrete_values") or []:
                m = re.match(r"\s*(\w+)\s*==\s*(\S+)", cv)
                if m:
                    vals[m.group(1)] = m.group(2)
            entry = {"id": t.get("id"), "tipo": t.get("kind"), "valori": t.get("concrete_values") or []}
            notes = []
            if any(k in state_vars and vals[k] not in ("0", "false") for k in vals):
                notes.append("il testimone chiede variabili di stato diverse da quelle iniziali: non applicate")
            args, bad = [], None
            for typ, pname in params:
                a, why = to_arg(typ, vals.get(pname))
                if why:
                    bad = f"{pname}: {why}"
                    break
                args.append(a)
            if bad:
                entry.update(esito="fuori_dominio", dettaglio=bad)
            else:
                rc, out, err = run(["cast", "send", "--rpc-url", rpc, "--private-key", KEY,
                                    "--create", "0x" + bytecode + ctor_args, "--json"])
                try:
                    addr = json.loads(out)["contractAddress"]
                except Exception:
                    entry.update(esito="errore", dettaglio="deploy fallito: " + (err.strip().splitlines() or ["?"])[-1][:200])
                    result["test"].append(entry)
                    continue
                rc, out, err = run(["cast", "call", "--rpc-url", rpc, "--from", SENDER, addr, sig] + args)
                esito, det = classify(rc, out, err)
                entry.update(esito=esito, dettaglio=det, chiamata=f"{sig} con {args}")
            if t.get("kind") == "positive":
                # a positive witness should NOT break the assert
                entry["atteso"] = "regge"
            if notes:
                entry["nota"] = "; ".join(notes)
            result["test"].append(entry)
    return result


def main():
    roots = sys.argv[1:] or ["testOrganizzati28Settembre"]
    port = free_port()
    rpc = f"http://127.0.0.1:{port}"
    anvil = subprocess.Popen(["anvil", "--port", str(port), "--silent"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(3)
    try:
        folders = []
        for root in roots:
            for tcj in glob.glob(os.path.join(root, "**", "*.test_cases.json"), recursive=True):
                d = os.path.dirname(tcj)
                if any(s in d.split(os.sep) or s in d for s in SKIP_DIRS):
                    continue
                folders.append(d)
        for d in sorted(set(folders)):
            try:
                res = replay_folder(d, rpc)
            except Exception as e:
                res = {"errore": f"eccezione: {e}", "test": []}
            if res is None:
                continue
            with open(os.path.join(d, os.path.basename(d) + ".replay.json"), "w") as f:
                json.dump(res, f, indent=2, ensure_ascii=False)
            esiti = [t["esito"] for t in res.get("test", [])]
            print(f"{d}\t{res.get('errore') or ' '.join(esiti)}", flush=True)
    finally:
        anvil.terminate()


if __name__ == "__main__":
    main()
