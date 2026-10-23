#!/usr/bin/env python3
"""
generate_report.py — scans every tested contract folder under the benchmark
roots below, pulls out its verdict/test-count/concrete-values from the real
.zmiout and .test_cases.json files on disk, and writes a single HTML report
(one row per contract) to present the full test campaign in one page.

The "coherent" column is not something this script can infer on its own —
whether a result is correct depends on knowing the expected behaviour of
each contract, which was established by hand over the course of the testing
session (manual value checks, comparisons against known baselines, etc).
That knowledge is recorded in the NOTES dict below, keyed by contract folder
name; everything else (verdict, test count, concrete values, file paths) is
read fresh from disk every time this script runs, so the report always
reflects the current state of the repo.

Usage:
    python3 script/generate_report.py [-o OUTPUT.html]
"""
import argparse
import glob
import html
import json
import os
import re
from datetime import datetime

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (display title, folder relative to REPO)
# regenerazioneNoPatchT4b10Settembre e' la rigenerazione completa e
# definitiva dei 37 contratti gia' testati, rifatta da zero ripartendo dal
# Solidity, con tutte le correzioni del 10 settembre applicate E con
# patch_t_constr (la ri-derivazione di condizioni di branch in step4b)
# disattivata di default (vedi DISABLE_PATCH_T_CONSTR in
# step4b_fix_branch_constraints.py) -- quel meccanismo si e' rivelato
# responsabile di almeno 2 falsi positivi confermati (Math_max, simple_if)
# e di beneficio nullo sul resto del campione controllato a mano.
# REPORT_ORG: folder with the results to report (default: the 28 September run)
ORG = os.environ.get("REPORT_ORG", "esperimenti/testOrganizzati28Settembre")
BENCHMARK_GROUPS = [
    ("SolTG - originali (smtCheckerTests di Solidity)", f"{ORG}/soltg/originali"),
    ("SolTG - asserzioni negate", f"{ORG}/soltg/negati"),
    ("SolTG - varianti _fail", f"{ORG}/soltg/fail"),
    ("TPLP", f"{ORG}/tplp"),
    ("Solidity - Math (OpenZeppelin)", f"{ORG}/solidity/math"),
    ("Solidity - scritti a mano", f"{ORG}/solidity/handmade"),
    ("Solidity - access control (SmartBugs / not-so-smart-contracts)", f"{ORG}/solidity/access_control"),
    ("Proprieta' sulle variabili (28 settembre)", f"{ORG}/proprieta_variabili"),
    ("Proprieta' sulle variabili, seconda batteria (28 settembre)", f"{ORG}/proprieta_variabili_2"),
    ("Proprieta' sulle variabili, ordine dei parametri (28 settembre)", f"{ORG}/proprieta_variabili_3_ordine"),
]
for _sub, _label in (("solcmc", "SolCMC (smtCheckerTests)"),
                     ("solcmc_stato", "SolCMC con stato / piu' funzioni"),
                     ("senza_step4b", "SENZA step 4b (stessi contratti, .t_constr.pl non modificato)")):
    _root = os.path.join(REPO, ORG, _sub)
    if os.path.isdir(_root):
        for _cat in sorted(os.listdir(_root)):
            if os.path.isdir(os.path.join(_root, _cat)) and not _cat.startswith("_"):
                BENCHMARK_GROUPS.append((f"{_label} - {_cat}", f"{ORG}/{_sub}/{_cat}"))

# Known-correct result (verdict, test count) from an external baseline, for
# groups where one exists -- currently only the TPLP family, compared
# against test2/26Jun_TPLP_<name>.
TPLP_BASELINE = {
    "AuctionOffer":            ("derivable", 1),
    "AuctionOffer_vgood":      ("derivable", 2),
    "LotteryFaulty":           ("derivable", 1),
    "LotteryFaulty_vgood":     ("derivable", 2),
    "Operation_faulty":        ("derivable", 1),
    "Operation_faulty_vgood":  ("derivable", 2),
    "OwnableFaulty":           ("derivable", 1),
    "OwnableFaulty_vgood":     ("derivable", 2),
    "SplitterFaulty":          ("derivable", 7),
    "SplitterFaulty_vgood":    ("derivable", 3),
}

# Expected verdict (ground truth), established by hand this session --
# mostly straight from each contract's own "// NEGATED ... always true" /
# "expect nonDerivable" header comment (a negated always-true assertion is
# always violated -- "derivable" -- unless the negated branch is dead code,
# in which case it's genuinely unreachable -- "nonDerivable"), from the TPLP
# June baseline (TPLP_BASELINE above), or from a manual source-level proof
# (Math_max/simple_if: both branches' own asserts restate their branch
# condition, so neither can ever fail; Math_min: a real off-by-one bug we
# found in the library, confirmed at the source level; short_circuit_and_*:
# confirmed against the contract's own embedded SMTChecker comment).
# Contracts not listed here have no established ground truth yet -- the
# report marks those "ignoto" rather than guessing.
GROUND_TRUTH = dict(list(TPLP_BASELINE.items()))
for _name, _verdict in {
    "branches_merge_variables_3_negated": "derivable",
    "branches_merge_variables_5_negated": "derivable",
    "branches_merge_variables_6_negated": "derivable",
    "function_call_inside_branch_negated": "derivable",
    "function_call_inside_branch_2_negated": "derivable",
    "function_call_inside_branch_3_negated": "derivable",
    "function_call_inside_branch_4_negated": "derivable",
    "function_call_inside_else_branch_negated": "nonDerivable",
    "identity_call_negated": "derivable",
    "inline_branch_negated": "derivable",
    "no_deadcode_negated": "derivable",
    "only_assert2_negated": "derivable",
    "only_assert2_var_negated": "derivable",
    "return_1_negated": "derivable",
    "return_in_both_branches_negated": "derivable",
    "short_circuit_and_negated": "derivable",
    "only_assert2_fail": "derivable",
    "return_1_fail": "derivable",
    "return_2_fail": "derivable",
    "short_circuit_and_fail": "derivable",
    "short_circuit_and_need_both_fail": "derivable",
    "test_same_branch_twice": "derivable",
    "simple_if2": "derivable",
    "Math_min": "derivable",
    "simple_if": "nonDerivable",
    "Math_max": "nonDerivable",
    # OperationFaulty corrected on 1/10 (assert diff == |x - y|): the assembly
    # bug really breaks it, verified with Foundry on x = 2, y = 1
    "Operation_faulty_v2": "derivable",
    "Operation_faulty_v2_vgood": "derivable",
    # SolTG originals without an SMTChecker footer: all asserts always hold
    "identity_call": "nonDerivable",
    "inline_branch": "nonDerivable",
    "no_deadcode": "nonDerivable",
    "return_in_both_branches": "nonDerivable",
    "only_assert2": "nonDerivable",
    "only_assert2_var": "nonDerivable",
    # access control: every contract is vulnerable by construction
    # (anyone can call the function, the assert on msg.sender can fail)
    "Missing": "derivable",
    "MultiOwnable": "derivable",
    "Phishable": "derivable",
    "PhishableNoOrigin": "derivable",
    "Rubixi": "derivable",
    "Unprotected": "derivable",
}.items():
    GROUND_TRUTH[_name] = (_verdict, None)

# classification label for (expected_verdict, actual_verdict) -- test-count
# mismatches are NOT considered here, only the derivable/nonDerivable call
CLASSIFICATION = {
    ("derivable", "derivable"): "VP (vero positivo)",
    ("nonDerivable", "nonDerivable"): "VN (vero negativo)",
    ("derivable", "nonDerivable"): "FN (falso negativo)",
    ("nonDerivable", "derivable"): "FP (falso positivo)",
}

