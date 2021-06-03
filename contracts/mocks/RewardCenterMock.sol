pragma solidity ^0.5.16;
//pragma experimental ABIEncoderV2;

import "../RewardCenter/RewardCenter.sol";

contract RewardCenterMock is RewardCenter {
    
    // Just a place holder.
    struct BeneficiaryDetails {
        uint256 beneficiary;
        uint256 amount;
        string comment;
        IERC20 collat;
    }

    mapping(address =>  BeneficiaryDetails) public beneficiaries;
    
    function deposit(uint256 amount) public {
        address account = msg.sender;
        roomToken.transferFrom(account,address(this),amount);
    }
}
