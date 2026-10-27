contract Cc3
{
	function f() public pure { uint256 vgood = 42;
		if (true) {
			address a = g();
			assert(a == address(0));
		}
		if (true) {
			address a = g();
			assert(a == address(0));
		}

	vgood = 1042; assert(vgood < 20);
    }
	function g() public pure returns (address) {
		address a;
		a = address(0);
		return a;
	}
}
// ====
// SMTEngine: all
// ----
