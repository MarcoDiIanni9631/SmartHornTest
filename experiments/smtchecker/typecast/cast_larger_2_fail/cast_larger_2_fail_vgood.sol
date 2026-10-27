contract C
{
	function f() public pure { uint256 vgood = 42;
		uint16 a = 0x1234;
		uint32 b = uint32(a); // b will be 0x00001234 now
		assert(a != b);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
// Warning 6328: (116-130): CHC: Assertion violation happens here.\nCounterexample:\n\na = 4660\nb = 4660\n\nTransaction trace:\nC.constructor()\nC.f()
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