# status: "ok" (verified correct), "warn" (open question / known limitation,
# not a wrong result), "bad" (confirmed wrong / crashed)
# Gas benchmark of 2 October (testing-gas/trunk/TPLP_Contracts/02Ott_significativi):
# every contract has the auxiliary vgood assert, so the expected verdict is
# always derivable; the expected tests are one per Solidity path.
GAS_OTT = os.environ.get("REPORT_GAS_OTT", "../../testing-gas/trunk/TPLP_Contracts/02Ott_significativi")
GAS_OTT_NOTES = {
    "AuctionRefund": "Atteso: 3 cammini (rimborso, pagamento esatto, pagamento insufficiente = bug). Trovati 3 test, uno per cammino: newBid=1/payment=2 e newBid=1/payment=1 positivi, newBid=2/payment=1 negativo. Valori e vincoli verificati sul sorgente.",
    "LotteryTickets": "Atteso: 5 cammini, uno per tickets = 1..5. Trovati 5 test: tickets=1 positivo, tickets=2..5 negativi con owner = tickets-1 e playerCount = 1 (il bug). Valori e vincoli verificati sul sorgente.",
    "OperationK": "Atteso: 6 cammini, k = 1..3 per x < y (positivo) e x > y (negativo). Trovati 6 test (x=1,y=2 e x=2,y=1 per ogni k). Valori e vincoli verificati sul sorgente.",
    "SplitterN": "Atteso: 6 cammini, n = 1..3 per r = 0 (positivo) e r > 0 (negativo). Trovati 6 test (a=1, r=0 o r=1 per ogni n). Valori e vincoli verificati sul sorgente.",
    "RewardSystem": "Esempio del paper, lanciato con --stop-first-per-loop come nel paper: 3 test (points = 9, 2, 10), identici alla tabella del paper.",
    "LoopBasic": "Da SolTG (loop_basic.sol), senza bug: solo test positivi, uno per x = 1..9 (lanciato con --looplimit 10). Valori e vincoli verificati sul sorgente.",
}
for _name in GAS_OTT_NOTES:
    GROUND_TRUTH.setdefault(_name, ("derivable", None))
# esempi aggiuntivi del 5/10 (05Ott_esempi_aggiuntivi), nelle versioni con
# bug del confronto Yul/SolCMC del 13/10: il bug c'e', quindi derivable
for _name in ("PaymentPlan", "BootVesting"):
    GROUND_TRUTH.setdefault(_name, ("derivable", None))

NOTES = {
    # soltgBenchmark9Settembre
    "branches_merge_variables_3_negated": ("ok", "2 test, uno per ramo; testimoni e vincoli verificati sul sorgente il 28/9."),
    "branches_merge_variables_5_negated": ("ok", "2 test, uno per ramo; testimoni e vincoli verificati sul sorgente il 28/9."),
    "branches_merge_variables_6_negated": ("ok", "2 test, uno per ramo; testimoni e vincoli verificati sul sorgente il 28/9."),
    "function_call_inside_branch_negated": ("bad", "Falso negativo con address: la variabile a e' un address restituito da g()."),
    "function_call_inside_branch_2_negated": ("ok", "Else morto, corretto."),
    "function_call_inside_branch_3_negated": ("bad", "Falso negativo con address: la variabile a e' un address restituito da g()."),
    "function_call_inside_branch_4_negated": ("bad", "Falso negativo con address: la variabile a e' un address restituito da g()."),
    "return_in_both_branches_negated": ("ok", "Corretto."),
    "short_circuit_and_negated": ("ok", "Corretto dopo il rilancio sulla funzione giusta g (il 10-11/9 era stata analizzata f, interna e senza assert)."),
    # soltgBenchmark10Settembre
    "function_call_inside_else_branch_negated": ("ok", "Corretto."),
    "identity_call_negated": ("ok", "Corretto."),
    "inline_branch_negated": ("ok", "Corretto."),
    "no_deadcode_negated": ("ok", "Era regredito a nonDerivable per un mio tentativo di fix poi annullato — ora derivable, corretto, come atteso."),
    "only_assert2_negated": ("ok", "Stesso schema di no_deadcode_negated, ora corretto (derivable)."),
    "only_assert2_var_negated": ("ok", "Stesso schema di no_deadcode_negated, ora corretto (derivable)."),
    "return_1_negated": ("bad", "Crash trasformazione (memoria)."),
    "only_assert2_fail": ("ok", "Coincide di nuovo con baseline 8/9 (derivable)."),
    "return_1_fail": ("bad", "Crash trasformazione (memoria) — nessun verdetto."),
    "short_circuit_and_fail": ("ok", "Corretto: x = 0 e' il valore di x all'inizio della chiamata; SolCMC mostra quello finale (1)."),
    "Math_max": ("ok", "Falso positivo uint256 negativo E il falso positivo residuo di patch_t_constr sono risolti oggi — nonDerivable, corretto."),
    "Math_min": ("ok", "Falso positivo uint256 risolto oggi. Bug reale confermato nel contratto (1 testimone, a=b=0)."),
    "Math_average": ("bad", "Crash: xor non supportato dal backend."),
    "simple_if": ("ok", "RISOLTO oggi: era un falso positivo di patch_t_constr (derivable con a==0, un valore che non raggiunge nemmeno l'assert). Ora nonDerivable, confermato corretto anche contro un run indipendente precedente."),
    "simple_if2": ("warn", "Verdetto giusto. Testimoni a = 0 corretti; il test con a != 0 e' falso (non fa fallire l'assert) (funzione con due return, problema noto yul-chc)."),
    "return_2_fail": ("bad", "Crash trasformazione (memoria)."),
    "short_circuit_and_need_both_fail": ("warn", "Verdetto e cammino giusti. Il vincolo sullo stato dice x = 2 (al momento dell'assert), come SolCMC; il valore concreto mostrato e' x = 0, cioe' quello di inizio chiamata. b non compare perche' e' locale."),
    "test_same_branch_twice": ("bad", "Non completato: interrotto insieme a SplitterFaulty per finire la sessione."),
    "Operation_faulty_v2": ("ok", "Versione corretta del 1/10: stesso bug in assembly, assert diff == |x - y|. Testimone x = 2, y = 1 verificato con Foundry (l'assert fallisce davvero)."),
    "Operation_faulty_v2_vgood": ("ok", "Versione corretta del 1/10, variante vgood. Testimoni verificati con Foundry."),
    "Operation_faulty": ("bad", "Il tool trova x = 2, y = 1 (come il 25/8 e come nell'articolo), ma Foundry non lo conferma: sulla EVM positiveDifference(2, 1) restituisce 2^256 - 1 senza errori, perche' in assembly sub(1, 2) non vale -1 ma 2^256 - 1 > 0. L'assert diff > 0 regge: il bug dichiarato non e' reale, e il tool tratta sub dell'assembly come una sottrazione fra interi."),
    "SplitterFaulty": ("ok", "Risultato della run del 25/8 (testing-gas/.../25Ago_retest, timeout 1800 s): bug trovato, 7 test come la baseline di giugno."),
    "Phishable": ("bad", "Falso negativo con address (msg.sender / owner)."),
    "PhishableNoOrigin": ("bad", "Falso negativo con address (msg.sender / owner), anche senza tx.origin."),
    "MultiOwnable": ("bad", "Nessun .zmiout dalla run dell'8 settembre, causa ancora da verificare."),
    "no_deadcode": ("bad", "Falso positivo noto (funzione con due return, nasce in yul-chc: anche z3 nativo da' unsat). Qui basta una chiamata con argomento nel ramo else."),
    "only_assert2_var": ("bad", "Falso positivo noto (funzione con due return, yul-chc), stesso schema di no_deadcode."),
    "return_in_both_branches": ("bad", "Falso positivo noto dei piu' return: nasce nella traduzione yul-chc."),
    "return_1": ("bad", "Nessun verdetto: il transform di yul-chc viene ucciso per memoria (stack 32GB), come l'11/9."),
    "short_circuit_and": ("warn", "Verdetto giusto ma non significativo: anche la versione negata da' nonDerivable (falso negativo)."),
    "P13_max_of_two_bug": ("ok", "Corretto dopo il fix del 28/9 sull'ordine dei parametri: vincoli -1 <= x - y < 0 e x < 1000, cioe' y = x + 1."),
    "P28_order_range_bug": ("ok", "Corretto dopo il fix del 1/10 sul range dei parametri: testimone x = 0, y = 200. Prima era x = -200."),
    "only_assert2": ("bad", "Falso positivo noto (funzione con due return, yul-chc), stesso schema di no_deadcode."),
    "function_call_inside_branch": ("warn", "Verdetto giusto ma non significativo: anche la versione negata da' nonDerivable (falso negativo)."),
    "function_call_inside_branch_3": ("warn", "Verdetto giusto ma non significativo: anche la versione negata da' nonDerivable (falso negativo)."),
    "function_call_inside_branch_4": ("warn", "Verdetto giusto ma non significativo: anche la versione negata da' nonDerivable (falso negativo)."),
    "SplitterFaulty_vgood": ("ok", "Risultato della run del 25/8 (testing-gas/.../25Ago_retest, timeout 1800 s): bug trovato, 3 test come la baseline di giugno."),
}


