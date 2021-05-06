pragma solidity ^0.5.1;

interface IRewardProgram{
    function lpMarketAdd(address market, address account, uint256 amount) external;
    function lpMarketRemove(address market, address account, uint256 amount) external;
    function resolveVote(address marketAddress,uint8 selection, address account, uint256 votePower) external;
    function validationVote(address marketAddress,bool validationFlag,address account, uint256 votePower) external;
}