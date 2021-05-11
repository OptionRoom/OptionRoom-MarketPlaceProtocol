pragma solidity ^0.5.0;

import {CourtToken11} from "./Demo_CourtToken.sol";
import {Demo_HnM_CourtFarming} from "./Demo_CourtFarming.sol";
import {Demo_RnLP_CourtFarming} from "./Demo_CourtFarming.sol";
import {HM_Claim} from "./HM_Claim.sol";
import {DemoToken11} from "./Demo_USDT.sol";

contract Demo_USDT is DemoToken11{
    
}

contract HT_Farming is Demo_HnM_CourtFarming{
    
}

contract Matter_Farming is Demo_HnM_CourtFarming{
    
}

contract Room_Farming is Demo_RnLP_CourtFarming{
    
}

contract RoomLP_Farming is Demo_RnLP_CourtFarming{
    
}


contract Demo_Court is CourtToken11{
    
}


contract HT_Claim is HM_Claim{
    
}

contract Matter_Claim is HM_Claim{
    
}

// config
//2,3,4,5 give mint court permissions
// 2 ,3 add claimTo them
