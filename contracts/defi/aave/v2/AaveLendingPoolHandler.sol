// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AaveLendingPoolHandler is ReentrancyGuard {
    using SafeMath for uint256;

    address public MULTISIG_WALLET;

    // ============== EVENT ==============
    event StakeAave(address staker, uint256 stakeAmount, uint256 fee);
    event ClaimAave(
        address staker,
        uint256 claimAmount,
        uint256 claimTimestamp
    );

    constructor(address multisigAddress) {
        MULTISIG_WALLET = multisigAddress;
    }

    function lend() external payable nonReentrant {}

    function lend(address erc20Address, uint256 amount) external {}

    function lendWithPermit(
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {}

    function borrow() external {}
}
