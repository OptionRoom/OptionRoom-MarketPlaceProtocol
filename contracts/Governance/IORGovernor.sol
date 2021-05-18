pragma solidity ^0.5.1;

interface IORGovernor{
    function getAccountInfo(address account) external view returns(bool governorFlag, bool suspendedFlag, uint256 power) ;
    function getSuspendReason(address account) external view returns(string memory reason);
    function userhasWrongVoting(address account, address[] calldata markets) external  returns (bool);
}



contract DummyORGovernor is IORGovernor{
    
  
    function getAccountInfo(address ) external view returns(bool governorFlag, bool suspendedFlag, uint256 power){
        return (true,false, 100);
    }
    function getSuspendReason(address ) external view returns(string memory reason){
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