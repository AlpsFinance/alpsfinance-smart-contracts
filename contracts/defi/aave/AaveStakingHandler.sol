// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IStakedAave} from "./interfaces/IStakedAave.sol";

contract AaveStakingHandler {
    using SafeMath for uint256;

    address public AAVE_TOKEN;
    address public STK_AAVE_TOKEN;
    address public MULTISIG_WALLET;

    // ============== EVENT ==============
    event StakeAave(address staker, uint256 stakeAmount, uint256 fee);
    event ClaimAave(
        address staker,
        uint256 claimAmount,
        uint256 claimTimestamp
    );

    // ============== ERROR ==============
    error InvalidZeroAmount();

    // ============== MODIFIER ==============
    modifier onlyValidAmount(uint256 amount) {
        if (amount <= 0) revert InvalidZeroAmount();
        _;
    }

    constructor(
        address aaveTokenAddress,
        address stkAaveTokenAddress,
        address multisigAddress
    ) {
        AAVE_TOKEN = aaveTokenAddress;
        STK_AAVE_TOKEN = stkAaveTokenAddress;
        MULTISIG_WALLET = multisigAddress;
    }

    /**
     * @dev Stake Aave and minting StkAave
     * @param amount - (uint256)
     */
    function stake(uint256 amount) external onlyValidAmount(amount) {
        _stake(amount);
    }

    /**
     * @dev Stake Aave and minting StkAave with Permit (no approval)
     * @param amount - (uint256)
     */
    function stakeWithPermit(
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyValidAmount(amount) {
        IERC20Permit(AAVE_TOKEN).permit(
            msg.sender,
            address(this),
            amount,
            block.timestamp + 15 minutes,
            v,
            r,
            s
        );
        _stake(amount);
    }

    /**
     * @dev Unstake Aave by burning StkAave
     * @param amount - (uint256) Amount of StkAave that would like to be unstaked
     */
    function unstake(uint256 amount) external onlyValidAmount(amount) {
        _unstake(amount);
    }

    /**
     * @dev Unstake Aave by burning StkAave with Permit (no approval)
     * @param amount - (uint256)
     */
    function unstakeWithPermit(
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyValidAmount(amount) {
        IERC20Permit(STK_AAVE_TOKEN).permit(
            msg.sender,
            address(this),
            amount,
            block.timestamp + 15 minutes,
            v,
            r,
            s
        );
        _unstake(amount);
    }

    // ==================== INTERNAL FUNCTIONS ====================

    function _stake(uint256 amount) internal {
        IERC20(AAVE_TOKEN).transferFrom(msg.sender, address(this), amount);

        // Stake AAVE
        IERC20(AAVE_TOKEN).approve(STK_AAVE_TOKEN, amount);
        uint256 stakingFee = SafeMath.div(amount, 1000); // 0.1% fee
        IStakedAave(STK_AAVE_TOKEN).stake(
            msg.sender,
            SafeMath.sub(amount, stakingFee)
        );
        IStakedAave(STK_AAVE_TOKEN).stake(MULTISIG_WALLET, stakingFee);

        emit StakeAave(msg.sender, amount, stakingFee);
    }

    function _unstake(uint256 amount) internal {
        IERC20(STK_AAVE_TOKEN).transferFrom(msg.sender, address(this), amount);
        uint256 unstakingFee = SafeMath.div(amount, 1000); // 0.1% fee
        IStakedAave(STK_AAVE_TOKEN).redeem(MULTISIG_WALLET, unstakingFee);
        IStakedAave(STK_AAVE_TOKEN).redeem(
            msg.sender,
            SafeMath.sub(amount, unstakingFee)
        );
    }
}
