pragma solidity ^0.5.1;

import "./IRewardCenter.sol";
import "../Guardian/GnGOwnable.sol";

contract RewardCenter is IRewardCenter, GnGOwnable{
    
    address rewardProgramAddress;
    
    function setRewardProgram(address programAddress) public onlyGovOrGur{
        rewardProgramAddress = programAddress;
    }
    
    function sendRoomReward(address beneficiary, uint256 amount, string calldata comment) external{
        require(msg.sender == rewardProgramAddress, "only reward program allowed to send rewards");
        //todo
    }
    
    function sendRoomRewardByERC20Value(address beneficiary, uint256 amount, IERC20 erc20, string calldata comment) external{
        require(msg.sender == rewardProgramAddress, "only reward program allowed to send rewards");
        //todo
    }
    
    // todo: gardian controll
    function sendRoomRewardByDollarAmount(address beneficiary, uint256 amount, string calldata comment) external{
        require(msg.sender == rewardProgramAddress, "only reward program allowed to send rewards");
        //todo
    }
    
    
    function sendRoomByGovOrGur(address beneficiary, uint256 amount) public onlyGovOrGur{
        //todo
    }
}
