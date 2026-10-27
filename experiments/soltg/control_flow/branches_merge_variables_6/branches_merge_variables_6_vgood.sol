// Variable is reset in both branches
contract Cb8 {
    function f(uint x) public pure { uint256 vgood = 42;
        uint a = 2;
        if (x > 10) {
            a = 3;
        } else {
            a = 4;
        }
        assert(a >= 3);
    vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
