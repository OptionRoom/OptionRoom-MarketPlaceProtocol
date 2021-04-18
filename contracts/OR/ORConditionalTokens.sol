pragma solidity ^0.5.1;

import {ConditionalTokens} from "../../gnosis.pm/conditional-tokens-contracts/contracts/ConditionalTokens.sol";
import {IORGovernance} from "./IORGovernance.sol";
import {ORFPMarket} from "./ORFPMarket.sol";

contract ORConditionalTokens is ConditionalTokens {

    function redeem(address marketAddress) public {
        ORFPMarket market = ORFPMarket(marketAddress);
        IORGovernance governance = market.ORGovernance();
        governance.resolveMarketAction(marketAddress);
        redeemPositions(market.collateralToken(), 0x0000000000000000000000000000000000000000000000000000000000000000, market.conditionIds(0), market.getIndexSet());
    }

}
