% smt2pl_to_constr.pl
%
% Converts the Prolog CHCs produced by VeriMAP's smt2map from an SMT-LIB file
% of the Solidity compiler's CHC engine (SolCMC, also used by SolTG) into the
% format read by our interpreter:
%     Head :- constr((C1, C2, ...)), Call1, Call2, ...
%
% smt2map leaves the whole antecedent of each rule inside constr(and(...)),
% predicate calls included. This script:
%   1. takes the predicate calls out of constr(...);
%   2. removes the boolean structure, which our interpreter cannot handle:
%      - a local boolean variable with a definition (K = (L > M),
%        S = and(T, U), Q = K, ...) is replaced by its definition;
%      - booleans that are predicate arguments become ints: true = 1,
%        false = 0;
%      - the rest (and, not, ~, implies, ite, = between booleans) is put in
%        disjunctive normal form, and the clause is split in one clause per
%        disjunct; ite inside an arithmetic term, x = ite(C, V, W), becomes
%        (C and x = V) or (not C and x = W);
%   3. the transaction (tx_type) argument of every predicate becomes one int
%      argument per field in tx_fields/1 (block.timestamp, msg.sender, ...),
%      and 'block.timestamp'(Tx) becomes that int: so the requires on them
%      are kept and their values show up in the tests. The field order is
%      written in a "% tx_fields:" comment at the top of the output;
%   4. drops the constraints on structured values (state, transaction, crypto,
%      arrays: select/store, field accessors). Every predicate argument is
%      declared int. This is an over-approximation: the dropped constraints
%      are counted on stderr.
%
% Usage:
%   swipl -q -g main -t halt script/smt2pl_to_constr.pl -- [--single-tx] IN.smt2.pl OUT.pl

:- op(1150, fx, pred).
:- op(1150, fx, mode).
:- op(1150, fx, query).
:- op(1150, fx, ignore).
:- op(1150, fx, type).
:- op(1179, xfx, --->).
:- op(200, fy, ~).

% clauses with more disjuncts than this keep only their plain constraints
max_disjuncts(256).

main :-
    current_prolog_flag(argv, Argv),
    append(_, [In, Out], Argv), !,
    read_all(In, Terms),
    findall(Name/Ar-Types, ( member((:- pred(P)), Terms), functor(P, Name, Ar),
                             P =.. [_ | Types] ), Decls),
    nb_setval(dropped, 0),
    nb_setval(split, 0),
    nb_setval(skipped_tx, 0),
    nb_setval(too_big, 0),
    ( memberchk('--single-tx', Argv) -> nb_setval(single_tx, true) ; nb_setval(single_tx, false) ),
    setup_call_cleanup(open(Out, write, S), write_all(S, Terms, Decls), close(S)),
    nb_getval(dropped, D), nb_getval(split, Sp), nb_getval(too_big, TB),
    format(user_error, "[smt2pl_to_constr] ~w -> ~w~n", [In, Out]),
    format(user_error, "  ~w constraint(s) on structured values dropped~n", [D]),
    format(user_error, "  ~w clause(s) split on booleans, ~w too big to split~n", [Sp, TB]),
    nb_getval(skipped_tx, Tx),
    ( Tx > 0 -> format(user_error, "  ~w transaction-chaining clause(s) dropped (--single-tx)~n", [Tx]) ; true ).
main :-
    format(user_error, "Usage: swipl -q -g main -t halt smt2pl_to_constr.pl -- IN OUT~n", []),
    halt(1).

read_all(File, Terms) :-
    setup_call_cleanup(open(File, read, S),
                       read_terms(S, Terms),
                       close(S)).

read_terms(S, Terms) :-
    read_term(S, T, [variable_names(_)]),
    (   T == end_of_file
    ->  Terms = []
    ;   Terms = [T | Rest],
        read_terms(S, Rest)
    ).

count(Key) :- nb_getval(Key, N), N1 is N + 1, nb_setval(Key, N1).

% ---------------------------------------------------------------- output

