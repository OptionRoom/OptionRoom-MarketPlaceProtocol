pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./OR/ORConditionalTokens.sol";
import "./OR/ORMarketController.sol";
import "./OR/ORMarketsQuery.sol";
import "./RewardCenter/RewardProgram.sol";
import "./RewardCenter/RewardCenter.sol";
import "./Governance/ORGovernor.sol";
import "./CourtStake/CourtStake.sol";
import {RoomOraclePriceDummy} from "./RewardCenter/IRoomOraclePrice.sol";
import "./CourtStake/CourtStake.sol";

import { DemoToken } from "./DemoToken.sol";
import {RoomDemoToken} from "./DemoToken.sol";
import {TransferHelper} from "./Helpers/TransferHelper.sol";
import {SafeERC20} from "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

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


contract AAA9ORMarketsQuery is ORMarketsQuery{
    
}

contract AAA10OracleDummy is RoomOraclePriceDummy{
    
}

contract AAA11DemoRoom1 is RoomDemoToken{

} 


contract AAAQ{
    
    address aaa0;
    AAA1DemoToken1 aaa1;
    AAA2ConditnalToken1 aaa2;
    AAA3MarketController1 aaa3;
    AAA4Market aaa4;
    AAA5RewardProgram aaa5;
    AAA6RewardCenter aaa6;
    AAA7ORGovernor aaa7;
    AAA8CourtStakeDummy aaa8;
    AAA9ORMarketsQuery aaa9;
    AAA10OracleDummy aaa10;
    AAA11DemoRoom1 aaa11;
    
    function a() public{
     //aaa1.setCentralTimeAddressForTesting(aaa0);
	 //aaa2.setCentralTimeAddressForTesting(aaa0);
	 aaa3.setCentralTimeAddressForTesting(aaa0);
	 //aaa4.setCentralTimeAddressForTesting(aaa0);
	 aaa5.setCentralTimeAddressForTesting(aaa0);
	 aaa6.setCentralTimeAddressForTesting(aaa0);
	 aaa7.setCentralTimeAddressForTesting(aaa0);
	 aaa8.setCentralTimeAddressForTesting(aaa0);
	 //aaa9.setCentralTimeAddressForTesting(aaa0);
	 //aaa10.setCentralTimeAddressForTesting(aaa0);
	// aaa11.setCentralTimeAddressForTesting(aaa0);
    }
}


contract  aaaa1{
    using TransferHelper for IERC20;
    
    function transfer(IERC20 token, address rec, uint256 amount) public{
        token.safeTransfer(rec,amount);
        
    }
    
    function transferFrom(IERC20 token, address from, address rec, uint256 amount) public{
        token.safeTransferFrom(from,rec,amount);
        
    }
}


contract  aaaaa2{
    using SafeERC20 for IERC20;
    
    function transfer(IERC20 token, address rec, uint256 amount) public{
        token.safeTransfer(rec,amount);
        
    }
    
    function transferFrom(IERC20 token, address from, address rec, uint256 amount) public{
        token.safeTransferFrom(from,rec,amount);
        
    }
}

/*
contract AAA6CourtStake is CourtStake{
    
}

*/

