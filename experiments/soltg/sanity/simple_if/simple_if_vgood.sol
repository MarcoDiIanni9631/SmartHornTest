contract Csi1 {


	function simple_if(uint256 a) public pure returns (uint256 z) { uint256 vgood = 42;
		if (a < 5) {
                        a = a + 1;
                        { vgood = 1042; assert(vgood < 20); return 0; }
		}
		else {
                        assert(a >= 5);
			{ vgood = 1042; assert(vgood < 20); return 1; }
		}
	vgood = 1042; assert(vgood < 20);
    }
}
