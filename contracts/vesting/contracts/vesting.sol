// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//import "./lib/DateTime.sol";
import "./CustomAdmin.sol";
import "./frequencyHelper.sol";
import "./CustomPausable.sol";

/**
 * @title Lockup
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * creator.
 */
contract Lockup is CustomAdmin, FrequencyHelper, CustomPausable {
  using SafeMath for uint256;
  //using ERC20 for IERC20;

  ///@dev Token allocation structure for vesting schedule.
    struct Allocation {
        string  memberName;
        uint256 startedOn;
        uint256 releaseOn;
        uint256 allocation;
        uint256 closingBalance;
        bool deleted;
        uint256 withdrawn;
        uint256 lastWithdrawnOn;
    }


      ///@notice Maximum amount of tokens that can be withdrawn for the specified frequency.
    ///Zero means that there's no cap;
    uint256 public withdrawalCap;

    ///@notice The frequency of token withdrawals. If the withdrawalCap is zero, this variable is ignored.
    uint256 public withdrawalFrequency;

    ///@notice The date on which the vesting schedule was started. 
    ///Please note that the start dates of individual vesting schedules
    ///could be different than this.
    uint256 public vestingStartedOn;

    ///@notice The minimum period of vesting.
    ///Please note that individual vesting schedules cannot have
    ///shorter period than this.
    uint256 public minimumVestingPeriod;

    ///@notice The earliest date on which the vested tokens can be redeemed.
    ///Please note that individual withdrawal dates cannot be earlier
    ///than this.
    uint256 public earliestWithdrawalDate;

    ///@notice The sum total amount of tokens vested for all allocations.
    uint256 public totalVested;

    ///@notice The sum total amount of tokens withdrawn from all allocations.
    uint256 public totalWithdrawn;

    ///@notice The ERC20 contract of the coin being vested.
    ERC20 public vestingCoin;

    ///@notice The list of vesting schedule allocations;
    mapping(address => Allocation) internal allocations;

///Events;
     event Funded(address indexed _funder, uint256 _amount, uint256 _previousCap, uint256 _newCap);
    event FundRemoved(address indexed _address, uint256 _amount, uint256 _remainingInPool);
     event Withdrawn(address indexed _address, string _memberName, uint256 _amount);


     event AllocationCreated(address indexed _address, string _memberName, uint256 _amount, uint256 _releaseOn);
     event AllocationDeleted(address indexed _address, string _memberName, uint256 _amount);
      event AllocationIncreased(address indexed _address, string _memberName, uint256 _amount, uint256 _additionalAmount);
       event AllocationDecreased(address indexed _address, string _memberName, uint256 _amount, uint256 _lessAmount);
    event ScheduleExtended(address indexed _address, string _memberName, uint256 _releaseOn, uint256 _newReleaseDate);


     constructor(uint256 _minPeriod, uint256 _withdrawalCap, ERC20 _vestingCoin) public  {
        minimumVestingPeriod = _minPeriod;
        vestingStartedOn = block.timestamp;
        vestingCoin = _vestingCoin;
        withdrawalCap = _withdrawalCap;
    }


      ///@notice The balance of this smart contract. 
    ///@return Returns the closing balance of vesting coin held by this contract.
    function getAvailableFunds() public view returns(uint256) {
        return vestingCoin.balanceOf(address(this));
    }

      function getAmountInVesting() public view returns(uint256) {
        return totalVested.sub(totalWithdrawn);
    }

 modifier afterEarliestWithdrawalDate {
        require(block.timestamp >= earliestWithdrawalDate);
        
        _;
    }

       ///@notice Enables this vesting schedule contract to receive the ERC20 (vesting coin).
    ///Before calling this function please approve your desired amount of the coin
    ///for this smart contract address.
    ///Please note that this action is restricted to administrators only.
    ///@return Returns true if the funding was successful.
    function fund() external onlyAdmin returns(bool) {
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
    function removeFunds(uint256 _amount) external onlyAdmin returns(bool) {        
        uint256 balance = vestingCoin.balanceOf(address(this));
        uint256 locked = getAmountInVesting();

        require(balance > locked);

        uint256 available = balance - locked;

        require(available >= _amount);
        
        require(vestingCoin.transfer(msg.sender, _amount));

        emit FundRemoved(msg.sender, _amount, available.sub(_amount));
        return true;
    }



       function createAllocation(address _address, string memory _memberName, uint256 _amount, uint256 _releaseOn) external onlyAdmin returns(bool) {
        require(_address != address(0), "Invalid address.");
        require(_amount > 0, "Invalid amount.");
        require(allocations[_address].startedOn == 0, "Access is denied. Duplicate entry.");
        require(_releaseOn >= earliestWithdrawalDate, "Access is denied. Please specify a longer vesting period.");
        require(getAvailableFunds() >= getAmountInVesting().add(_amount), "Access is denied. Insufficient balance, vesting cap exceeded.");
        
        allocations[_address] = Allocation({ 
            startedOn: block.timestamp,
            memberName: _memberName,
            releaseOn: _releaseOn,
            allocation: _amount,
            closingBalance: _amount,
            deleted: false,
            withdrawn: 0,
            lastWithdrawnOn: 0
        });
        
        totalVested = totalVested.add(_amount);

        emit AllocationCreated(_address, _memberName, _amount, _releaseOn);
        return true;
    }

     function deleteAllocation(address _address) external onlyAdmin returns(bool) {
        require(_address != address(0), "Invalid address.");
        require(allocations[_address].startedOn > 0, "Access is denied. Requested vesting schedule does not exist.");
        require(!allocations[_address].deleted, "Access is denied. Requested vesting schedule does not exist.");

        uint256 allocation = allocations[_address].allocation;
        uint256 previousBalance = allocations[_address].closingBalance;
        uint256 withdrawn = allocations[_address].withdrawn;
        uint256 lessAmount = previousBalance.sub(withdrawn);

        allocations[_address].allocation = allocation.sub(lessAmount);
        allocations[_address].closingBalance = 0;
        allocations[_address].deleted = true;
        
        totalVested = totalVested.sub(lessAmount);

        emit AllocationDeleted(_address, allocations[_address].memberName, lessAmount);
        return true;
    }



 ///@notice Increases the total allocation of the specified vesting schedule.
    ///Please note that this action can only be performed by an administrator.
    ///@param _address The address of the beneficiary whose allocation is being requested to be increased.
    ///@param _additionalAmount The additional amount in vesting coin to be addeded to the existing allocation.
    ///@return Returns true if the vesting schedule allocation was successfully increased.
    function increaseAllocation(address _address, uint256 _additionalAmount) external onlyAdmin returns(bool) {
        require(_address != address(0), "Invalid address.");
        require(_additionalAmount > 0, "Invalid amount.");

        require(allocations[_address].startedOn > 0, "Access is denied. Requested vesting schedule does not exist.");
        require(!allocations[_address].deleted, "Access is denied. Requested vesting schedule does not exist.");

        require(getAvailableFunds() >= getAmountInVesting().add(_additionalAmount), "Access is denied. Insufficient balance, vesting cap exceeded.");

        allocations[_address].allocation = allocations[_address].allocation.add(_additionalAmount);
        allocations[_address].closingBalance = allocations[_address].closingBalance.add(_additionalAmount);

        totalVested = totalVested.add(_additionalAmount);

        emit AllocationIncreased(_address, allocations[_address].memberName, allocations[_address].allocation.sub(_additionalAmount), _additionalAmount);
        return true;
    }

     ///@notice Decreases the total allocation of the specified vesting schedule.
    ///Please note that this action can only be performed by an administrator.
    ///@param _address The address of the beneficiary whose allocation is being requested to be decreased.
    ///@param _lessAmount The amount in vesting coin to be decreased from the existing allocation.
    ///@return Returns true if the vesting schedule allocation was successfully decreased.
    function decreaseAllocation(address _address, uint256 _lessAmount) external onlyAdmin returns(bool) {
        require(_address != address(0), "Invalid address.");
        require(_lessAmount > 0);

        require(allocations[_address].startedOn > 0, "Access is denied. Requested vesting schedule does not exist.");
        require(!allocations[_address].deleted, "Access is denied. Requested vesting schedule does not exist.");
        require(allocations[_address].closingBalance >= _lessAmount, "Access is denied. Insufficient funds.");

        allocations[_address].allocation = allocations[_address].allocation.sub(_lessAmount);
        allocations[_address].closingBalance = allocations[_address].closingBalance.sub(_lessAmount);
        
        totalVested = totalVested.sub(_lessAmount);

        emit AllocationDecreased(_address, allocations[_address].memberName, allocations[_address].allocation.add(_lessAmount), _lessAmount);
        return true;
    }

    ///@notice Extends the release date of the specified vesting schedule allocation.
    ///Please note that this action can only be performed by an administrator.
    ///@param _address The address of the beneficiary who allocation is being requested to be extended.
    ///@param _newReleaseDate A new release date to extend the allocation to.
    ///@return Returns true if the vesting schedule allocation was successfully extended.
    function extendAllocation(address _address, uint256 _newReleaseDate) external onlyAdmin returns(bool) {
        require(_address != address(0), "Invalid address.");
        require(allocations[_address].startedOn > 0, "Access is denied. Requested vesting schedule does not exist.");
        require(!allocations[_address].deleted, "Access is denied. Requested vesting schedule does not exist.");
        require (block.timestamp < allocations[_address].releaseOn, "Access is denied. The vesting schedule was already released.");
        require(_newReleaseDate > allocations[_address].releaseOn, "Access is denied. You can also extend the release date but not the other way around.");        
        

        uint256 previousReleaseDate = allocations[_address].releaseOn;
        allocations[_address].releaseOn = _newReleaseDate;

        emit ScheduleExtended(_address, allocations[_address].memberName, previousReleaseDate, _newReleaseDate);
        return true;
    }
    
    ///@notice Gets the drawing power of the beneficiary.
    ///@param _address The address to check the drawing power of.
    ///@return Returns the amount in vesting coin that can be withdrawn.
    function getDrawingPower(address _address) public view returns(uint256) {
        if(withdrawalCap == 0){
            return 0;
        }
        
        uint256 duration = block.timestamp - allocations[_address].releaseOn;
        uint256 cycles = 1 + (duration.div(withdrawalFrequency));

        uint256 amount = cycles * withdrawalCap;
        uint256 cap = amount > allocations[_address].allocation ? allocations[_address].allocation : amount;
        uint256 drawingPower = cap.sub(totalWithdrawn);

        return drawingPower;
    }
    
    ///@notice Signifies if the sender has enough balances to withdraw the desired amount of the vesting coin.
    ///@param _amount The amount desired to be withdrawn.
    modifier canWithdraw(uint256 _amount)  {
        require(allocations[msg.sender].startedOn > 0, "Access is denied. Requested vesting schedule does not exist.");
        require(!allocations[msg.sender].deleted, "Access is denied. Requested vesting schedule does not exist.");
        require(block.timestamp >= allocations[msg.sender].releaseOn, "Access is denied. You are not allowed to withdraw before the release date.");
        require(allocations[msg.sender].closingBalance >= _amount, "Access is denied. Insufficient funds.");
        
        uint256 drawingPower = getDrawingPower(msg.sender);

        ///Zero means unlimited amount.
        ///We've already verified above that the investor has sufficient balance.
        if(withdrawalCap > 0){
            require(drawingPower >= _amount, "Access is denied. The requested amount exceeds your allocation.");
            _;
        }
    }

    ///@notice This action enables the beneficiaries to withdraw a desired amount from this contract.    
    ///@param _amount The amount in vesting coin desired to withdraw.
    function withdraw(uint256 _amount) external canWithdraw(_amount) afterEarliestWithdrawalDate whenNotPaused returns(bool) {                        
        allocations[msg.sender].lastWithdrawnOn = block.timestamp;

        allocations[msg.sender].closingBalance = allocations[msg.sender].closingBalance.sub(_amount);
        allocations[msg.sender].withdrawn = allocations[msg.sender].withdrawn.add(_amount);

        totalWithdrawn = totalWithdrawn.add(_amount);

        require(vestingCoin.transfer(msg.sender, _amount));

        emit Withdrawn(msg.sender, allocations[msg.sender].memberName, _amount);
        return true;
    }
}