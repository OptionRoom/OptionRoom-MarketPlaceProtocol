pragma solidity ^0.5.0;


//import '../gnosis_mod/conditional-tokens-market-makers/contracts/FixedProductMarketMaker.sol';

import "./OR/ORConditionalTokens.sol";
import './OR/ORPredictionMarket.sol';

import { DemoToken } from "./DemoToken.sol";

contract AAA1DemoToken1 is DemoToken{
    
}

contract AAA2ConditnalToken1 is ORConditionalTokens{
    
}

contract AAA3MarketFactory1 is ORPredictionMarket{
 
    
    constructor() public{
        collateralToken = 0xA84765b0ac58fA119Bd6BC333f152B3518C21489;
        ct = ConditionalTokens(0x38BDC8d8290825Bb29ccC258277d7Fe753c2dc7c);
    } 
    
}


contract AAA4Market is ORFPMarket{
    
}
