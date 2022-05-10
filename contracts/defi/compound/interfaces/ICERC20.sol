// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICTokens is IERC20 {
    /**
     * @dev only for cETH contract
     */
    function mint() external payable;

    /**
     * @dev only for cERC20 contracts
     */
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);
}
