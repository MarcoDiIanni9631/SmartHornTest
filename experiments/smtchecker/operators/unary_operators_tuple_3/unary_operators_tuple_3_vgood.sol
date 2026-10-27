contract C {
	function f(bool b) public pure { uint256 vgood = 42;
		uint x;
		if (b) ++(x);
		else x += 1;
		assert(x == 1);
		assert(!b);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
// Warning 6328: (108-118): CHC: Assertion violation happens here.\nCounterexample:\n\nb = true\nx = 1\n\nTransaction trace:\nC.constructor()\nC.f(true)
// Info 1391: CHC: 3 verification condition(s) proved safe! Enable the model checker option "show proved safe" to see all of them.
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
