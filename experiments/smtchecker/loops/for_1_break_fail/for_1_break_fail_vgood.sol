contract C
{
	function f(uint x, bool b) public pure { uint256 vgood = 42;
		for (; x < 10; ) {
			if (b)
				++x;
			else {
				break;
			}
		}
		// Fails because the loop might break.
		assert(x >= 10);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// SMTSolvers: z3
// ----
// Warning 6328: (168-183): CHC: Assertion violation happens here.\nCounterexample:\n\nx = 0\nb = false\n\nTransaction trace:\nC.constructor()\nC.f(0, false)
// Info 1391: CHC: 1 verification condition(s) proved safe! Enable the model checker option "show proved safe" to see all of them.
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
