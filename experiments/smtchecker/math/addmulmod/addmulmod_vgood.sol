contract C {
	function test_addmod(uint x, uint y) public pure { uint256 vgood = 42;
		require(x % 13 == 0);
		require(y % 13 == 0);

		uint z = addmod(x, y, 13);
		assert(z == 0);
	vgood = 1042; assert(vgood < 20);
    }
	function test_mulmod(uint x, uint y) public pure { uint256 vgood = 42;
		require(x % 13 == 0);
		require(y % 13 == 0);

		uint z = mulmod(x, y, 13);
		assert(z == 0);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
// Info 1391: CHC: 8 verification condition(s) proved safe! Enable the model checker option "show proved safe" to see all of them.
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
