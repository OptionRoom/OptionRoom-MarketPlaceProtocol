pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

library ORMarketLib1 {
    
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
    
    
    
    
    
    
}