pragma solidity ^0.5.1;
//pragma experimental ABIEncoderV2;

import "../RewardCenter/RewardCenter.sol";

contract RewardProgramMock is RewardCenter {
    
    // Just a place holder.
    struct BeneficiaryDetails {
        uint256 beneficiary;
        uint256 amount;
        string comment;
        IERC20 collat;
    }

    mapping(address =>  BeneficiaryDetails) public beneficiaries;
    
    function sendRoomReward(address beneficiary, uint256 amount, string calldata comment) external{
        BeneficiaryDetails storage user = beneficiaries[beneficiary];

    }

    function sendRoomRewardByERC20Value(address beneficiary, uint256 amount, IERC20 erc20, string calldata comment) external{
        //todo
    }

}