write_all(S, Terms, Decls0) :-
    tx_fields(Fs),
    format(S, "% tx_fields: ~q~n", [Fs]),
    maplist(expand_decl, Decls0, Decls),
    findall(N/A, member(N/A-_, Decls), Preds),
    forall(member(Name/Ar-_, Decls),
           ( length(Ints, Ar), maplist(=(int), Ints), P2 =.. [Name | Ints],
             format(S, ":- pred ~q.~n", [P2]) )),
    forall(member((:- mode(M)), Terms),
           ( expand_mode(Decls0, M, M2), format(S, ":- mode ~q.~n", [M2]) )),
    forall(member((:- query(Q)), Terms), format(S, ":- query ~q.~n", [Q])),
    forall(( member(C0, Terms), is_clause(C0), \+ skipped_clause(C0) ),
           ( expand_tx(Decls0, C0, C),
             convert_clause(C, Preds, Decls, Cs2), maplist(write_clause(S), Cs2) )),
    % solc prints one query per assert and only the last error target is the
    % goal of the last query: make ff reach every error target, so that all
    % the asserts of the contract are checked
    forall(( member(T/0, Preds), sub_atom(T, 0, _, _, error_target_),
             \+ ( member((ff :- B), Terms), sub_term(T, B) ) ),
           format(S, "ff :- constr(true), ~q.~n", [T])).

% ---------------------------------------------------------------- transaction fields

tx_fields(['block.timestamp', 'block.number', 'msg.sender', 'msg.value', 'tx.origin']).

expand_decl(N/_-Ts, N/Ar-Ts2) :-
    tx_fields(Fs), length(Fs, K), length(Ints, K), maplist(=(int), Ints),
    foldl(expand_type(Ints), Ts, [], Rev), reverse(Rev, Ts2), length(Ts2, Ar).

expand_type(Ints, tx_type, Acc, Acc1) :- !, reverse(Ints, R), append(R, Acc, Acc1).
expand_type(_, T, Acc, [T | Acc]).

expand_mode(Decls, M, M2) :-
    M =.. [N | Ms], length(Ms, Ar),
    (   memberchk(N/Ar-Ts, Decls)
    ->  tx_fields(Fs), length(Fs, K),
        foldl(expand_mode_arg(K), Ms, Ts, [], Rev), reverse(Rev, Ms2), M2 =.. [N | Ms2]
    ;   M2 = M
    ).

expand_mode_arg(K, Md, tx_type, Acc, Acc1) :- !, length(L, K), maplist(=(Md), L), append(L, Acc, Acc1).
expand_mode_arg(_, Md, _, Acc, [Md | Acc]).

% every variable V used as a transaction gets one fresh variable per field;
% in the atoms V is replaced by the field variables, and 'f'(V) by the
% variable of field f (no findall: the variables must stay the same)
expand_tx(Decls, C0, C) :-
    tx_vars(C0, Decls, [], Vs),
    maplist(tx_pair, Vs, Pairs),
    map_tx(C0, Decls, Pairs, C).

tx_pair(V, V-FVs) :- tx_fields(Fs), length(Fs, K), length(FVs, K).

tx_vars(T, _, Acc, Acc) :- var(T), !.
tx_vars(T, _, Acc, Acc) :- \+ compound(T), !.
tx_vars(T, Decls, Acc0, Acc) :-
    T =.. [F | As], length(As, Ar),
    (   memberchk(F/Ar-Ts, Decls)
    ->  foldl(tx_arg, As, Ts, Acc0, Acc1)
    ;   tx_fields(Fs), memberchk(F, Fs), As = [V], var(V)
    ->  add_var(V, Acc0, Acc1)
    ;   Acc1 = Acc0
    ),
    foldl(tx_vars_(Decls), As, Acc1, Acc).

tx_vars_(Decls, T, A0, A) :- tx_vars(T, Decls, A0, A).

tx_arg(V, tx_type, A0, A) :- var(V), !, add_var(V, A0, A).
tx_arg(_, _, A, A).

