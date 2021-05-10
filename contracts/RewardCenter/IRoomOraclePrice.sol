pragma solidity ^0.5.1;


interface IRoomOraclePrice{
    function getPrice() external returns(uint256 numerator, uint256 denominator);
    function getPriceByERC20(address erc20Address) external returns(uint256 numerator, uint256 denominator);
}