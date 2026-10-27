contract Simplelb {
	function f(uint x) public pure { uint256 vgood = 42;
		uint y;
		require(x > 0);
		while (y < x)
			++y;
		assert(y == x);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// SMTSolvers: z3
// ----
