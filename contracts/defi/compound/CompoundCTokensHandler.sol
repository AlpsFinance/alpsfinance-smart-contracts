// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CompoundCTokensHandler {
    function lend() external payable {}

    function lend(address erc20Address, uint256 amount) external {}

    function borrow() external {}
}
