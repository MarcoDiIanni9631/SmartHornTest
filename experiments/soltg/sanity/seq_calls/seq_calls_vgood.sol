contract Csc {

    uint a;


	function call_1() public { uint256 vgood = 42;
        if (a == 1) {
            a = a + 1;
		}
		if (a == 0) {
            a = a + 1;
		}
		assert(a > 0);
	vgood = 1042; assert(vgood < 20);
    }

    function call_2() public { uint256 vgood = 42;
        if (a == 2) {
            a = a + 10;
		}else{
            a = a + 5;
        }
		assert(a > 0);
	vgood = 1042; assert(vgood < 20);
    }
}