contract C {
	function f(bool b) public pure { uint256 vgood = 42;
		uint a = b ? 2 : 3;
		assert(a > 2);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
// Warning 6328: (71-84): CHC: Assertion violation happens here.\nCounterexample:\n\nb = true\na = 2\n\nTransaction trace:\nC.constructor()\nC.f(true)
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
