pragma solidity ^0.5.1;
import "./OR/FixedProductMarketMakerFactoryOR.sol";
import "./ORFPMarket.sol";



contract ORPredMarket is FixedProductMarketMakerFactory{
    
    struct MarketProposal {
        address proposer;
        uint256 createdTime;
        uint256 approveVotesCount;
        uint256 rejectVotesCount;
        uint256 participationTime;
        uint256 SettelingPeriod;
        
    }
    
    ConditionalTokens ct = ConditionalTokens(0xe652A61388f5389DfbcF80dF9DDC5890453f3C57);
    address collateralToken = 0x6A9Ea9Fb55D559F87389203e04B34e91c299EC3B; 
    
    // voting time 1 day = 86,400 sec
    uint256 public votingPeriod = 86400; 
    uint public proposalCount;
    
    address governenceAdd;
    
    MarketProposal[] MarketProposals;
    
    constructor() public{
        crntTime = block.timestamp;
        
        governenceAdd = msg.sender;
    }
    
    function state(uint proposalId) public view returns (ORMarketLib.MarketProposalState) {
        if(proposalId > proposalCount || proposalId == 0){
            return ORMarketLib.MarketProposalState.Invalid;
        }
        
        uint256 currentTime = getCurrentTime();
        MarketProposal memory marketProposal = MarketProposals[proposalId]; // todo check storage instead of memory
        
        
        if( (currentTime - marketProposal.createdTime) < votingPeriod){
            return ORMarketLib.MarketProposalState.Pending;
            
        }else if(marketProposal.rejectVotesCount > marketProposal.approveVotesCount){
            return ORMarketLib.MarketProposalState.Rejected;
        
        }else if(currentTime < marketProposal.participationTime){
            return ORMarketLib.MarketProposalState.Active;

        }else if(currentTime > (marketProposal.participationTime + marketProposal.SettelingPeriod)){
            return ORMarketLib.MarketProposalState.finished;
            
        }else{
            return ORMarketLib.MarketProposalState.Setteling;
        }
        
    }
    
    mapping(bytes32 => address) public proposalIds;
    function createMarketProposal(bytes32 questionId) public {
        require(proposalIds[questionId] == address(0),"proposal Id already used");
        
        
        ct.prepareCondition(address(this), questionId, 2);
        bytes32[]  memory conditionIds = new bytes32[](1);
        conditionIds[0] = ct.getConditionId(address(this), questionId, 2);
        
        FixedProductMarketMaker fpMarket = createFixedProductMarketMaker(ct,IERC20(collateralToken),conditionIds,0);
        proposalIds[questionId] = address(fpMarket);
        
    }
    
    // governence
    function setVotingTime(uint256 peridInMintues) public governence{
        votingPeriod = peridInMintues*60;
    }
    
    
    modifier governence{
        require(msg.sender == governenceAdd);
      _;
    }
    
    
    function getCurrentTime() public view returns(uint256){
        //TODO 
        //return block.timestamp;
        return crntTime;
    }
    
    
    
    //TODO just for testing remove them
    uint256 crntTime;
    function increaseTime(uint256 t) public{
        crntTime+=t;
    }
    
}