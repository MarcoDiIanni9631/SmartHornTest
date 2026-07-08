% ================================================================
%  File: main.pl
%  Autore: Marco Di Ianni
%  Descrizione:
%    Questo file rappresenta il modulo principale del meta-interprete
%    sviluppato per l'analisi simbolica di programmi tradotti in Prolog
%    da file SMT-LIB (tramite smt2map).
%
%  Esecuzione:
%    swipl -s main.pl -- <file.smt2.pl> <ff|incorrect>
%
% ================================================================


% =============================
%  Librerie e moduli importati
% =============================

:- use_module(library(dcg/basics)).
:- use_module(library(clpq)).
:- use_module(logic_utils).
:- use_module(io).

:- dynamic input_names/1.
:- dynamic test_counter/1.
:- dynamic loop_limit/1.
:- dynamic skip_pred/1.
:- dynamic sat_found_positive/1. % sat_found_positive(F/A) — trovato test positivo (vgood) per questo pred ricorsivo
:- dynamic sat_found_negative/1. % sat_found_negative(F/A) — trovato test negativo per questo pred ricorsivo
:- dynamic stop_per_loop/0.   % flag: --stop-first-per-loop attivo
:- discontiguous zmi_aux/10.

% -------------------------------------------------------------
% Loop detection: limite di unfolding per predicato
%
% loop_limit(K) — ogni predicato (functor/arità) può comparire al
% massimo K volte nella call trace del cammino corrente.
% K=1 → nessun loop: ogni predicato è eseguito al più una volta
%        per cammino (produce al massimo un test per cammino strutturale).
% K=2 → una iterazione di loop permessa, ecc.
% Impostato dinamicamente all'avvio tramite set_loop_limit/1.
% -------------------------------------------------------------
loop_limit(2000).

set_loop_limit(K) :-
    retractall(loop_limit(_)),
    assertz(loop_limit(K)).

% calls_count(+Calls, +F, +A, -N)
% Conta quante volte il predicato F/A compare nella lista Calls.
calls_count([], _, _, 0).
calls_count([Call | Rest], F, A, N) :-
    (   functor(Call, F, A)
    ->  calls_count(Rest, F, A, N0), N is N0 + 1
    ;   calls_count(Rest, F, A, N)
    ).


% -------------------------------------------------------------
% Contatore dei test (progressivo)
%
% reset_test_counter/0  azzera il contatore.
% next_test_id(-Id)     incrementa e restituisce l’id del test corrente.
% Serve per stampare risultati numerati quando troviamo rami SAT.
% -------------------------------------------------------------

reset_test_counter :-
    retractall(test_counter(_)),
    assertz(test_counter(0)).

next_test_id(Id) :-
    retract(test_counter(N)),
    Id is N + 1,
    assertz(test_counter(Id)).

% -------------------------------------------------------------
% Scelta del solver e caricamento moduli
%
% Imposta il solver da utilizzare (turibe o vidal) e carica
% i moduli necessari per interfacciarsi con Z3 e CLPQ.
% Di default viene attivato il solver 'turibe' all'avvio.
% -------------------------------------------------------------
set_solver(turibe) :-
    getenv('SWIZ3_TURIBE_PATH', Z3Path),
    assertz(file_search_path(z3lib, Z3Path)),
    use_module('../solvers/solver_turibe'),
    use_module(z3lib(z3)).

% -------------------------------------------------------------
% set_solver(+Solver)
%
% Configura a runtime il backend Z3.
% - turibe: usa la libreria Z3 tramite wrapper "solver_turibe"
%   e path SWIZ3_TURIBE_PATH (env var).
% Nota: viene inizializzato automaticamente all’avvio (now).
% -------------------------------------------------------------


:- initialization(set_solver(turibe), now).

:- use_module('../solvers/solver_turibe',
              [ z3_sat_check/4,
                z3constr2lower/3,      
                enable_debug/0, disable_debug/0, debug_print/1, debug_print/2
              ]).
:- use_module('../solvers/solver_clpq', [clpq_sat_from_formula/1]).

% init_input_names(CFile) :-
%     retractall(input_names(_)),
%     extract_input_names(CFile, Names),
%     InputNames = [vgood | Names],
%     assertz(input_names(InputNames)),
%     format("📥 Input variables from C: ~w~n", [InputNames]).
% % ----------------------------
% % Custom logical operators
% % ----------------------------

% :- op(1000, yfx, &).   % and
% :- op(1000, yfx, v).   % or
% :- op(1000, yfx, or).  % alternative or
% :- op(900,  fy, ~).    % not

% -------------------------------------------------------------
% Disabilitazione operatori logici infissi (and/or/&/v)
%
% I file generati possono contenere simboli che interferiscono con
% operatori definiti globalmente da SWI-Prolog o da librerie.
% Impostando precedenza 0, evitiamo parsing ambiguo e forziamo
% l’uso della rappresentazione a termini (più controllabile).
% -------------------------------------------------------------

% --- Disable all logical infix operators globally ---
:- op(0, xfx, or).
:- op(0, yfx, or).
:- op(0, xfy, or).
:- op(0, fy, or).
:- op(0, fx, or).
:- op(0, xf, or).

:- op(0, xfx, and).
:- op(0, yfx, and).
:- op(0, xfy, and).
:- op(0, fy, and).
:- op(0, fx, and).
:- op(0, xf, and).

:- op(0, xfx, &).
:- op(0, yfx, &).
:- op(0, xfy, &).
:- op(0, fy, &).
:- op(0, fx, &).
:- op(0, xf, &).

