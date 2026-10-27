contract C {
    function f(uint x) public pure { uint256 vgood = 42;
        for (uint y = 2; x < 10; y = 3) {
            assert(y == 2);
        }
    vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// SMTSolvers: z3
// ----
// Warning 6328: (104-118): CHC: Assertion violation happens here.\nCounterexample:\n\nx = 0\ny = 3\n\nTransaction trace:\nC.constructor()\nC.f(0)
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