def expected_from_sol(sol):
    """Expected verdict written in the source itself: our own
    "// EXPECTED: derivable|nonDerivable" line, or the SMTChecker footer of
    the smtCheckerTests files (after "// ----", a "Warning 6328 ... Assertion
    violation" line means the assert can fail, no such line means it holds)."""
    with open(sol, encoding="utf-8", errors="replace") as f:
        src = f.read()
    m = re.search(r"//\s*EXPECTED:\s*(nonDerivable|derivable)", src)
    if m:
        return (m.group(1), None)
    if "// ----" in src:
        footer = src.split("// ----", 1)[1]
        return ("derivable" if "Warning 6328" in footer else "nonDerivable", None)
    return None


def expected_witness_from_sol(sol):
    """Human-readable expected witness: our own "// EXPECTED: ..." line, or
    the counterexample SolCMC printed in the smtCheckerTests footer."""
    with open(sol, encoding="utf-8", errors="replace") as f:
        src = f.read()
    m = re.search(r"//\s*EXPECTED:\s*(.*)", src)
    if m:
        return m.group(1).strip()
    if "// ----" in src:
        cexs = []
        for line in src.split("// ----", 1)[1].splitlines():
            if "Warning 6328" in line and "Counterexample:" in line:
                body = line.split("Counterexample:", 1)[1].split("Transaction trace:")[0]
                vals = [v.strip() for v in body.split("\\n") if "=" in v and v.strip()[:1] != "="]
                cexs.append("SolCMC: " + ", ".join(vals))
            elif "Warning 6328" in line:
                cexs.append("SolCMC: violazione (senza controesempio)")
        return " | ".join(cexs) if cexs else "SolCMC: nessuna violazione"
    return ""


# Manual notes for SolCMC files, keyed by path under the org folder (the
# SolCMC suite reuses SolTG names, so NOTES by name must not apply there).
SOLCMC_NOTES = {
    "solcmc/control_flow_branches_with_return/return_in_both_branches": ("bad", "Falso positivo noto dei piu' return: nasce nella traduzione yul-chc."),
    "solcmc_stato/invariants/aon_blog_post": ("known", "Differenza di modello: il bug si raggiunge solo con 6 transazioni di fila (press_D, press_E, ...), noi analizziamo una sola chiamata."),
    "solcmc_stato/functions/function_call_state_var_init": ("na", "Non applicabile: l'assert e' eseguito nell'inizializzazione di una variabile di stato, non in una funzione pubblica."),
    "solcmc_stato/inheritance/constructor_state_variable_init": ("na", "Non applicabile: l'assert e' nel costruttore."),
    "solcmc_stato/inheritance/constructor_state_variable_init_function_call": ("na", "Non applicabile: l'assert e' nel costruttore e nell'inizializzazione di una variabile di stato."),
    "solcmc_stato/verification_target/no_target_for_constructor_of_abstract_constract": ("na", "Non applicabile: l'assert e' nel costruttore di un contratto astratto."),
    "solcmc/natspec/abstract_free_function_1": ("ok", "Non e' un falso negativo: SolCMC trova la violazione solo per l'annotazione @custom:smtchecker abstract-function-nondet (tratta msb() come valore arbitrario). Nel codice reale msb() ha il corpo vuoto e restituisce 0, quindi l'assert regge: il nostro nonDerivable e' giusto."),
    "solcmc/control_flow_branches_with_return/simple_if2": ("warn", "Verdetto giusto, testimone a = 0 identico a SolCMC; il test con a != 0 e' falso (non fa fallire l'assert) (due return, problema noto)."),
}


def compare_with_solcmc(expected_witness, data):
    """'si' / 'no (x: SolCMC 1, noi 0)' / '' comparing the variables that
    appear both in SolCMC's counterexample and in any of our test cases."""
    if not expected_witness.startswith("SolCMC:") or not data:
        return ""
    theirs = {}
    for part in expected_witness.split("|"):
        for kv in part.replace("SolCMC:", "").split(","):
            if "=" in kv:
                k, v = [t.strip() for t in kv.split("=", 1)]
                if k and re.fullmatch(r"-?\d+|true|false", v):
                    theirs.setdefault(k, v)
    ours_all = []
    for fn in data.get("functions", []):
        for tc in fn.get("test_cases", []):
            d = {}
            for cv in tc.get("concrete_values") or []:
                m = re.match(r"\s*(\w+)\s*==\s*(\S+)", cv)
                if m:
                    d[m.group(1)] = m.group(2)
            ours_all.append(d)
    common = [k for k in theirs if any(k in d for d in ours_all)]
    if not common:
        return ""
    # a match if at least one of our tests agrees on every common variable
    for d in ours_all:
        if all(d.get(k) == theirs[k] for k in common if k in d) and any(k in d for k in common):
            return "si"
    k = common[0]
    ours_v = next(d[k] for d in ours_all if k in d)
    return f"no ({k}: SolCMC {theirs[k]}, noi {ours_v})"


def load_foundry_results():
    """{'group/contract': {'reale': n, 'regge': n, 'dominio': n, 'altro': n}}
    from <ORG>/foundry_testimoni/forge_results.json (written by
    foundry_report.py). Each test file says which contract it comes from in
    its header ('// Witnesses found by our tool for <group>/<contract>')."""
    proj = os.path.join(REPO, ORG, "foundry_testimoni")
    res_path = os.path.join(proj, "forge_results.json")
    if not os.path.exists(res_path):
        return {}
    out = {}
    for suite, v in json.load(open(res_path)).items():
        tfile = os.path.join(proj, suite.split(":")[0])
        if not os.path.exists(tfile):
            continue
        m = re.search(r"// Witnesses found by our tool for (\S+)", open(tfile, encoding="utf-8").read())
        if not m:
            continue
        cnt = {"reale": 0, "regge": 0, "dominio": 0, "altro": 0}
        for r in v.get("test_results", {}).values():
            reason = r.get("reason") or ""
            k = ("reale" if r.get("status") == "Success" else
                 "regge" if "did not revert" in reason else
                 "dominio" if "fuori dominio" in reason else "altro")
            cnt[k] += 1
        out[m.group(1)] = cnt
    return out


REPORT_TITLE = "Report test SolTG / TPLP / Solidity"
HOW_TO_READ = ""
HOW_TO_READ_OTT = """<details open style="background:white;border-radius:8px;padding:0.8rem 1.2rem;box-shadow:0 1px 3px rgba(0,0,0,0.1);margin:1rem 0;">
<summary><b>Come leggere il report</b></summary>
<p>Per ogni contratto il nostro tool risponde <b>derivable</b> (esiste un input che fa fallire un assert, e ne da' i valori)
oppure <b>nonDerivable</b> (nessun assert puo' fallire). Il report confronta questa risposta con quella <b>attesa</b>.</p>
<p><b>Da dove viene la risposta attesa</b> (scritta per ogni contratto nella riga "Atteso stabilito da"):</p>
<ul>
<li><b>SolCMC</b> (test del compilatore Solidity): dal file stesso. In fondo a ogni test c'e' l'output dello SMTChecker di Solidity:
<code>Warning 6328 ... Assertion violation</code> vuol dire che l'assert puo' fallire (atteso derivable), nessun 6328 vuol dire sano (atteso nonDerivable).</li>
<li><b>Proprieta' sulle variabili</b> (test scritti da noi): riga <code>// EXPECTED:</code> nel sorgente; il nome finisce in <code>_safe</code> (nonDerivable) o <code>_bug</code> (derivable).</li>
<li><b>SolTG e benchmark gas</b>: tabella nello script del report, stabilita leggendo il sorgente
(es. un assert sempre vero, negato a mano, deve fallire: atteso derivable). Nel benchmark gas c'e' sempre l'assert ausiliario <code>vgood</code>, quindi l'atteso e' sempre derivable.</li>
</ul>
<p><b>I colori</b>: <b>verde</b> = risposta uguale a quella attesa; <b>giallo</b> = risposta giusta ma valori sbagliati (controllati a mano);
<b>rosso</b> = risposta sbagliata (falso positivo o falso negativo) o crash del nostro interprete;
<b>grigio</b> = il contratto non arriva al nostro interprete (errore di GREY o yul-chc); <b>blu</b> = timeout.</p>
<p><b>I valori</b>: il verde dice che la risposta derivable/nonDerivable e' giusta. I valori trovati sono mostrati per ogni contratto
(e per SolCMC confrontati con il controesempio dello SMTChecker, riga "Valori = SolCMC?"), ma sono stati controllati a mano solo dove c'e' una nota
(tutti i contratti del benchmark gas). Un controesempio diverso da quello di SolCMC puo' essere valido: di solito ce ne sono tanti.</p>
<p>Cliccando su una fetta di un grafico si vede l'elenco dei contratti, con risposta attesa, risposta ottenuta, valori, vincoli e sorgente.</p>
</details>
"""
EXTRA_META = ""

