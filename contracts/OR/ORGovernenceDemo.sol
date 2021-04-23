pragma solidity ^0.5.1;

import "./IORGovernance.sol";
import "./ORFPMarket.sol";
import "./ORConditionalTokens.sol";

contract ORGovernanceDemo is IORGovernance {

    mapping(address => uint256) powerPerUser;
    mapping(address => bool) resolvedMarkets;

    function getPowerCount(address account) external returns (uint256) {
        //return powerPerUser[account];
        return 100;
    }

    function resolveMarketAction(address marketAddress) external {
       
        if (resolvedMarkets[marketAddress] == true) {
            return;
        }

        resolvedMarkets[marketAddress] = true;
        ORFPMarket market = ORFPMarket(marketAddress);
        require(market.state() == ORFPMarket.MarketState.Resolved, "market is not in resolved state");

        ORConditionalTokens orConditionalTokens = ORConditionalTokens(address(market.conditionalTokens()));
        orConditionalTokens.reportPayouts(market.questionId(), market.getResolvingOutcome());
    }

   
    // todo: not a real function, just to mimic the Governance power
    function setSenderPower(uint256 power) public {
        powerPerUser[msg.sender] = power;
    }
    
    // todo: not a real function, just to mimic the Governance power
    function setPower(address account, uint256 power) public{
        powerPerUser[account] = power;
    }
}
