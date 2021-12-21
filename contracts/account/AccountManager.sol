// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

import "./MarginAccount.sol";
import "./HedgeFundAccount.sol";

/**
 * THIS IS THE `AccountManager` contract
 *
 * Description:
 *
 * This contract will function as a manager + factory for the account contracts.
 * Some of the main functionality for the `AccountManager` contract will be to:
 * - Create a new user account
 * - Delete an existing user account
 * - Managing access control to protect user's account
 *
 * Currently there are two types of account:
 * - Margin Account (accountId = 0)
 * - Hedge Fund Account (accountId = 1)
 */
contract AccountManager {
    /**
     * ACCOUNT REGISTRIES
     *
     * The registry variables is used to store users account information in mapping type
     * - first address is for user address, e.g. msg.sender
     * - second address is for account address (type: margin or hedge fund)
     */
    mapping(address => address) public marginAccountRegistry;
    mapping(address => address) public hedgeFundAccountRegistry;

    /**
     * Check whether `msg.sender` is the account owner of `accountAddress`
     */
    modifier onlyAccountOwner(uint256 accountId, address accountAddress) {
        require(
            getAccountAddressById(accountId, msg.sender) == accountAddress,
            "You are not the account owner of this account address!"
        );
        _;
    }

    /**
     * To check whether the user has an existing account based on `isExist`
     */
    modifier onlyAccountExist(uint256 accountId, bool isExist) {
        if (isExist) {
            require(
                getAccountAddressById(accountId, msg.sender) != address(0),
                "No existing account found for the user!"
            );
        } else {
            require(
                getAccountAddressById(accountId, msg.sender) == address(0),
                "An existing account found for the user!"
            );
        }
        _;
    }

    /**
     * Get Account address by `accountId`
     */
    function getAccountAddressById(uint256 accountId, address msgSender)
        internal
        view
        returns (address)
    {
        if (accountId == 0) {
            return marginAccountRegistry[msgSender];
        } else if (accountId == 1) {
            return hedgeFundAccountRegistry[msgSender];
        } else {
            return address(0);
        }
    }

    /**
     * Create new user account with type based on `accountId`
     */
    function createNewAccount(uint256 accountId)
        external
        onlyAccountExist(accountId, false)
    {
        if (accountId == 0) {
            MarginAccount newMarginAccount = new MarginAccount();
            marginAccountRegistry[msg.sender] = address(newMarginAccount);
        } else if (accountId == 1) {
            HedgeFundAccount newHedgeFundAccount = new HedgeFundAccount();
            hedgeFundAccountRegistry[msg.sender] = address(newHedgeFundAccount);
        } else {
            revert("Not a valid accountId given!");
        }
    }

    /**
     * Delete an existing user account of `accountAddress`
     */
    function deleteAccount(uint256 accountId, address accountAddress)
        public
        onlyAccountExist(accountId, true)
        onlyAccountOwner(accountId, accountAddress)
    {
        if (accountId == 0) {
            marginAccountRegistry[msg.sender] = address(0);
        } else if (accountId == 1) {
            hedgeFundAccountRegistry[msg.sender] = address(0);
        } else {}
    }
}
