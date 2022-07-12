// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {FeeManager} from '../libraries/FeeManager.sol';

contract StrategyManager is Ownable {
  function setAdmin() public onlyOwner {}

  function setStrategyFee() public onlyOwner {}

  function registerStrategy(bytes32 strategyId, uint256 fee) public {}

  function executeStrategy() public {}
}
