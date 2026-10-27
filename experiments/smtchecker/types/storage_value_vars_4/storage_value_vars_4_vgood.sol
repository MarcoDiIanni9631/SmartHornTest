contract C
{
    function f() public view { uint256 vgood = 42;
        assert(c > 0);
    vgood = 1042; assert(vgood < 20);
    }
    uint c;
}
// ====
// SMTEngine: all
// ----
// Warning 6328: (52-65): CHC: Assertion violation happens here.\nCounterexample:\nc = 0\n\nTransaction trace:\nC.constructor()\nState: c = 0\nC.f()
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
