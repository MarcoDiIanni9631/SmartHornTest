contract Cdw2
{
	function f(uint x) public pure { uint256 vgood = 42;
		require(x < 100);
		do {
			x = x + 1;
		} while (x < 1000);
		assert(x > 0);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// SMTSolvers: z3
// ----
