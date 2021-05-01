pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;
import "./IORMarketController.sol";
import "../TimeDependent/TimeDependent.sol";
import "../RewardCenter/IRewardCenter.sol";

interface IORMarketForMarketGovernor{
    function getBalances(address account) external view returns (uint[] memory);
    function getConditionalTokenAddress() external view returns(address);
    function questionId() external view returns(bytes32);
}

interface IReportPayouts{
    function reportPayouts(bytes32 questionId, uint[] calldata payouts) external;
}


contract ORMarketController is IORMarketController, TimeDependent{

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
        uint256[2] validatingVotesCount;
        uint256[2] resolvingVotesCount;
        bool    disputedFlag;
    }
    
    IRewardCenter rewardCenter ;
    
    mapping(address => MarketInfo) marketsInfo;

    mapping(address => address[]) public marketValidatingVoters;
    mapping(address => mapping(address => MarketVotersInfo)) public marketValidatingVotersInfo;
    
    mapping(address => address[]) public marketResolvingVoters;
    mapping(address => mapping(address => MarketVotersInfo)) public marketResolvingVotersInfo;
    
    mapping(address => address[]) public marketDisputers;
    mapping(address => mapping(address => MarketDisputersInfo)) public marketDisputersInfo;
    
    
    
    mapping(address => bool) payoutsMarkets;
    
    uint256 public marketMinShareLiq = 100e18; //TODO
    uint256 public marketValidatingPeriod = 1800;
    uint256 public marketDisputePeriod = 4 * 1800;
    uint256 public marketReCastResolvingPeriod = 4 * 1800;
    uint256 public disputeThreshold = 100e18;
   
    uint256 public validationRewardPerDay = 1700e18; // todo
    uint256 public validationLastRewardsDistributedDay;
    mapping(uint256 => uint256) validationTotalPowerCastedPerDay;
    mapping(uint256 => uint256) validationRewardsPerDay;
    mapping(uint256 => mapping(address => uint256)) validationTotalPowerCastedPerDayPerUser;
    mapping(address => uint256) validationLastClaimedDayPerUser;
    
    
    uint256 public resolveRewardPerDay = 1700e18; // todo
    uint256 public resolveLastRewardsDistributedDay;
    mapping(uint256 => uint256) resolveTotalPowerCastedPerDay;
    mapping(uint256 => uint256) resolveRewardsPerDay;
    mapping(uint256 => mapping(address => uint256)) resolveTotalPowerCastedPerDayPerUser;
    mapping(address => uint256) resolveLastClaimedDayPerUser;
    
    
    event DisputeSubmittedEvent(address indexed disputer, address indexed market, uint256 disputeTotalBalances, bool reachThresholdFlag);
    
    mapping(address => uint256) powerPerUser;
    
    constructor() public{
        uint256 cDay = getCurrentTime() / 1 days;
        validationLastRewardsDistributedDay =cDay;
        resolveLastRewardsDistributedDay = cDay;
    }
    
     
    
   
    function ValidationInstallRewards() public{
        uint256 dayPefore = (getCurrentTime() / 1 days) - 1;
        if(dayPefore > validationLastRewardsDistributedDay){
            for(uint256 index=dayPefore; index > validationLastRewardsDistributedDay; index--){
                validationRewardsPerDay[index] = validationRewardPerDay;
            }
            validationLastRewardsDistributedDay = dayPefore;
        }
    }
  
    function ResolveInstallRewards() public{
        uint256 dayPefore = (getCurrentTime() / 1 days) - 1;
        if(dayPefore > resolveLastRewardsDistributedDay){
            for(uint256 index=dayPefore; index > resolveLastRewardsDistributedDay; index--){
                resolveRewardsPerDay[index] = resolveRewardPerDay;
            }
            resolveLastRewardsDistributedDay = dayPefore;
        }
    }
    
    function ValidationRewards(address account) public view returns(uint256 todayReward, uint256 rewardsCanClaim){
        uint256 cDay = getCurrentTime() /1 days;
        uint256 tCPtoday = validationTotalPowerCastedPerDay[cDay];
        if(tCPtoday != 0){
            uint256 userTotalPowerVotesToday = validationTotalPowerCastedPerDayPerUser[cDay][account];
            todayReward = validationRewardPerDay * userTotalPowerVotesToday * 1e18/ tCPtoday;
            todayReward = todayReward / 1e18;
        }
        
        uint256 LastClaimedDay = validationLastClaimedDayPerUser[account];
        for(uint256 index = LastClaimedDay + 1; index < cDay; index++){
            if(validationTotalPowerCastedPerDay[cDay] != 0){
                rewardsCanClaim += validationRewardsPerDay[index] * validationTotalPowerCastedPerDayPerUser[index][account] * 1e18/ validationTotalPowerCastedPerDay[cDay];
            }
        }
        rewardsCanClaim = rewardsCanClaim / 1e18;
    }
    
    function ResolveRewards(address account) public view returns(uint256 todayReward, uint256 rewardsCanClaim){
        uint256 cDay = getCurrentTime() /1 days;
        uint256 tCPtoday = resolveTotalPowerCastedPerDay[cDay];
        if(tCPtoday != 0){
            uint256 userTotalPowerVotesToday = resolveTotalPowerCastedPerDayPerUser[cDay][account];
            todayReward = resolveRewardPerDay * userTotalPowerVotesToday * 1e18/ tCPtoday;
            todayReward = todayReward / 1e18;
        }
        
        uint256 LastClaimedDay = resolveLastClaimedDayPerUser[account];
        for(uint256 index = LastClaimedDay + 1; index < cDay; index++){
            if(resolveTotalPowerCastedPerDay[cDay] != 0){
                rewardsCanClaim += resolveRewardsPerDay[index] * resolveTotalPowerCastedPerDayPerUser[index][account] * 1e18/ resolveTotalPowerCastedPerDay[cDay];
            }
        }
        rewardsCanClaim = rewardsCanClaim / 1e18;
    }
    
    function validationWithdrawUserRewards() public {
        //todo: check if ther is punlty
        
        require(address(rewardCenter) != address(0), "Reward center is not set");
        address account = msg.sender;
        uint256 cDay = getCurrentTime() /1 days;
        
        uint256 rewardsCanClaim;
        uint256 LastClaimedDay = validationLastClaimedDayPerUser[account];
        for(uint256 index = LastClaimedDay + 1; index < cDay; index++){
            if(validationTotalPowerCastedPerDay[cDay] != 0){
                rewardsCanClaim += validationRewardsPerDay[index] * validationTotalPowerCastedPerDayPerUser[index][account] * 1e18/ validationTotalPowerCastedPerDay[cDay];
            }
        }
        
        validationLastClaimedDayPerUser[account] = cDay -1;
        
        // todo: ask the reward center to send rewardsCanClaim
        rewardCenter.sendReward(account,rewardsCanClaim);
        
    }
    
    function ResolveWithdrawUserRewards() public {
        //todo: check if ther is punlty
        
        require(address(rewardCenter) != address(0), "Reward center is not set");
        
        address account = msg.sender;
        uint256 cDay = getCurrentTime() /1 days;
        
        uint256 rewardsCanClaim;
        uint256 LastClaimedDay = resolveLastClaimedDayPerUser[account];
        for(uint256 index = LastClaimedDay + 1; index < cDay; index++){
            if(resolveTotalPowerCastedPerDay[cDay] != 0){
                rewardsCanClaim += resolveRewardsPerDay[index] * resolveTotalPowerCastedPerDayPerUser[index][account] * 1e18/ resolveTotalPowerCastedPerDay[cDay];
            }
        }
        
        resolveLastClaimedDayPerUser[account] = cDay -1;
        
        // todo: ask the reward center to send rewardsCanClaim
        rewardCenter.sendReward(account,rewardsCanClaim);
        
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
        
        require(getMarketState(marketAddress) == ORMarketLib.MarketState.Resolved, "market is not in resolved state");

        IReportPayouts orConditionalTokens = IReportPayouts(address(market.getConditionalTokenAddress()));
        orConditionalTokens.reportPayouts(market.questionId(), getResolvingOutcome(marketAddress));
    }
    
    function getAccountInfo(address account) public returns(bool canVote, uint256 votePower){
        //return (true, powerPerUser[account]);  todo
        return (true, 100);
    }

   
   
    
    function getMarketState(address marketAddress) public view returns (ORMarketLib.MarketState) {
        
        MarketInfo memory marketInfo = marketsInfo[marketAddress];
        
        uint256 time = getCurrentTime();
        if(marketInfo.createdTime == 0){
            return ORMarketLib.MarketState.Invalid;
            
        } else if (time <marketInfo.createdTime + marketValidatingPeriod ) {
            return ORMarketLib.MarketState.Validating;

        } else if (marketInfo.validatingVotesCount[0] >= marketInfo.validatingVotesCount[1] ) {
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
    
    
    function castGovernanceValidatingVote(address marketAddress,bool validationFlag) public {
        ValidationInstallRewards(); // first user in a day will mark the previous day to be distrubted
         
        address account = msg.sender;
        require(getMarketState(marketAddress) == ORMarketLib.MarketState.Validating, "Market is not in validation state");
        
        MarketVotersInfo storage marketVotersInfo = marketValidatingVotersInfo[marketAddress][account];
        require(marketVotersInfo.voteFlag == false, "user already voted");
        
        bool canVote;
        uint256 votePower;
        (canVote,votePower) = getAccountInfo(account);
        require(canVote == true, "user can not vote");
        
        uint8 validationSelection = 0;
        if(validationFlag) { validationSelection = 1; }
        
        if(marketVotersInfo.insertedFlag == 0){ // action on 1'st vote for the user
            marketVotersInfo.insertedFlag = 1;
            marketValidatingVoters[marketAddress].push(account);
            
            uint256 cDay = getCurrentTime() /1 days;
            validationTotalPowerCastedPerDay[cDay]+= votePower;
            validationTotalPowerCastedPerDayPerUser[cDay][account]+= votePower;
        }
        
        marketVotersInfo.voteFlag = true;
        marketVotersInfo.power = votePower;
        marketVotersInfo.selection = validationSelection;

        marketsInfo[marketAddress].validatingVotesCount[validationSelection] += votePower;
    }
    
    function withdrawGovernanceValidatingVote(address marketAddress) public {
        address account = msg.sender;
        require(getMarketState(marketAddress) == ORMarketLib.MarketState.Validating, "Market is not in validation state");
        
        MarketVotersInfo storage marketVotersInfo = marketValidatingVotersInfo[marketAddress][account];
        require(marketVotersInfo.voteFlag == true, "user did not vote");
        
        marketVotersInfo.voteFlag = false;
        
        uint8 validationSelection = marketVotersInfo.selection;
        marketsInfo[marketAddress].validatingVotesCount[validationSelection] -= marketVotersInfo.power;
        marketVotersInfo.power = 0;
        
    }
 
    function castGovernanceResolvingVote(address marketAddress,uint8 outcomeIndex) public {
        ResolveInstallRewards(); // first user in a day will mark the previous day to be distrubted
        
        address account = msg.sender;
        ORMarketLib.MarketState marketState = getMarketState(marketAddress);

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
            
            uint256 cDay = getCurrentTime() /1 days;
            resolveTotalPowerCastedPerDay[cDay]+= votePower;
            resolveTotalPowerCastedPerDayPerUser[cDay][account]+= votePower;
        }
        
        marketVotersInfo.voteFlag = true;
        marketVotersInfo.power = votePower;
        marketVotersInfo.selection = outcomeIndex;

        marketsInfo[marketAddress].resolvingVotesCount[outcomeIndex] += votePower;
    }
    
    function withdrawGovernanceResolvingVote(address marketAddress) public{
        address account = msg.sender;
        ORMarketLib.MarketState marketState = getMarketState(marketAddress);
        
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
        require(getMarketState(marketAddress) == ORMarketLib.MarketState.DisputePeriod, "Market is not in dispute state");
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
    
    
    function isValidatingVoter(address marketAddress, address account) public view returns(MarketVotersInfo memory){
        return marketValidatingVotersInfo[marketAddress][account];
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
    
    function getMarketInfo(address marketAddress) public view returns (MarketInfo memory) {
        return marketsInfo[marketAddress];
    }
    
    
     // todo: not a real function, just to mimic the Governance power
    function setSenderPower(uint256 power) public {
        powerPerUser[msg.sender] = power;
    }
    
    // todo: not a real function, just to mimic the Governance power
    function setPower(address account, uint256 power) public{
        powerPerUser[account] = power;
    }
    
    // market configuration
    function setMarketMinShareLiq(uint256 minLiq) public {
        marketMinShareLiq = minLiq;
    }

    function setMarketValidatingPeriod(uint256 p) public{
        marketValidatingPeriod = p;
    }

    function setMarketDisputePeriod(uint256 p) public{
        marketDisputePeriod = p;
    }

    function setMarketReCastResolvingPeriod(uint256 p) public{
        marketReCastResolvingPeriod = p;
    }

    function setDisputeThreshold(uint256 t) public{
        disputeThreshold = t;
    }
    
    function setRewardCenter(address rc) public{
        rewardCenter = IRewardCenter(rc);
    }
    
/*    
    function isPendingVoter1(address marketAddress, address account) public view returns(bool votingFlag,uint8 validFlag, uint256 power){
        MarketVotersInfo memory marketVotersInfo = marketPendingVotersInfo[marketAddress][account];
        if(marketVotersInfo.power != 0){
            validFlag = true;
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
