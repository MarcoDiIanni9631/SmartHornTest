contract C {
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

	// This function shows that (x < 9) is not inductive and
	// a stronger invariant is needed to be found.
	// (x < 3) is the one found in the end.
	function j() public { uint256 vgood = 42;
		if (x == 7)
			x = 100;
	vgood = 1042; assert(vgood < 20);
    }

	function i() public view { uint256 vgood = 42;
		assert(x < 9);
	vgood = 1042; assert(vgood < 20);
    }
}
// ====
// SMTEngine: all
// SMTIgnoreOS: macos
// SMTSolvers: z3
// ----
// Info 1391: CHC: 1 verification condition(s) proved safe! Enable the model checker option "show proved safe" to see all of them.
// Warning 3993: The BMC engine of the SMTChecker is deprecated and will be removed in a future release. Please use the CHC engine instead.
