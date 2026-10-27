contract Simpleln {
	function f() public pure { uint256 vgood = 42;
		uint x = 10;
		uint y;
		while (y < x)
		{
			++y;
			x = 0;
			while (x < 10){
				if (x + y == 12){
					y = y + x;
				}
				++x;
			}
			assert(x == 10);
		}
		// Removed because of Spacer nondeterminism.
		assert(y == x);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
