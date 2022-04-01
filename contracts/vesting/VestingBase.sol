// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


/**
 * @title Vesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, vesting period. Optionally revocable by the
 * creator.
 */
contract VestingBase is Ownable, Pausable {
    using SafeMath for uint256;

    ///@notice The sum total amount of tokens withdrawn from all allocations.
    uint256 public totalWithdrawn;

    ///@notice The ERC20 contract of the coin being vested.
    ERC20 public vestingCoin;

    uint256 public Rounds = 0;

    mapping(address => bool) public vestingClaimed;
    mapping(uint256 => bytes32) private RootToRounds;

    ///Events;
    event Funded(
        address indexed _funder,
        uint256 _amount,
        uint256 _previousCap,
        uint256 _newCap
    );
    event FundRemoved(
        address indexed _address,
        uint256 _amount,
        uint256 _remainingInPool
    );
    event Withdrawn(address indexed _address, uint256 _amount);

    ///@notice Constructs this contract
    ///@param _vestingCoin The ERC20 contract of the coin being vested.

    constructor(ERC20 _vestingCoin) {
        vestingCoin = _vestingCoin;
    }

    ///@notice The Vesting Token balance of this smart contract.
    ///@return Returns the closing balance of vesting coin held by this contract.
    function getAvailableFunds() public view returns (uint256) {
        return vestingCoin.balanceOf(address(this));
    }

    ///@notice Gets the markle tree of each vesting Rounds.
    ///@param _round The round of which markleTree to be viewed.
    ///@return Returns Total vested balance.
    function getMerkleRoot(uint256 _round)
        public
        view
        onlyOwner
        returns (bytes32)
    {
        return RootToRounds[_round];
    }

    ///@notice Enables this vesting contract to receive the ERC20 (vesting coin).
    ///Before calling this function please approve your desired amount of the coin
    ///for this smart contract address.
    ///Please note that this action is restricted to administrators only.
    ///@return Returns true if the funding was successful.
    function fund() external onlyOwner returns (bool) {
        ///Check the funds available.
        uint256 allowance = vestingCoin.allowance(msg.sender, address(this));
        require(allowance > 0, "Nothing to fund.");

        ///Get the current allocation.
        uint256 current = getAvailableFunds();

        require(vestingCoin.transferFrom(msg.sender, address(this), allowance));

        emit Funded(msg.sender, allowance, current, getAvailableFunds());
        return true;
    }

    ///@notice Allows you to withdraw the surplus balance of the vesting coin from this contract.
    ///Please note that this action is restricted to administrators only
    ///and you may only withdraw amounts above the sum total allocation balances.
    ///@param _amount The amount desired to withdraw.
    ///@return Returns true if the withdrawal was successful.
    function removeFunds(uint256 _amount) external onlyOwner returns (bool) {
        uint256 balance = vestingCoin.balanceOf(address(this));

        uint256 available = balance - totalWithdrawn;

        require(available >= _amount, "amount is grater than balanace");

        require(vestingCoin.transfer(msg.sender, _amount));

        emit FundRemoved(msg.sender, _amount, available.sub(_amount));
        return true;
    }

    ///@notice This action enables admin to set newMarkelRoot.

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        require(
            _newMerkleRoot != 0x00,
            "Vesting: Invalid new merkle root value!"
        );

        Rounds = Rounds + 1;
        RootToRounds[Rounds] = _newMerkleRoot;
    }

    ///@notice This action enables the beneficiaries to withdraw a desired amount from this contract.
    ///@param _amount The amount in vesting coin desired to withdraw.
    function withdraw(
        uint256 _amount,
        bytes32[] calldata _proof,
        uint256 _round
    ) external whenNotPaused returns (bool) {
        require(
            !vestingClaimed[msg.sender],
            "Vesting: Vesting has been claimed!"
        );
        bytes32 merkleRoot = RootToRounds[_round];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        bool isValidLeaf = MerkleProof.verify(_proof, merkleRoot, leaf);
        require(isValidLeaf, "Vesting: Address has no Vesting allocation!");

        // Set address to claimed
        vestingClaimed[msg.sender] = true;
        totalWithdrawn = totalWithdrawn.add(_amount);

        require(vestingCoin.transfer(msg.sender, _amount));
        emit Withdrawn(msg.sender, _amount);

        return true;
    }
}