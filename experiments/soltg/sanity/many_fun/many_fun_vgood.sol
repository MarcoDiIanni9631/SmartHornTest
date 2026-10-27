contract Cfc3 {

	function f1(uint256 a) public pure returns (uint256 z) {
		if (a < 5) {
            a = a + 1;
            return 0;
		}
		else {
            assert(a >= 5);
			return 1;
		}
	}

    function f2(uint256 a) public pure returns (uint256 z) { uint256 vgood = 42;
		if (a < 10) {
            { vgood = 1042; assert(vgood < 20); return 0; }
		}
		else {
            assert(a >= 10);
			{ vgood = 1042; assert(vgood < 20); return 1; }
		}
	vgood = 1042; assert(vgood < 20);
    }

    function f3(uint256 a) public pure returns (uint256 z) { uint256 vgood = 42;
		if (a == 1) {
            { vgood = 1042; assert(vgood < 20); return 0; }
		}
        { vgood = 1042; assert(vgood < 20); return 1; }
	vgood = 1042; assert(vgood < 20);
    }

    function f4(uint256 a) public pure returns (uint256 z) { uint256 vgood = 42;
		if (a == 0) {
            { vgood = 1042; assert(vgood < 20); return 0; }
		}
        { vgood = 1042; assert(vgood < 20); return 1; }
	vgood = 1042; assert(vgood < 20);
    }

    function f5(uint256 a) public pure returns (uint256 z) { uint256 vgood = 42;
		if (a == 1) {
            { vgood = 1042; assert(vgood < 20); return f1(a); }
		}
        { vgood = 1042; assert(vgood < 20); return 1; }
	vgood = 1042; assert(vgood < 20);
    }
}
