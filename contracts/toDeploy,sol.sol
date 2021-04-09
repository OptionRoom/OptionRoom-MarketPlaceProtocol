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
        collateralToken = 0xEbd14f77afE2205f0B5387517b1DA299b2CaC1A2;
        ct = ConditionalTokens(0x710E31652d6Df88Bf7Aa42eE05D3d3E83FeE2Ce1);
    }
    
}


contract AAA4Market is ORFPMarket{
    
}
