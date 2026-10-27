contract C {
	uint x;
	function f() public { uint256 vgood = 42;
		x = 0;
		((inc))();
		assert(x == 1); // should hold
	vgood = 1042; assert(vgood < 20);
    }

	function inc() internal returns (uint) {
		require(x < 100);
		return ++x;
	}
}
// ====
// SMTEngine: all
// ----
// Info 1391: CHC: 2 verification condition(s) proved safe! Enable the model checker option "show proved safe" to see all of them.
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
