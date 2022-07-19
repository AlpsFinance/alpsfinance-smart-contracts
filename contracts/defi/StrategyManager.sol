// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {FeeManager} from '../libraries/FeeManager.sol';

contract StrategyManager is AccessControl, ReentrancyGuard {
  struct Strategy {
    string topic;
    uint256 fee; // 3 decimal place
  }

  mapping(bytes32 => Strategy) public strategyMappingRegistry;

  // ============== ERROR ==============
  error FailedStrategyExecution();
  error InvalidFeeValue();

  // ============== MODIFIER ==============
  modifier onlyValidFee(uint256 amount) {
    // If fee exceeds 100%
    if (amount > 100000) revert InvalidFeeValue();
    _;
  }

  function setStrategyFee(bytes32 strategyId, uint256 fee)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    onlyValidFee(fee)
  {
    strategyMappingRegistry[strategyId].fee = fee;
  }

  function registerStrategy(
    bytes32 strategyId,
    string calldata topic,
    uint256 fee
  ) external onlyRole(DEFAULT_ADMIN_ROLE) onlyValidFee(fee) {
    strategyMappingRegistry[strategyId].topic = topic;
    strategyMappingRegistry[strategyId].fee = fee;
  }

  function executeStrategy(
    address[] calldata targets,
    bytes32[] calldata strategyIds,
    uint256[] calldata params
  ) external nonReentrant {
    for (uint8 i = 0; i < targets.length; i++) {
      (bool success, ) = targets[i].call(
        abi.encodeWithSignature(
          strategyMappingRegistry[strategyIds[i]].topic,
          params[i]
        )
      );
      if (!success) revert FailedStrategyExecution();
    }
  }
}
