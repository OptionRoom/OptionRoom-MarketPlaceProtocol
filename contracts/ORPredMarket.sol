pragma solidity ^0.5.1;

contract ORPredMarket{
    
    struct MarketProposal {
        address proposer;
        uint256 createdTime;
        uint256 approveVotesCount;
        uint256 rejectVotesCount;
        uint256 participationTime;
        uint256 SettelingPeriod;
        
    }
    
    enum MarketProposalState {
        Invalid,
        Pending, // governence voting for validation
        Rejected,
        Active,
        Inactive,
        Setteling, // governency voting for result
        finished  // can redeem
        
    }
    
    // voting time 1 day = 86,400 sec
    uint256 public votingPeriod = 86400; 
    uint public proposalCount;
    
    address governenceAdd;
    
    MarketProposal[] MarketProposals;
    
    constructor() public{
        ct = block.timestamp;
        
        governenceAdd = msg.sender;
    }
    
    function state(uint proposalId) public view returns (MarketProposalState) {
        if(proposalId > proposalCount || proposalId == 0){
            return MarketProposalState.Invalid;
        }
        
        uint256 currentTime = getCurrentTime();
        MarketProposal memory marketProposal = MarketProposals[proposalId]; // todo check storage instead of memory
        
        
        if( (currentTime - marketProposal.createdTime) < votingPeriod){
            return MarketProposalState.Pending;
            
        }else if(marketProposal.rejectVotesCount > marketProposal.approveVotesCount){
            return MarketProposalState.Rejected;
        
        }else if(currentTime < marketProposal.participationTime){
            return MarketProposalState.Active;

        }else if(currentTime > (marketProposal.participationTime + marketProposal.SettelingPeriod)){
            return MarketProposalState.finished;
            
        }else{
            return MarketProposalState.Setteling;
        }
        
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
        return ct;
    }
    
    
    
    //TODO just for testing remove them
    uint256 ct;
    function increaseTime(uint256 t) public{
        ct+=t;
    }
    
}