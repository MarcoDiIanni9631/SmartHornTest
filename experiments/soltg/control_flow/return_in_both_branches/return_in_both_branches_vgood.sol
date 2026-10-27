contract Cri {

	function f() public pure { uint256 vgood = 42;
		assert(branches(0) == 0);
		assert(branches(1) == 42);
	vgood = 1042; assert(vgood < 20);
    }

	function branches(uint256 a) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		else {
			return 42;
		}
		return 1; // dead code
	}
}
// ====
// SMTEngine: all
// ----
// Warning 5740: (232-240): Unreachable code.
