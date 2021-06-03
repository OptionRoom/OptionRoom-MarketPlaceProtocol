// File: contracts\Governance\IORGovernor.sol

pragma solidity ^0.5.16;

interface IORGovernor{
    function getAccountInfo(address account) external view returns(bool governorFlag, bool suspendedFlag, uint256 power) ;
    function getSuspendReason(address account) external view returns(string memory reason);
    function userHasWrongVoting(address account, address[] calldata markets) external  returns (bool);
}

// File: contracts\CourtStake\ICourtStake.sol

pragma solidity ^0.5.16;

interface ICourtStake{
    function suspendAccount(address account, uint256 numOfDays) external;
    
    function getUserPower(address account) external view returns(uint256);
}

// File: contracts\Guardian\GnGOwnable.sol

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
    
    modifier onlyGuardian {
        require(msg.sender == guardianAddress, "caller is not guardian");
        _;
    }
    
    
    function transferGuardian(address newGuardianAddress) public onlyGovOrGur {
        emit GuardianTransferred(guardianAddress, newGuardianAddress);
        guardianAddress = newGuardianAddress;
    }
    
    function transferGovernor(address newGovernorAddress) public onlyGovOrGur {
        emit GuardianTransferred(governorAddress, newGovernorAddress);
        governorAddress = newGovernorAddress;
    }
}

// File: contracts\Governance\ORGovernor.sol

pragma solidity ^0.5.16;





contract ORGovernor is GnGOwnable, IORGovernor{
    
    struct WrongMarketsVoting{
        uint256 lastWrongVotingCount;
        uint256 lastUpdateDate;
        address[] wrongMarkets;
    }
    
    ICourtStake courtStake;
    address public marketsControllerAddress;
    mapping(address => uint256) suspended;
    mapping(address => string) suspendReason;
    mapping(address => WrongMarketsVoting) public WrongVoting;
    
    uint8 coefficientPrevWrong =  3;
    
    function setCoefficientPrevWrong(uint8 newCoefficient) public onlyGovOrGur {
        coefficientPrevWrong = newCoefficient;
    }
    
    function setCourtStake(address courtStakeAddress) public onlyGovOrGur{
        courtStake = ICourtStake(courtStakeAddress);
    }
    
    
    function setMarketsControllerAddress(address controllerAddress) public onlyGovOrGur{
        marketsControllerAddress = controllerAddress;
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
    
    function userHasWrongVoting(address account, address[] calldata markets) external  returns (bool){
        require(msg.sender == marketsControllerAddress, "caller is not market controller");
        
        WrongMarketsVoting storage wrongVoting = WrongVoting[account];
        uint256 arrLength = markets.length;
        uint256 wrongVotingCount=0;
        
        for(uint256 i=0;i < arrLength; i++){
            if(markets[i] != address(0)){
                wrongVotingCount++;
                wrongVoting.wrongMarkets.push(markets[i]);
            }
        }
        
        wrongVoting.lastWrongVotingCount = wrongVotingCount;
        wrongVoting.lastUpdateDate = block.timestamp;
        
        if(wrongVotingCount >0){
            uint256 suspendDays = wrongVotingCount + coefficientPrevWrong * wrongVoting.wrongMarkets.length ;
            _suspendAccount(account, suspendDays, "wrong settlement vote");
            return true;
        }
        
        return false;
    }
    
    function getCurrentTime() public view returns(uint256){

        return block.timestamp;
    }
}
