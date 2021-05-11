pragma solidity ^0.5.1;
import "../RewardCenter/IRoomOraclePrice.sol";


contract RoomOraclePriceMock is IRoomOraclePrice {

    uint256 numerator;
    uint256 denominator;
    
    function setNum(uint256 value) public {
        numerator = value;
    }

    function setDen(uint256 value) public {
        denominator = value;
    }

    function getPrice() external view returns(uint256 roomAmount, uint256 usdAmount, uint8 usdDecimals){
        roomAmount = 1e18;
        usdAmount = 1250000;
        usdDecimals = 6;

        return (roomAmount,usdAmount,usdDecimals);
    }
}
