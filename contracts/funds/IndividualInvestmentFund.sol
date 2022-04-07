// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract IndividualInvestmentFund is AccessControl {
    event TransactionExecuted(
        address[] targets,
        uint256[] values,
        bytes[] calldatas
    );

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}

    /**
     * @dev Exectue transactions through the fund
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) public payable virtual returns (bool) {
        require(
            targets.length == values.length &&
                targets.length == calldatas.length,
            "IndividualInvestmentFund: proposal not successful"
        );

        _execute(targets, values, calldatas);

        emit TransactionExecuted(targets, values, calldatas);

        return true;
    }

    /**
     * @dev Internal execution mechanism. Can be overriden to implement different execution mechanism
     */
    function _execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) internal virtual {
        string
            memory errorMessage = "IndividualInvestmentFund: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{
                value: values[i]
            }(calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
        }
    }
}
