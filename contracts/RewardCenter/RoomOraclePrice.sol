pragma solidity ^0.5.1;
import "./IRoomOraclePrice.sol";
import "./USv2Interfaces/IUniswapV2Factory.sol";
import "./USv2Interfaces/IUniswapV2Pair.sol";

contract RoomOraclePrice is IRoomOraclePrice{
    //todo set eth address
    address WETRaddress = 0x21B7BD70dA5F3f3Dacfc52aFeF42652F36942bB7;
    address USDaddress  = 0x6bE424a5c03110B77DA0077868b99Ef4DCFdD790;
    address ROOMaddress = 0xF2F7D8156B3f1f7f8d57ef5D5b8D2Af7a8cb757C;
    uint8 USDdecimals = 6;
    
    IUniswapV2Factory uniFactoryAdress  = IUniswapV2Factory(0xA6aDCDeF95dee370f6D45BA0C683e9e4d9c0Ab8f);
    
    function getPrice() public view returns(uint256 roomAmount, uint256 usdAmount, uint8 usdDecimals){
        IUniswapV2Pair eth_usd_pair = IUniswapV2Pair(uniFactoryAdress.getPair(WETRaddress,USDaddress));
        if(address(eth_usd_pair) == address(0)){
            return (roomAmount, usdAmount, usdDecimals);
        }
        
        uint256 usdR;
        uint256 ethwR1;
        if(eth_usd_pair.token0() == WETRaddress){
            (ethwR1,usdR, ) = eth_usd_pair.getReserves();
        }else{
            (usdR,ethwR1, ) = eth_usd_pair.getReserves();
        }
        
        IUniswapV2Pair eth_room_pair = IUniswapV2Pair(uniFactoryAdress.getPair(WETRaddress,ROOMaddress));
        if(address(eth_room_pair) == address(0)){
            return (roomAmount, usdAmount, usdDecimals);
        }
        
        
        
        uint256 roomR;
        uint256 ethwR2;
        if(eth_usd_pair.token0() == WETRaddress){
            (ethwR2,roomR, ) = eth_room_pair.getReserves();
        }else{
            (roomR,ethwR2, ) = eth_room_pair.getReserves();
        }
        
        usdDecimals = USDdecimals;
        roomAmount = 1e18;
        usdAmount = (ethwR2 * usdR * 1e18) / (ethwR1 * roomR);
        
    }
    
}