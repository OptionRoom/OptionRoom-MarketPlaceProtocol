pragma solidity ^0.5.0;


//import '../gnosis_mod/conditional-tokens-market-makers/contracts/FixedProductMarketMaker.sol';
import './OR/ORPredictionMarket.sol';

import { DemoToken } from "./DemoToken.sol";

contract AAA1DemoToken1 is DemoToken{
    
}

contract AAA2ConditnalToken1 is ConditionalTokens{
    
}

contract AAA3MarketFactory1 is ORPredictionMarket{
 
    
    constructor() public{
        collateralToken = 0xd1838d1849A9fdA59526ed8Da5C591B08e85cc92;
        ct = ConditionalTokens(0x35A47B61327445571bD9AFadb1e1DFD2176D0D82);
    }
    
}


contract AAA4Market is ORFPMarket{
    
}
