pragma solidity ^0.5.1;
import "./FixedProductMarketMakerOR.sol";


interface IORGovernence{
    function getPowerCount(address account) external returns(uint256);
    function resolve(address marketAddress) external;
}

contract ORFPMarket is FixedProductMarketMaker{
    enum MarketState {
        Invalid,
        Pending, // governence voting for validation
        Rejected,
        Active,
        Inactive,
        Resolving, // governency voting for result
        Resolved  // can redeem
        
    }
    
    uint256 public constant votingPeriod = 86400;
    
    address public proposer;
    uint256 public createdTime;
    uint256 public approveVotesCount;
    uint256 public rejectVotesCount;
    uint256 public participationEndTime;
    uint256 public settlingPeriod;
    
    IORGovernence public orgovernence;
    
    bool initedPhase2;
    
    function init2( address _proposer,uint256 _createdTime, uint256 _participationEndTime, uint256 _settlingPeriod, address _governence) public{
        require(initedPhase2 == false, "init2 already called");
        initedPhase2 = true;
        proposer= _proposer;
        createdTime = _createdTime;
        participationEndTime = _participationEndTime;
        settlingPeriod = _settlingPeriod;
        orgovernence= IORGovernence(_governence);
    }
    
    
    function state() public view  returns(MarketState){
        
        uint256 time = getCurrentTime();
        
        if( (time - createdTime) < votingPeriod){
            return MarketState.Pending;
            
        }else if(rejectVotesCount > approveVotesCount){
            return MarketState.Rejected;
        
        }else if(time < participationEndTime){
            return MarketState.Active;

        }else if(time > (participationEndTime + settlingPeriod)){
            return MarketState.Resolved;
            
        }else{
            return MarketState.Resolving;
        }
    }
    
    
    mapping(address => bool) marketVoters;  
    function approveMarket(bool approve) public{
        require(state() == MarketState.Pending, "Market is not in pendinf state");
        require(marketVoters[msg.sender] == false, "user already voted");
        marketVoters[msg.sender] = true;
            
        if(approve == true){
            approveVotesCount+= orgovernence.getPowerCount(msg.sender);
        }else{
            rejectVotesCount+= orgovernence.getPowerCount(msg.sender);
        }
        
    }
    
   
    function addLiquidity(uint256 amount) public{
        uint[] memory distributionHint;
        if(totalSupply() >0){
            
            addFunding(amount,distributionHint);
        }else{
            distributionHint = new uint[](2);
            distributionHint[0] = 1;
            distributionHint[1] = 1;
            addFunding(amount,distributionHint);
        }
    }
    
    function removeLiquidity(uint256 shares) public {
        removeFunding(shares);
        //todo
    }
    
    function merg() public{
        uint[] memory balances = getBalances(msg.sender);
        uint minBalance = balances[0];
        for(uint256 i=0;i<balances.length;i++){
            if(balances[i] < minBalance){
                minBalance = balances[i];
            }
        }
        
        uint[] memory sendAmounts = new uint[](balances.length);
        for(uint256 i=0;i<balances.length;i++){
            sendAmounts[i] = minBalance;
        }
        
        
        conditionalTokens.safeBatchTransferFrom( msg.sender, address(this), positionIds, sendAmounts, "");
        mergePositionsThroughAllConditions(minBalance);
        
        require(collateralToken.transfer(msg.sender, minBalance), "return transfer failed");
    }
    
    mapping(address => bool) resolvingVoters;
    uint256[2] public resolvingVotes;
    function resolvingMarket(uint256 outcomeIndex) public{
        require(state() == MarketState.Resolving, "market is not in settling period");
        require(resolvingVoters[msg.sender] == false, "already voted");
        resolvingVotes[outcomeIndex] += orgovernence.getPowerCount(msg.sender);
    }
   
    function getIndexSet() public pure returns(uint256[] memory indexSet){
        indexSet = new uint256[](2);
        indexSet[0] =1; 
        indexSet[1] =2;
    }
    
    function getResolvingOutcome() public view returns(uint256[] memory indexSet){
        indexSet = new uint256[](2);
        indexSet[0]=1;
        indexSet[1]=1;
        
        if(resolvingVotes[0] > resolvingVotes[1]){
            indexSet[1] = 0;
        }
         if(resolvingVotes[1] > resolvingVotes[0]){
            indexSet[1] = 1;
        }
    }
    
    
    bool resolved;
    function resolve() public{
       if(resolved == true){
           return;
       }
       resolved = true;
       require(state() == MarketState.Resolved, "Market is not in resolved state");
       orgovernence.resolve(address(this));
    }
    
    function getCurrentTime() public view returns(uint256){
        //TODO 
        //return block.timestamp;
        return crntTime;
    }
    
    
    
    //TODO just for testing remove them
    uint256 crntTime;
    function increaseTime(uint256 t) public{
        crntTime+=t;
    }
}