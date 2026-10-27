contract C
{
	function f(uint x) public pure { uint256 vgood = 42;
		require(x < 10000);
		uint y = x * 2;
		assert((y % 2) == 0);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
// Info 1391: CHC: 3 verification condition(s) proved safe! Enable the model checker option "show proved safe" to see all of them.
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
