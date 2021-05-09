pragma solidity ^0.5.1;

import "./IRewardCenter.sol";

contract RewardCenter is IRewardCenter {
    
    function sendRoomReward(address beneficiary, uint256 amount, string calldata comment) external{
        //todo
    }
    
    function sendRoomRewardByERC20Value(address beneficiary, uint256 amount, IERC20 erc20, string calldata comment) external{
        //todo
    }
    
    // todo: gardian controll
    function sendRoomRewardByDollarAmount(address beneficiary, uint256 amount, string calldata comment) external{
        
    }
}
