pragma solidity ^0.5.1;

interface IRewardCenter{
    function sendReward(address account, uint256 ammount) external;
}