pragma solidity ^0.5.1;
import "../RewardCenter/IRoomOraclePrice.sol";


contract RoomOraclePriceMock is IRoomOraclePrice {
    
    uint256 roomAmountValue = 1e18;
    uint256 usdAmountValue = 1000000;
    uint8 usdDecimalsValue = 6;
    
    function setValues(uint256 roomAmount, uint256 usdAmount, uint8 usdDecimals) public {
        roomAmountValue = roomAmount;
        usdAmountValue = usdAmount;
        usdDecimalsValue = usdDecimals;
    }

    function getPrice() external view returns(uint256 roomAmount, uint256 usdAmount, uint8 usdDecimals){
        return (roomAmountValue,usdAmountValue,usdDecimalsValue);
    }
    

    function buyRoom(address tokenA, uint256 amountTokenA, uint256  minRoom, address to) external {

    }


    function getExpectedRoomByToken(address tokenA, uint256 amountTokenA) external view returns(uint256) {
        return 1e18;
    }

    function getExpectedTokenByRoom(address tokenA, uint256 roomAmount) external view returns(uint256) {
        return 1e18;
    }
}
