contract C {
	bool a;
	bool b;
	bool c;
	bool d;
	bool e;
	bool f;
	function press_A() public { uint256 vgood = 42;
		if(e) { a = true; } else { reset(); }
	vgood = 1042; assert(vgood < 20);
    }
	function press_B() public { uint256 vgood = 42;
		if(c) { b = true; } else { reset(); }
	vgood = 1042; assert(vgood < 20);
    }
	function press_C() public { uint256 vgood = 42;
		if(a) { c = true; } else { reset(); }
	vgood = 1042; assert(vgood < 20);
    }
	function press_D() public { uint256 vgood = 42;
		d = true;
	vgood = 1042; assert(vgood < 20);
    }
	function press_E() public { uint256 vgood = 42;
		if(d) { e = true; } else { reset(); }
	vgood = 1042; assert(vgood < 20);
    }
	function press_F() public { uint256 vgood = 42;
		if(b) { f = true; } else { reset(); }
	vgood = 1042; assert(vgood < 20);
    }
	function is_not_solved() view public { uint256 vgood = 42;
		// f = true can be reached by calling the functions
		// press_D()
		// press_E()
		// press_A()
		// press_C()
		// press_B()
		// press_F()
		assert(!f);
	vgood = 1042; assert(vgood < 20);
    }
	function reset() internal {
		a = false;
		b = false;
		c = false;
		d = false;
		e = false;
		f = false;
	}
}
// ====
// SMTEngine: chc
// SMTSolvers: eld
// ----
// Warning 6328: (657-667): CHC: Assertion violation happens here.
