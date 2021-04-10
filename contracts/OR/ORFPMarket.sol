pragma solidity ^0.5.1;
import "./ORMarketLib.sol";
import "./FixedProductMarketMakerOR.sol";


interface IORGovernence{
    function getPowerCount(address account) external returns(uint256);
}

contract ORFPMarket is FixedProductMarketMaker{
    enum MarketState {
        Invalid,
        Pending, // governence voting for validation
        Rejected,
        Active,
        Inactive,
        Setteling, // governency voting for result
        finished  // can redeem
        
    }
    
    uint256 public constant votingPeriod = 86400;
    
    address public proposer;
    uint256 public createdTime;
    uint256 public approveVotesCount;
    uint256 public rejectVotesCount;
    uint256 public participationEndTime;
    uint256 public settelingPeriod;
    
    IORGovernence public orgovernence;
    
    bool initedPhase2;
    
    function init2( address _proposer,uint256 _createdTime, uint256 _participationEndTime, uint256 _settelingPeriod, address _governence) public{
        require(initedPhase2 == false, "init2 already called");
        initedPhase2 = true;
        proposer= _proposer;
        createdTime = _createdTime;
        participationEndTime = _participationEndTime;
        settelingPeriod = _settelingPeriod;
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

        }else if(time > (participationEndTime + settelingPeriod)){
            return MarketState.finished;
            
        }else{
            return MarketState.Setteling;
        }
    }
    
    
    mapping(address => bool) voters;  
    function voting(bool approve) public{
        if(state() ==  MarketState.Pending && voters[msg.sender] == false){ 
            voters[msg.sender] = true;
            
            if(approve == true){
                approveVotesCount+= orgovernence.getPowerCount(msg.sender);
            }else{
                rejectVotesCount+= orgovernence.getPowerCount(msg.sender);
            }
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
