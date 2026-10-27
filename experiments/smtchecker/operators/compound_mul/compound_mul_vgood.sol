contract C
{
	function f(uint x) public pure { uint256 vgood = 42;
		require(x < 10);
		uint y = 10;
		y *= y + x;
		assert(y <= 190);
		assert(y < 50);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
// Warning 6328: (117-131): CHC: Assertion violation happens here.\nCounterexample:\n\nx = 0\ny = 100\n\nTransaction trace:\nC.constructor()\nC.f(0)
// Info 1391: CHC: 3 verification condition(s) proved safe! Enable the model checker option "show proved safe" to see all of them.
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
