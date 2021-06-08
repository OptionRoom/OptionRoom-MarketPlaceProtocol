pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;
import "./OR/ORConditionalTokens.sol";
import "./OR/ORMarketController.sol";
import "./OR/ORMarketsQuery.sol";
import "./RewardCenter/RewardProgram.sol";
import "./RewardCenter/RewardCenter.sol";
import "./Governance/ORGovernor.sol";
import "./CourtStake/CourtStake.sol";
import "./RewardCenter/IRoomOraclePrice.sol";
import "./CourtStake/CourtStake.sol";

import { DemoToken } from "./DemoToken.sol";

contract AAA0Time is CentralTimeForTesting{
    //0x3c4Fca7B5944A750C3EBF732dBf04591aCbb821d
}

contract AAA1DemoToken1 is DemoToken{

} 

contract AAA2ConditnalToken1 is ORConditionalTokens{

} 


contract AAA3MarketController1 is ORMarketController{
    
    

}

contract AAA4Market is ORFPMarket{
    


}


contract AAA5RewardProgram is RewardProgram{
    
}


contract AAA6RewardCenter is RewardCenter{
    
}


contract AAA7ORGovernor is ORGovernor{
    
}

contract AAA8CourtStakeDummy is CourtStakeDummy{
    
}

contract AAA8CourtStake is CourtStake{
    
}

contract AAA9ORMarketsQuery is ORMarketsQuery{
    
}

contract MainDeployer{
    AAA0Time public aa0;
    AAA1DemoToken1 public aa1;
    AAA2ConditnalToken1 public  aa2;
    AAA3MarketController1 public aa3;
    AAA4Market public aa4;
    AAA5RewardProgram public aa5;
    AAA6RewardCenter public aa6;
    AAA7ORGovernor public aa7;
    AAA8CourtStakeDummy public aa8d;
    AAA8CourtStake public aa8;
    AAA9ORMarketsQuery public aa9;
    
    function a0(address a ) public{
        aa0 =  AAA0Time(a);
    }
    
    function a1(address a) public{
        aa1 =  AAA1DemoToken1(a);
    }
    
    function a2(address a) public{
        aa2 =  AAA2ConditnalToken1(a);
    }
    function a3(address a) public{
        aa3 =  AAA3MarketController1(a);
    }
    function a4(address a) public{
        aa4 =  AAA4Market(a);
    }
    function a5(address a) public{
        aa5 =  AAA5RewardProgram(a);
    }
    function a6(address a) public{
        aa6 =  AAA6RewardCenter(a);
    }
    function a7(address a) public{
        aa7 =  AAA7ORGovernor(a);
    }
    
    function a8d(address a) public{
        aa8d=  AAA8CourtStakeDummy(a);
        
    }
    function a8(address a) public{
        
        aa8 =  AAA8CourtStake(a);
    }
    
    function a9(address a) public{
        
        aa9 =  AAA9ORMarketsQuery(a);
    }
    
    
    
   
    
    
    function setTime() public{
        //aa1.setCentralTimeAddressForTesting(address(aa0));
        //aa2.setCentralTimeAddressForTesting(address(aa0));
        aa3.setCentralTimeAddressForTesting(address(aa0));
        //aa4.setCentralTimeAddressForTesting(address(aa0));
        aa5.setCentralTimeAddressForTesting(address(aa0));
        //aa6.setCentralTimeAddressForTesting(address(aa0));
        aa7.setCentralTimeAddressForTesting(address(aa0));
        aa8.setCentralTimeAddressForTesting(address(aa0));
        aa8d.setCentralTimeAddressForTesting(address(aa0));
        //aa9.setCentralTimeAddressForTesting(address(aa0));
    }
    
    
    
    function linkAll() public{
        
        //a0 config (CentralTimeForTesting) : none
        
        //a1 config (DemoToken) : none
        
        //a2 config (ORConditionalTokens) : None
        
        //a3 config (marketController)
        aa3.setConditionalToken(address(aa2));
        aa3.setRewardProgram(address(aa5));
        aa3.setIORGoverner(address(aa7));
        aa3.setTemplateAddress(address(aa4));
        
        //a4 config (ORFPMarket) : none
        
        //a5 config (RewardProgram)
        aa5.setMarketControllerAddress(address(aa3));
        aa5.setRewardCenter(address(aa6));
        
        //a6 config (RewardCenter)
        aa6.setRewardProgram(address(aa5));
        //aa6.setRoomAddress(roomAddress); //todo: set room addres for reward center
        //aa6.setRoomOraclePrice(oracleaddress) //todo: set oracle 
        
        //a7 config (AAA7ORGovernor)
        aa7.setCourtStake(address(aa8d));
        
        //a8 config (AAA8CourtStake)
        //aa8.setCourtTokenAddress(courtTokenAddress)
        
        //a9 config (AAA9ORMarketsQuery)
        aa9.setMarketsController(address(aa3));
        
        
    }
}

/*
contract AAA6CourtStake is CourtStake{
    
}

*/

