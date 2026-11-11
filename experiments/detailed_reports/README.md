# Detailed reports

Working reports of the evaluation (labels in Italian). One row per contract (222),
column `escluso` marks the 16 contracts with tuples or casts (excluded in the thesis).

| file | content |
|---|---|
| `confronto_tool.html` | comparison of all tools on both benchmarks, with Foundry results (open in a browser) |
| `riepilogo.csv` | totals per benchmark and tool, on all 222 contracts and on the 206 without tuples/casts |
| `per_tool/noi_solcmc.csv`, `per_tool/noi_yul2chc.csv` | SmartHornTest, SolCMC and yul2chc routes: outcome, tests, time, Foundry |
| `per_tool/soltg.csv` | SolTG (official version): outcome, generated tests, pass, panic, time |
| `per_tool/mythril.csv`, `per_tool/manticore.csv` | Mythril and Manticore: outcome, time |
| `tutti_i_tool.csv` | all tools in one table |
| `loop_percorsi.csv` | contracts with loops: tests of SmartHornTest and SolTG |
| `errori_per_categoria.csv` | wrong or missing answers, by category, with the cause |
| `report_chccomp.html`, `chccomp.csv` | meta-interpreter on CHC-COMP 2024 (LIA, LIA-Lin) against Z3 |

Outcome codes: ok/giusto = correct, fn = bug missed, fp = false alarm, nonanalizzato = not analyzed.
