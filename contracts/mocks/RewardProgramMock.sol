pragma solidity ^0.5.1;
//pragma experimental ABIEncoderV2;

import "../RewardCenter/RewardProgram.sol";

contract RewardProgramMock is RewardProgram {

    function initialize() internal {
    }
    
    function doInitialization () public {
        uint256 cDay = getCurrentTime() / 1 days;
        deploymentDay = cDay;
        gLastRewardsDistributedDay[uint256(RewardType.Validation)] = cDay;
        gLastRewardsDistributedDay[uint256(RewardType.Resolve)] = cDay;
        gLastRewardsDistributedDay[uint256(RewardType.Trade)] = cDay;
        gRewardPerDay[uint256(RewardType.Validation)] = validationRewardPerDay;
        gRewardPerDay[uint256(RewardType.Resolve)] = resolveRewardPerDay;
        gRewardPerDay[uint256(RewardType.Trade)] = tradeRewardPerDay;
    }
}
