pragma solidity ^0.5.1;

interface IORGovernence{
    function getPowerCount(address account) external returns(uint256);
    function resolve(address marketAddress) external;
}