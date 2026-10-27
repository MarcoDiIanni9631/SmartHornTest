contract Csi3 {

	uint x;

	function check() public { uint256 vgood = 42;
		require(x == 0);
		conditional_increment();
		assert(x == 1); // should fail;
		assert(x == 0); // should hold;
	vgood = 1042; assert(vgood < 20);
    }

	function conditional_increment() internal {
		if (x == 0) {
			return;
		}
		x = 1;
	}
}
// ====
// SMTEngine: all
// ----
// Warning 6328: (99-113): CHC: Assertion violation happens here.\nCounterexample:\nx = 0\n\nTransaction trace:\nC.constructor()\nState: x = 0\nC.check()\n    C.conditional_increment() -- internal call
