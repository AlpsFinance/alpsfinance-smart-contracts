// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

///@title This contract enables to create multiple contract administrators.
contract CustomAdmin is Ownable {
  ///@notice List of administrators.
  mapping(address => bool) public admins;

  event AdminAdded(address indexed _address);
  event AdminRemoved(address indexed _address);

  ///@notice Validates if the sender is actually an administrator.
  modifier onlyAdmin() {
    require(admins[msg.sender] || msg.sender == owner());
    _;
  }

  ///@notice Adds the specified address to the list of administrators.
  ///@param _address The address to add to the administrator list.
  function addAdmin(address _address) external onlyAdmin {
    require(_address != address(0));
    require(!admins[_address]);

    //The owner is already an admin and cannot be added.
    require(_address != owner());

    admins[_address] = true;

    emit AdminAdded(_address);
  }

  ///@notice Adds multiple addresses to the administrator list.
  ///@param _accounts The wallet addresses to add to the administrator list.
  function addManyAdmins(address[] memory _accounts) external onlyAdmin {
    for(uint8 i=0; i<_accounts.length; i++) {
      address account = _accounts[i];

      ///Zero address cannot be an admin.
      ///The owner is already an admin and cannot be assigned.
      ///The address cannot be an existing admin.
      if(account != address(0) && !admins[account] && account != owner()){
        admins[account] = true;

        emit AdminAdded(_accounts[i]);
      }
    }
  }
  
  ///@notice Removes the specified address from the list of administrators.
  ///@param _address The address to remove from the administrator list.
  function removeAdmin(address _address) external onlyAdmin {
    require(_address != address(0));
    require(admins[_address]);

    //The owner cannot be removed as admin.
    require(_address != owner());

    admins[_address] = false;
    emit AdminRemoved(_address);
  }


  ///@notice Removes multiple addresses to the administrator list.
  ///@param _accounts The wallet addresses to add to the administrator list.
  function removeManyAdmins(address[] memory _accounts) external onlyAdmin {
    for(uint8 i=0; i<_accounts.length; i++) {
      address account = _accounts[i];

      ///Zero address can neither be added or removed from this list.
      ///The owner is the super admin and cannot be removed.
      ///The address must be an existing admin in order for it to be removed.
      if(account != address(0) && admins[account] && account != owner()){
        admins[account] = false;

        emit AdminRemoved(_accounts[i]);
      }
    }
  }
}