map_tx(T, _, _, T) :- var(T), !.
map_tx(T, _, _, T) :- \+ compound(T), !.
map_tx(T, Decls, Pairs, T2) :-
    T =.. [F | As], length(As, Ar),
    (   memberchk(F/Ar-Ts, Decls)
    ->  foldl(map_tx_arg(Decls, Pairs), As, Ts, [], Rev), reverse(Rev, As2), T2 =.. [F | As2]
    ;   tx_fields(Fs), nth1(I, Fs, F), As = [V], var(V), tx_lookup(V, Pairs, FVs)
    ->  nth1(I, FVs, T2)
    ;   maplist(map_tx_(Decls, Pairs), As, As2), T2 =.. [F | As2]
    ).

map_tx_(Decls, Pairs, A, A2) :- map_tx(A, Decls, Pairs, A2).

map_tx_arg(_, Pairs, V, tx_type, Acc, Acc1) :- !,
    (   var(V), tx_lookup(V, Pairs, FVs)
    ->  true
    ;   tx_fields(Fs), length(Fs, K), length(FVs, K)
    ),
    reverse(FVs, R), append(R, Acc, Acc1).
map_tx_arg(Decls, Pairs, A, _, Acc, [A2 | Acc]) :- map_tx(A, Decls, Pairs, A2).

tx_lookup(V, [K-FVs | _], FVs) :- V == K, !.
tx_lookup(V, [_ | T], FVs) :- tx_lookup(V, T, FVs).

% --single-tx: drop the clause that chains transactions
%     interface_0(...) :- interface_0(...), summary(...)
% so that every test is one call to the contract after the constructor
skipped_clause((H :- B)) :-
    nb_getval(single_tx, true),
    functor(H, N, A), sub_atom(N, 0, _, _, interface_),
    sub_term(G, B), compound(G), functor(G, N, A), !,
    count(skipped_tx).

is_clause((:- _)) :- !, fail.
is_clause(_).

write_clause(S, C) :-
    \+ \+ ( numbervars(C, 0, _), format(S, "~W.~n", [C, [quoted(true), numbervars(true)]]) ).

% ---------------------------------------------------------------- clauses

convert_clause((H :- B), Preds, Decls, Clauses) :- !,
    conjuncts(B, Gs0),
    flatten_goals(Gs0, Preds, Calls, Cs0),
    bool_vars([H | Calls], Decls, Cs0, Bools),
    term_variables([H | Calls], NonLocal),
    inline_bools(Cs0, Bools, NonLocal, Cs1),
    list_to_and(Cs1, F0),
    nnf(F0, +, Bools, F),
    max_disjuncts(Max),
    (   dnf(F, Max, Ds)
    ->  ( Ds = [_, _ | _] -> count(split) ; true )
    ;   count(too_big),
        sure_literals(F, Lits), Ds = [Lits]
    ),
    maplist(make_clause(H, Calls), Ds, Clauses).
convert_clause(H, _, _, [(H :- constr(true))]).

make_clause(H, Calls, Lits, (H :- Body)) :-
    (   Lits == []
    ->  Constr = constr(true)
    ;   list_to_comma(Lits, Conj), Constr = constr(Conj)
    ),
    list_to_comma([Constr | Calls], Body).

% a variable here is a boolean name (K in and(..., K)): never unify it
conjuncts(G, [G]) :- var(G), !.
conjuncts((A, B), L) :- !, conjuncts(A, LA), conjuncts(B, LB), append(LA, LB, L).
conjuncts(G, [G]).

% split body goals into predicate calls and constraints; constr(...) bodies
% are flattened through and/2
flatten_goals([], _, [], []).
flatten_goals([G | Gs], Preds, Calls, [G | Cs]) :- var(G), !,
    flatten_goals(Gs, Preds, Calls, Cs).
flatten_goals([constr(C) | Gs], Preds, Calls, Cs) :- !,
    and_list(C, L),
    flatten_goals(L, Preds, Calls1, Cs1),
    flatten_goals(Gs, Preds, Calls2, Cs2),
    append(Calls1, Calls2, Calls), append(Cs1, Cs2, Cs).
flatten_goals([G | Gs], Preds, [G | Calls], Cs) :-
    callable(G), functor(G, N, A), memberchk(N/A, Preds), !,
    flatten_goals(Gs, Preds, Calls, Cs).
