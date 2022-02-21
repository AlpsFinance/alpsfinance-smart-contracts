// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Presale is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    struct PresaleData {
        uint256 startingDate;
        uint256 price;
    }

    Counters.Counter public presaleRound;
    address public tokenAddress;

    // Mapping `presaleRound` to its data details
    mapping(uint256 => PresaleData) presaleDetailsMapping;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    /**
     * Getting the current Presale Round
     */
    function getCurrentPresaleRound() public pure returns (uint256) {
        return 0;
    }

    /**
     * Getting the Current Price
     */
    function getCurrentPrice() public view returns (uint256) {
        uint256 currentPresaleRound = getCurrentPresaleRound();
        return presaleDetailsMapping[currentPresaleRound].price;
    }

    /**
     * Execute the Presale of ALPS Token in exchange of other token
     *
     * @dev paymentTokenAddress - Address of the token use to pay (address 0 is for native token)
     * @dev amount - Amount denominated in the `paymentTokenAddress` being paid
     * @dev aggregatorTokenAddress - Use to convert price with Chainlink
     */
    function presaleTokens(
        address paymentTokenAddress,
        uint256 amount,
        address aggregatorTokenAddress
    ) public payable {}
}
