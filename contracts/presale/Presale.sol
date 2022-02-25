// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../token/interfaces/IERC20Custom.sol";
import "../libraries/PriceConverter.sol";

contract Presale is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    struct PresaleData {
        uint256 startingTime;
        uint256 endingTime;
        uint256 usdPrice;
    }

    Counters.Counter public currentPresaleRound;
    address public tokenAddress;

    // Mapping `presaleRound` to its data details
    mapping(uint256 => PresaleData) presaleDetailsMapping;
    mapping(address => bool) presaleTokenAvaliblilityMapping;

    error presaleRoundClosed();
    error presaleTokenNotAvailable();

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    /**
     * Getting the Current Price
     */
    function getCurrentPrice() public view returns (uint256) {
        return presaleDetailsMapping[currentPresaleRound.current()].usdPrice;
    }

    /**
     * Execute the Presale of ALPS Token in exchange of other token
     *
     * @dev _paymentTokenAddress - Address of the token use to pay (address 0 is for native token)
     * @dev _amount - Amount denominated in the `paymentTokenAddress` being paid
     * @dev _aggregatorTokenAddress - Use to convert price with Chainlink
     */
    function presaleTokens(
        address _paymentTokenAddress,
        uint256 _amount,
        address _aggregatorTokenAddress
    ) public payable nonReentrant {
        uint256 currentPresalePrice = getCurrentPrice();

        // Check whether the presale round is still open
        PresaleData memory currentPresale = presaleDetailsMapping[
            currentPresaleRound.current()
        ];
        if (
            block.timestamp >= currentPresale.startingTime &&
            block.timestamp <= currentPresale.endingTime
        ) revert presaleRoundClosed();

        // Check whether token is valid
        if (presaleTokenAvaliblilityMapping[_paymentTokenAddress])
            revert presaleTokenNotAvailable();

        // Convert the token with Chainlink Price Feed
        uint256 presaleAmount = SafeMath.mul(
            SafeMath.div(
                uint256(
                    PriceConverter.getDerivedPrice(
                        _aggregatorTokenAddress,
                        address(0),
                        18
                    )
                ),
                currentPresalePrice
            ),
            _amount
        );

        // Send ALPS token to `msg.sender`
        IERC20Custom token = IERC20Custom(tokenAddress);
        token.mint(msg.sender, presaleAmount);
    }

    /**
     * Creating/Updating a presale round information
     *
     * @dev _presaleRound
     * @dev _startingTime
     * @dev _endingTime
     * @dev _usdPrice
     */
    function setPresaleRound(
        uint256 _presaleRound,
        uint256 _startingTime,
        uint256 _endingTime,
        uint256 _usdPrice
    ) public onlyOwner {
        presaleDetailsMapping[_presaleRound].startingTime = _startingTime;
        presaleDetailsMapping[_presaleRound].endingTime = _endingTime;
        presaleDetailsMapping[_presaleRound].usdPrice = _usdPrice;
    }
}
