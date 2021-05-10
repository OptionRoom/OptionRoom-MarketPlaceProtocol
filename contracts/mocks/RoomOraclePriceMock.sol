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
    
    function getPrice() external returns(uint256 numerator, uint256 denominator){
        numerator = 1;
        denominator = 1;
    }

    function getPriceByERC20(address erc20Address) external returns(uint256 numerator, uint256 denominator){
        numerator = 1;
        denominator = 1;
    }
}
