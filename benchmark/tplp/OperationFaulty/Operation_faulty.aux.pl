evm_globals(['msg.value']).

prop(Env1, Cf0, []) :-
    Cmd = cmd(
        'subO_fun_positiveDifference_38_Block0_1',
        fun_call(subO_fun_positiveDifference_38, [num(_V_v0), num(_V_v1)], [])
    ),
    Cf0 = cf(Cmd, Env1).
