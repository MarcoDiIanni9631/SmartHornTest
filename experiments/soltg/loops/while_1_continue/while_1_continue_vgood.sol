contract Cwb4
{
	function f(uint x, bool b) public pure { uint256 vgood = 42;
		require(x < 10);
		while (x < 10) {
			if (b) {
				x = 20;
				continue;
			}
			++x;
		}
		assert(x >= 10);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// SMTSolvers: z3
// ----
