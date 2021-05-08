pragma solidity ^0.5.0;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {IERC20} from "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../TimeDependent/TimeDependent.sol";
import "./ICourtStake.sol";

contract CourtStake is TimeDependent, ICourtStake {
    //using SafeMath for uint256;
    
    // This is  ERC20 address. //todo getCourt address
    IERC20 public constant courtToken = IERC20(0xBE55c87dFf2a9f5c95cB5C07572C51fd91fe0732);
    //todo: calc optimize
    
    struct StakedInfo{
        uint256 amount;
        uint256 dayIndex;
    }
    
    mapping(address => uint256) stakedPerUser;
    mapping(address => StakedInfo[]) stakedInfoUser;
    
    mapping(address => uint256) suspended;
    
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
        require(stakedPerUser[account] >= amount, "amount excced stake amout");
        
        uint256 removeAmount = amount;
        while( removeAmount > 0){
            uint256 i =0;
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
        
        stakedPerUser[account] -= amount;
    }
    
    function suspendAccount(address account, uint256 numOfDays) public{
        // todo: sec check
        
        suspended[account] = getCurrentDay() + numOfDays;
    }
    
    function getUserPower(address account) public view returns(uint256){
        uint256 cDay = getCurrentDay();
        
        if(cDay < suspended[account]){
            return 0;
        }
        
        uint256 stakedLength = stakedInfoUser[account].length;
        uint256 power;
        for(uint256 i=0; i < stakedLength; i++){
            uint256 daysDef = cDay = stakedInfoUser[account][i].dayIndex;
            if(daysDef > 50){
                daysDef = 50;
            }
            power += (stakedInfoUser[account][i].amount + (3 *stakedInfoUser[account][i].amount * daysDef/50 ));
        }
    }
    
    function getCurrentDay() public view returns(uint256){
        return getCurrentTime() / 1 days;
    }
}


    