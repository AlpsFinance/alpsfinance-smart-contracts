// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

/**
 * @title Vesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, vesting period. Optionally revocable by the
 * creator.
 */
contract VestingBase is Ownable, Pausable {
  using SafeMath for uint256;

  /// @notice The sum total amount of tokens withdrawn from all allocations.
  uint256 public totalWithdrawn;

  /// @notice The ERC20 contract of the coin being vested.
  ERC20 public vestingCoin;

  mapping(uint256 => mapping(address => bool)) vestingClaimed;
  mapping(uint256 => bytes32) private RootToRounds;

  /// Events;
  event FundRemoved(address indexed _address, uint256 _amount);
  event Withdrawn(address indexed _address, uint256 _amount);

  /**
   * @notice Constructs this contract
   * @param _vestingCoin The ERC20 contract of the coin being vested.
   */
  constructor(ERC20 _vestingCoin) {
    vestingCoin = _vestingCoin;
  }

  /**
   * @notice The Vesting Token balance of this smart contract.
   * @return Returns the closing balance of vesting coin held by this contract.
   */
  function getAvailableFunds() public view returns (uint256) {
    return vestingCoin.balanceOf(address(this));
  }

  /**
   * @notice Gets the markle tree of each vesting Rounds.
   * @param _round The round of which markleTree to be viewed.
   * @return Returns Total vested balance.
   */
  function getMerkleRoot(uint256 _round)
    public
    view
    onlyOwner
    returns (bytes32)
  {
    return RootToRounds[_round];
  }

  /**
   * @notice Allows you to withdraw the surplus balance of the vesting coin from this contract.
   * Please note that this action is restricted to administrators only
   * and you may only withdraw amounts above the sum total allocation balances.
   * @param _amount The amount desired to withdraw.
   * @return Returns true if the withdrawal was successful.
   */
  function removeFunds(uint256 _amount) external onlyOwner returns (bool) {
    uint256 balance = vestingCoin.balanceOf(address(this));

    require(balance >= _amount, 'amount is grater than balanace');

    require(vestingCoin.transfer(msg.sender, _amount));

    emit FundRemoved(msg.sender, _amount);
    return true;
  }

  /**
   * @notice This action enables admin to set newMarkelRoot.
   */
  function setMerkleRoot(bytes32 _newMerkleRoot, uint256 _round)
    external
    onlyOwner
  {
    require(
      _newMerkleRoot != 0x00,
      'VestingBase: Invalid new merkle root value!'
    );

    RootToRounds[_round] = _newMerkleRoot;
  }

  /**
   * @notice This action enables the beneficiaries to withdraw a desired amount from this contract.
   * @param _amount The amount in vesting coin desired to withdraw.
   */
  function withdraw(
    uint256 _amount,
    bytes32[] calldata _proof,
    uint256 _round
  ) external whenNotPaused returns (bool) {
    require(
      !vestingClaimed[_round][msg.sender],
      'VestingBase: Vesting has been claimed!'
    );
    bytes32 merkleRoot = RootToRounds[_round];
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
    bool isValidLeaf = MerkleProof.verify(_proof, merkleRoot, leaf);
    require(isValidLeaf, 'VestingBase: Address has no Vesting allocation!');

    // Set address to claimed
    vestingClaimed[_round][msg.sender] = true;
    totalWithdrawn = totalWithdrawn.add(_amount);

    require(vestingCoin.transfer(msg.sender, _amount));
    emit Withdrawn(msg.sender, _amount);

    return true;
  }
}
