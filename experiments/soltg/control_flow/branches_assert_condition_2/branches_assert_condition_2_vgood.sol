contract Cb1 {
    constructor(){}
    function f(uint x) public returns(bool) { uint256 vgood = 42;
        if (x > 10) {

            assert(x > 9);
            { vgood = 1042; assert(vgood < 20); return true; }
        }
        else if (x > 2)
        {
            assert(x <= 10 && x > 2);
            { vgood = 1042; assert(vgood < 20); return false; }
        }
        else
        {
           assert(0 <= x && x <= 2);
            { vgood = 1042; assert(vgood < 20); return true; }
        }
    vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
