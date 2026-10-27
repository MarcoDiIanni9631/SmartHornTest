// SPDX-License-Identifier: MIT

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
contract  Math {


    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) public pure returns (uint256) { uint256 vgood = 42;
        if(a >= b){
            assert(a>=b);
            { vgood = 1042; assert(vgood < 20); return a; }
        } else {
            assert(b>a);
            { vgood = 1042; assert(vgood < 20); return b; }
        }
    vgood = 1042; assert(vgood < 20);
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) public pure returns (uint256) { uint256 vgood = 42;
        if(a < b){
            assert(a<b);
            { vgood = 1042; assert(vgood < 20); return a; }
        } else {
            assert(b>a);
            { vgood = 1042; assert(vgood < 20); return b; }
        }
    vgood = 1042; assert(vgood < 20);
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) public pure returns (uint256) { uint256 vgood = 42;

        assert(((a & b) + (a ^ b) / 2)*2 == a+b);
        // (a + b) / 2 can overflow.
        { vgood = 1042; assert(vgood < 20); return (a & b) + (a ^ b) / 2; }
    vgood = 1042; assert(vgood < 20);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) public pure returns (uint256) { uint256 vgood = 42;
        // (a + b - 1) / b can overflow on addition, so we distribute.
        { vgood = 1042; assert(vgood < 20); return a / b + (a % b == 0 ? 0 : 1); }
    vgood = 1042; assert(vgood < 20);
    }
}
