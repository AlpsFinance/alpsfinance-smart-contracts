// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IStakedAave.sol";

contract AaveStakingHandler {
    using SafeMath for uint256;

    address public AAVE_TOKEN;
    address public STK_AAVE_TOKEN;
    address public MULTISIG_WALLET;

    // ------------- EVENT -------------
    event StakeAave(address staker, uint256 stakeAmount, uint256 fee);
    event ClaimAave(
        address staker,
        uint256 claimAmount,
        uint256 claimTimestamp
    );

    // ------------- ERROR -------------
    error InvalidZeroAmount();

    // ------------- MODIFIER -------------
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

    function stake(uint256 amount) external onlyValidAmount(amount) {
        IERC20(AAVE_TOKEN).transferFrom(msg.sender, address(this), amount);

        // Stake AAVE
        IERC20(AAVE_TOKEN).approve(STK_AAVE_TOKEN, amount);
        IStakedAave(STK_AAVE_TOKEN).stake(address(this), amount);

        // Distributing stkAAVE + fee
        uint256 stakeAaveBalance = IERC20(STK_AAVE_TOKEN).balanceOf(
            address(this)
        );
        uint256 stakingFee = SafeMath.div(stakeAaveBalance, 1000); // 0.1% fee
        IERC20(STK_AAVE_TOKEN).transfer(MULTISIG_WALLET, stakingFee);
        IERC20(STK_AAVE_TOKEN).transfer(
            msg.sender,
            SafeMath.sub(stakeAaveBalance, stakingFee)
        );

        emit StakeAave(msg.sender, amount, stakingFee);
    }
}