:- op(0, xfx, v).
:- op(0, yfx, v).
:- op(0, xfy, v).
:- op(0, fy, v).
:- op(0, fx, v).
:- op(0, xf, v).

:- op(900, fy, ~).

% ----------------------------
% Entry point for collecting ALL SAT branches
% --------------------------

% -------------------------------------------------------------
% Predicato principale: zmi(+Head)
%
% Esegue l’analisi simbolica del predicato Head impostando
% il solver Turibe e un limite massimo di profondità (MaxDepths).
% Usa zmi_branch_sat/3 per esplorare tutti i percorsi logici
% fino a trovare i rami soddisfacibili (SAT), poi stampa i modelli.
% -------------------------------------------------------------



% -------------------------------------------------------------
% zmi(+Head)
%
% Entry point dell’analisi simbolica.
%
% Versione attiva:
%   esegue una singola esplorazione tramite zmi_branch_sat/3
%   (utile per debugging e per fermarsi al primo SAT).

% -------------------------------------------------------------


% Wrapper per compatibilità: zmi/2 accetta MaxDepths
zmi(Head, MaxDepths) :-
    zmi(Head, MaxDepths, false).

zmi(Head) :-
    zmi(Head, 10000000, false).

zmi(Head, MaxDepths, StopFirst) :-
    set_solver(turibe),
    reset_test_counter,
    retractall(sat_found_positive(_)),
    retractall(sat_found_negative(_)),
    ( StopFirst == true ->
        ( zmi_branch_sat((Head; falseVerimap), MaxDepths, _) -> true ; true ),
        ( test_counter(0) -> format('No SAT branches found in MaxDepths = ~w.\n', [MaxDepths]) ; true )
    ;
        findall(Model,
                zmi_branch_sat((Head; falseVerimap), MaxDepths, Model),
                Models),
        ( Models == [] ->
            format('No SAT branches found in MaxDepths = ~w.\n', [MaxDepths])
        ;
            true
        )
    ).



    
% -------------------------------------------------------------
% Stampa dei modelli soddisfacenti (SAT)
%
% print_all_models/1  stampa in sequenza tutti i modelli trovati.
% print_single_model/1  mostra i vincoli CLPQ risolti e
% il modello finale calcolato dal solver Z3.
% -------------------------------------------------------------

print_all_models([]).
print_all_models([M|Rest]) :-
    writeln('--- SAT MODEL ---'),
    print_single_model(M), nl,
    print_all_models(Rest).



print_single_model(model(_, _, _Calls, _)) :-
    true.
    % writeln('CALL TRACE:'),
    % writeln(Calls),
    % % nl,
    % writeln('--- CLPQ Constraints ---'),
    % clpq_sat_from_formula(FinalCLPQ),
    % nl,
    % writeln('--- FINAL MODEL (Z3) ---'),
    % writeln(FinalZ3).



% -------------------------------------------------------------
% zmi_branch_sat(+Head, +MaxDepths, -Model)
%
% Esegue una derivazione simbolica partendo da Head.
% Stato simbolico:
%   - Z3 formula corrente (FinalZ3)
%   - CLPQ formula corrente (FinalCLPQ)
%   - Call trace (FinalCalls)
%   - Albero di derivazione (Tree)
%
% Dopo la derivazione:
%   - verifica SAT su FinalZ3 (z3_sat_check/4)
%   - costruisce un test-id progressivo
%   - estrae variabili di input dal primo predicato con arità > 0
%   - lega i nomi input_names/1 ai valori del modello Z3
%
% Nota: assume che il primo predicato con arità > 0 rappresenti la “firma input”.
% -------------------------------------------------------------


zmi_branch_sat(Head, MaxDepths, model(FinalZ3, FinalCLPQ, FinalCalls, Tree)) :-

    InitialZ3   = true,
    InitialCLPQ = true,
    InitialCalls = [],

    zmi_aux(Head, InitialZ3, InitialCLPQ, [], InitialCalls, MaxDepths,
            FinalZ3, FinalCLPQ, FinalCalls, Tree),

    % Verifica SAT
    z3_sat_check(FinalZ3, sat, ModelPretty, _Pairs),

    get_dict(constants, ModelPretty, Consts),
    classify_test_from_vmapgood_consts(Consts, TestResult),

    % Filtro duplicati: se stop_per_loop è attivo e questo tipo di test
    % (positivo o negativo) è già stato trovato per i predicati ricorsivi
    % di questa derivazione, scarta il test (fail → findall backtraca).
    ( stop_per_loop, is_duplicate_test_type(FinalCalls, TestResult) -> fail ; true ),

    % Marca i predicati ricorsivi come "già trovato SAT" (se --stop-first-per-loop)
    % distinguendo tra test positivi (vgood) e negativi
    mark_loop_preds(FinalCalls, TestResult),

    next_test_id(TestId),
    nl,
    format('================ TEST #~w =================~n', [TestId]),
    nl,
    format('✅ INCORRECT/FF FOUND: ~w~n', [FinalZ3]),
    nl,nl,
    %Recupero primo predicato con arità diversa da 0
    first_nonzero_arity_atom(FinalCalls, FirstCall),
   % writeln('first non zero arity fatto'),
    % writeln('Stampo FinalCalls'),
    % writeln(FinalCalls),
    % writeln('Stampo FirstCAll'),
    % writeln(First),
    
        
    
    %Estraggo le variabili argomento del predicato con arità diversa da 0
    extract_var_list(FirstCall, VarList),
    % writeln('estrazione fatta'),
    % writeln('stampo Varlist'),
    % writeln(VarList),




    %Costruisco le coppie
    extract_values_from_model(VarList, Consts, ValueList),
    writeln('RISULTATO TEST:'),
    writeln(TestResult),
    % Stampa finale della CALL TRACE simbolica
    format("\n📌 CALL TRACE :\n", []),
    % writeln(FinalCalls),
    print_call_trace_symbolic(FinalCalls),
    % Stampa del vincolo finalZ3
    format('\nMODELLO Z3:\n', []),
    writeln(ModelPretty),
    nl,nl,
