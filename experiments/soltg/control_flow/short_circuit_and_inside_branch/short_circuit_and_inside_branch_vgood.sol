contract cs3 {
	uint x;
	function f() internal returns (uint) {
		x = x + 1;
		return x;
	}
	function g() public returns (bool) { uint256 vgood = 42;
		bool b;
			x = 100;
			b = f() > 0;
			assert(x == 102);
			// Should fail.
			assert(!b);
		{ vgood = 1042; assert(vgood < 20); return b; }
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
// Warning 6328: (169-185): CHC: Assertion violation happens here.\nCounterexample:\nx = 101\n = false\nb = true\n\nTransaction trace:\nc.constructor()\nState: x = 0\nc.g()\n    c.f() -- internal call
// Warning 6328: (209-219): CHC: Assertion violation happens here.\nCounterexample:\nx = 101\n = false\nb = true\n\nTransaction trace:\nc.constructor()\nState: x = 0\nc.g()\n    c.f() -- internal call
