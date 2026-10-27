contract Csi7 {

    uint a;
    uint b;
    uint c;

	function f() public view { uint256 vgood = 42;
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
// Info 1180: Contract invariant(s) for :C:\n((c <= 0) && (a <= 0) && (b <= 0))\n