input_names(Names),
writeln('Stampo nomi'),
    writeln(Names),
writeln('Stampo ValueList'),
    writeln(ValueList),
bind_named_inputs(Names, ValueList, InputBindings),
nl,
writeln('INPUT BINDINGS :'),
writeln(InputBindings),
    format('\n============================================\n\n', []).


% is_duplicate_test_type(+Calls, +TestResult)
% Vero se in questa derivazione c'è almeno un predicato ricorsivo (che appare
% >= 2 volte) per cui abbiamo già trovato un test dello stesso tipo (positivo
% o negativo). Usato per scartare test ridondanti quando --stop-first-per-loop
% è attivo.
is_duplicate_test_type(Calls, testVerimapGood) :-
    member(Call, Calls),
    functor(Call, F, A),
    calls_count(Calls, F, A, N),
    N >= 2,
    is_directly_recursive(F/A),
    sat_found_positive(F/A), !.
is_duplicate_test_type(Calls, TestResult) :-
    TestResult \= testVerimapGood,
    member(Call, Calls),
    functor(Call, F, A),
    calls_count(Calls, F, A, N),
    N >= 2,
    is_directly_recursive(F/A),
    sat_found_negative(F/A), !.

% mark_loop_preds(+Calls, +TestResult)
% Se --stop-first-per-loop è attivo, marca i predicati ricorsivi che compaiono
% >= 2 volte nella call trace come "SAT trovato" per il tipo di test corrente
% (positivo/vgood o negativo). Il ramo viene tagliato solo quando ENTRAMBI i
% tipi sono stati trovati per quel predicato.
mark_loop_preds(Calls, TestResult) :-
    ( stop_per_loop ->
        forall(
            ( member(Call, Calls),
              functor(Call, F, A),
              calls_count(Calls, F, A, N),
              N >= 2,
              is_directly_recursive(F/A) ),
            mark_loop_pred_by_type(F/A, TestResult)
        )
    ; true ).

mark_loop_pred_by_type(FA, testVerimapGood) :-
    ( \+ sat_found_positive(FA) -> assertz(sat_found_positive(FA)) ; true ).
mark_loop_pred_by_type(FA, _) :-
    ( \+ sat_found_negative(FA) -> assertz(sat_found_negative(FA)) ; true ).

% is_directly_recursive(+F/A)
% Vero se il predicato F/A ha almeno una clausola che chiama F/A nel corpo.
is_directly_recursive(F/A) :-
    functor(Head, F, A),
    clause(Head, Body),
    body_contains_pred(Body, F, A),
    !.

body_contains_pred((G, Rest), F, A) :-
    !,
    ( functor(G, F, A) -> true
    ; body_contains_pred(G, F, A)
    ; body_contains_pred(Rest, F, A)
    ).
body_contains_pred(G, F, A) :-
    functor(G, F, A).


% ----------------------------
% Interpreter rules
% ----------------------------


% -------------------------------------------------------------
% zmi_aux(+Goal, +Z3In, +CLPQIn, +SymTabIn, +CallsIn, +Steps,
%         -Z3Out, -CLPQOut, -CallsOut, -Tree)
%
% Meta-interprete simbolico.
% - Propaga vincoli Z3 e CLPQ lungo la derivazione
% - Mantiene una tabella di tipi (SymTab) ricostruita dai pred_arg/3
% - Accumula la call trace (CallsOut)
%
% Steps è il budget di profondità (MaxDepths).
% -------------------------------------------------------------


% -------------------------------------------------------------
% Caso base: zmi_aux/8 con goal true
%
% Se il goal è true, termina la ricorsione restituendo
% i vincoli correnti Z3 e CLPQ senza modificarli.
% -------------------------------------------------------------

% zmi_aux(true, Z3, CLPQ,_, _, Z3, CLPQ, true).
zmi_aux(true, Z3, CLPQ,_, Calls, _, Z3, CLPQ, Calls, true).

% -------------------------------------------------------------
% Gestione della disgiunzione ( ; )
%
% Serve a gestire correttamente la
% terminazione dell'intero albero 
% distingue branch da analizzare e falseVerimap 
% per individuare la fine dell'esplorazione dell'albero senza
% interrompere l’esplorazione complessiva.
% -------------------------------------------------------------
zmi_aux((G ; _), Z3In, CLPQIn, SymTab, CallsIn, Steps,Z3Out, CLPQOut, CallsOut,Tree) :-
    zmi_aux(G, Z3In, CLPQIn, SymTab, CallsIn, Steps,Z3Out, CLPQOut, CallsOut,Tree).

zmi_aux((_ ; G), Z3In, CLPQIn, SymTab, CallsIn, Steps,Z3Out, CLPQOut, CallsOut,Tree) :-
    zmi_aux(G, Z3In, CLPQIn, SymTab, CallsIn, Steps,Z3Out, CLPQOut, CallsOut,Tree).
% -------------------------------------------------------------
% Caso di terminazione: falseVerimap
% falseVerimap stampa e poi fail per forzare backtracking 
% sulla disgiunzione e quindi “segnare fine albero” senza produrre modello
% Quando viene raggiunto, la ricorsione si arresta
% -------------------------------------------------------------
zmi_aux(falseVerimap, Z3, CLPQ, _, _, _, Z3, CLPQ,_, false) :-
    nl, nl,
    writeln('Ho raggiunto la terminazione dell\'albero'), 
    nl, nl,
    fail.

