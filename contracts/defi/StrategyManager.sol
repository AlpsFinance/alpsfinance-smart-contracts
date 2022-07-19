// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {FeeManager} from '../libraries/FeeManager.sol';

contract StrategyManager is AccessControl {
  function setStrategyFee() public {}

  function registerStrategy(bytes32 strategyId, uint256 fee) public {}

  function executeStrategy() public {}
}
