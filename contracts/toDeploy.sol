pragma solidity ^0.5.0;

import "./OR/ORConditionalTokens.sol";
import './OR/ORPredictionMarket.sol';
import "./OR/ORGovernenceDemo.sol";

import { DemoToken } from "./DemoToken.sol";

contract AAA0GovernencyDemo is ORGovernanceDemo {

}

contract AAA1DemoToken1 is DemoToken{

}

contract AAA2ConditnalToken1 is ORConditionalTokens{

}


contract AAA3MarketFactory1 is ORPredictionMarket{

   /*
    constructor() public{
        governenceAdd = 0x102Ea1BB7c34d5b49E8647bfad8d231A8F6E39B4;
        collateralToken = 0xF5995555E2E7C4707C023F3f3260FF324b7a85c6;
        ct = ORConditionalTokens(0x9F245c9eB0E6cB2E94ED8682c07cDF5f19cD6440);

    }
    */

    function setA0(address a) public{
        governenceAdd = a;
    }

    function setA1(address a) public{
        collateralToken = a;
    }

    function setA2(address a) public{
        ct = ORConditionalTokens(a);
    }

}


contract AAA4Market is ORFPMarket{

}