% -------------------------------------------------------------
% Caso di arresto per profondità massima
%
% Interrompe la ricorsione quando il numero di passi
% supera il limite impostato (MaxDepths), evitando loop infiniti.
% -------------------------------------------------------------

zmi_aux(_, _, _, _, _,0, _, _, _, _) :- 
    writeln('Limite MaxDepth raggiunto'),
    fail.

% -------------------------------------------------------------
% Gestione della congiunzione (A, B)
%
% Esegue i due goal in sequenza, propagando i vincoli Z3 e CLPQ
% dal primo al secondo. 
% -------------------------------------------------------------
% zmi_aux((A, B), Z3In, CLPQIn,SymTab, CallsIn, Steps, Z3Out, CLPQOut, (TreeA, TreeB)) :-
%     zmi_aux(A, Z3In, CLPQIn,SymTab, Steps, TempZ3, TempCLPQ, TreeA),
%     zmi_aux(B, TempZ3, TempCLPQ,SymTab, Steps, Z3Out, CLPQOut, TreeB).


zmi_aux((A, B), Z3In, CLPQIn, SymTab, CallsIn, Steps,
        Z3Out, CLPQOut, CallsOut,
        (TreeA, TreeB)) :-

    zmi_aux(A, Z3In, CLPQIn, SymTab, CallsIn, Steps,
            TempZ3, TempCLPQ, CallsMid, TreeA),

    zmi_aux(B, TempZ3, TempCLPQ, SymTab, CallsMid, Steps,
            Z3Out, CLPQOut, CallsOut, TreeB).

% -------------------------------------------------------------
% Gestione dei vincoli: constr(C)
%
% Normalizza il vincolo logico C e lo integra nei vincoli
% correnti di Z3 e CLPQ. Combina inoltre le annotazioni di tipo
% provenienti dalla SymTab per costruire vincoli tipizzati
% (Var:Type = Var:Type). Il vincolo finale viene verificato
% in Z3 tramite z3_sat_check/3.
% -------------------------------------------------------------

%ex version correct
% zmi_aux(constr(C), Z3In, CLPQIn, SymTab, CallsIn, _Steps,
%         Z3Out, CLPQOut, CallsOut,
%         constr(Normalized)) :-

%     CallsOut = CallsIn,
%     normalize_bool_expr(C, Normalized),
%     build_conjunct([CLPQIn, Normalized], CLPQTmp),
%     build_conjunct([Z3In, Normalized], Z3Tmp),
%     build_type_equality_list(SymTab, TypeAnnots),
%     conj_to_list(Z3Tmp, Z3List),
%     append(TypeAnnots, Z3List, FlatList),
%     build_conjunct(FlatList, Z3Final),
%     Z3Out  = Z3Final,
%     CLPQOut = CLPQTmp,
%     z3_sat_check(Z3Final, sat, _,_).


% zmi_aux(constr(C), Z3In, CLPQIn, SymTab, CallsIn, _Steps,
%         Z3Out, CLPQOut, CallsOut,
%         constr(Normalized)) :-

%     CallsOut = CallsIn,
%     normalize_bool_expr(C, Normalized),
%     build_conjunct([CLPQIn, Normalized], CLPQTmp),
%     build_conjunct([Z3In,  Normalized], Z3Tmp),

%     build_type_equality_list(SymTab, TypeAnnots),

%     conj_to_list(Z3Tmp, Z3List0),
%     strip_type_equalities(Z3List0, Z3CoreList),

%     append(TypeAnnots, Z3CoreList, FlatList),
%     build_conjunct(FlatList, Z3Final),

%     Z3Out   = Z3Final,
%     CLPQOut = CLPQTmp,
%     z3_sat_check(Z3Final, sat, _, _).

zmi_aux(constr(C), Z3In, CLPQIn, SymTab, CallsIn, _Steps,
        Z3Out, CLPQOut, CallsOut,
        constr(Normalized)) :-

    CallsOut = CallsIn,
normalize_bool_expr(C, Normalized),

% ---- CLPQ resta come prima ----
build_conjunct([CLPQIn, Normalized], CLPQTmp),

% 1. Trasformo Z3In in lista piatta
conj_to_list(Z3In, Z3ListIn),

% 2. Aggiungo il nuovo vincolo
append(Z3ListIn, [Normalized], Z3ListTmp),

% 3. Aggiungo type annotations
build_type_equality_list(SymTab, TypeAnnots),
append(TypeAnnots, Z3ListTmp, Z3ListWithTypes),

% 4. Rimuovo duplicati veri
sort(Z3ListWithTypes, Z3ListNoDup),

% 5. Ricostruisco formula piatta
build_conjunct(Z3ListNoDup, Z3Final),

Z3Out   = Z3Final,
CLPQOut = CLPQTmp,

z3_sat_check(Z3Final, sat, _, _).


% zmi_aux(Head, Z3In, CLPQIn, _SymTabIn, CallsIn, Steps,
%         Z3Out, CLPQOut, CallsOut,
%         skip(Head)) :-

%     Steps > 0,
%     Head \= true,
%     Head \= (_, _),
%     Head \= constr(_),

%     functor(Head, HeadF, HeadA),s" — e
%     skip_pred(HeadF),
%     !,

%     calls_count(CallsIn, HeadF, HeadA, HeadCount),
%     loop_limit(LoopK),
%     ( HeadCount >= LoopK ->
%         ( debug_print('Loop rilevato, taglio il ramo'),
%           debug_print(Head),
%           fail )
%     ; true ),

