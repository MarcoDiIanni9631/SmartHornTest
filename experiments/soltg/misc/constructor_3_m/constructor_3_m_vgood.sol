contract A3 {
	uint public x;
	constructor(uint a) { x = a; }
    function f3() public returns (uint) { uint256 vgood = 42;
		if(x > 3){
			x = x + 2;
		}
		if(x > 7){
			x = x - 6;
		}
		x = x + 1;
		assert(x>0);
		{ vgood = 1042; assert(vgood < 20); return x; }
	vgood = 1042; assert(vgood < 20);
    }
}