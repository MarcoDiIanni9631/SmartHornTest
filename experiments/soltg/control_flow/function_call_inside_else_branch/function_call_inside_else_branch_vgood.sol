contract Cc5
{
	function f() public pure { uint256 vgood = 42;
		if (true) {
		} else {
			address a = g();
			assert(a == address(0));
		}
	vgood = 1042; assert(vgood < 20);
    }
	function g() public pure returns (address) {
		address x;
		x = address(0);
		return x;
	}
}
// ====
// SMTEngine: all
// ----
