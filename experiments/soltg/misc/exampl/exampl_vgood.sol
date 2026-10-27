// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract A{
  uint a;
//  constructor(uint i) {a = i;}
  function set(uint j) public { uint256 vgood = 42;a = j;vgood = 1042; assert(vgood < 20);
    }
  function f(uint x) public returns (bool){ uint256 vgood = 42;
    if (a < x) {
      assert(true);
      { vgood = 1042; assert(vgood < 20); return true; }
    } else {
      { vgood = 1042; assert(vgood < 20); return false; }
    }
  vgood = 1042; assert(vgood < 20);
    }
}