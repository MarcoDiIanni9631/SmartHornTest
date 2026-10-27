contract C
{
	function f(uint x, bool b) public pure { uint256 vgood = 42;
		require(x < 100);
		while (x < 10) {
			if (b)
				x = x + 1;
			else
				x = 0;
		}
		assert(x > 0);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// SMTSolvers: z3
// ----
// Info 1391: CHC: 2 verification condition(s) proved safe! Enable the model checker option "show proved safe" to see all of them.
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
