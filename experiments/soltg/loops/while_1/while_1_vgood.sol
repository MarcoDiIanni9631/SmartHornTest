contract Cwb1
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
