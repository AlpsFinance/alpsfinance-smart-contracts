// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./IndividualInvestmentFund.sol";
import "./DAOInvestmentFund/DAOInvestmentFundBase.sol";

/**
 * @notice THIS IS THE `FundFactory` contract
 *
 * @dev Description:
 *
 * This contract will function as a manager + factory for the investment fund contracts.
 * Some of the main functionality for the `FundFactory` contract will be to:
 * - Create a new user fund
 * - "Burning" exsiting user's fund
 * - Managing access control to protect user's account
 *
 * Currently there are two types of funds:
 * - Individual Investment Fund
 * - DAO Investment Fund
 */
contract FundFactory is Initializable {
    enum InvestmentFundType {
        INDIVIDUAL,
        DAO
    }

    /**
     * Fund REGISTRIES
     *
     * The registry variables is used to store users account information in mapping type
     * - first address is for user address, e.g. msg.sender
     * - second address is for fund's address (type: individual or DAO investment fund)
     */
    mapping(address => address) public individualInvestmentFundRegistry;
    mapping(address => address) public daoInvestmentFundRegistry;

    /**
     * @dev Check whether `msg.sender` is the fund owner of `accountAddress`
     */
    modifier onlyFundOwner(
        InvestmentFundType investmentFund,
        address accountAddress
    ) {
        require(
            getAccountAddressById(investmentFund, msg.sender) == accountAddress,
            "You are not the account owner of this account address!"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Get Account address by `accountId`
     */
    function getAccountAddressById(
        InvestmentFundType investmentFund,
        address account
    ) internal view returns (address) {
        if (investmentFund == InvestmentFundType.INDIVIDUAL) {
            return individualInvestmentFundRegistry[account];
        } else if (investmentFund == InvestmentFundType.DAO) {
            return daoInvestmentFundRegistry[account];
        } else {
            return address(0);
        }
    }

    /**
     * @dev Create new user account with type based on `accountId`
     */
    function createNewFund(InvestmentFundType investmentFund) external {
        if (investmentFund == InvestmentFundType.INDIVIDUAL) {
            IndividualInvestmentFund newIndividualInvestmentFund = new IndividualInvestmentFund();
            individualInvestmentFundRegistry[msg.sender] = address(
                newIndividualInvestmentFund
            );
        } else if (investmentFund == InvestmentFundType.DAO) {
            // DAOInvestmentFundBase newDAOInvestmentFund = new DAOInvestmentFundBase();
            daoInvestmentFundRegistry[msg.sender] = address(0);
        } else {
            revert("Not a valid accountId given!");
        }
    }

    /**
     * @dev "Burn" an existing user account of `accountAddress`
     */
    function burnExistingFund(
        InvestmentFundType investmentFund,
        address accountAddress
    ) public onlyFundOwner(investmentFund, accountAddress) {
        if (investmentFund == InvestmentFundType.INDIVIDUAL) {
            individualInvestmentFundRegistry[msg.sender] = address(0);
        } else if (investmentFund == InvestmentFundType.DAO) {
            daoInvestmentFundRegistry[msg.sender] = address(0);
        } else {}
    }
}
