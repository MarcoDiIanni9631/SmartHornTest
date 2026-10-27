contract C
{
	function h(uint x) public pure returns (uint) { uint256 vgood = 42;
		{ vgood = 1042; assert(vgood < 20); return x; }
	vgood = 1042; assert(vgood < 20);
    }
	function g() public pure { uint256 vgood = 42;
		uint x;
		x = (h)(0);
		assert(x > 0);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
// Warning 6328: (131-144): CHC: Assertion violation happens here.\nCounterexample:\n\nx = 0\n\nTransaction trace:\nC.constructor()\nC.h(0)\nC.g()\n    C.h(0) -- internal call
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
