pragma solidity ^0.5.1;

import "./FixedProductMarketMakerOR.sol";
import "./IORGovernance.sol";

/**
    @title ORFPMarket Extended version of the FixedProductMarketMaker
*/
contract ORFPMarket is FixedProductMarketMaker {

    enum MarketState {
        Invalid,
        Pending, // governance voting for validation
        Rejected,
        Active,
        Inactive,
        Resolving, // governance voting for result
        Resolved,  // can redeem
        DisputePeriod, // Dispute
        ResolvingAfterDispute

    }

    struct MarketVotersInfo{
        uint256 power;
        uint8 selection;
    }

    struct MarketDisputersInfo{
        uint256 indexZeroBalance;
        uint256 indexOneBalance;
        uint256 totalBalances;
        string reason;
    }

    uint256 public marketPendingPeriod;
    uint256 public marketDisputePeriod ;
    uint256 public marketReCastResolvingPeriod;
    uint256 public marketCreatedTime;
    uint256 public marketParticipationEndTime;
    uint256 public marketResolvingEndTime;

    address[] public marketPendingVoters;
    mapping(address => MarketVotersInfo) public marketPendingVotersInfo;
    uint256[] public marketPendingVotesCount;


    address[] public marketResolvingVoters;
    mapping(address => MarketVotersInfo) public marketResolvingVotersInfo;
    uint256[] public marketResolvingVotesCount;

    uint256 public minHoldingToDispute;
    uint256 public disputeThreshold;
    uint256 public disputeTotalBalances;
    address[] public marketDisputers;
    mapping(address => MarketDisputersInfo) public marketDisputersInfo;


    address public proposer;
    bytes32 public questionId;


    uint256 public minShareLiq;


    uint256 public lastResolvingVoteTime;
    uint256 public lastDisputeResolvingVoteTime;

    bool private initializationPhase2;

    string public marketQuestionID;

    bool public marketDisputedFlag;

    IORGovernance public ORGovernance;

    bool setTimesFlag;
    function setTimes(
            uint256 _marketCreatedTime,
            uint256 _marketParticipationEndTime,
            uint256 _marketResolvingEndTime,
            uint256 _marketPendingPeriod,
            uint256 _marketDisputePeriod,
            uint256 _marketReCastResolvingPeriod
    ) public{
        require(setTimesFlag == false, "Times already set");
        setTimesFlag = true;
        marketCreatedTime = _marketCreatedTime;
        marketParticipationEndTime = _marketParticipationEndTime;
        marketResolvingEndTime= _marketResolvingEndTime;
        marketPendingPeriod = _marketPendingPeriod;
        marketDisputePeriod = _marketDisputePeriod;
        marketReCastResolvingPeriod = _marketReCastResolvingPeriod;

//        ct = marketCreatedTime;
    }

    function setConfig(
            string memory _marketQuestionID,
            address _proposer,
            uint256 _minShareLiq,
            uint256 _minHoldingToDispute,
            uint256 _disputeThreshold,
            address _governance,
            bytes32 _questionId
    ) public {
        require(initializationPhase2 == false, "Initialization already called");
        initializationPhase2 = true;
        marketQuestionID = _marketQuestionID;
        minShareLiq = _minShareLiq;
        proposer = _proposer;
        questionId = _questionId;
        ORGovernance = IORGovernance(_governance);

        minHoldingToDispute = _minHoldingToDispute;
        disputeThreshold = _disputeThreshold;

        marketPendingVotesCount.push(0);
        marketPendingVotesCount.push(0);

        marketResolvingVotesCount.push(0);
        marketResolvingVotesCount.push(0);
    }



    function state() public view returns (MarketState) {

        uint256 time = getCurrentTime();

        if (time < marketCreatedTime + marketPendingPeriod ) {
            return MarketState.Pending;

        } else if (marketPendingVotesCount[0] >= marketPendingVotesCount[1] ) {
            return MarketState.Rejected;

        } else if (time < marketParticipationEndTime) {
            return MarketState.Active;

        } else if ( time < marketResolvingEndTime){
            return MarketState.Resolving;

        } else if(marketResolvingVotesCount[0] == marketResolvingVotesCount[1]){
            if(marketDisputedFlag){
                return MarketState.ResolvingAfterDispute;
            }
            return MarketState.Resolving;

        }

        uint256 resolvingDisputeEndTime;
        if(marketResolvingEndTime > lastResolvingVoteTime)
        {
            resolvingDisputeEndTime = marketResolvingEndTime + marketDisputePeriod;
        }else{
            resolvingDisputeEndTime = lastResolvingVoteTime + marketDisputePeriod;
        }

        if(time < resolvingDisputeEndTime){
          return MarketState.DisputePeriod;
        }

        if(marketDisputedFlag){
             if(time < resolvingDisputeEndTime + marketReCastResolvingPeriod){
                 return MarketState.ResolvingAfterDispute;
             }
        }

        return MarketState.Resolved;

    }

    function _beforeBuy() internal {
        require(state() == MarketState.Active, "Market is not in active state");
    }

    function _beforeSell() internal {
        require(state() == MarketState.Active, "Market is not in active state");
    }

    function castGovernanceApprovalVote(bool approveFlag) public {
        require(state() == MarketState.Pending, "Market is not in pending state");
        uint8 approveSelection = 0;
        if(approveFlag) { approveSelection = 1; }

        address account = msg.sender;
        if(marketPendingVotersInfo[account].power != 0) {
            marketPendingVotesCount[marketPendingVotersInfo[account].selection] -= marketPendingVotersInfo[account].power;
        } else {
            require(address(ORGovernance) != address(0),"Governance not assigned");
            marketPendingVoters.push(account);
            
            marketPendingVotersInfo[account].power = ORGovernance.getPowerCount(msg.sender);
        }
        
        marketPendingVotersInfo[account].selection = approveSelection;

        marketPendingVotesCount[approveSelection] += marketPendingVotersInfo[account].power;
    }

    function isPendingVoter(address account) public view returns(bool votingFlag,uint8 approveFlag, uint256 power){
        if(marketPendingVotersInfo[account].power != 0){
            votingFlag = true;
            approveFlag = marketPendingVotersInfo[account].selection;
            power = marketPendingVotersInfo[account].power;
        }
    }

    function addLiquidity(uint256 amount) public {
        uint[] memory distributionHint;
        if (totalSupply() > 0) {
            addFunding(amount, distributionHint);
        } else {
            distributionHint = new uint[](2);
            distributionHint[0] = 1;
            distributionHint[1] = 1;
            addFunding(amount, distributionHint);
        }
    }

    function removeLiquidity(uint256 shares, bool autoMerge) public {
        removeFunding(shares);
        if(autoMerge == true){
            merge();
        }
    }

    function merge() public {
        uint[] memory balances = getBalances(msg.sender);
        uint minBalance = balances[0];
        for (uint256 i = 0; i < balances.length; i++) {
            if (balances[i] < minBalance) {
                minBalance = balances[i];
            }
        }

        uint[] memory sendAmounts = new uint[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            sendAmounts[i] = minBalance;
        }

        conditionalTokens.safeBatchTransferFrom(msg.sender, address(this), positionIds, sendAmounts, "");
        mergePositionsThroughAllConditions(minBalance);

        require(collateralToken.transfer(msg.sender, minBalance), "return transfer failed");
    }


    function castGovernanceResolvingVote(uint8 outcomeIndex) public {
        MarketState marketState = state();

        require(marketState == MarketState.Resolving || marketState == MarketState.ResolvingAfterDispute, "Market is not in resolving/ResolvingAfterDispute states");

        if(marketState == MarketState.Resolving){
            lastResolvingVoteTime = getCurrentTime();
        }else{
            lastDisputeResolvingVoteTime = getCurrentTime();
        }
        address account = msg.sender;
        if(marketResolvingVotersInfo[account].power != 0){
            marketPendingVotesCount[marketResolvingVotersInfo[account].selection] -= marketResolvingVotersInfo[account].power;

        }else{
            require(address(ORGovernance) != address(0),"Governance not assigned");
            marketResolvingVoters.push(account);
            
            marketResolvingVotersInfo[account].power = ORGovernance.getPowerCount(msg.sender);
        }
        
        marketResolvingVotersInfo[account].selection = outcomeIndex;

        marketResolvingVotesCount[outcomeIndex] += marketResolvingVotersInfo[account].power;
    }

    function isResolvingVoter(address account) public view returns(bool votingFlag,uint8 selection, uint256 power){
        if(marketResolvingVotersInfo[account].power != 0){
            votingFlag = true;
            selection = marketResolvingVotersInfo[account].selection;
            power = marketResolvingVotersInfo[account].power;
        }
    }

    function getIndexSet() public pure returns (uint256[] memory indexSet) {
        indexSet = new uint256[](2);
        indexSet[0] = 1;
        indexSet[1] = 2;
    }

    function disputeMarket(string memory disputeReason) public{
        require(state() == MarketState.DisputePeriod, "Market is not in dispute state");
        address account = msg.sender;
        uint[] memory balances = getBalances(account);
        uint256 userTotalBalances = balances[0] + balances[1];

        require(userTotalBalances > minHoldingToDispute, "Low holding to dispute");
        require(marketDisputersInfo[account].totalBalances == 0, "User already dispute");

        marketDisputers.push(account);
        marketDisputersInfo[account].indexZeroBalance = balances[0];
        marketDisputersInfo[account].indexOneBalance = balances[1];
        marketDisputersInfo[account].totalBalances = userTotalBalances;
        marketDisputersInfo[account].reason = disputeReason;
        disputeTotalBalances += userTotalBalances;

        if(disputeTotalBalances >= disputeThreshold){
            marketDisputedFlag = true;
        }
    }

    function getResolvingOutcome() public view returns (uint256[] memory indexSet) {
        indexSet = new uint256[](2);
        indexSet[0] = 1;
        indexSet[1] = 1;

        if (marketResolvingVotesCount[0] > marketResolvingVotesCount[1]) {
            indexSet[1] = 0;
        }
        if (marketResolvingVotesCount[1] > marketResolvingVotesCount[0]) {
            indexSet[0] = 0;
        }
    }

    function getPercentage() public view returns (uint256[] memory percentage) {
        percentage = new uint256[](2);
        uint256[] memory balances = getPoolBalances();
        uint256 totalBalances = balances[0] + balances[1] ;
        if(totalBalances == 0){
            percentage[0] = 500000 ;
            percentage[1] = 500000 ;

        }else{
            percentage[0] = balances[1] * 1000000 / totalBalances;
            percentage[1] = balances[0] * 1000000 / totalBalances;

        }
    }

    function getPositionIds() public view returns (uint256[] memory) {
        return positionIds;
    }

    function getGovernanceVotingResults() public view returns (uint256[] memory governanceVotes) {
        return marketPendingVotesCount;
    }

    function getMarketQuestionID() public view returns(string memory){
        return marketQuestionID;
    }


    function getCurrentState() public view returns (MarketState yes) {
        return state();
    }

    function beforeRemoveFunding(uint sharesToBurn) internal {
        if(msg.sender == proposer) {
            MarketState marketState = state();
            if(marketState == MarketState.Pending || marketState == MarketState.Active){
                require(balanceOf(msg.sender).sub(sharesToBurn) >= minShareLiq, "The remaining shares dropped under the minimum");
            }
        }
    }

    function getSharesPercentage(address account) public view returns(uint256) {
        return balanceOf(account) * 100 * 10000 / totalSupply();
    }

    //TODO just for testing remove them
    uint256 timeIncrease;

    function increaseTime(uint256 t) public {
        timeIncrease += t;
    }

    function resetTimeIncrease() public {
        timeIncrease = 0;
    }

    function getCurrentTime() public view returns (uint256) {
        //TODO
        //return block.timestamp;
        return block.timestamp + timeIncrease;
    }
    ///// Internal testing to be cleaned later
/*    uint256 ct;
    function getCurrentTime() public view returns (uint256) {
        //return block.timestamp ;
        return ct;
    }

    function increaseTime(uint256 t) public{
        ct+=t;
    }*/

}
