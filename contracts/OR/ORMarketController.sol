pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./IORMarketController.sol";
import "../TimeDependent/TimeDependent.sol";

import "./FixedProductMarketMakerFactoryOR.sol";

interface IORMarketForMarketGovernor{
    function getBalances(address account) external view returns (uint[] memory);
    function getConditionalTokenAddress() external view returns(address);
    function questionId() external view returns(bytes32);
}

interface IReportPayouts{
    function reportPayouts(bytes32 questionId, uint[] calldata payouts) external;
}


contract ORMarketController is IORMarketController, TimeDependent, FixedProductMarketMakerFactory{
    using SafeMath for uint256;

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
    
    mapping(address => MarketInfo) marketsInfo;

    mapping(address => address[]) public marketValidatingVoters;
    mapping(address => mapping(address => MarketVotersInfo)) public marketValidatingVotersInfo;

    mapping(address => address[]) public marketResolvingVoters;
    mapping(address => mapping(address => MarketVotersInfo)) public marketResolvingVotersInfo;

    mapping(address => address[]) public marketDisputers;
    mapping(address => mapping(address => MarketDisputersInfo)) public marketDisputersInfo;
    
   
    mapping(address => bool) payoutsMarkets;
    
    uint256 public validationRewardPerDay = 1700e18; // todo
    uint256 public resolveRewardPerDay = 1700e18; // todo
    uint256 public tradeRewardPerDay = 1700e18; // todo
   

    uint256 public marketMinShareLiq = 100e18; //TODO
    uint256 public marketFee = 20000000000000000;  //2% todo
    uint256 public marketValidatingPeriod = 1800; // todo
    uint256 public marketDisputePeriod = 4 * 1800; // todo
    uint256 public marketReCastResolvingPeriod = 4 * 1800; //todo
    uint256 public disputeThreshold = 100e18; // todo
    
    ConditionalTokens public ct = ConditionalTokens(0x6A6B973E3AF061dB947673801e859159F963C026); //todo
    mapping(bytes32 => address) public proposalIds;
    
    
    event DisputeSubmittedEvent(address indexed disputer, address indexed market, uint256 disputeTotalBalances, bool reachThresholdFlag);

    mapping(address => uint256) powerPerUser;
    
    constructor() public{
        
        
    }
    
    function addMarket(address marketAddress, uint256 _marketCreatedTime,  uint256 _marketParticipationEndTime,  uint256 _marketResolvingEndTime) public returns(uint256){
        // security check
        MarketInfo storage marketInfo = marketsInfo[marketAddress];
        marketInfo.createdTime = _marketCreatedTime;
        marketInfo.participationEndTime = _marketParticipationEndTime;
        marketInfo.resolvingEndTime = _marketResolvingEndTime;
        
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

    function addTrade(address account, uint256 amount, bool byeFlag) public{
        // security check
        address market = msg.sender;
        ORMarketLib.MarketState marketState = getMarketState(market);
        require(marketState == ORMarketLib.MarketState.Active, "Market is not in active state");
        
       
    }
 
    function castGovernanceResolvingVote(address marketAddress,uint8 outcomeIndex) public {
       
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
        //TODO: palanty
    }

    function disputeMarket(address marketAddress, string memory disputeReason) public{
        require(getMarketState(marketAddress) == ORMarketLib.MarketState.DisputePeriod, "Market is not in dispute state");
        address account = msg.sender;
        uint[] memory balances = IORMarketForMarketGovernor(marketAddress).getBalances(account);
        uint256 userTotalBalances = balances[0] + balances[1];

        require(userTotalBalances > 0, "Low holding to dispute");

        MarketDisputersInfo storage disputersInfo = marketDisputersInfo[marketAddress][account];
        require(disputersInfo.balances[0] == 0 && disputersInfo.balances[1] == 0, "User already dispute");

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
    ////////////////////////
    function createMarketProposal(string memory marketQuestionID, uint256 participationEndTime, uint256 resolvingEndTime, IERC20 collateralToken, uint256 initialLiq) public {
        bytes32 questionId = bytes32(marketsCount);
        require(proposalIds[questionId] == address(0), "proposal Id already used");

        ct.prepareCondition(address(this), questionId, 2);
        bytes32[]  memory conditionIds = new bytes32[](1);
        conditionIds[0] = ct.getConditionId(address(this), questionId, 2);
        //ORMarketController marketController =  ORMarketController(governanceAdd);
        
        ORFPMarket fpMarket = createFixedProductMarketMaker(ct, collateralToken, conditionIds, marketFee);
        fpMarket.setConfig(marketQuestionID, msg.sender, address(this), marketMinShareLiq ,questionId);
        addMarket(address(fpMarket),getCurrentTime(), participationEndTime, resolvingEndTime);
        
        proposalIds[questionId] = address(fpMarket);
        
        marketAddLiquidity(address(fpMarket),initialLiq);
        //TODO: check collateralToken is from the list
    }
    
    
    function marketAddLiquidity(address market,uint256 amount) public{
        ORFPMarket fpMarket = ORFPMarket(market);
        IERC20 collateralToken = fpMarket.collateralToken();
         // Add liquidity
        collateralToken.transferFrom(msg.sender,address(this),amount);
        collateralToken.approve(address(fpMarket),amount);
        fpMarket.addLiquidityTo(msg.sender,amount);
    }
    
    function marketRemoveLiquidity(address market,uint256 sharesAmount, bool autoMerg) public{
        
        address beneficiary = msg.sender;
        
        ORFPMarket fpMarket = ORFPMarket(market);
        
        address proposer = fpMarket.proposer();
        
        fpMarket.transferFrom(beneficiary,address(this),sharesAmount);
        fpMarket.approve(address(fpMarket),sharesAmount);
        
         if(beneficiary == proposer) {
            ORMarketLib.MarketState marketState = getMarketState(market);
            if(marketState == ORMarketLib.MarketState.Validating || marketState == ORMarketLib.MarketState.Active){
                require(fpMarket.balanceOf(beneficiary).sub(sharesAmount) >= marketMinShareLiq, "The remaining shares dropped under the minimum");
            }
        }
        
        fpMarket.removeLiquidityTo(beneficiary,sharesAmount, autoMerg);
    }
    
    
    function marketBuy(address market,uint investmentAmount, uint outcomeIndex, uint minOutcomeTokensToBu) public{
        ORFPMarket fpMarket = ORFPMarket(market);
        IERC20 collateralToken = fpMarket.collateralToken();
        
        collateralToken.transferFrom(msg.sender,address(this),investmentAmount);
        collateralToken.approve(address(fpMarket),investmentAmount);
        
        fpMarket.buyTo(msg.sender,investmentAmount,outcomeIndex,minOutcomeTokensToBu);
    }
    
    function marketSell(address market, uint256 amount, uint256 index) public{
        ORFPMarket fpMarket = ORFPMarket(market);
        uint256[] memory PositionIds = fpMarket.getPositionIds();
        ct.setApprovalForAll(address(fpMarket),true);
        ct.safeTransferFrom(msg.sender, address(this), PositionIds[index], amount, "");
        fpMarket.sellTo(msg.sender,amount,index);
    }

    

    function getMarketsCount(ORMarketLib.MarketState marketState) public view returns(uint256){
        uint256 marketsInStateCount = 0;
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].state() == marketState){
                marketsInStateCount++;
            }
        }

        return marketsInStateCount;
    }
    
    function getMarketCountByProposer(address account) public view returns(uint256){
        uint256 marketsInStateCount = 0;
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account){
                marketsInStateCount++;
            }
        }

        return marketsInStateCount;
    }
    
    function getMarketCountByProposerNState(address account, ORMarketLib.MarketState marketState) public view returns(uint256){
        uint256 marketsInStateCount = 0;
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account && fpMarkets[marketIndex].state() == marketState){
                marketsInStateCount++;
            }
        }

        return marketsInStateCount;
    }
    
    function getMarketCountByTrader(address trader) public view returns(uint256){
        uint256 marketsInStateCount = 0;
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].traders(trader) == true){
                marketsInStateCount++;
            }
        }

        return marketsInStateCount;
    }
    
    function getMarketCountByTraderNState(address trader, ORMarketLib.MarketState marketState) public view returns(uint256){
        uint256 marketsInStateCount = 0;
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].traders(trader) == true && fpMarkets[marketIndex].state() == marketState){
                marketsInStateCount++;
            }
        }

        return marketsInStateCount;
    }

    function getMarkets(ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;

        if(length <0){
            uint256 mc = getMarketsCount(marketState);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
        }

        markets = new ORFPMarket[](uLength);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }
    
    
    function getMarketsByProposer(address account, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;

        if(length <0){
            uint256 mc = getMarketCountByProposer(account);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
        }

        markets = new ORFPMarket[](uLength);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }
    
    function getMarketsByTrader(address trader, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;

        if(length <0){
            uint256 mc = getMarketCountByTrader(trader);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
        }

        markets = new ORFPMarket[](uLength);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].traders(trader) == true){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }
    
    function getMarketsByProposerNState(address account, ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;

        if(length <0){
            uint256 mc = getMarketCountByProposerNState(account,marketState);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
        }

        markets = new ORFPMarket[](uLength);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account && fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }
    
    function getMarketsByTraderNState(address trader, ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;

        if(length <0){
            uint256 mc = getMarketCountByTraderNState(trader,marketState);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
        }

        markets = new ORFPMarket[](uLength);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].traders(trader) == true && fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }

    function getMarketsQuestionIDs(ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets,string[] memory questionsIDs){
        uint256 uLength;

        if(length <0){
            uint256 mc = getMarketsCount(marketState);
            if(startIndex >= mc){
                return (markets,questionsIDs);
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
        }

        markets = new ORFPMarket[](uLength);
        questionsIDs = new string[](uLength);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return (markets,questionsIDs);
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                    questionsIDs[currentIndex] = fpMarkets[marketIndex].getMarketQuestionID();
                }
                marketInStateIndex++;
            }
        }

        return (markets,questionsIDs);
    }
    
    function getMarketsQuestionIDsByProposer(address account, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets,string[] memory questionsIDs){
        uint256 uLength;

        if(length <0){
            uint256 mc = getMarketCountByProposer(account);
            if(startIndex >= mc){
                return (markets,questionsIDs);
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
        }

        markets = new ORFPMarket[](uLength);
        questionsIDs = new string[](uLength);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return (markets,questionsIDs);
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                    questionsIDs[currentIndex] = fpMarkets[marketIndex].getMarketQuestionID();
                }
                marketInStateIndex++;
            }
        }

        return (markets,questionsIDs);
    }
    
    
    function getMarketsQuestionIDsByProposerNState(address account, ORMarketLib.MarketState marketStat, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets,string[] memory questionsIDs){
        uint256 uLength;

        if(length <0){
            uint256 mc = getMarketCountByProposerNState(account,marketStat);
            if(startIndex >= mc){
                return (markets,questionsIDs);
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
        }

        markets = new ORFPMarket[](uLength);
        questionsIDs = new string[](uLength);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account && fpMarkets[marketIndex].state() == marketStat){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return (markets,questionsIDs);
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                    questionsIDs[currentIndex] = fpMarkets[marketIndex].getMarketQuestionID();
                }
                marketInStateIndex++;
            }
        }

        return (markets,questionsIDs);
    }
    
    function getMarketsQuestionIDsByTraderNState(address trader, ORMarketLib.MarketState marketStat, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets,string[] memory questionsIDs){
        uint256 uLength;

        if(length <0){
            uint256 mc = getMarketCountByTraderNState(trader,marketStat);
            if(startIndex >= mc){
                return (markets,questionsIDs);
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
        }

        markets = new ORFPMarket[](uLength);
        questionsIDs = new string[](uLength);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].traders(trader) == true && fpMarkets[marketIndex].state() == marketStat){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return (markets,questionsIDs);
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                    questionsIDs[currentIndex] = fpMarkets[marketIndex].getMarketQuestionID();
                }
                marketInStateIndex++;
            }
        }

        return (markets,questionsIDs);
    }

    function getMarket(string memory marketQuestionID) public view returns(ORFPMarket  market){

        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
             string memory mqID = fpMarkets[marketIndex].getMarketQuestionID();
             if(hashCompareWithLengthCheck(mqID,marketQuestionID) == true){
                 return fpMarkets[marketIndex];
             }
        }
    }

    function hashCompareWithLengthCheck(string memory a, string memory b) internal pure returns (bool) {
        bytes memory bytesA = bytes(a);
        bytes memory bytesB = bytes(b);

        if(bytesA.length != bytesB.length) {
            return false;
        } else {
            return keccak256(bytesA) == keccak256(bytesB);
        }
    }
    
    ////////////////////////
    
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


}
