pragma solidity ^0.5.16;

import "../OR/ORMarketLib.sol";

interface IORMarketController {

    function payoutsAction(address marketAddress) external;
    
    function getMarketState(address marketAddress) external view returns (ORMarketLib.MarketState);
}
