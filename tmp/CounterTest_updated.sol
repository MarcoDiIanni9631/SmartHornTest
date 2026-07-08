

contract CounterTest {
    uint256 public count;

    function run() public {
        count = count + 1;
        assert(count == 0);
    }
}
