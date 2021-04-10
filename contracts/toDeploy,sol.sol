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
        collateralToken = 0x0A56CA08EdfcE34b110C80cC4D85b21b406e50BB;
        ct = ConditionalTokens(0x78ECBC8c9337DfD4c816b9bc99D5762f6337297d);
    }
    
}


contract AAA4Market is ORFPMarket{
    
}
