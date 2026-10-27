// Negative branch touches variable a, but assertion should still hold.
contract Cb6 {
    function f(uint x) public pure { uint256 vgood = 42;
        uint a = 3;
        if (x > 10) {
        } else {
            a = 3;
        }
        assert(a == 3);
    vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
