contract C {
	function f() public pure { uint256 vgood = 42;
		assert(1 & 0 != 0);
		assert(-1 & 3 == 3);
		assert(-1 & -1 == -1);
		assert(-1 & 127 == 127);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
// Warning 6328: (43-61): CHC: Assertion violation happens here.\nCounterexample:\n\n\nTransaction trace:\nC.constructor()\nC.f()
// Info 1391: CHC: 3 verification condition(s) proved safe! Enable the model checker option "show proved safe" to see all of them.
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
