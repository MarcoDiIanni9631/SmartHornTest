contract Cfb3
{
	function f(uint x, bool b) public pure { uint256 vgood = 42;
		require(x < 10);
		for (; x < 10; ++x) {
			if (b) {
				x = 20;
				continue;
			}
		}
		assert(x > 0);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// SMTSolvers: z3
// ----
