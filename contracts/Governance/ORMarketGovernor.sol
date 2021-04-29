pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;
import "./IORMarketGovernor.sol";
import "../TimeDependent/TimeDependent.sol";

interface IORMarketForMarketGovernor{
    function getBalances(address account) external view returns (uint[] memory);
    function getConditionalTokenAddress() external view returns(address);
    function questionId() external view returns(bytes32);
}

interface IReportPayouts{
    function reportPayouts(bytes32 questionId, uint[] calldata payouts) external;
}

contract ORMarketGovernor is IORGovernor, TimeDependent{

    struct MarketVotersInfo{
        uint256 power;
        bool voteFlag;
        uint8 selection;
        uint8 insertedFlag;
    }
    
    struct MarketDisputersInfo{
        uint256[2] balances;
        string reason;
    }

    struct MarketInfo{
        //address marketAddress;
        uint256 createdTime;
        uint256 participationEndTime;
        uint256 resolvingEndTime;
        uint256 lastResolvingVoteTime;
        uint256 lastDisputeResolvingVoteTime;
        uint256 disputeTotalBalances;
        uint256[2] pendingVotesCount;
        uint256[2] resolvingVotesCount;
        bool    disputedFlag;
    }
    
    mapping(address => MarketInfo) marketsInfo;

    mapping(address => address[]) public marketPendingVoters;
    mapping(address => mapping(address => MarketVotersInfo)) public marketPendingVotersInfo;
    
    mapping(address => address[]) public marketResolvingVoters;
    mapping(address => mapping(address => MarketVotersInfo)) public marketResolvingVotersInfo;
    
    mapping(address => address[]) public marketDisputers;
    mapping(address => mapping(address => MarketDisputersInfo)) public marketDisputersInfo;
    
    
    
    mapping(address => bool) payoutsMarkets;
    
    uint256 public marketMinShareLiq = 100e18;
    uint256 public marketPendingPeriod = 1800;
    uint256 public marketDisputePeriod = 4 * 1800;
    uint256 public marketReCastResolvingPeriod = 4 * 1800;
    uint256 public disputeThreshold = 100e18;
    
    
    
    event DisputeSubmittedEvent(address indexed disputer, address indexed market, uint256 disputeTotalBalances, bool reachThresholdFlag);
    
    mapping(address => uint256) powerPerUser;
    
    
    function getPowerCount(address account) external returns (uint256) {
        //return powerPerUser[account]; todo
        return 100;
    }
    
    function addMarket(uint256 _marketCreatedTime,  uint256 _marketParticipationEndTime,  uint256 _marketResolvingEndTime) external returns(uint256){
        
        MarketInfo storage marketInfo = marketsInfo[msg.sender];
        marketInfo.createdTime = _marketCreatedTime;
        marketInfo.participationEndTime = _marketParticipationEndTime;
        marketInfo.resolvingEndTime = _marketResolvingEndTime;
        
        return marketMinShareLiq;
    }

    function payoutsAction(address marketAddress) external {
       
        if (payoutsMarkets[marketAddress] == true) {
            return;
        }

        payoutsMarkets[marketAddress] = true;
        IORMarketForMarketGovernor market = IORMarketForMarketGovernor(marketAddress);
        
        require(state(marketAddress) == ORMarketLib.MarketState.Resolved, "market is not in resolved state");

        IReportPayouts orConditionalTokens = IReportPayouts(address(market.getConditionalTokenAddress()));
        orConditionalTokens.reportPayouts(market.questionId(), getResolvingOutcome(marketAddress));
    }
    
    function getAccountInfo(address account) public returns(bool canVote, uint256 votePower){
        return (true, 100);
    }

   
    // todo: not a real function, just to mimic the Governance power
    function setSenderPower(uint256 power) public {
        powerPerUser[msg.sender] = power;
    }
    
    // todo: not a real function, just to mimic the Governance power
    function setPower(address account, uint256 power) public{
        powerPerUser[account] = power;
    }
    
    function state(address marketAddress) public view returns (ORMarketLib.MarketState) {
        
        MarketInfo memory marketInfo = marketsInfo[marketAddress];
        
        uint256 time = getCurrentTime();
        if(marketInfo.createdTime == 0){
            return ORMarketLib.MarketState.Invalid;
            
        } else if (time <marketInfo.createdTime + marketPendingPeriod ) {
            return ORMarketLib.MarketState.Pending;

        } else if (marketInfo.pendingVotesCount[0] >= marketInfo.pendingVotesCount[1] ) {
            return ORMarketLib.MarketState.Rejected;

        } else if (time < marketInfo.participationEndTime) {
            return ORMarketLib.MarketState.Active;

        } else if ( time < marketInfo.resolvingEndTime){
            return ORMarketLib.MarketState.Resolving;

        } else if(marketInfo.resolvingVotesCount[0] == marketInfo.resolvingVotesCount[1]){
            if(marketInfo.disputedFlag){
                return ORMarketLib.MarketState.ResolvingAfterDispute;
            }
            return ORMarketLib.MarketState.Resolving;

        }

        uint256 resolvingDisputeEndTime;
        if(marketInfo.resolvingEndTime > marketInfo.lastResolvingVoteTime)
        {
            resolvingDisputeEndTime = marketInfo.resolvingEndTime + marketDisputePeriod;
        }else{
            resolvingDisputeEndTime = marketInfo.lastResolvingVoteTime + marketDisputePeriod;
        }

        if(time < resolvingDisputeEndTime){
          return ORMarketLib.MarketState.DisputePeriod;
        }

        if(marketInfo.disputedFlag){
             if(time < resolvingDisputeEndTime + marketReCastResolvingPeriod){
                 return ORMarketLib.MarketState.ResolvingAfterDispute;
             }
        }

        return ORMarketLib.MarketState.Resolved;

    }
    
    
    function castGovernanceApprovalVote(address marketAddress,bool approveFlag) public {
        address account = msg.sender;
        require(state(marketAddress) == ORMarketLib.MarketState.Pending, "Market is not in pending state");
        
        MarketVotersInfo storage marketVotersInfo = marketPendingVotersInfo[marketAddress][account];
        require(marketVotersInfo.voteFlag == false, "user already voted");
        
        bool canVote;
        uint256 votePower;
        (canVote,votePower) = getAccountInfo(account);
        require(canVote == true, "user can not vote");
        
        uint8 approveSelection = 0;
        if(approveFlag) { approveSelection = 1; }
        
        if(marketVotersInfo.insertedFlag == 0){
            marketVotersInfo.insertedFlag = 1;
            marketPendingVoters[marketAddress].push(account);
        }
        
        marketVotersInfo.voteFlag = true;
        marketVotersInfo.power = votePower;
        marketVotersInfo.selection = approveSelection;

        marketsInfo[marketAddress].pendingVotesCount[approveSelection] += votePower;
    }
    
    function withdrawGovernanceApprovalVote(address marketAddress) public {
        address account = msg.sender;
        require(state(marketAddress) == ORMarketLib.MarketState.Pending, "Market is not in pending state");
        
        MarketVotersInfo storage marketVotersInfo = marketPendingVotersInfo[marketAddress][account];
        require(marketVotersInfo.voteFlag == true, "user did not vote");
        
        marketVotersInfo.voteFlag = false;
        
        uint8 approveSelection = marketVotersInfo.selection;
        marketsInfo[marketAddress].pendingVotesCount[approveSelection] -= marketVotersInfo.power;
        marketVotersInfo.power = 0;
        
    }
 
    function castGovernanceResolvingVote(address marketAddress,uint8 outcomeIndex) public {
        address account = msg.sender;
        ORMarketLib.MarketState marketState = state(marketAddress);

        require(marketState == ORMarketLib.MarketState.Resolving || marketState == ORMarketLib.MarketState.ResolvingAfterDispute, "Market is not in resolving/ResolvingAfterDispute states");
        
        MarketVotersInfo storage marketVotersInfo = marketResolvingVotersInfo[marketAddress][account];
        require(marketVotersInfo.voteFlag == false, "user already voted");
        
        bool canVote;
        uint256 votePower;
        (canVote,votePower) = getAccountInfo(account);
        require(canVote == true, "user can not vote");
        
        
        if(marketState == ORMarketLib.MarketState.Resolving){
             marketsInfo[marketAddress].lastResolvingVoteTime = getCurrentTime();
        }else{
             marketsInfo[marketAddress].lastDisputeResolvingVoteTime = getCurrentTime();
        }
        
        if(marketVotersInfo.insertedFlag == 0){
            marketVotersInfo.insertedFlag = 1;
            marketResolvingVoters[marketAddress].push(account);
        }
        
        marketVotersInfo.voteFlag = true;
        marketVotersInfo.power = votePower;
        marketVotersInfo.selection = outcomeIndex;

        marketsInfo[marketAddress].resolvingVotesCount[outcomeIndex] += votePower;
    }
    
    function withdrawGovernanceResolvingVote(address marketAddress) public{
        address account = msg.sender;
        ORMarketLib.MarketState marketState = state(marketAddress);
        
        require(marketState == ORMarketLib.MarketState.Resolving || marketState == ORMarketLib.MarketState.ResolvingAfterDispute, "Market is not in resolving/ResolvingAfterDispute states");
        
        MarketVotersInfo storage marketVotersInfo = marketResolvingVotersInfo[marketAddress][account];
        require(marketVotersInfo.voteFlag == true, "user did not vote");
        
        marketVotersInfo.voteFlag = false;
        
        uint8 outcomeIndex = marketVotersInfo.selection;
        marketsInfo[marketAddress].resolvingVotesCount[outcomeIndex] -= marketVotersInfo.power;
        marketVotersInfo.power = 0;
        //TODO: plenty
    }
    
    function disputeMarket(address marketAddress, string memory disputeReason) public{
        require(state(marketAddress) == ORMarketLib.MarketState.DisputePeriod, "Market is not in dispute state");
        address account = msg.sender;
        uint[] memory balances = IORMarketForMarketGovernor(marketAddress).getBalances(account);
        uint256 userTotalBalances = balances[0] + balances[1];

        require(userTotalBalances > 0, "Low holding to dispute");
        
        MarketDisputersInfo storage disputersInfo = marketDisputersInfo[marketAddress][account];
        require(disputersInfo.balances[0] > 0 || disputersInfo.balances[1] > 0, "User already dispute");

        marketDisputers[marketAddress].push(account);
        disputersInfo.balances[0] = balances[0];
        disputersInfo.balances[1] = balances[1];
        disputersInfo.reason = disputeReason;
        marketsInfo[marketAddress].disputeTotalBalances += userTotalBalances;

        if(marketsInfo[marketAddress].disputeTotalBalances >= disputeThreshold){
            marketsInfo[marketAddress].disputedFlag = true;
        }
        
        emit DisputeSubmittedEvent(account,marketAddress,marketsInfo[marketAddress].disputeTotalBalances,marketsInfo[marketAddress].disputedFlag);
    }
    
    
    function isPendingVoter(address marketAddress, address account) public view returns(MarketVotersInfo memory){
        return marketPendingVotersInfo[marketAddress][account];
    }

    function isResolvingVoter(address marketAddress, address account) public view returns(MarketVotersInfo memory){
        return marketResolvingVotersInfo[marketAddress][account];
    }
    
    function getResolvingVotesCount(address marketAddress) public view returns (uint256[2] memory) {
        return marketsInfo[marketAddress].resolvingVotesCount;
    }
    
    function getResolvingOutcome(address marketAddress) public view returns (uint256[] memory indexSet) {
        indexSet = new uint256[](2);
        indexSet[0] = 1;
        indexSet[1] = 1;

        if (marketsInfo[marketAddress].resolvingVotesCount[0] > marketsInfo[marketAddress].resolvingVotesCount[1]) {
            indexSet[1] = 0;
        }
        if (marketsInfo[marketAddress].resolvingVotesCount[1] > marketsInfo[marketAddress].resolvingVotesCount[0]) {
            indexSet[0] = 0;
        }
    }
    
    // market configuration
    function setMarketMinShareLiq(uint256 minLiq) public {
        marketMinShareLiq = minLiq;
    }

    function setMarketPendingPeriod(uint256 p) public{
        marketPendingPeriod = p;
    }

    function setMarketDisputePeriod(uint256 p) public{
        marketPendingPeriod = p;
    }

    function setMarketReCastResolvingPeriod(uint256 p) public{
        marketReCastResolvingPeriod = p;
    }

    function setDisputeThreshold(uint256 t) public{
        disputeThreshold = t;
    }
    
/*    
    function isPendingVoter1(address marketAddress, address account) public view returns(bool votingFlag,uint8 approveFlag, uint256 power){
        MarketVotersInfo memory marketVotersInfo = marketPendingVotersInfo[marketAddress][account];
        if(marketVotersInfo.power != 0){
            votingFlag = true;
            approveFlag = marketVotersInfo.selection;
            power = marketVotersInfo.power;
        }
    }

    function isResolvingVoter1(address marketAddress, address account) public view returns(bool votingFlag,uint8 selection, uint256 power){
        MarketVotersInfo memory marketVotersInfo = marketResolvingVotersInfo[marketAddress][account];
        
        if(marketVotersInfo.power != 0){
            votingFlag = true;
            selection = marketVotersInfo.selection;
            power = marketVotersInfo.power;
        }
    }
    
    
*/
    
}
