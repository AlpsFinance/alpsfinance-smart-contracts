// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';

library FeeManager {
  error InvalidZeroAmount();

  function calculateFeeAndValue() internal returns (uint256, uint256) {
    if (msg.value <= 0) revert InvalidZeroAmount();
    uint256 depositFee = SafeMath.div(msg.value, 1000); // 0.1% fee
    // SEND Fee to MULTISIG
    return (depositFee, SafeMath.sub(msg.value, depositFee));
  }

  function sendFeeNative() internal {}

  function sendFeeERC20() internal {}
}