flatten_goals([G | Gs], Preds, Calls, [G | Cs]) :-
    flatten_goals(Gs, Preds, Calls, Cs).

and_list(X, [X]) :- var(X), !.
and_list(and(A, B), L) :- !, and_list(A, LA), and_list(B, LB), append(LA, LB, L).
and_list(true, []) :- !.
and_list(implies(true, X), L) :- !, and_list(X, L).
and_list(implies(true), []) :- !.
and_list(X, [X]).

list_to_and([], true).
list_to_and([X], X) :- !.
list_to_and([X | Xs], and(X, R)) :- list_to_and(Xs, R).

list_to_comma([X], X) :- !.
list_to_comma([X | Xs], (X, R)) :- list_to_comma(Xs, R).

memq(X, [Y | _]) :- X == Y, !.
memq(X, [_ | T]) :- memq(X, T).

% ---------------------------------------------------------------- boolean variables

% Bools: the variables of type bool. Seeds: the bool arguments of the head
% and of the calls (from the :- pred declarations), the variables used as
% formulas (in and/not/implies/ite conditions, or alone as a conjunct), the
% names of a comparison (K = (L > M)); then K = V spreads the type.
% (no findall here: it would copy the variables)
bool_vars(Atoms, Decls, Cs, Bools) :-
    foldl(bool_args(Decls), Atoms, [], Ba),
    foldl(add_if_var, Cs, Ba, B0),
    all_subterms(Cs, Ts),
    foldl(formula_vars, Ts, B0, B1),
    bool_fix(Ts, B1, Bools).

bool_args(Decls, A, B0, B) :-
    functor(A, N, Ar),
    (   memberchk(N/Ar-Ts, Decls)
    ->  A =.. [_ | Args], foldl(bool_arg, Args, Ts, B0, B)
    ;   B = B0
    ).

bool_arg(V, bool, B0, B) :- var(V), !, add_var(V, B0, B).
bool_arg(_, _, B, B).

add_var(V, B, B) :- memq(V, B), !.
add_var(V, B, [V | B]).

all_subterms(Cs, Ts) :- foldl(subterms, Cs, [], Ts).

subterms(T, Acc, [T | Acc]) :- var(T), !.
subterms(T, Acc, [T | Acc1]) :- compound(T), !, T =.. [_ | As], foldl(subterms, As, Acc, Acc1).
subterms(T, Acc, [T | Acc]).

% a variable alone (a conjunct) is a formula too: it shows up in Ts as itself
% only if it is a top-level constraint, handled by formula_vars(V) below
formula_vars(T, B0, B) :- var(T), !, B = B0.
formula_vars(T, B0, B) :-
    (   formula_args(T, Vs) -> true ; Vs = [] ),
    foldl(add_if_var, Vs, B0, B).

add_if_var(V, B0, B) :- ( var(V) -> add_var(V, B0, B) ; B = B0 ).

formula_args(and(A, B), [A, B]).
formula_args(or(A, B), [A, B]).
formula_args(not(A), [A]).
formula_args(~(A), [A]).
formula_args(implies(A, B), [A, B]).
formula_args(ite(C, _, _), [C]).
formula_args(K = E, [K]) :- var(K), nonvar(E), is_formula_shape(E), !.
formula_args(E = K, [K]) :- var(K), nonvar(E), is_formula_shape(E).

is_formula_shape(true).
is_formula_shape(false).
is_formula_shape(E) :- compound(E), functor(E, F, Ar),
    memberchk(F/Ar, [and/2, or/2, not/1, (~)/1, implies/2,
                     (=)/2, (<)/2, (>)/2, (=<)/2, (>=)/2, (=\=)/2]).

bool_fix(Ts, B0, Bs) :-
    foldl(spread, Ts, B0-false, B1-Changed),
    ( Changed == true -> bool_fix(Ts, B1, Bs) ; Bs = B1 ).

