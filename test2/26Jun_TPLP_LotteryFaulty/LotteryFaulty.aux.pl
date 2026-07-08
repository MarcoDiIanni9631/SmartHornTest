evm_globals(['msg.value']).

prop(Env1, Cf0, []) :-
    Cmd = cmd(
        'subO_fun_enter_37_Block0_1',
        fun_call(subO_fun_enter_37, [num(_V_v0)], [])
    ),
    Cf0 = cf(Cmd, Env1).
