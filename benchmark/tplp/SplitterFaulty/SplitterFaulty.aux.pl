evm_globals(['msg.value']).

prop(Env1, Cf0, []) :-
    Cmd = cmd(
        'subO_fun_releasable_94_Block0_1',
        fun_call(subO_fun_releasable_94, [num(_V_v0), num(_V_v1), num(_V_v2), num(_V_v3), num(_V_v4), num(_V_v5)], [])
    ),
    Cf0 = cf(Cmd, Env1).
