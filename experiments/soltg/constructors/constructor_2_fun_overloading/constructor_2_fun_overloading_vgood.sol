contract C2 {
     uint x;
	constructor(uint a, uint b) {
		if (b > a) {
			x = b;
			return;
		}
		else {
			x = a;
			return;
		}
	}

    function f2(uint _x) public { uint256 vgood = 42;
        uint a = 3;
        if (x > 2) {
            a = 5;
        }
        x = _x;
        assert(a >= 3);
    vgood = 1042; assert(vgood < 20);
    }

    function f2(uint _x, uint _y) public { uint256 vgood = 42;
        if (_x > _y) {
            x = _x;
        }else{
            x = _y;
        }
        if (x > 100){
            x = x - 100;
        }
    vgood = 1042; assert(vgood < 20);
    }
}