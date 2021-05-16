pragma solidity ^0.5.1;


interface IRoomOraclePrice{
    function getPrice() external view returns(uint256 roomAmount, uint256 usdAmount, uint8 usdDecimals);
    function buyRoom(address tokenA, uint256 amountTokenA, address to) external;
}

contract RoomOraclePriceDummy is IRoomOraclePrice{
    function getPrice() external view returns(uint256 roomAmount, uint256 usdAmount, uint8 usdDecimals){
        roomAmount = 1e18;
        usdAmount = 1250000;
        usdDecimals = 6;
        
        return (roomAmount,usdAmount,usdDecimals);
    }
}