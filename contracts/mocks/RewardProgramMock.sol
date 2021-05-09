pragma solidity ^0.5.1;
//pragma experimental ABIEncoderV2;

import "../RewardCenter/RewardProgram.sol";

contract RewardProgramMock is RewardProgram {

    function initialize() internal {
    }
    
    function doInitialization () public {
        uint256 cDay = getCurrentTime() / 1 days;
        deploymentDay = cDay;
        gLastRewardsDistributedDay[0] = cDay;
        gLastRewardsDistributedDay[1] = cDay;
        gLastRewardsDistributedDay[2] = cDay;
        gRewardPerDay[0] = validationRewardPerDay;
        gRewardPerDay[1] = resolveRewardPerDay;
        gRewardPerDay[2] = tradeRewardPerDay;
    }
}
