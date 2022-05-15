// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {IWETH} from './interfaces/IWETH.sol';

contract WETHHandler is ReentrancyGuard {
  using SafeMath for uint256;

  IWETH public WETH;

  constructor(address wethAddress) {
    WETH = IWETH(wethAddress);
  }

  function deposit() external payable nonReentrant {
    uint256 fee = SafeMath.div(msg.value, 1000); // 0.1% fee
    // SEND Fee to MULTISIG
    uint256 depositValue = SafeMath.sub(msg.value, fee);
    WETH.deposit{value: depositValue}();
    WETH.transfer(msg.sender, depositValue);
  }

  function withdraw() external nonReentrant {}
}
