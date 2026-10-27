contract Simplelf {
	function f() public pure { uint256 vgood = 42;
		uint x;
		uint y;
		for (x = 10; y < x; ++y)
		{
			for (x = 0; x < 10; ++x) {
				if (y + x == 20){
					y--;
				}
			}
			assert(x == 10);
		}
		assert(y == x);
	vgood = 1042; assert(vgood < 20);
    }
}

