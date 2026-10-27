contract C {
    uint transient x;
    function test() public view { uint256 vgood = 42; assert(x == 0); vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// ----
// UnimplementedFeatureError 1834: Transient storage variables are not supported.
