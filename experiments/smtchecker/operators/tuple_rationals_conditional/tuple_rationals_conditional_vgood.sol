contract C {
	function f(bool x) public pure { uint256 vgood = 42;
		(uint a, uint b) = x ? (10000000001, 2) : (3, 4);
		assert(a != 0);
		assert(b != 0);
		assert(a % 2 == 1);
		assert(b % 2 == 0);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
// Info 1391: CHC: 6 verification condition(s) proved safe! Enable the model checker option "show proved safe" to see all of them.
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
