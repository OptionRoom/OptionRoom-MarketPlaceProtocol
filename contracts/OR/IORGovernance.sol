pragma solidity ^0.5.1;

interface IORGovernance {
    function getPowerCount(address account) external returns (uint256);

    function resolveMarketAction(address marketAddress) external;
}