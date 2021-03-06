pragma solidity ^0.5.16;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./ICourtStake.sol";
import "../TimeDependent/TimeDependent.sol";
import "../Guardian/GnGOwnable.sol";

contract CourtStake is TimeDependent, ICourtStake, GnGOwnable {
    //using SafeMath for uint256;
    
    // This is  ERC20 address. //todo getCourt address
    IERC20 public courtToken = IERC20(0x5B44cf5ada8074EAb3FB1F7C1695a1aA9B24de7F);
    //todo: calc optimize
    
    struct StakedInfo{
        uint256 amount;
        uint256 dayIndex;
    }
    
    mapping(address => bool) public hasSuspendPermission;
    
    mapping(address => uint256) public stakedPerUser;
    mapping(address => StakedInfo[]) stakedInfoUser;
    
    mapping(address => uint256) suspended;

    uint8 public powerReachMaxInDays = 50;
    uint8 public maxAuth = 3;
    
    event Suspended(address indexed suspenser, address suspended, uint256 daysCount);
    
    function setCourtTokenAddress(address courtTokenAdd) public onlyGovOrGur{
        courtToken = IERC20(courtTokenAdd);
    }
    
    function suspendPermission(address account, bool permissionFlag) public onlyGovOrGur{
        hasSuspendPermission[account] = permissionFlag;
    }
    
    function deposit(uint256 amount) public{
        address account = msg.sender;
        uint256 cDay = getCurrentDay();
        
        require(cDay >= suspended[account] , "user can not deposit before suspended date");
        
        stakedInfoUser[account].push(StakedInfo({
            amount:amount,
            dayIndex:cDay
        }));
        
        courtToken.transferFrom(account,address(this),amount);
        
        stakedPerUser[account] += amount; 
        
    }
    
    function withdraw(uint256 amount) public{
        uint256 cDay = getCurrentDay();
        
        address account = msg.sender;
        require(cDay >= suspended[account] , "user can not withdraw before suspended date");
        require(stakedPerUser[account] >= amount, "amount exceed deposited amount");
        stakedPerUser[account] -= amount;
        
        uint256 removeAmount = amount;
        uint256 i =0;
        while( removeAmount > 0){
           
            StakedInfo storage stakedInfo = stakedInfoUser[account][i];
            
            if(stakedInfo.amount > 0){
                if(removeAmount > stakedInfo.amount){
                    removeAmount -= stakedInfo.amount;
                    stakedInfo.amount =0;
                }else{
                    stakedInfo.amount -= removeAmount;
                    removeAmount = 0;
                }
            }
            
            i++;
        }
        
        courtToken.transfer(msg.sender,amount);
    }
    
    function suspendAccountByGovOrGur(address account, uint256 numOfDays) public onlyGovOrGur{
        
        _suspendAccount(account,numOfDays);
    }

    function setPowerReachMaxInDays(uint8 numOfDays) public onlyGovOrGur{
        require( numOfDays > 0 , "Max days can not be Zero");
        powerReachMaxInDays = numOfDays;
    }

    function setMaxAuth(uint8 auth) public onlyGovOrGur {
        maxAuth = auth;
    }
    
    function _suspendAccount(address account, uint256 numOfDays) internal {
        
        suspended[account] = getCurrentDay() + numOfDays;
        emit Suspended(msg.sender, account, numOfDays );
    }
    
    function suspendAccount(address account, uint256 numOfDays) external {
        require(hasSuspendPermission[msg.sender] == true, "Caller has no permission to suspend");
        _suspendAccount(account,numOfDays);
    }
    
    function getUserPower(address account) public view returns(uint256){
        uint256 cDay = getCurrentDay();
        
        if(cDay < suspended[account]){
            return 0;
        }
        
        uint256 stakedLength = stakedInfoUser[account].length;
        uint256 power;
        for(uint256 i=0; i < stakedLength; i++){
            uint256 daysDef = cDay - stakedInfoUser[account][i].dayIndex;
            if(daysDef > powerReachMaxInDays){
                daysDef = powerReachMaxInDays;
            }
            power += (stakedInfoUser[account][i].amount + (maxAuth *stakedInfoUser[account][i].amount * daysDef / powerReachMaxInDays ));
        }
        
        return power;
    }
    
    function getCurrentDay() public view returns(uint256){
        return getCurrentTime() / 1 days;
    }
}

contract CourtStakeDummy is CourtStake{
    mapping(address => uint256) powers;
    
    function setUserPower(address account, uint256 power) public{
        powers[account] = power;
    }
    
    function getUserPower(address account) public view returns(uint256){
        return powers[account];
    }
}


    
