pragma solidity ^0.5.1;
import "./IORGovernor.sol";
import "../CourtStake/ICourtStake.sol";
import "../TimeDependent/TimeDependent.sol";
import "../Guardian/GnGOwnable.sol";
import {IORGovernor} from "./IORGovernor.sol";

contract ORGovernor is TimeDependent, GnGOwnable, IORGovernor{
    
    struct WrongMarketsVoting{
        uint256 lastwrongVotingCount;
        uint256 lastUpdateDate;
        address[] wrongMarkets;
    }
    
    ICourtStake courtStake;
    address public marketsControllarAddress;
    mapping(address => uint256) suspended;
    mapping(address => string) suspendReason;
    mapping(address => WrongMarketsVoting) public WrongVoting;
    
    function setCourtStake(address courtStakeAddress) public onlyGovOrGur{
        courtStake = ICourtStake(courtStakeAddress);
    }
    
    
    function setMarketsControllarAddress(address controllerAddress) public onlyGovOrGur{
        marketsControllarAddress = controllerAddress;
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
    
    
    function suspendAccount(address account, uint256 numOfDays, string memory reason) public onlyGovOrGur{
        
        _suspendAccount(account,numOfDays,reason);
    }
    
    function _suspendAccount(address account, uint256 numOfDays, string memory reason) internal {
        
        suspended[account] =  numOfDays + (getCurrentTime() /1 days);
        suspendReason[account] = reason;
        
        courtStake.suspendAccount(account,numOfDays);
    }
    
    function userhasWrongVoting(address account, address[] calldata markets) external  returns (bool){
        require(msg.sender == marketsControllarAddress, "caller is not market controller");
        
        WrongMarketsVoting storage wrongVoting = WrongVoting[account];
        uint256 arrLength = markets.length;
        uint256 wrongVotingCount=0;
        
        for(uint256 i=0;i < arrLength; i++){
            if(markets[i] != address(0)){
                wrongVotingCount++;
                wrongVoting.wrongMarkets.push(markets[i]);
            }
        }
        
        wrongVoting.lastwrongVotingCount = wrongVotingCount;
        wrongVoting.lastUpdateDate = block.timestamp;
        
        if(wrongVotingCount >0){
            
            courtStake.suspendAccount(account, wrongVoting.wrongMarkets.length + 3);
            return true;
        }
        
        return false;
    }
}