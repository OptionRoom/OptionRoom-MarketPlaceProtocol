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
        collateralToken = 0x6Cf985ADDEc5847A95FfC2Fbd2d12dD64B70f146;
        ct = ConditionalTokens(0x74E7E3383288FEaa69fA72bE26C9C9fE6942B7e4);
    }
    
}


contract AAA4Market is ORFPMarket{
    
}
