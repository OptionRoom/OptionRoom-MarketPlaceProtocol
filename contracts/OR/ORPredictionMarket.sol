pragma solidity ^0.5.1;
import "./FixedProductMarketMakerFactoryOR.sol";
//import "./ORFPMarket.sol";




contract ORPredictionMarket is FixedProductMarketMakerFactory{
    
    
    
    address public collateralToken = 0xB1B9C9AbE8CC193467b62F2E2a1Af98183049dB7; 
    ConditionalTokens public ct = ConditionalTokens(0x6A6B973E3AF061dB947673801e859159F963C026);
    
    address governenceAdd;
    
    
    
    constructor() public{
        crntTime = block.timestamp;
        
        governenceAdd = msg.sender;
    }
    
    /*
    function state(uint proposalId) public view returns (ORMarketLib.MarketProposalState) {
        if(proposalId > proposalCount || proposalId == 0){
            return ORMarketLib.MarketProposalState.Invalid;
        }
        
        // todo continue
        
    }
    */
    
 
    
    mapping(bytes32 => address) public proposalIds;
    
    function createMarketProposal(bytes32 questionId) public {
        require(proposalIds[questionId] == address(0),"proposal Id already used");
        
        
        ct.prepareCondition(address(this), questionId, 2);
        bytes32[]  memory conditionIds = new bytes32[](1);
        conditionIds[0] = ct.getConditionId(address(this), questionId, 2);
        
        ORFPMarket fpMarket = createFixedProductMarketMaker(ct,IERC20(collateralToken),conditionIds,20000000000000000);
        
        
        fpMarket.init2(msg.sender,getCurrentTime(),0,0,governenceAdd);
        
        proposalIds[questionId] = address(fpMarket);
    }
    
    // governence
    
    
    modifier governence{
        require(msg.sender == governenceAdd);
      _;
    }
    
    
    
    
    
}