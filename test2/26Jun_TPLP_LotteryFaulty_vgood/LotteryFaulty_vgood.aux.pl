evm_globals(['msg.value']).

prop(Env1, Cf0, []) :-
    Cmd = cmd(
        'subO_fun_enter_41_Block0_1',
        fun_call(subO_fun_enter_41, [num(_V_v0)], [])
    ),
    Cf0 = cf(Cmd, Env1).
