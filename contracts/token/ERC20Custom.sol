// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ERC20Custom is
    ERC20,
    ERC20Burnable,
    Pausable,
    AccessControl,
    ERC20Permit,
    ERC20Votes
{
    using SafeMath for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _cap;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _capSupply
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        require(_capSupply > 0, "ERC20Capped: cap is 0");
        _cap = _capSupply;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev Set new cap supply
     */
    function setCap(uint256 _newCap) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _newCap > totalSupply(),
            "ERC20Custom: New cap set to be lower than or equal to total supply!"
        );
        _cap = _newCap;
    }

    /**
     * @dev Increase the cap supply
     */
    function increaseCap(uint256 _increaseCap) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _increaseCap > 0,
            "ERC20Custom: Increase Cap value has non-valid 0 value!"
        );
        _cap = SafeMath.add(cap(), _increaseCap);
    }

    /**
     * @dev Decrease the cap supply
     */
    function decreaseCap(uint256 _decreaseCap) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            (_decreaseCap > 0) &&
                (_decreaseCap <= SafeMath.sub(cap(), totalSupply())),
            "ERC20Custom: Decrease Cap value has non-valid value!"
        );
        _cap = SafeMath.sub(cap(), _decreaseCap);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        require(
            ERC20.totalSupply() + amount <= cap(),
            "ERC20Capped: cap exceeded"
        );
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