%     debug_print('Esecuzione diretta (skip):'),
%     debug_print(Head),

%     append(CallsIn, [Head], CallsOut),

%     clause(Head, RawBody),
%     extract_skip_constr(RawBody, SkipC),

%     format("~n=== SKIP: ~w ===~n", [HeadF]),
%     format("  Constraint: ~w~n", [SkipC]),
%     format("  Head PRIMA: ~w~n", [Head]),
%     format("  Z3 PRIMA:   ~w~n", [Z3In]),

%     zmi_skip_body(RawBody, Z3In, CLPQIn, Z3Out, CLPQOut),

%     format("  Head DOPO:  ~w~n", [Head]),
%     format("  Z3 DOPO:    ~w~n", [Z3Out]),
%     format("  (vincolo aggiunto a Z3 senza SAT check)~n", []).


% extract_skip_constr(constr(C), C) :- !.
% extract_skip_constr((constr(C), _), C) :- !.
% extract_skip_constr(Body, Body).


% zmi_skip_body(true, Z3, CLPQ, Z3, CLPQ) :- !.
% zmi_skip_body((A, B), Z3In, CLPQIn, Z3Out, CLPQOut) :- !,
%     zmi_skip_body(A, Z3In, CLPQIn, Z3Mid, CLPQMid),
%     zmi_skip_body(B, Z3Mid, CLPQMid, Z3Out, CLPQOut).
% zmi_skip_body(constr(C), Z3In, CLPQIn, Z3Out, CLPQOut) :- !,
%     normalize_bool_expr(C, Normalized),
%     build_conjunct([CLPQIn, Normalized], CLPQOut),
%     conj_to_list(Z3In, Z3ListIn),
%     append(Z3ListIn, [Normalized], Z3ListTmp),
%     build_conjunct(Z3ListTmp, Z3Out),
%     call(C).
% zmi_skip_body(Goal, Z3In, CLPQIn, Z3Out, CLPQOut) :-
%     clause(Goal, Body),
%     zmi_skip_body(Body, Z3In, CLPQIn, Z3Out, CLPQOut).


zmi_aux(Head, Z3In, CLPQIn, SymTabIn, CallsIn, Steps,
        Z3Out, CLPQOut, CallsOut,
        SubTree => HeadCopy) :-

    Steps > 0,
    Head \= true,
    Head \= (_, _),
    Head \= constr(_),

    %  Loop detection 
    % Se il predicato corrente compare già K volte nella call trace
    % del cammino corrente, taglia il ramo (loop rilevato).
    functor(Head, HeadF, HeadA),
    calls_count(CallsIn, HeadF, HeadA, HeadCount),
    loop_limit(LoopK),
    ( HeadCount >= LoopK ->
        (debug_print('Loop rilevato, taglio il ramo'),
        debug_print(Head),
        fail)
    ; true ),
    % stop-first-per-loop: taglia solo se abbiamo già trovato sia un test positivo
    % (vgood) che uno negativo per questo predicato ricorsivo
    ( HeadCount >= 1, sat_found_positive(HeadF/HeadA), sat_found_negative(HeadF/HeadA) -> fail ; true ),
    % ─────────────────────────────────────────────────────────

    HeadCopy = Head,
    append(CallsIn, [Head], CallsMid),
    % append(CallsIn, [HeadCopy], CallsMid),

    % Recupera la clausola
  %  debug_print(cercando_clausola(HeadF/HeadA)),
    clause(Head, RawBody),
    debug_print('Mi trovo in quest head'),
    debug_print(Head),
   % nl,

    debug_print('Con questo Body!'),
    debug_print(RawBody),
  % nl,
    
    % Porta constr in testa
    reorder_body(RawBody, TempBody),

    % Aggiunge tipi alla symtab
    conj_to_list(TempBody, BodyList),
    extend_type_table_list([Head | BodyList], SymTabIn, SymTabFinal),

    % Ricostruisce il corpo
    build_conjunct(BodyList, Body),

    NewSteps is Steps - 1,

    % Continua la derivazione
    zmi_aux(Body, Z3In, CLPQIn, SymTabFinal, CallsMid, NewSteps,
            Z3Out, CLPQOut, CallsOut,
            SubTree).



% -------------------------------------------------------------
% Ricostruzione tipi (SymTab)
%
% extend_type_table_list/3 scorre i goal della clausola e, se sono
% predicati del programma, usa pred_arg(Pred/Arity,Pos,Type) per
% associare (Var-Type). Queste info vengono poi re-iniettate in Z3
% come uguaglianze tipizzate Var:Type = Var:Type.
% -------------------------------------------------------------

extend_type_table_list([], SymTab, SymTab).

%versione senza ottimiazziozneo

extend_type_table_list([Goal | Rest], SymTabIn, SymTabOut) :-

        % writeln('Sono entrato in extend_type_table_list'),
    ( Goal = constr(_) ; Goal == true ) ->
        extend_type_table_list(Rest, SymTabIn, SymTabOut)
    ;
       ( Goal =.. [Pred | Args],
        length(Args, Arity),
        PredArity = Pred/Arity,
        build_type_pairs(PredArity, 1, Args, [], Pairs),
        % writeln('Stampo Goal'),
        % writeln(Goal),
        % writeln('Stampo Tipo arita e coppia'),
        % writeln(PredArity-Pairs),
        append(SymTabIn, Pairs, Combined),
          sort(Combined, SymTabNext),
        extend_type_table_list(Rest, SymTabNext, SymTabOut)
       ).

