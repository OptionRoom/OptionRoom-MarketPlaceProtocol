pragma solidity ^0.5.1;

interface IORGovernor{
    function getAccountInfo(address account) external returns(bool governorFlag, bool suspendedFlag, uint256 power) ;
    function getSuspendReason(address account) external returns(string memory reason);
}