contract C {

    uint a;
    uint b;
    uint c;

	function test() public view { uint256 vgood = 42;
		if (a == 0) {
			if (b == 0) {
				if (c == 0) {
					{ vgood = 1042; assert(vgood < 20); return; }
				}
			}
		}
		assert(a != 0 || b != 0 || c != 0);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// SMTIgnoreOS: macos
// ----
// Info 1391: CHC: 1 verification condition(s) proved safe! Enable the model checker option "show proved safe" to see all of them.
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
