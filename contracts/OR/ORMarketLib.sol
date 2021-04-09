pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

library ORMarketLib {
    
    struct MarketProposal {
        address proposer;
        uint256 createdTime;
        uint256 approveVotesCount;
        uint256 rejectVotesCount;
        uint256 participationEndTime;
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
    
    uint256 public constant votingPeriod = 86400;
    
    
    function state(MarketProposal memory marketProposal, uint256 time) public pure returns(MarketProposalState){
        
        
        if( (time - marketProposal.createdTime) < votingPeriod){
            return ORMarketLib.MarketProposalState.Pending;
            
        }else if(marketProposal.rejectVotesCount > marketProposal.approveVotesCount){
            return ORMarketLib.MarketProposalState.Rejected;
        
        }else if(time < marketProposal.participationEndTime){
            return ORMarketLib.MarketProposalState.Active;

        }else if(time > (marketProposal.participationEndTime + marketProposal.SettelingPeriod)){
            return ORMarketLib.MarketProposalState.finished;
            
        }else{
            return ORMarketLib.MarketProposalState.Setteling;
        }
    }
    
    
    
}