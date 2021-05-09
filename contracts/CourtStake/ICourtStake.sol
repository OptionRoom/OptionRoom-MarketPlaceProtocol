pragma solidity ^0.5.0;

interface ICourtStake{
    function suspendAccount(address account, uint256 numOfDays) external;
    
    function getUserPower(address account) external view returns(uint256);
}

