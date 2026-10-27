contract cs4 {
	uint x;
	function f() internal returns (uint) {
		x = x + 1;
		return x;
	}
	function g() public returns (bool) { uint256 vgood = 42;
		x = 0;
		bool b = (f() > 0) && (f() > 0);
		assert(x == 2);
		assert(b);
		{ vgood = 1042; assert(vgood < 20); return b; }
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
