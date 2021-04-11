pragma solidity ^0.5.1;

import { ConditionalTokens } from "../../gnosis.pm/conditional-tokens-contracts/contracts/ConditionalTokens.sol";
import { ORFPMarket } from "./ORFPMarket.sol";

contract ORConditionalTokens is ConditionalTokens{
    
    //function redeemPositions(IERC20 collateralToken, bytes32 parentCollectionId, bytes32 conditionId, uint[] calldata indexSets) external {
    function redeem(address marketAddress) public{
        ORFPMarket market = ORFPMarket(marketAddress);
        market.resolve();
        redeemPositions(market.collateralToken(),0x0000000000000000000000000000000000000000000000000000000000000000,market.conditionIds(0),market.getIndexSet());
    }
    
}