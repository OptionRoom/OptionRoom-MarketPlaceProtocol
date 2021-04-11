pragma solidity ^0.5.1;
import "./IORGovernence.sol";
import "./ORFPMarket.sol";
import "./ORConditionalTokens.sol";

contract ORGovernenceDemo is IORGovernence{
    
    mapping(address=>uint256) powerPerUser;
    
    function getPowerCount(address account) external returns(uint256){
         return powerPerUser[account];
    }
    
    mapping(address => bool) resolvedMarkets;
    
    function resolve(address marketAddress) external{
        if(resolvedMarkets[marketAddress] == true){
            return;
        }
        resolvedMarkets[marketAddress] = true;
        ORFPMarket market = ORFPMarket(marketAddress);
        require(market.state() == ORFPMarket.MarketState.Resolved, "market is not in resolved state");
        
        ORConditionalTokens orConditionalTokens =  ORConditionalTokens(address(market.conditionalTokens()));
        orConditionalTokens.reportPayouts(market.questionId(),market.getResolvingOutcome());
    }
    
    function getInputsToReolve(address marketAddress) public view returns(ORConditionalTokens orConditionalTokens,bytes32 questionId,uint256[] memory indxs){
        ORFPMarket market = ORFPMarket(marketAddress);
        questionId = market.questionId();
        indxs = market.getResolvingOutcome();
        orConditionalTokens =  ORConditionalTokens(address(market.conditionalTokens));
    }
    

    function setPower(uint256 power) public{
        powerPerUser[msg.sender] = power;
    }
    
}