FOUNDRY = None
# --no-foundry: the report ignores the Foundry results (no column, no colour
# based on EVM execution)
NO_FOUNDRY = False


def foundry_for(rel_folder):
    """Foundry counts for a contract folder (path relative to REPO), matched
    on the 'group/contract' suffix written in the test file header."""
    global FOUNDRY
    if NO_FOUNDRY:
        return None
    if FOUNDRY is None:
        FOUNDRY = load_foundry_results()
    rel = rel_folder.replace(os.sep, "/")
    best = None
    for key, cnt in FOUNDRY.items():
        if rel.endswith("/" + key) or rel == key:
            if best is None or len(key) > len(best[0]):
                best = (key, cnt)
    return best[1] if best else None


def find_sol(folder):
    sols = glob.glob(os.path.join(folder, "*.sol"))
    return sols[0] if sols else None


def find_zmiout(folder):
    zs = glob.glob(os.path.join(folder, "*.zmiout"))
    # prefer a definitive (non-"timeout") result if both exist
    zs.sort(key=lambda p: ("timeout" in os.path.basename(p), p))
    return zs[0] if zs else None


def parse_verdict(zmiout_path):
    base = os.path.basename(zmiout_path)
    timed_out = ".timeout." in base
    if re.search(r"\.nonDerivable\.", base):
        v = "nonDerivable"
    elif re.search(r"\.derivable\.", base):
        v = "derivable"
    else:
        v = "?"
    incomplete = "notFullyExplored" in base
    return v, timed_out, incomplete


def count_tests(zmiout_path):
    with open(zmiout_path, encoding="utf-8", errors="replace") as f:
        return len(re.findall(r"TEST #\d+", f.read()))


