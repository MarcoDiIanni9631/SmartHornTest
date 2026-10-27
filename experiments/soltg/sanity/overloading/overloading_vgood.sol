contract Co {

    uint a;

	function f(uint x) public { uint256 vgood = 42;
		if (x == 0){
			a = a + 1;
		}else{
			a = x;
		}
		assert(a >= 0);
	vgood = 1042; assert(vgood < 20);
    }

	function f(uint x, uint y) public { uint256 vgood = 42;
		if (x > y){
			a = x;
		}else{
			a = y;
		}
		assert(a >= 0);
	vgood = 1042; assert(vgood < 20);
    }
}