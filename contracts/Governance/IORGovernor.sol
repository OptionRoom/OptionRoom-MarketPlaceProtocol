pragma solidity ^0.5.1;

interface IORGovernor{
    function getAccountInfo(address account) external returns(bool governorFlag, bool suspendedFlag, uint256 power) ;
    function getSuspendReason(address account) external returns(string memory reason);
}



contract DummyORGovernor is IORGovernor{
    
  
    function getAccountInfo(address account) external returns(bool governorFlag, bool suspendedFlag, uint256 power){
        return (true,true, powerPerUser[account]);
    }
    function getSuspendReason(address account) external returns(string memory reason){
        return "";
    }
    
    
    
    ////////
    mapping(address => uint256) powerPerUser;
     // todo: not a real function, just to mimic the Governance power
    function setAccountPower(address account, uint256 power) public {
        powerPerUser[account] = power;
    }
    
    // todo: not a real function, just to mimic the Governance power
    function setPower(address account, uint256 power) public{
        powerPerUser[account] = power;
    }
}