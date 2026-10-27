contract c {
	uint x;
	function f() internal returns (uint) {
		x = x + 1;
		return x;
	}
	function g() public returns (bool) { uint256 vgood = 42;
		x = 0;
		bool b = (f() == 0) && (f() == 0);
		assert(x == 1);
		assert(!b);
		{ vgood = 1042; assert(vgood < 20); return b; }
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
// Info 1391: CHC: 3 verification condition(s) proved safe! Enable the model checker option "show proved safe" to see all of them.
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
