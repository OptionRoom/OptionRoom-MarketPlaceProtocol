pragma solidity ^0.5.16;

library ORMarketLib{
    enum MarketState {
        Invalid,
        Validating, // governance voting for validation
        Rejected,
        Active,
        Inactive,
        Resolving, // governance voting for result
        Resolved,  // can redeem
        DisputePeriod, // Dispute
        ResolvingAfterDispute,
        ForcedResolved
    }
}
