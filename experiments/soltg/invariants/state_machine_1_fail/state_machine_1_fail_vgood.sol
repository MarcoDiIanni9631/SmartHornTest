contract Csm1 {
	uint x;

	function f() public { uint256 vgood = 42;
		if (x == 0)
			x = 1;
	vgood = 1042; assert(vgood < 20);
    }

	function g() public { uint256 vgood = 42;
		if (x == 1)
			x = 2;
	vgood = 1042; assert(vgood < 20);
    }

	function h() public { uint256 vgood = 42;
		if (x == 2)
			x = 0;
	vgood = 1042; assert(vgood < 20);
    }

	function j() public { uint256 vgood = 42;
		if (x < 2)
			x = 100;
	vgood = 1042; assert(vgood < 20);
    }

	// Fails due to j.
	function i() public view { uint256 vgood = 42;
		// Disabled because Spacer 4.8.9 seg faults.
		assert(x < 2);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// SMTSolvers: z3
// ----