spread(T, B0-_, B-C) :-
    nonvar(T), T = (L = R), var(L), var(R),
    (   memq(L, B0), \+ memq(R, B0) -> B = [R | B0], C = true
    ;   memq(R, B0), \+ memq(L, B0) -> B = [L | B0], C = true
    ), !.
spread(_, S, S).

is_bool(T, Bs) :- var(T), !, memq(T, Bs).
is_bool(ite(_, A, B), Bs) :- !, ( is_bool(A, Bs) ; is_bool(B, Bs) ), !.
is_bool(T, _) :- is_formula_shape(T).

% a local boolean variable with a definition is replaced by it
inline_bools(Cs0, Bs, NonLocal, Cs) :-
    select(C, Cs0, Rest),
    nonvar(C), C = (L = R),
    (   var(L), memq(L, Bs), \+ memq(L, NonLocal), is_bool(R, Bs), X = L, E = R
    ;   var(R), memq(R, Bs), \+ memq(R, NonLocal), is_bool(L, Bs), X = R, E = L
    ),
    unify_with_occurs_check(X, E), !,
    inline_bools(Rest, Bs, NonLocal, Cs).
inline_bools(Cs, _, _, Cs).

% ---------------------------------------------------------------- negation normal form

% nnf(Formula, Polarity, Bools, Out): Out uses and/2, or/2, true, false and
% arithmetic comparisons only. A boolean variable B becomes B = 1 / B = 0.
% Atoms on structured values become true (dropped) in both polarities, which
% over-approximates.
nnf(V, P, Bs, L) :- var(V), !,
    (   memq(V, Bs)
    ->  ( P == (+) -> L = (V = 1) ; L = (V = 0) )
    ;   count(dropped), L = true
    ).
nnf(true, P, _, L) :- !, ( P == (+) -> L = true ; L = false ).
nnf(false, P, _, L) :- !, ( P == (+) -> L = false ; L = true ).
nnf(and(A, B), P, Bs, F) :- !,
    nnf(A, P, Bs, FA), nnf(B, P, Bs, FB),
    ( P == (+) -> F = and(FA, FB) ; F = or(FA, FB) ).
nnf(or(A, B), P, Bs, F) :- !,
    nnf(A, P, Bs, FA), nnf(B, P, Bs, FB),
    ( P == (+) -> F = or(FA, FB) ; F = and(FA, FB) ).
nnf(not(A), P, Bs, F) :- !, flip(P, Q), nnf(A, Q, Bs, F).
nnf(~(A), P, Bs, F) :- !, flip(P, Q), nnf(A, Q, Bs, F).
% A -> B is (not A) or (A and B); not (A -> B) is A and not B
nnf(implies(A, B), P, Bs, F) :- !,
    (   P == (+)
    ->  nnf(A, -, Bs, NA), nnf(A, +, Bs, PA), nnf(B, +, Bs, PB),
        F = or(NA, and(PA, PB))
    ;   nnf(A, +, Bs, PA), nnf(B, -, Bs, NB), F = and(PA, NB)
    ).
nnf(ite(C, A, B), P, Bs, F) :- !,
    nnf(C, +, Bs, PC), nnf(C, -, Bs, NC),
    nnf(A, P, Bs, FA), nnf(B, P, Bs, FB),
    F = or(and(PC, FA), and(NC, FB)).
% = between booleans: iff
nnf(X = Y, P, Bs, F) :- ( is_bool(X, Bs) ; is_bool(Y, Bs) ), !,
    nnf(X, +, Bs, PX), nnf(X, -, Bs, NX),
    nnf(Y, +, Bs, PY), nnf(Y, -, Bs, NY),
    (   P == (+)
    ->  F = or(and(PX, PY), and(NX, NY))
    ;   F = or(and(PX, NY), and(NX, PY))
    ).
% arithmetic comparison: first lift an ite out of its arguments
nnf(C, P, Bs, F) :- is_comparison(C), sub_term(I, C), nonvar(I), I = ite(Cnd, V, W), !,
    replace_once(C, I, V, CV), replace_once(C, I, W, CW),
    nnf(Cnd, +, Bs, PC), nnf(Cnd, -, Bs, NC),
    nnf(CV, P, Bs, FV), nnf(CW, P, Bs, FW),
    F = or(and(PC, FV), and(NC, FW)).
