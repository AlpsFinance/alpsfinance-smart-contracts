
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20TokenMock is ERC20 {
    constructor() ERC20("TestToken", "TTK") {
        _mint(msg.sender, 100000000000000000000000000);
    }
}