pragma solidity ^0.5.1;

import "../OR/IORGovernance.sol";
import "../OR/ORFPMarket.sol";
import "../OR/ORConditionalTokens.sol";

contract ORGovernanceMock is IORGovernance {

    mapping(address => uint256) powerPerUser;
    mapping(address => bool) resolvedMarkets;

    function getPowerCount(address account) external returns (uint256) {
        return powerPerUser[account];
    }

    function resolveMarketAction(address marketAddress) external {
        // TODO: Nasser Why not require instead ?
        if (resolvedMarkets[marketAddress] == true) {
            return;
        }

        resolvedMarkets[marketAddress] = true;
        ORFPMarket market = ORFPMarket(marketAddress);
        require(market.state() == ORFPMarket.MarketState.Resolved, "market is not in resolved state");

        ORConditionalTokens orConditionalTokens = ORConditionalTokens(address(market.conditionalTokens()));
        orConditionalTokens.reportPayouts(market.questionId(), market.getResolvingOutcome());
    }

    function getInputsToResolve(address marketAddress) public view returns (ORConditionalTokens orConditionalTokens, bytes32 questionId, uint256[] memory indices) {
        ORFPMarket market = ORFPMarket(marketAddress);
        questionId = market.questionId();
        indices = market.getResolvingOutcome();
        orConditionalTokens = ORConditionalTokens(address(market.conditionalTokens));
    }


    function setPower(uint256 power) public {
        powerPerUser[msg.sender] = power;
    }

}
