contract C
{
	function h(uint x) public pure returns (uint) {
		return x;
	}
	function g() public pure { uint256 vgood = 42;
		uint x;
		x = h(42);
		assert(x > 0);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
// Info 1391: CHC: 1 verification condition(s) proved safe! Enable the model checker option "show proved safe" to see all of them.
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
