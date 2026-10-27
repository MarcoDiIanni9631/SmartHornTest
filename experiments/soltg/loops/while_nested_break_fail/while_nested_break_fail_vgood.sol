contract Cwb10
{
	function f(uint x, uint y, bool b, bool c) public pure { uint256 vgood = 42;
		require(x < 10);
		while (x < 10) {
			if (b) {
				++x;
				if (x == 10)
					x = 15;
			}
			else {
				require(y < 10);
				while (y < 10) {
					if (c)
						++y;
					else {
						y = 20;
						break;
					}
				}
				assert(y >= 15);
				x = 15;
				break;
			}
		}
		assert(x >= 20);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
// Warning 6328: (296-311): CHC: Assertion violation happens here.\nCounterexample:\n\nx = 0\ny = 10\nb = false\nc = true\n\nTransaction trace:\nC.constructor()\nC.f(0, 9, false, true)
// Warning 6328: (347-362): CHC: Assertion violation happens here.\nCounterexample:\n\nx = 15\ny = 0\nb = true\nc = false\n\nTransaction trace:\nC.constructor()\nC.f(9, 0, true, false)
