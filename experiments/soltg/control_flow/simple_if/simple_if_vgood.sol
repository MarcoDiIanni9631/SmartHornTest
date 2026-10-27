contract Csi {
	function f(uint256 a, uint256 b) public pure returns (uint256) { uint256 vgood = 42;
		if (a == 0) {
			{ vgood = 1042; assert(vgood < 20); return 0; }
		}
		assert(a!=0);
		{ vgood = 1042; assert(vgood < 20); return b / a; } // This division is safe because of the early return in if-block.
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
