pragma solidity ^0.5.0;


//import '../gnosis_mod/conditional-tokens-market-makers/contracts/FixedProductMarketMaker.sol';

import "./OR/ORConditionalTokens.sol";
import './OR/ORPredictionMarket.sol';
import "./OR/ORGovernenceDemo.sol";

import { DemoToken } from "./DemoToken.sol";

contract AAA0GovernencyDemo is ORGovernenceDemo{
    
}

contract AAA1DemoToken1 is DemoToken{
    
}

contract AAA2ConditnalToken1 is ORConditionalTokens{
    
}

contract AAA3MarketFactory1 is ORPredictionMarket{
 
     
    constructor() public{
        governenceAdd = 0xf1A4D964393cd1044A74FB935D61FfBfaC80697E;
        collateralToken = 0x05Adb8daa5efc36C288c3E8C75Be7b84a9021DF1;
        ct = ConditionalTokens(0x021835D6B59f98B0203325Ef7614a619aA3a2A4C);
        
    } 
    
}


contract AAA4Market is ORFPMarket{
    
}
