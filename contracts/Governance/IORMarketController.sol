pragma solidity ^0.5.1;

import "../OR/ORMarketLib.sol";

interface IORMarketController {

    function payoutsAction(address marketAddress) external;
    
    function getAccountInfo(address account) external returns(bool canVote, uint256 votePower);
    
    function addMarket( uint256 _marketCreatedTime,  uint256 _marketParticipationEndTime,  uint256 _marketResolvingEndTime) external returns(uint256);
    
    function getMarketState(address marketAddress) external view returns (ORMarketLib.MarketState);
}
