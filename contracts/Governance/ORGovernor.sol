pragma solidity ^0.5.1;
import "./IORGovernor.sol";
import "../CourtStake/ICourtStake.sol";
import "../TimeDependent/TimeDependent.sol";

contract ORGovernor is TimeDependent{
    
    ICourtStake courtStake;
    mapping(address => uint256) suspended;
    mapping(address => string) suspendReason;
    function setCourtStake(address courtStakeAddress) public{
        //sec unchecked
        courtStake = ICourtStake(courtStakeAddress);
    }
    
    function getAccountInfo(address account) external view returns(bool governorFlag, bool suspendedFlag, uint256 power){
        
        uint256 cDay = getCurrentTime() / 1 days;
        
        if( suspended[account] > cDay){
            return(true, true, 0);
        }
        
        return(true,false, courtStake.getUserPower(account));
    }
    
    function getSuspendReason(address account) external view returns(string memory reason){
        return suspendReason[account];
    }
    
    
    function suspendAccount(address account, uint256 numOfDays, string memory reason) public{
        //todo sec check
        suspended[account] =  numOfDays + (getCurrentTime() /1 days);
        suspendReason[account] = reason;
    }
}