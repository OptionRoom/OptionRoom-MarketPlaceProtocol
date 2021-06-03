/**
 *Submitted for verification at BscScan.com on 2021-05-12
*/

pragma solidity ^0.5.16;


contract GnGOwnable {
    address public guardianAddress;
    address public governorAddress;
    
    event GuardianTransferred(address indexed oldGuardianAddress, address indexed newGuardianAddress);
    event GovernorTransferred(address indexed oldGuardianAddress, address indexed newGuardianAddress);
    
    constructor() public{
        guardianAddress = msg.sender;
    }
    
    modifier onlyGovOrGur{
        require(msg.sender == governorAddress || msg.sender == guardianAddress, "caller is not governor or guardian");
        _;
    }
    
    
    function transfeerGuardian(address newGuardianAddress) public  {
        require(msg.sender == guardianAddress, "Caller is not the guardian");
        emit GuardianTransferred(guardianAddress, newGuardianAddress);
        guardianAddress = newGuardianAddress;
    }
    
    function transfeerGovernor(address newGovernorAddress) public onlyGovOrGur {
        emit GuardianTransferred(governorAddress, newGovernorAddress);
        governorAddress = newGovernorAddress;
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface ICourtStake{
    function suspendAccount(address account, uint256 numOfDays) external;
    
    function getUserPower(address account) external view returns(uint256);
}


contract CourtStakeFlat is  ICourtStake, GnGOwnable {
    
    
    IERC20 public courtToken = IERC20(0x75dcb13c357983b6281BDCD57d2D6e66f8c6086a);
    
    struct StakedInfo{
        uint256 amount;
        uint256 dayIndex;
    }
    
    mapping(address => bool) public hasSuspendPermission;
    
    mapping(address => uint256) public stakedPerUser;
    mapping(address => StakedInfo[]) stakedInfoUser;
    
    mapping(address => uint256) suspended;
    
    uint8 public powerReachMaxInDays = 100;
    uint8 public maxAuth = 2;
    
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
            power += (stakedInfoUser[account][i].amount + (maxAuth * stakedInfoUser[account][i].amount * daysDef / powerReachMaxInDays ));
        }
        
        return power;
    }
    
    function getCurrentDay() public view returns(uint256){
        return block.timestamp / 1 days;
    }
}