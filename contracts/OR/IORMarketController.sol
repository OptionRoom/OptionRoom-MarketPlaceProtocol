pragma solidity ^0.5.1;

import "../OR/ORMarketLib.sol";

interface IORMarketController {

    function payoutsAction(address marketAddress) external;
    
    function addTrade(address account, uint256 amount, bool byeFlag) external;
    
    function getMarketState(address marketAddress) external view returns (ORMarketLib.MarketState);
}