% %     %Asserito in db pred_arg('main@bb22.i'/5, 1, int).
% %     %PredArity = 'main@bb22.i'/5
% %     %Pos posizione corrente dell'argomento (1,2,3...)
% %     %[Var | Rest] lista degli argomenti del predicato (es. [A, B, C, D])
% %     %AccIn Coppie trovate finora - [B-bool, A-int]
% %     %AccOut valorizzato alla fine con AccIn quando è lista vuota

% ex versione funzioannte ma che da type error ogni tanto

build_type_pairs(_, _, [], Acc, Acc).
 
build_type_pairs(PredArity, Pos, [Var | Rest], AccIn, AccOut) :-
    var(Var), %es A
    pred_arg(PredArity, Pos, Type),
    atom(Type), % tipi atomici (int, bool, …)
    !,
    AccNext = [Var-Type | AccIn],
    Pos1 is Pos + 1,
    build_type_pairs(PredArity, Pos1, Rest, AccNext, AccOut).
 
build_type_pairs(PredArity, Pos, [Var | Rest], AccIn, AccOut) :-
    var(Var), %es A
    pred_arg(PredArity, Pos, Type),
    Type = array(Index, Elem), % array(Index, Elem) con entrambi ground (es. array(int,int), array(int,bool))
    ground(Index),
    ground(Elem),
    !,
    AccNext = [Var-array(Index, Elem) | AccIn],
    Pos1 is Pos + 1,
    build_type_pairs(PredArity, Pos1, Rest, AccNext, AccOut).
 
build_type_pairs(PredArity, Pos, [_Var | Rest], AccIn, AccOut) :-
    AccNext = AccIn,
    Pos1 is Pos + 1,
    build_type_pairs(PredArity, Pos1, Rest, AccNext, AccOut).


% ----------------------------
% Costruzione vincoli di uguaglianza tipizzata
% ----------------------------

% Caso 1: variabile con tipo atomico (int, bool, ecc.)
build_type_equality(Var-Type, (Var:Type = Var:Type)) :-
    var(Var),
    atom(Type),
     !.

% Caso 2: variabile con tipo array(Index, Elem), entrambi ground
build_type_equality(Var-array(Index, Elem), (Var:array(Index, Elem) = Var:array(Index, Elem))) :-
    var(Var),
    ground(Index), ground(Elem),
     !.

build_type_equality_list([], []).

build_type_equality_list([X | Rest], [Y | Ys]) :-
    build_type_equality(X, Y),           
    !,
    build_type_equality_list(Rest, Ys).

build_type_equality_list([_ | Rest], Ys) :-
    build_type_equality_list(Rest, Ys).


%% constr_to_rawground(+Constr, -RawGround)
%  1) Normalizza il vincolo (usa logic_utils:normalize_bool_expr/2)
%  2) Rinomina le variabili per Z3 (usa z3constr2lower/3)

constr_to_rawground(Constr,Pairs, RawGround) :-
    normalize_bool_expr(Constr, Norm),
    z3constr2lower(Norm, Pairs, RawGround).


%% constr_push_check(+Constr, -Result, -RawGround)
%  1) Converte il vincolo in RawGround tramite constr_to_rawground/2
%  2) Esegue il push+check su Z3 tramite z3_sat_check/3
constr_push_check(Constr, Result, RawGround) :-
    constr_to_rawground(Constr,_Pairs, RawGround),
    z3_sat_check(RawGround, Result, _, _).

% ----------------------------
% Sposta constr in testa
% ----------------------------

move_constr(Lista, Risultato) :-
    split_constr(Lista, Ts, Altri),
    append(Ts, Altri, Risultato).

split_constr([], [], []).
split_constr([H|T], [H|Ts], Altri) :-
    H =.. [constr, _],
     !,
    split_constr(T, Ts, Altri).
split_constr([H|T], Ts, [H|Altri]) :-
    split_constr(T, Ts, Altri).

reorder_body(BodyIn, BodyOut) :-

    conj_to_list(BodyIn, FlatList),
    move_constr(FlatList, ReorderedList),
    build_conjunct(ReorderedList, BodyOut).

% ----------------------------
% Derivation tree printing
% ----------------------------

print_tree(Tree) :- print_tree(Tree, 0).
print_tree(true, Indent) :- tab(Indent), writeln('true').
print_tree(constr(C), Indent) :- tab(Indent), format('constr(~w)~n', [C]).
print_tree((A, B), Indent) :- print_tree(A, Indent), print_tree(B, Indent).
print_tree(SubTree => Head, Indent) :-
    Head =.. [F | Args],
    tab(Indent), format('~w(~w)~n', [F, Args]),
    NewIndent is Indent + 2,
    print_tree(SubTree, NewIndent).
print_tree('Step limit reached', Indent) :-
    tab(Indent), writeln('[... Step limit reached ...]').
print_tree(Other, Indent) :- tab(Indent), writeln(Other).

% ----------------------------
% Wrapper: carica file e lancia zmi/1
% ----------------------------

% run_analysis(File, Target) :-
%     format("📂 Analisi del file: ~w con target: ~w~n", [File, Target]),
%     load_clean(File),
%     zmi(Target).
%     %format("📌 Analisi terminata.~n", []).

run_analysis(File, Target, MaxDepth, LoopLimit) :-
    run_analysis(File, Target, MaxDepth, LoopLimit, none, false).

run_analysis(File, Target, MaxDepth, LoopLimit, SkipFile) :-
    run_analysis(File, Target, MaxDepth, LoopLimit, SkipFile, false).

