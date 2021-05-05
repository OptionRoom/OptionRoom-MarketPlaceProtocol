pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./OR/ORConditionalTokens.sol";
import './OR/ORPredictionMarket.sol';
import "./OR/ORMarketController.sol";

import { DemoToken } from "./DemoToken.sol";

contract AAA0MarketGovernor is ORMarketController {

}

contract AAA1DemoToken1 is DemoToken{

} 

contract AAA2ConditnalToken1 is ORConditionalTokens{

}


contract AAA3MarketFactory1 is ORPredictionMarket{
    address public collateralToken;
    
   /*
    constructor() public{
        governenceAdd = 0x102Ea1BB7c34d5b49E8647bfad8d231A8F6E39B4;
        collateralToken = 0xF5995555E2E7C4707C023F3f3260FF324b7a85c6;
        ct = ORConditionalTokens(0x9F245c9eB0E6cB2E94ED8682c07cDF5f19cD6440);

    }
    */

    /*function setA0(address a) public{
        governanceAdd = a;
    }*/

    function setA1(address a) public{
        collateralToken = a;
        
    }

    function setA2(address a) public{
        ct = ORConditionalTokens(a);
    }
    

}

contract timeAA is CentralTimeForTesting{
    //0x3c4Fca7B5944A750C3EBF732dBf04591aCbb821d
}


contract AAA4Market is ORFPMarket{
    


}
