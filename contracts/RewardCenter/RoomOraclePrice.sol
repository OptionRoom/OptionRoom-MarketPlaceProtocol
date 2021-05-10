pragma solidity ^0.5.1;
import "./IRoomOraclePrice.sol";


contract RoomOraclePrice is IRoomOraclePrice{
    function getPrice() external returns(uint256 numerator, uint256 denominator){
        //todo    
    }
    
    function getPriceByERC20(address erc20Address) external returns(uint256 numerator, uint256 denominator){
        // todo
    }
}