run_analysis(File, Target, MaxDepth, LoopLimit, SkipFile, StopFirst) :-
    format("📂 Analisi del file: ~w con target: ~w~n", [File, Target]),
    ( SkipFile \= none ->
        format("⚡ Skip file: ~w~n", [SkipFile]),
        consult(SkipFile)
    ; true ),
    set_loop_limit(LoopLimit),
    load_clean(File),
    zmi(Target, MaxDepth, StopFirst).




:- initialization(main, main).

% main :-
%     current_prolog_flag(argv, Argv),
%     ( Argv = [File, Target] ->(
%         run_analysis(File, Target),
%         halt(0))
%     ; (format("Uso: swipl -s main.pl -- <file.smt2.pl> <ff|incorrect>~n", []),
%       halt(1))
%     ).

% =============================
% CLI (arg parsing)
% =============================

usage :-
    format("Uso: swipl -s main.pl -- [--debug] [--stop-first] [--stop-first-per-loop] [--skip-file F] <file.pl> <target> [--maxdepth N] [--looplimit N]~n", []).

default_maxdepth(1000000).
default_looplimit(2000).

parse_int_arg(AtomOrString, N) :-
    (   atom(AtomOrString)
    ->  atom_string(AtomOrString, S)
    ;   S = AtomOrString
    ),
    catch(number_string(N, S), _, fail),
    integer(N),
    N > 0.

% parse_flags(+Tokens, -File, -Target, -MaxDepth, -LoopLimit, -Debug, -SkipFile, -StopFirst)
parse_flags(Tokens, File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst) :-
    parse_flags_(Tokens, _, _, _, _, _, _, _,
                 File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst).

parse_flags_([], File, Target, MaxDepthIn, LoopLimitIn, DebugIn, SkipIn, StopFirstIn,
             File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst) :-
    ( var(MaxDepthIn)   -> default_maxdepth(MaxDepth)  ; MaxDepth   = MaxDepthIn   ),
    ( var(LoopLimitIn)  -> default_looplimit(LoopLimit) ; LoopLimit  = LoopLimitIn  ),
    ( var(DebugIn)      -> Debug = false                ; Debug      = DebugIn      ),
    ( var(SkipIn)       -> SkipFile = none              ; SkipFile   = SkipIn       ),
    ( var(StopFirstIn)  -> StopFirst = false            ; StopFirst  = StopFirstIn  ).

parse_flags_(['--debug' | Rest], FileAcc, TargetAcc, MDep, LLim, _, Skp, SF,
             File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst) :-
    parse_flags_(Rest, FileAcc, TargetAcc, MDep, LLim, true, Skp, SF,
                 File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst).

parse_flags_(['--stop-first' | Rest], FileAcc, TargetAcc, MDep, LLim, Dbg, Skp, _,
             File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst) :-
    parse_flags_(Rest, FileAcc, TargetAcc, MDep, LLim, Dbg, Skp, true,
                 File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst).

parse_flags_(['--maxdepth', VS | Rest], FileAcc, TargetAcc, _, LLim, Dbg, Skp, SF,
             File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst) :-
    parse_int_arg(VS, N),
    parse_flags_(Rest, FileAcc, TargetAcc, N, LLim, Dbg, Skp, SF,
                 File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst).

parse_flags_(['--looplimit', VS | Rest], FileAcc, TargetAcc, MDep, _, Dbg, Skp, SF,
             File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst) :-
    parse_int_arg(VS, N),
    parse_flags_(Rest, FileAcc, TargetAcc, MDep, N, Dbg, Skp, SF,
                 File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst).

parse_flags_(['--skip-file', VS | Rest], FileAcc, TargetAcc, MDep, LLim, Dbg, _, SF,
             File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst) :-
    parse_flags_(Rest, FileAcc, TargetAcc, MDep, LLim, Dbg, VS, SF,
                 File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst).

% Primo token non-flag: è File
parse_flags_([Tok | Rest], FileAcc, TargetAcc, MDep, LLim, Dbg, Skp, SF,
             File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst) :-
    \+ sub_atom(Tok, 0, 2, _, '--'),
    var(FileAcc),
    parse_flags_(Rest, Tok, TargetAcc, MDep, LLim, Dbg, Skp, SF,
                 File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst).

% Secondo token non-flag: è Target
parse_flags_([Tok | Rest], FileAcc, TargetAcc, MDep, LLim, Dbg, Skp, SF,
             File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst) :-
    \+ sub_atom(Tok, 0, 2, _, '--'),
    nonvar(FileAcc),
    var(TargetAcc),
    parse_flags_(Rest, FileAcc, Tok, MDep, LLim, Dbg, Skp, SF,
                 File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst).

parse_argv(Argv, File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst) :-
    append(_, Tail, Argv),
    Tail \= [],
    parse_flags(Tail, File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst),
    nonvar(File), nonvar(Target).

main :-
    current_prolog_flag(argv, Argv),
    ( memberchk('--stop-first-per-loop', Argv) ->
        assertz(stop_per_loop),
        delete(Argv, '--stop-first-per-loop', CleanArgv)
    ;
        CleanArgv = Argv
    ),
    (   parse_argv(CleanArgv, File, Target, MaxDepth, LoopLimit, Debug, SkipFile, StopFirst)
    ->  ( Debug == true -> enable_debug ; true ),
        run_analysis(File, Target, MaxDepth, LoopLimit, SkipFile, StopFirst),
        halt(0)
    ;   usage,
        halt(1)
    ).





print_call_trace_symbolic([]) :- !.
print_call_trace_symbolic([Call | Rest]) :-
    Call =.. [F | Args],
    format("~w(", [F]),
    print_args_symbolic(Args),
    format(")~n"),
    print_call_trace_symbolic(Rest).

