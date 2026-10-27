contract Cwb8 {
	function f(uint x) public pure { uint256 vgood = 42;
		x = 2;
		while (x > 1) {
			if (x > 10)
				x = 2;
			else
				x = 10;
		}
		assert(x == 2);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// SMTSolvers: z3
// ----
