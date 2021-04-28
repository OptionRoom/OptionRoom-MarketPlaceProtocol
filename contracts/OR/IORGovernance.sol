pragma solidity ^0.5.1;

interface IORGovernance {

    function resolveMarketAction(address marketAddress) external;
    
    function getAccountInfo(address account) external returns(bool canVote, uint256 votePower);
}
