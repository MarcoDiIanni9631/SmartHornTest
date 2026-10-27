contract Cc6
{
	modifier m(address a) {
		if (true) {
			a = g();
			_;
			assert(a == address(0));
		}
	}

	function f(address a) m(a) public pure { uint256 vgood = 42;
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