def load_json_values(folder):
    jsons = glob.glob(os.path.join(folder, "*.test_cases.json"))
    if not jsons:
        return None
    try:
        with open(jsons[0], encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def summarize_values(data):
    """Compact 'testN: v1=x, v2=y | ...' summary of concrete_values across
    every test case in every function, for display in one table cell."""
    if not data:
        return ""
    parts = []
    for fn in data.get("functions", []):
        for tc in fn.get("test_cases", []):
            vals = tc.get("concrete_values") or []
            tag = "pos" if tc.get("kind") == "positive" else "neg"
            label = f"#{tc.get('id')}({tag})"
            parts.append(f"{label}: " + (", ".join(vals) if vals else "(nessuna var libera)"))
    return " | ".join(parts)


def summarize_constraints(data):
    """Projected CLP(Q) constraints per test case, e.g. '#1: x>=9, x<10'."""
    if not data:
        return ""
    parts = []
    for fn in data.get("functions", []):
        for tc in fn.get("test_cases", []):
            # the constraints with the state at the start of the call (the
            # inputs of the path), when the json has them
            cs = [c for c in (tc.get("constraints_clpq_start") or tc.get("constraints_clpq") or [])
                  if "115792089237316195423570985008687907853269984665640564039457584007913129639935" not in c]
            if cs:
                parts.append(f"#{tc.get('id')}: " + ", ".join(cs))
    return " | ".join(parts)

for _name, _text in GAS_OTT_NOTES.items():
    NOTES.setdefault(_name, ("ok", _text))


# REPORT_ROUTE=solcmc: results of the SolCMC route (solc CHC query ->
# smt2map -> smt2pl_to_constr.pl -> interpreter). The hand notes above
# describe the Yul route (yul-chc bugs, Yul test counts), so they are
# replaced with the notes of this route; GROUND_TRUTH stays.
ROUTE = os.environ.get("REPORT_ROUTE", "")
if ROUTE == "solcmc":
    NOTES = {
        "OperationK": ("bad", "Test in parte sbagliati: il bug e' in inline assembly, che SolCMC non supporta (warning 'unsupported language feature'), quindi la query di solc non lo modella."),
        "SplitterN": ("bad", "Test in parte sbagliati: il bug e' in inline assembly, che SolCMC non supporta (warning 'unsupported language feature'), quindi la query di solc non lo modella."),
        "RewardSystem": ("ok", "Lanciato con --looplimit 10 (non --stop-first-per-loop come nel paper): un test per ogni numero di giri del ciclo, piu' completo dei 3 del paper."),
    }
    SOLCMC_NOTES = {k: v for k, v in SOLCMC_NOTES.items() if v[0] in ("na", "known")}
    SOLCMC_NOTES.update({
        "solcmc/verification_target/no_target_for_abstract_constract": ("na", "Nessuna query da solc: il contratto e' astratto, non c'e' niente da verificare."),
        "solcmc_stato/verification_target/no_target_for_constructor_of_abstract_constract": ("na", "Nessuna query da solc: l'assert e' nel costruttore di un contratto astratto."),
        "solcmc/types/tuple_declarations": ("bad", "Falso positivo del convertitore: SolCMC codifica le tuple come valori strutturati (datatype SMT), che smt2pl_to_constr.pl butta via; senza quei vincoli l'assert sembra violabile."),
        "solcmc/types/tuple_declarations_empty": ("bad", "Falso positivo del convertitore: SolCMC codifica le tuple come valori strutturati (datatype SMT), che smt2pl_to_constr.pl butta via; senza quei vincoli l'assert sembra violabile."),
        "solcmc/types/tuple_declarations_function": ("bad", "Falso positivo del convertitore: SolCMC codifica le tuple come valori strutturati (datatype SMT), che smt2pl_to_constr.pl butta via; senza quei vincoli l'assert sembra violabile."),
        "solcmc/types/tuple_declarations_function_2": ("bad", "Falso positivo del convertitore: SolCMC codifica le tuple come valori strutturati (datatype SMT), che smt2pl_to_constr.pl butta via; senza quei vincoli l'assert sembra violabile."),
        "solcmc_stato/types/tuple_assignment_multiple_calls": ("bad", "Falso positivo del convertitore: SolCMC codifica le tuple come valori strutturati (datatype SMT), che smt2pl_to_constr.pl butta via; senza quei vincoli l'assert sembra violabile."),
        "solcmc/operators/tuple_rationals_conditional": ("bad", "Falso positivo del convertitore: SolCMC codifica le tuple come valori strutturati (datatype SMT), che smt2pl_to_constr.pl butta via; senza quei vincoli l'assert sembra violabile."),
        "solcmc/typecast/cast_smaller_2": ("bad", "Falso positivo del convertitore: la conversione uint32 -> uint16 non e' aritmetica lineare e il vincolo viene buttato via."),
        "solcmc/special/blobhash_beyond_limit": ("bad", "Falso positivo del convertitore: blobhash(index) e' una funzione non interpretata (valore strutturato), il vincolo che vale 0 oltre il limite viene buttato via."),
        "solcmc/unsupported/transient_storage_state_variable": ("known", "Nessuna query da solc: SolCMC non supporta le variabili transient."),
    })


def row_for(group_folder, name):
    folder = os.path.join(group_folder, name)
    # hand-written NOTES / GROUND_TRUTH are keyed by contract name and were
    # written for the SolTG/TPLP/own copies; the SolCMC suite reuses some of
    # the same names, so there only the SMTChecker footer counts
    if re.search(r"[/\\]solcmc(_stato)?[/\\]", folder):
        _key = os.path.relpath(folder, os.path.join(REPO, ORG))
        notes, truth = ({name: SOLCMC_NOTES[_key]} if _key in SOLCMC_NOTES else {}), {}
    else:
        notes, truth = NOTES, GROUND_TRUTH
    sol = find_sol(folder)
    zmiout = find_zmiout(folder)
    rel_folder = os.path.relpath(folder, REPO)

    if not sol:
        return None  # not a contract folder

    if not zmiout:
        # a crash in GREY (step 1) leaves only the .sol in the folder; the
        # run log in the category's _logs/ tells it was actually executed
        logs = os.path.join(group_folder, "_logs", f"regen_{name}.log")
        started = (any(not f.endswith(".sol") for f in os.listdir(folder))
                   or os.path.exists(logs) or os.path.exists(logs + ".gz"))
        if name in notes:
            note_key, note_text = notes[name]
        elif started:
            note_key, note_text = ("bad", "Nessun .zmiout: crash o analisi non completata (vedi il log di regen_all).")
        else:
            note_key, note_text = ("pending", "Non ancora eseguito (in coda).")
        verdict, tests = "— (crash / non completato)", "—"
        values_summary = ""
        constraints_summary = ""
        classification = "— (nessun verdetto: crash o non completato)"
    else:
        v, timed_out, incomplete = parse_verdict(zmiout)
        tests = count_tests(zmiout)
        verdict = v + (" (timeout)" if timed_out else "") + (", esplorazione incompleta" if incomplete else "")
        data = load_json_values(folder)
        values_summary = summarize_values(data) if tests else ""
        constraints_summary = re.sub(r"(\d+)r(\d+)", r"\1/\2", summarize_constraints(data)) if tests else ""
        note_key, note_text = notes.get(name, ("", ""))
        if not note_key:
            # a timeout only makes a "nothing found" answer uncertain: a
            # violation found before the deadline is a certain answer
            note_key = "warn" if (timed_out or incomplete) and v != "derivable" else "ok"
        expected = truth.get(name) or expected_from_sol(sol)
        if v == "nonDerivable" and (timed_out or incomplete):
            classification = "ignoto (timeout: esplorazione incompleta)"
            if not note_text:
                note_text = "Timeout: l'analisi non ha finito di esplorare. Viene ritentata a 600 s alla fine del lancio notturno (_ritenta_timeout.sh)."
        elif expected and v in ("derivable", "nonDerivable"):
            classification = CLASSIFICATION.get((expected[0], v), "ignoto")
        else:
            classification = "ignoto (verità non stabilita)"
        if name not in notes and classification[:2] in ("FP", "FN"):
            note_key = "bad"

    baseline = TPLP_BASELINE.get(name)
    baseline_str = ""
    if baseline:
        bverdict, btests = baseline
        baseline_str = f"{bverdict}, {btests} test"
        if zmiout:
            v, _, _ = parse_verdict(zmiout)
            if v == bverdict and str(tests) == str(btests):
                if not note_text:
                    note_text = "Identico alla baseline di giugno."
                if note_key not in ("bad",):
                    note_key = "ok"
            else:
                note_key = "warn" if note_key != "bad" else note_key
                if not note_text:
                    note_text = f"Diverso dalla baseline ({bverdict}, {btests} test)."

    # a file whose asserts are all commented out (e.g. SolCMC's
    # file_level/recursion.sol, disabled upstream) tests nothing
    with open(sol, encoding="utf-8", errors="replace") as f:
        code = f.read().split("// ====")[0].split("// ----")[0]
    code = re.sub(r"//.*", "", re.sub(r"/\*.*?\*/", "", code, flags=re.S))
    if "assert(" not in code:
        note_key = "warn"
        note_text = "Test vuoto: tutti gli assert sono commentati nel sorgente, il verdetto non dice nulla."
        classification = "ignoto (nessun assert attivo)"

    # crash BEFORE our interpreter (GREY / generate_facts / yul-chc transform /
    # step4): no .t_constr.pl was ever produced
    conv_failed = not zmiout and not (glob.glob(os.path.join(folder, "*.t_constr.pl"))
                                      or glob.glob(os.path.join(folder, "*.chc.pl")))
    _exp = truth.get(name) or expected_from_sol(sol)
    if truth.get(name):
        expected_source = ("tabella scritta a mano nello script (GROUND_TRUTH), stabilita leggendo il sorgente"
                           + (" e la baseline TPLP di giugno" if name in TPLP_BASELINE else ""))
    elif _exp:
        with open(sol, encoding="utf-8", errors="replace") as f:
            _src = f.read()
        expected_source = ("riga // EXPECTED: nel sorgente (test scritto da noi)" if re.search(r"//\s*EXPECTED:", _src)
                           else "footer SMTChecker del file (compilatore Solidity): Warning 6328 = l'assert puo' fallire")
    else:
        expected_source = "nessuna: risultato atteso non stabilito"
    expected_verdict = _exp[0] if _exp else ""
    timeout_s = ""
    if zmiout:
        with open(zmiout, encoding="utf-8", errors="replace") as f:
            m = re.search(r"Timeout:\s*(\d+)\s*s", f.read(4000))
        timeout_s = f"{m.group(1)} s" if m else ""

    return {
        "conv_failed": conv_failed,
        "foundry": foundry_for(rel_folder) if zmiout else None,
        "expected_verdict": expected_verdict,
        "expected_source": expected_source,
        "timeout": timeout_s,
        "name": name,
        "path": rel_folder,
        "sol": os.path.relpath(sol, REPO),
        "verdict": verdict,
        "tests": tests,
        "baseline": baseline_str,
        "status": note_key or "warn",
        "note": note_text,
        "values": values_summary,
        "expected_witness": expected_witness_from_sol(sol),
        "match_solcmc": compare_with_solcmc(expected_witness_from_sol(sol), load_json_values(folder) if zmiout else None),
        "constraints": constraints_summary,
        "classification": classification,
    }


def collect(groups_override=None):
    groups = []
    for title, rel in (groups_override if groups_override is not None else BENCHMARK_GROUPS):
        folder = os.path.join(REPO, rel)
        if not os.path.isdir(folder):
            continue
        rows = []
        for name in sorted(os.listdir(folder)):
            sub = os.path.join(folder, name)
            if not os.path.isdir(sub):
                continue
            r = row_for(folder, name)
            if r:
                rows.append(r)
        groups.append((title, rows))
    return groups


STATUS_LABEL = {"ok": "OK", "warn": "DA VERIFICARE", "bad": "PROBLEMA", "pending": "IN CODA",
                "known": "PROBLEMA NOTO", "na": "NON APPLICABILE"}


# Macro-categories for the report: every folder group is shown inside the
# benchmark it belongs to, in one table per benchmark.
MACROS = [
    ("Benchmark gas (2 ottobre): contratti con rami e loop", lambda t: t.startswith("Benchmark gas")),
    ("SolTG", lambda t: t.startswith("SolTG")),
    ("SolCMC (benchmark Solidity: smtCheckerTests)", lambda t: t.startswith("SolCMC")),
    ("TPLP", lambda t: t.startswith("TPLP")),
    ("Contratti Solidity reali e scritti a mano (Math, access control, altri)", lambda t: t.startswith("Solidity")),
    ("Proprieta' sulle variabili (test scritti da me)", lambda t: t.startswith("Proprieta") or t.startswith("Controllo ordine")),
    ("Confronto senza step 4b", lambda t: t.startswith("SENZA")),
]


# Per ora le tabelle complete sono nascoste: il report mostra i grafici e,
# cliccando su una fetta, l'elenco dei contratti con tutti i dettagli.
SHOW_TABLES = False


def merge_by_macro(groups):
    merged, used = [], set()
    for label, match in MACROS:
        rows = []
        for title, grows in groups:
            if match(title):
                used.add(title)
                sub = title.split(" - ", 1)[1] if " - " in title else title
                rows.extend(dict(r, sub=sub) for r in grows)
        if rows:
            merged.append((label, rows))
    for title, grows in groups:
        if title not in used and grows:
            merged.append((title, [dict(r, sub=title) for r in grows]))
    return merged


def macro_summary(rows):
    c = {"VP": 0, "VN": 0, "FP": 0, "FN": 0, "timeout": 0, "crash": 0, "coda": 0, "ignoto": 0}
    for r in rows:
        cl = r.get("classification", "")
        if r["status"] == "pending":
            c["coda"] += 1
        elif cl[:2] in ("VP", "VN", "FP", "FN"):
            c[cl[:2]] += 1
        elif "timeout" in cl:
            c["timeout"] += 1
        elif cl.startswith("\u2014"):
            c["crash"] += 1
        else:
            c["ignoto"] += 1
    labels = [("VP", "veri positivi"), ("VN", "veri negativi"), ("FP", "falsi positivi"),
              ("FN", "falsi negativi"), ("timeout", "timeout"), ("crash", "crash / nessun verdetto"),
              ("ignoto", "senza verita' di base"), ("coda", "in coda")]
    return " &middot; ".join(f"<b>{c[k]}</b> {v}" for k, v in labels if c[k])


def outcome(r):
    """Colour category of one contract (None = in coda / non applicabile):
      ok          verde    verdetto giusto
      valori      giallo   verdetto giusto, valori diversi da quelli attesi
                           (o mostrati in modo incompleto)
      timeout     blu      l'analisi non ha finito in tempo
      conversione marrone  il contratto non arriva al nostro interprete
                           (crash di GREY / yul-chc) o problema noto della
                           traduzione yul-chc (piu' return)
      nonconfr    grigio   differenza di modello con SolCMC o nessuna
                           risposta di riferimento
      bad         rosso    errore del nostro interprete"""
    cl = r.get("classification", "")
    note = r.get("note") or ""
    if r["status"] in ("pending", "na"):
        return None
    if r["status"] == "known":
        return None if "Differenza di modello" in note else "conversione"
    if cl[:2] in ("FP", "FN"):
        return "bad" if r["status"] == "bad" or not note else None
    if cl[:2] == "VN":
        return "ok"
    fo = r.get("foundry")
    if cl[:2] == "VP" and fo and sum(fo.values()):
        if fo["reale"] == 0:
            # same verdict as the reference (paper / June baseline), but running
            # the contract on the EVM no witness breaks the assert: the
            # reference itself was wrong (Operation_faulty: sub wraps around)
            return "smentito"
        if fo["regge"] or fo["dominio"] or fo["altro"]:
            return "valori"      # bug is real, but some witnesses are false or impossible
    if cl[:2] == "VP":
        if r["status"] != "ok":
            return "valori"      # a test or a value is really wrong (e.g. x = -200 for a uint)
        # a witness different from SolCMC's is still a valid one (all checked
        # with Foundry): green, the comparison stays visible in the panel
        return "ok"
    if cl.startswith("\u2014"):
        # stopped by hand before finishing: not a crash, it just needed more time
        if "non completato" in note.lower() or "interrott" in note.lower():
            return "timeout"
        if r.get("conv_failed"):
            return "conversione"
        return "bad"
    if "timeout" in cl:
        return "timeout"
    # no reference answer (asserts all commented out, SolCMC not run)
    return None


def outcome_reason(r):
    """Short, human explanation of the colour chosen by outcome()."""
    o = outcome(r)
    cl = r.get("classification", "")
    fo = r.get("foundry") or {}
    n = sum(fo.values()) if fo else 0
    if o == "smentito":
        return (f"Viola: il tool da' lo stesso risultato del riferimento (articolo / baseline), "
                f"ma eseguendo il contratto con Foundry con i valori trovati ({n} test) l'assert non "
                f"fallisce (nessun Panic 0x01). Era sbagliato anche il riferimento: sulla EVM il bug non c'e'.")
    if o == "bad":
        if cl.startswith("FP"):
            return "Rosso: falso positivo, il tool trova un bug che secondo il riferimento non c'e'."
        if cl.startswith("FN"):
            return "Rosso: falso negativo, il tool non trova un bug che secondo il riferimento c'e'."
        return "Rosso: crash del nostro interprete durante l'analisi."
    if o == "valori":
        if fo and n:
            return (f"Giallo: il bug c'e' (verdetto giusto), ma su Foundry solo {fo['reale']} testimoni su {n} "
                    f"fanno fallire davvero l'assert"
                    + (f"; {fo['dominio']} hanno valori impossibili per il tipo" if fo.get('dominio') else "") + ".")
        return "Giallo: verdetto giusto, ma i valori mostrati sono incompleti o sbagliati."
    if o == "conversione":
        return "Grigio: il contratto non arriva al nostro interprete (crash di GREY o di yul-chc) o problema noto della traduzione."
    if o == "timeout":
        return "Blu: l'analisi non ha finito entro il timeout, la risposta non e' nota."
    if o == "ok":
        if fo and n:
            return f"Verde: verdetto giusto e tutti i {n} testimoni confermati da Foundry (l'assert fallisce davvero)."
        return "Verde: verdetto giusto."
    return ""


PIE_ORDER = ("ok", "valori", "conversione", "timeout", "smentito", "bad")
PIE_COLORS = {"ok": "#0ca30c", "diverso": "#8fd46a", "valori": "#e8a200",
              "conversione": "#9e9e9e", "timeout": "#2a78d6", "smentito": "#8e55d4", "bad": "#d03b3b"}
PIE_ICONS = {k: "" for k in PIE_ORDER}
PIE_LABELS = {"ok": "ha funzionato", "diverso": "valido, ma valori diversi da SolCMC",
              "valori": "verdetto giusto, ma valori sbagliati",
              "conversione": "conversione non riuscita (GREY / yul-chc)",
              "timeout": "timeout",
              "smentito": "uguale all'atteso, ma smentito dall'esecuzione su EVM",
              "bad": "errore del nostro interprete"}


def pie_items(rows):
    """Per-colour contract lists (with source code) for the click panel."""
    items = {k: [] for k in PIE_ORDER}
    for r in rows:
        o = outcome(r)
        if o is None:
            continue
        try:
            with open(os.path.join(REPO, r["sol"]), encoding="utf-8", errors="replace") as f:
                src = f.read()
        except Exception:
            src = ""
        items[o].append({
            "n": r["name"], "g": r.get("sub", ""), "p": r["path"],
            "c2": ("uguale all'atteso, smentito dall'esecuzione su EVM"
                   if r.get("classification", "")[:2] == "VP" and (r.get("foundry") or {}).get("reale") == 0
                   and sum((r.get("foundry") or {}).values()) else r.get("classification", "")),
            "ev": r.get("expected_verdict", ""), "es": r.get("expected_source", ""), "to": r.get("timeout", ""),
            "ms": r.get("match_solcmc", ""),
            "why": outcome_reason(r),
            "fo": (f"{r['foundry']['reale']} testimoni reali su {sum(r['foundry'].values())}"
                   + (f" ({r['foundry']['regge']} falsi" if r['foundry']['regge'] else "")
                   + (f", {r['foundry']['dominio']} fuori dominio" if r['foundry']['dominio'] else "")
                   + (")" if r['foundry']['regge'] or r['foundry']['dominio'] else "")) if r.get("foundry") else "",
            "v": str(r["verdict"]), "t": str(r["tests"]), "c": r.get("classification", ""),
            "m": r.get("note") or "", "e": r.get("expected_witness", ""),
            "val": r.get("values", ""), "k": r.get("constraints", ""), "src": src,
        })
    for k in items:
        items[k].sort(key=lambda x: (x["g"], x["n"]))
    return items


def pie_svg(title, rows, idx=0):
    counts = {k: 0 for k in PIE_ORDER}
    pending = 0
    na = 0
    for r in rows:
        o = outcome(r)
        if r["status"] == "pending":
            pending += 1
        elif o is None:
            na += 1
        else:
            counts[o] += 1
    total = sum(counts.values())
    if total == 0:
        return ""
    import math
    cx = cy = 90
    ro, ri = 80, 48
    parts = [f"<figure class='pie'><figcaption><b>{html.escape(title)}</b><br>"
             f"<span class='muted'>{total} contratti con esito"
             + (f", {pending} in coda" if pending else "")
             + (f", {na} non confrontabili esclusi" if na else "") + "</span></figcaption>",
             "<svg viewBox='0 0 180 180' width='180' height='180' role='img' "
             f"aria-label='{html.escape(title)}'>"]
    start = -math.pi / 2
    keys = [k for k in PIE_ORDER if counts[k]]
    for k in keys:
        frac = counts[k] / total
        tip = f"{PIE_LABELS[k]}: {counts[k]} su {total} ({frac:.0%})"
        if frac >= 0.9999:
            parts.append(f"<circle class='slice' data-pie='{idx}' data-k='{k}' cx='{cx}' cy='{cy}' r='{(ro+ri)/2}' fill='none' "
                         f"stroke='{PIE_COLORS[k]}' stroke-width='{ro-ri}'><title>{tip} - clicca per l'elenco</title></circle>")
            break
        end = start + frac * 2 * math.pi
        large = 1 if end - start > math.pi else 0
        p = lambda a, rad: (cx + rad * math.cos(a), cy + rad * math.sin(a))
        x1, y1 = p(start, ro); x2, y2 = p(end, ro); x3, y3 = p(end, ri); x4, y4 = p(start, ri)
        parts.append(f"<path class='slice' data-pie='{idx}' data-k='{k}' d='M{x1:.2f},{y1:.2f} A{ro},{ro} 0 {large} 1 {x2:.2f},{y2:.2f} "
                     f"L{x3:.2f},{y3:.2f} A{ri},{ri} 0 {large} 0 {x4:.2f},{y4:.2f} Z' "
                     f"fill='{PIE_COLORS[k]}' stroke='var(--surface)' stroke-width='2'>"
                     f"<title>{tip} - clicca per l'elenco</title></path>")
        start = end
    pct = (counts["ok"] + counts.get("diverso", 0)) / total
    parts.append(f"<text x='{cx}' y='{cy-2}' text-anchor='middle' class='pie-num'>{pct:.0%}</text>"
                 f"<text x='{cx}' y='{cy+16}' text-anchor='middle' class='pie-sub'>funzionano</text></svg>")
    parts.append("<ul class='pie-legend'>")
    for k in [k for k in PIE_ORDER if counts[k]]:
        parts.append(f"<li class='slice' data-pie='{idx}' data-k='{k}' tabindex='0' role='button'>"
                     f"<span class='sw' style='background:{PIE_COLORS[k]}'></span>"
                     f"{PIE_LABELS[k]}: <b>{counts[k]}</b></li>")
    parts.append("</ul></figure>")
    return "".join(parts)


PIE_JS = """<script>
(function () {
  var data = JSON.parse(document.getElementById('pie-data').textContent);
  var panel = document.getElementById('pie-panel');
  var labels = JSON.parse(document.getElementById('pie-labels').textContent);
  var colors = JSON.parse(document.getElementById('pie-colors').textContent);
  var icons = JSON.parse(document.getElementById('pie-icons').textContent);
  function esc(s) { var d = document.createElement('div'); d.textContent = s || ''; return d.innerHTML; }
  function row(label, value) { return value ? '<div class="pp-row"><span>' + label + '</span>' + esc(value) + '</div>' : ''; }
  function show(pie, k) {
    var list = data[pie].items[k];
    var h = '<div class="pp-head"><span class="sw" style="background:' + colors[k] + '"></span>' +
            '<b>' + esc(data[pie].title) + ': ' + labels[k] + '</b> (' + list.length + ' contratti)' +
            '<button type="button" class="pp-close" aria-label="chiudi">chiudi</button></div>';
    list.forEach(function (it) {
      var crash = it.v.charAt(0) === '\u2014';
      var got = crash ? 'nessun verdetto (crash)' : it.v + ', ' + it.t + ' test';
      var exp = it.ev ? it.ev : 'non noto';
      if (it.e && it.e !== it.ev) exp += ' \u2014 ' + it.e;
      h += '<details class="pp-item"><summary><b>' + esc(it.n) + '</b> <span class="muted">' + esc(it.g) +
           ' &middot; ' + esc(crash ? 'crash' : (it.c2 || it.c)) + '</span></summary>' +
           row('Perch\u00e9 questo colore', it.why) +
           row('Risultato atteso', exp) +
           row('Atteso stabilito da', it.es) +
           row('Risultato ottenuto', got) +
           row("Timeout dell'analisi", it.to ? it.to + (it.v.indexOf('timeout') >= 0 ? ' (raggiunto: analisi non completa)' : ' (non raggiunto: analisi completa)')
                                       : (crash ? 'analisi non partita (fermato prima)' : '')) +
           row('Valori trovati', it.val || (crash ? '' : 'nessuno (nessun parametro o variabile di stato libera)')) +
           row('Vincoli trovati', it.k) +
           row('Verificato con Foundry', it.fo) +
           row('Valori = SolCMC?', it.ms) +
           row('Cartella', it.p) +
           '<pre class="pp-src">' + esc(it.src) + '</pre></details>';
    });
    panel.innerHTML = h;
    panel.hidden = false;
    panel.querySelector('.pp-close').onclick = function () { panel.hidden = true; };
    panel.scrollIntoView({behavior: 'smooth', block: 'start'});
  }
  document.querySelectorAll('.slice').forEach(function (el) {
    var go = function () { show(+el.getAttribute('data-pie'), el.getAttribute('data-k')); };
    el.addEventListener('click', go);
    el.addEventListener('keydown', function (e) { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); go(); } });
  });
})();
</script>"""


def render_html(groups):
    groups = merge_by_macro(groups)
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    n600 = sum(1 for _, rows in groups for r in rows if r.get("timeout") == "600 s")
    total = sum(len(rows) for _, rows in groups)
    ok = sum(1 for _, rows in groups for r in rows if r["status"] == "ok")
    warn = sum(1 for _, rows in groups for r in rows if r["status"] == "warn")
    bad = sum(1 for _, rows in groups for r in rows if r["status"] == "bad")
    pending = sum(1 for _, rows in groups for r in rows if r["status"] == "pending")
    vp = sum(1 for _, rows in groups for r in rows if r.get("classification", "").startswith("VP"))
    vn = sum(1 for _, rows in groups for r in rows if r.get("classification", "").startswith("VN"))
    fp = sum(1 for _, rows in groups for r in rows if r.get("classification", "").startswith("FP"))
    fn = sum(1 for _, rows in groups for r in rows if r.get("classification", "").startswith("FN"))
    unk = sum(1 for _, rows in groups for r in rows if r.get("classification", "").startswith("ignoto") or r.get("classification", "").startswith("—"))

    parts = []
    parts.append(f"""<!doctype html>
<html lang="it">
<head>
<meta charset="utf-8">
<title>{REPORT_TITLE}</title>
<style>
  body {{ font-family: -apple-system, Segoe UI, Helvetica, Arial, sans-serif; margin: 2rem; color: #1a1a1a; background: #fafafa; }}
  h1 {{ margin-bottom: 0.2rem; }}
  .meta {{ color: #666; margin-bottom: 1.5rem; }}
  .summary {{ display: flex; gap: 1rem; margin-bottom: 2rem; }}
  .summary .card {{ padding: 0.8rem 1.2rem; border-radius: 8px; font-weight: 600; }}
  .card.ok {{ background: #e6f4ea; color: #1e7e34; }}
  .card.warn {{ background: #fff3cd; color: #8a6100; }}
  .card.bad {{ background: #fbe4e4; color: #a41818; }}
  :root {{ --surface: #fafafa; }}
  .cmdline {{ background: #e9e9e9; color: #333; padding: 0.5rem 0.8rem; border-radius: 6px; font-size: 0.85rem; margin: 0.5rem 0 1rem; white-space: normal; word-break: break-all; }}
  .cmdline code {{ background: none; user-select: all; }}
  .cmd {{ background: #1e1e1e; color: #e6e6e6; padding: 0.8rem 1rem; border-radius: 6px; font-size: 0.85rem; overflow-x: auto; user-select: all; }}
  code {{ background: #eee; padding: 0 0.3rem; border-radius: 3px; }}
  .pies {{ display: flex; flex-wrap: wrap; gap: 1.5rem; margin: 1rem 0 2rem; }}
  .pie {{ margin: 0; background: white; padding: 1rem; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); --surface: white; width: 220px; }}
  .pie figcaption {{ font-size: 0.9rem; margin-bottom: 0.5rem; }}
  .pie .muted {{ color: #666; font-size: 0.8rem; }}
  .pie-num {{ font-size: 26px; font-weight: 700; fill: #1a1a1a; }}
  .pie-sub {{ font-size: 11px; fill: #666; }}
  .pie-legend {{ list-style: none; padding: 0; margin: 0.5rem 0 0; font-size: 0.82rem; color: #1a1a1a; }}
  .pie-legend li {{ margin: 0.2rem 0; }}
  .slice {{ cursor: pointer; }}
  path.slice:hover, circle.slice:hover {{ opacity: 0.8; }}
  .pie-legend li.slice:hover {{ text-decoration: underline; }}
  #pie-panel {{ background: white; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.15); padding: 1rem 1.2rem; margin-bottom: 2rem; }}
  .pp-head {{ display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.8rem; font-size: 1rem; }}
  .pp-head .sw {{ display: inline-block; width: 12px; height: 12px; border-radius: 2px; }}
  .pp-close {{ margin-left: auto; border: 1px solid #ccc; background: #f5f5f5; border-radius: 4px; padding: 0.2rem 0.7rem; cursor: pointer; }}
  .pp-item {{ border-top: 1px solid #eee; padding: 0.4rem 0; }}
  .pp-item summary {{ cursor: pointer; }}
  .pp-item .muted {{ color: #666; font-size: 0.85rem; }}
  .pp-row {{ font-size: 0.85rem; margin: 0.3rem 0 0 1rem; }}
  .pp-row span {{ display: inline-block; min-width: 150px; color: #666; font-weight: 600; }}
  .pp-src {{ background: #f6f8fa; border: 1px solid #e5e5e5; border-radius: 6px; padding: 0.7rem; margin: 0.5rem 0 0 1rem; font-size: 0.8rem; overflow-x: auto; }}
  .pie-legend .sw {{ display: inline-block; width: 10px; height: 10px; border-radius: 2px; margin-right: 6px; vertical-align: middle; }}
  .status.known, .status.na {{ background: #eceff3; color: #555; }}
  .card.pending, .status.pending {{ background: #eceff3; color: #555; }}
  h2 {{ margin-top: 2.5rem; border-bottom: 2px solid #ddd; padding-bottom: 0.3rem; }}
  table {{ border-collapse: collapse; width: 100%; margin-top: 0.8rem; background: white; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }}
  th, td {{ border: 1px solid #e0e0e0; padding: 0.5rem 0.6rem; text-align: left; vertical-align: top; font-size: 0.88rem; }}
  th {{ background: #f0f0f0; position: sticky; top: 0; }}
  tr:nth-child(even) {{ background: #fbfbfb; }}
  .status {{ font-weight: 700; padding: 0.15rem 0.5rem; border-radius: 4px; display: inline-block; white-space: nowrap; }}
  .status.ok {{ background: #e6f4ea; color: #1e7e34; }}
  .status.warn {{ background: #fff3cd; color: #8a6100; }}
  .status.bad {{ background: #fbe4e4; color: #a41818; }}
  .cls {{ font-weight: 700; padding: 0.15rem 0.5rem; border-radius: 4px; display: inline-block; white-space: nowrap; font-size: 0.82rem; }}
  .cls-vp {{ background: #e6f4ea; color: #1e7e34; }}
  .cls-vn {{ background: #e6f0fb; color: #1a4d8a; }}
  .cls-fp {{ background: #fbe4e4; color: #a41818; }}
  .cls-fn {{ background: #f8d7da; color: #7a1020; }}
  .cls-unk {{ background: #eee; color: #666; }}
  .path, .values {{ font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 0.78rem; color: #444; }}
  .note {{ color: #444; }}

</style>
</head>
<body>
<h1>{REPORT_TITLE}</h1>
<div class="meta">Generato il {now} — {total} contratti testati — timeout dell'analisi: 60 s ({n600} contratti andati in timeout sono stati ritentati a 600 s)</div>
<div class="cmdline"><b>COMANDO:</b> <code>nohup bash script/sol2analysis.sh --gen-aux --aux-hint _f_ --varz3 --varclpq --timeout 60 cartella/Contratto/Contratto.sol incorrect &gt; Contratto.log 2&gt;&amp;1 &amp;</code></div>
{EXTRA_META}
""")

    pie_sets = []
    real = [(t, r) for t, r in groups if not t.startswith("Confronto senza")]
    if len(real) > 1:
        pie_sets.append(("Totale", [x for _, rs in real for x in rs]))
    for label, short in (("Benchmark gas", "Benchmark gas (2 ottobre)"),
                         ("SolCMC", "SolCMC (test del compilatore Solidity)"),
                         ("SolTG", "SolTG"),
                         ("Contratti Solidity", "Contratti Solidity (Math, scritti a mano, access control)"),
                         ("TPLP", "TPLP"),
                         ("Proprieta'", "Proprieta' sulle variabili")):
        for t, rs in real:
            if t.startswith(label):
                pie_sets.append((short, rs))
    if pie_sets:
        if HOW_TO_READ:
            parts.append(HOW_TO_READ)
        parts.append("<h2 style='margin-top:1rem;'>Esito dei test in sintesi</h2>")
        parts.append("<div class='pies'>" + "".join(pie_svg(t, rs, i) for i, (t, rs) in enumerate(pie_sets)) + "</div>")
        data = [{"title": t, "items": pie_items(rs)} for t, rs in pie_sets]
        parts.append("<div id='pie-panel' hidden></div>")
        parts.append("<script type='application/json' id='pie-labels'>" + json.dumps(PIE_LABELS) + "</script>")
        parts.append("<script type='application/json' id='pie-colors'>" + json.dumps(PIE_COLORS) + "</script>")
        parts.append("<script type='application/json' id='pie-icons'>" + json.dumps(PIE_ICONS) + "</script>")
        parts.append("<script type='application/json' id='pie-data'>"
                     + json.dumps(data).replace("</", "<\\/") + "</script>")
        # --no-foundry: drop the (always empty) Foundry row from the panel code
        parts.append(PIE_JS.replace("row('Verificato con Foundry', it.fo) +", "") if NO_FOUNDRY else PIE_JS)

    for title, rows in (groups if SHOW_TABLES else []):
        if not rows:
            continue
        parts.append(f"<h2>{html.escape(title)} ({len(rows)} contratti)</h2>")
        parts.append(f"<div class='meta'>{macro_summary(rows)}</div>")
        parts.append("<table><thead><tr>"
                      "<th>File</th><th>Sottogruppo</th><th>Percorso</th><th>Verdetto</th><th>Timeout</th><th>Test</th>"
                      "<th>Classificazione</th><th>Stato</th><th>Atteso (dal sorgente)</th><th>Valori = SolCMC?</th><th>Valori (dal JSON)</th>"
                      "<th>Vincoli proiettati CLP(Q)</th>"
                      "</tr></thead><tbody>")
        for r in rows:
            cls = r.get('classification', '')
            cclass = "cls-vp" if cls.startswith("VP") else \
                     "cls-vn" if cls.startswith("VN") else \
                     "cls-fp" if cls.startswith("FP") else \
                     "cls-fn" if cls.startswith("FN") else "cls-unk"
            parts.append("<tr>")
            parts.append(f"<td><strong>{html.escape(r['name'])}</strong></td>")
            parts.append(f"<td>{html.escape(r.get('sub', ''))}</td>")
            parts.append(f"<td class='path'>{html.escape(r['path'])}</td>")
            parts.append(f"<td>{html.escape(str(r['verdict']))}</td>")
            parts.append(f"<td>{html.escape(r.get('timeout', ''))}</td>")
            parts.append(f"<td>{html.escape(str(r['tests']))}</td>")
            parts.append(f"<td><span class='cls {cclass}'>{html.escape(cls)}</span></td>")
            parts.append(f"<td><span class='status {r['status']}'>{STATUS_LABEL.get(r['status'], r['status'])}</span></td>")
            parts.append(f"<td class='values'>{html.escape(r.get('expected_witness', ''))}</td>")
            _m = r.get('match_solcmc', '')
            _col = '#1e7e34' if _m == 'si' else ('#a41818' if _m.startswith('no') else '#444')
            parts.append(f"<td style='color:{_col};font-weight:600'>{html.escape(_m)}</td>")
            parts.append(f"<td class='values'>{html.escape(r['values'])}</td>")
            parts.append(f"<td class='values'>{html.escape(r.get('constraints', ''))}</td>")
            parts.append("</tr>")
        parts.append("</tbody></table>")

    parts.append("</body></html>")
    return "\n".join(parts)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=os.path.join(REPO, ORG, "report", "report_28settembre.html"))
    ap.add_argument("--folder", action="append",
                    help="Cartella (relativa alla repo) da usare al posto di BENCHMARK_GROUPS; si puo' ripetere")
    ap.add_argument("--title", action="append", help="Titolo del gruppo, uno per ogni --folder")
    ap.add_argument("--no-foundry", action="store_true", help="Ignora i risultati di Foundry")
    ap.add_argument("--ottobre", action="store_true",
                    help="Solo benchmark gas del 2/10, SolTG, SolCMC (smtCheckerTests di Solidity) e proprieta' sulle variabili")
    args = ap.parse_args()

    global NO_FOUNDRY, REPORT_TITLE, EXTRA_META
    NO_FOUNDRY = args.no_foundry
    global HOW_TO_READ
    if args.ottobre:
        REPORT_TITLE = "Report test: benchmark gas, SolTG, SolCMC, proprieta' sulle variabili"

    # REPORT_NOTE: optional line shown in the title and under the header
    note = os.environ.get("REPORT_NOTE", "")
    if note:
        REPORT_TITLE = REPORT_TITLE + " (" + note + ")"
        EXTRA_META = EXTRA_META + "<div class='meta'><b>" + html.escape(note) + "</b></div>\n"

    groups_override = None
    if args.folder:
        titles = args.title or []
        groups_override = [(titles[i] if i < len(titles) else f, f) for i, f in enumerate(args.folder)]
    elif args.ottobre:
        groups_override = [("Benchmark gas (2 ottobre)", GAS_OTT)] + [
            (t, f) for t, f in BENCHMARK_GROUPS
            if t.startswith("SolTG") or t.startswith("SolCMC") or t.startswith("Proprieta")]

    groups = collect(groups_override)
    out = render_html(groups)
    with open(args.output, "w", encoding="utf-8") as f:
        f.write(out)
    print(f"Report scritto in: {args.output}")


if __name__ == "__main__":
    main()
