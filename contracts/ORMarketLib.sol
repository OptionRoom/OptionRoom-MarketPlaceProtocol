pragma solidity ^0.5.1;

library ORMarketLib {
    
       enum MarketProposalState {
        Invalid,
        Pending, // governence voting for validation
        Rejected,
        Active,
        Inactive,
        Setteling, // governency voting for result
        finished  // can redeem
        
    }
}