nnf(C, P, _, F) :- is_comparison(C), C =.. [_, A, B], arith_term(A), arith_term(B), !,
    ( P == (+) -> L = C ; negate(C, L) ),
    eval_ground(L, F).
nnf(_, _, _, true) :- count(dropped).

flip(+, -).
flip(-, +).

replace_once(T, Old, New, New) :- T == Old, !.
replace_once(T, _, _, T) :- \+ compound(T), !.
replace_once(T, Old, New, T2) :-
    T =.. [F | As], replace_args(As, Old, New, As2), T2 =.. [F | As2].

replace_args([], _, _, []).
replace_args([A | As], Old, New, [A2 | As]) :- contains_eq(A, Old), !,
    replace_once(A, Old, New, A2).
replace_args([A | As], Old, New, [A | As2]) :- replace_args(As, Old, New, As2).

contains_eq(T, X) :- sub_term(S, T), S == X, !.

is_comparison(C) :- compound(C), C =.. [Op, _, _], memberchk(Op, [=, <, >, =<, >=, =\=]).

negate(A > B, A =< B).
negate(A >= B, A < B).
negate(A < B, A >= B).
negate(A =< B, A > B).
negate(A = B, A =\= B).
negate(A =\= B, A = B).

eval_ground(L, F) :-
    (   ground(L)
    ->  ( catch(call_cmp(L), _, fail) -> F = true ; F = false )
    ;   F = L
    ).

call_cmp(A = B) :- !, A =:= B.
call_cmp(C) :- call(C).

arith_term(X) :- var(X), !.
arith_term(X) :- number(X), !.
arith_term(X) :- compound(X), X =.. [Op, A, B], memberchk(Op, [+, -, *]), !, arith_term(A), arith_term(B).
arith_term(-(X)) :- arith_term(X).

% ---------------------------------------------------------------- disjunctive normal form

% dnf(F, Max, Ds): Ds is a list of conjunctions (lists of literals); fails
% when it would have more than Max disjuncts. Conjunctions that are clearly
% contradictory (false, L and not L, X = 1 and X = 0) are removed.
dnf(true, _, [[]]) :- !.
dnf(false, _, []) :- !.
dnf(or(A, B), Max, Ds) :- !,
    dnf(A, Max, DA), dnf(B, Max, DB),
    append(DA, DB, Ds), length(Ds, N), N =< Max.
dnf(and(A, B), Max, Ds) :- !,
    dnf(A, Max, DA), dnf(B, Max, DB),
    product(DA, DB, Ds),
    length(Ds, N), N =< Max.
dnf(L, _, [[L]]).

% no findall: the literals must keep their variables
product([], _, []).
product([X | Xs], DB, Ds) :-
    foldl(merge_into(X), DB, [], Ds1), reverse(Ds1, DsX),
    product(Xs, DB, Ds2),
    append(DsX, Ds2, Ds).

merge_into(X, Y, Acc, Acc1) :-
    ( merge_lits(X, Y, D) -> Acc1 = [D | Acc] ; Acc1 = Acc ).

merge_lits(X, [], X) :- !.
merge_lits(X, [L | Ls], D) :-
    (   memq(L, X)
    ->  X1 = X
    ;   \+ clash(L, X), append(X, [L], X1)
    ),
    merge_lits(X1, Ls, D).

clash(L, Ls) :- negate(L, N), memq(N, Ls), !.
clash(A = N1, Ls) :- number(N1), member(B = N2, Ls), B == A, number(N2), N1 =\= N2, !.

% fallback for clauses too big to split: keep the literals that hold in
% every disjunct (the top-level conjunction) and drop the disjunctions
sure_literals(and(A, B), L) :- !, sure_literals(A, LA), sure_literals(B, LB), append(LA, LB, L).
sure_literals(or(_, _), []) :- !, count(dropped).
sure_literals(true, []) :- !.
sure_literals(false, [1 = 0]) :- !.
sure_literals(L, [L]).