print_args_symbolic([]).
print_args_symbolic([A]) :- !, write(A).
print_args_symbolic([A | Rest]) :-
    write(A), write(", "),
    print_args_symbolic(Rest).





% ============================================================
% Sostituzione sicura delle variabili 
% ============================================================

lookup_var_value(Var, [V=Val | _], Val) :-
    Var == V, !.
lookup_var_value(Var, [_ | Rest], Val) :-
    lookup_var_value(Var, Rest, Val).

subst_var(Var, Consts, Value) :-
    var(Var),
    lookup_var_value(Var, Consts, Value),
    !.
subst_var(Var, _, Var).

subst_args([], _, []).
subst_args([A | As], Consts, [V | Vs]) :-
    subst_var(A, Consts, V),
    subst_args(As, Consts, Vs).

subst_call(Call, Consts, NewCall) :-
    Call =.. [F | Args],
    subst_args(Args, Consts, NewArgs),
    NewCall =.. [F | NewArgs].

subst_call_trace([], _, []).
subst_call_trace([C | Cs], Consts, [NC | NCs]) :-
    subst_call(C, Consts, NC),
    subst_call_trace(Cs, Consts, NCs).




% ============================================================
% Estrazione input programma C dal modello Z3
% ============================================================

% Trova il primo predicato della call trace con arità > 0
first_nonzero_arity_atom([Call | _], Call) :-
    Call =.. [_ | Args],
    Args \= [],
    !.

first_nonzero_arity_atom([_ | Rest], Call) :-
    first_nonzero_arity_atom(Rest, Call).


% Estrae la lista delle variabili da un predicato
extract_var_list(Call, VarList) :-
    Call =.. [_ | VarList].


% Costruisce Var=Value 
extract_values_from_model([], _, []).

extract_values_from_model([Var | Vars], Consts, [Var=Val | Rest]) :-
    lookup_var_value(Var, Consts, Val),
    !,
    extract_values_from_model(Vars, Consts, Rest).

extract_values_from_model([Var | Vars], Consts, [Var=unconstrained | Rest]) :-
    extract_values_from_model(Vars, Consts, Rest).



classify_test_from_vmapgood_consts(Consts, testVerimapGood) :-
    member(_=1042, Consts),
    !.

classify_test_from_vmapgood_consts(Consts, testFail) :-
    member(_=42, Consts),
    !.

classify_test_from_vmapgood_consts(_, testUnknown).



% -------------------------------------------------------------
% Rimozione type-equalities già presenti in Z3In
% Riconosce termini del tipo  (Var:Type = Var:Type)
% -------------------------------------------------------------

is_type_equality((L = R)) :-
    L == R,
    compound(L),
    functor(L, ':', 2).

strip_type_equalities([], []).
strip_type_equalities([H|T], R) :-
    is_type_equality(H),
    !,
    strip_type_equalities(T, R).
strip_type_equalities([H|T], [H|R]) :-
    strip_type_equalities(T, R).


% bind_inputs(InputNames, Vars, Consts, Bindings) :-
%     bind_inputs_prefix(InputNames, Vars, Consts, Bindings).

% bind_inputs_prefix([], _, _, []) :- !.
% bind_inputs_prefix(_, [], _, []) :- !.
% bind_inputs_prefix([Name|Ns], [Var|Vs], Consts, [Name=Value|Rest]) :-
%     ( lookup_var_value(Var, Consts, Value) -> true
%     ; Value = unconstrained
%     ),
%     bind_inputs_prefix(Ns, Vs, Consts, Rest).



%     is_all_uppercase(Name) :-
%     atom_chars(Name, Chars),
%     Chars \= [],
%     forall(member(C, Chars),
%            ( char_type(C, upper)
%            ; C == '_'
%            )).

% filter_input_names(InputNames, Filtered) :-
%     exclude(is_all_uppercase, InputNames, Filtered).


% skip_vgood([_Vgood | Rest], Rest) :- !.
% skip_vgood([], []).


% bind_inputs_from_values([], _, []).
% bind_inputs_from_values(_, [], []).
% bind_inputs_from_values([Name|Ns], [_=Val|Vs], [Name=Val|Rest]) :-
%     bind_inputs_from_values(Ns, Vs, Rest).



run_with_inputs(Target) :-
    input_vars(_Inputs),
    zmi(Target).


%     % =============================
% % INPUT NAMES (SEMANTIC)
% % =============================

% % input(Name, PositionInVarList)
% input_decl([
%     input(vgood, 1),
%     input(x,     2),
%     input(i,     3),
%     input(n,     4)
% ]).


% select_inputs([], _, []).
% select_inputs([input(Name,Pos) | Rest], VarList, [Name=Var | Out]) :-
%     nth1(Pos, VarList, Var),
%     select_inputs(Rest, VarList, Out).


%     bind_inputs_from_model([], _, []).
% bind_inputs_from_model([Name=Var | Rest], Consts, [Name=Val | Out]) :-
%     ( lookup_var_value(Var, Consts, Val) -> true
%     ; Val = unconstrained
%     ),
%     bind_inputs_from_model(Rest, Consts, Out).

bind_named_inputs(InputNames, ValueList, Bindings) :-
    bind_named_inputs_prefix(InputNames, ValueList, Bindings).

bind_named_inputs_prefix([], _, []) :- !.
bind_named_inputs_prefix(_, [], []) :- !.

bind_named_inputs_prefix(
    [Name | Ns],
    [_Var = Val | Vs],
    [Name = Val | Rest]
) :-
    bind_named_inputs_prefix(Ns, Vs, Rest).


% =============================
% INPUT NAMES
% =============================

input_names([vgood, a]).