// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// ERC20 openzeppelin wrapper with an implemented mint function.
import "@openzeppelin-contracts/token/ERC20/ERC20.sol";

contract E20 is ERC20 {
    constructor() ERC20("TestUSD", "TUSD") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
