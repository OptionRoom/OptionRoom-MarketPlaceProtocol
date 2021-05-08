pragma solidity ^0.5.1;
//pragma experimental ABIEncoderV2;

import "../RewardCenter/RewardProgram.sol";

contract RewardProgramMock is RewardProgram {

    function initialize() internal {
    }
    
    function doInitialization () public {
        uint256 cDay = getCurrentTime() / 1 days;
        validationLastRewardsDistributedDay = cDay;
        resolveLastRewardsDistributedDay = cDay;
    }
    
}
