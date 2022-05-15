// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {IWETH} from './interfaces/IWETH.sol';

contract WETHHandler is ReentrancyGuard {
  using SafeMath for uint256;

  IWETH public immutable WETH;

  constructor(address wethAddress) {
    WETH = IWETH(wethAddress);
  }

  // ============== EVENT ==============
  event DepositWrapped(address user, uint256 depositAmount, uint256 depositFee);
  event WithdrawWrapped(
    address user,
    uint256 withdrawalAmount,
    uint256 withdrawalFee
  );

  // ============== ERROR ==============
  error InvalidZeroAmount();

  /**
   * @dev Deposit ETH for WETH (or native for Wrapped Native token in general)
   */
  function deposit() external payable nonReentrant {
    if (msg.value <= 0) revert InvalidZeroAmount();
    uint256 depositFee = SafeMath.div(msg.value, 1000); // 0.1% fee
    // SEND Fee to MULTISIG
    uint256 depositValue = SafeMath.sub(msg.value, depositFee);
    WETH.deposit{value: depositValue}();
    WETH.transfer(msg.sender, depositValue);

    emit DepositWrapped(msg.sender, depositValue, depositFee);
  }

  /**
   * @dev Withdraw WETH for ETH (or Wrapped Native token for Native token in general)
   * @param amount (uint256) - amount of WETH to be burnt and withdraw ETH
   */
  function withdraw(uint256 amount) external nonReentrant {
    if (amount <= 0) revert InvalidZeroAmount();
    WETH.transferFrom(msg.sender, address(this), amount);
    WETH.withdraw(amount);
    uint256 withdrawalFee = SafeMath.div(amount, 1000); // 0.1% fee
    uint256 withdrawalValue = SafeMath.sub(amount, withdrawalFee);
    // SEND Fee to MULTISIG
    payable(msg.sender).transfer(withdrawalValue);

    emit WithdrawWrapped(msg.sender, withdrawalValue, withdrawalFee);
  }
}
