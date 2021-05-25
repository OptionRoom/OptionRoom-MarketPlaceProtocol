pragma solidity ^0.5.1;


interface IRoomOraclePrice{
    function getPrice() external view returns(uint256 roomAmount, uint256 usdAmount, uint8 usdDecimals);
    function getExpectedRoomByToken(address tokenA, uint256 tokenAmount) external view returns(uint256);
    function getExpectedTokenByRoom(address tokenA, uint256 roomAmount) external view returns(uint256);
    function buyRoom(address tokenA, uint256 amountTokenA, uint256  minRoom, address to) external;
}

contract RoomOraclePriceDummy is IRoomOraclePrice{
    function getPrice() external view returns(uint256 roomAmount, uint256 usdAmount, uint8 usdDecimals){
        roomAmount = 1e18;
        usdAmount = 1000000;
        usdDecimals = 6;
        
        return (roomAmount,usdAmount,usdDecimals);
    }

    function buyRoom(address tokenA, uint256 amountTokenA, uint256  minRoom, address to) external {

    }


    function getExpectedRoomByToken(address tokenA, uint256 tokenAmount) external view returns(uint256) {
        return 1e18;
    }
    
    function getExpectedTokenByRoom(address tokenA, uint256 roomAmount) external view returns(uint256) {
        return 1e18;
    }
}
