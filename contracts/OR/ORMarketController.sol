pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./IORMarketController.sol";
import "../Governance/IORGovernor.sol";
import "../TimeDependent/TimeDependent.sol";

import "./FixedProductMarketMakerFactoryOR.sol";
import "../RewardCenter/IRewardCenter.sol";
import "../RewardCenter/IRewardProgram.sol";
import "../RewardCenter/IRoomOraclePrice.sol";
import "../Guardian/GnGOwnable.sol";

interface IORMarketForMarketGovernor{
    function getBalances(address account) external view returns (uint[] memory);
    function getConditionalTokenAddress() external view returns(address);
    function questionId() external view returns(bytes32);
}

interface IReportPayouts{
    function reportPayouts(bytes32 questionId, uint[] calldata payouts) external;
}


contract ORMarketController is IORMarketController, TimeDependent, FixedProductMarketMakerFactory, GnGOwnable{
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
    
    IORGovernor public orGovernor;
    ConditionalTokens public ct; 
    IRewardProgram  public RP; //reward program
    address public roomOracleAddress;
    address public rewardCenterAddress;
    
    mapping(address => MarketInfo) marketsInfo;

    mapping(address => address[]) public marketValidatingVoters;
    mapping(address => mapping(address => MarketVotersInfo)) public marketValidatingVotersInfo;

    mapping(address => address[]) public marketResolvingVoters;
    mapping(address => mapping(address => MarketVotersInfo)) public marketResolvingVotersInfo;

    mapping(address => address[]) public marketDisputers;
    mapping(address => mapping(address => MarketDisputersInfo)) public marketDisputersInfo;
    
   
    mapping(address => bool) payoutsMarkets;

    uint256 public marketMinShareLiq = 100e18; //todo
    uint256 public marketLPFee = 20000000000000000;  //2% todo
    uint256 public protocolFee = 10000000000000000; //1%t odo
    uint256 public buyRoomThreshold = 1e18; //
    uint256 public marketValidatingPeriod = 1800; // todo
    uint256 public marketDisputePeriod = 4 * 1800; // todo
    uint256 public marketReCastResolvingPeriod = 4 * 1800; //todo
    uint256 public disputeThreshold = 100e18; // todo
    
    
    mapping(bytes32 => address) public proposalIds;
    
    
    event DisputeSubmittedEvent(address indexed disputer, address indexed market, uint256 disputeTotalBalances, bool reachThresholdFlag);
    
    constructor() public{
        
        
    }
    
    
    function addMarket(address marketAddress, uint256 _marketCreatedTime,  uint256 _marketParticipationEndTime,  uint256 _marketResolvingEndTime) internal returns(uint256){
        // todo security check
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

    function getAccountInfo(address account) public view returns(bool canVote, uint256 votePower){
        bool governorFlag; bool suspendedFlag;
        (governorFlag, suspendedFlag,  votePower) = orGovernor.getAccountInfo(account);
        canVote = governorFlag && !suspendedFlag;
        return (canVote, votePower);
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
            
            RP.validationVote(marketAddress, validationFlag, msg.sender, votePower);
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
            
            RP.resolveVote(marketAddress, outcomeIndex, msg.sender, votePower);
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
        
        ORFPMarket fpMarket = createFixedProductMarketMaker(ct, collateralToken, conditionIds, marketLPFee);
        fpMarket.setConfig(marketQuestionID, msg.sender, address(this), questionId);
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
        uint sharesAmount = fpMarket.addLiquidityTo(msg.sender,amount);
        
        RP.lpMarketAdd(market, msg.sender, sharesAmount);
    }
    
    function marketRemoveLiquidity(address market,uint256 sharesAmount, bool autoMerg) public{
        
        address beneficiary = msg.sender;
        
        ORFPMarket fpMarket = ORFPMarket(market);
        
        address proposer = fpMarket.proposer();
        
        fpMarket.transferFrom(beneficiary,address(this),sharesAmount);
        fpMarket.approve(address(fpMarket),sharesAmount);
        
        // todo : wrong : proposer can send his share to other addres and withdraw them
         if(beneficiary == proposer) {
            ORMarketLib.MarketState marketState = getMarketState(market);
            if(marketState == ORMarketLib.MarketState.Validating || marketState == ORMarketLib.MarketState.Active){
                require(fpMarket.balanceOf(beneficiary).sub(sharesAmount) >= marketMinShareLiq, "The remaining shares dropped under the minimum");
            }
        }
        
        fpMarket.removeLiquidityTo(beneficiary,sharesAmount, autoMerg);
        
        RP.lpMarketRemove(market, msg.sender, sharesAmount);
    }
    
    mapping(address => uint256) fees;
   
    function marketBuy(address market,uint investmentAmount, uint outcomeIndex, uint minOutcomeTokensToBu) public{
        ORMarketLib.MarketState marketState = getMarketState(market);
        require(marketState == ORMarketLib.MarketState.Active, "Market is not in active state");
        
        ORFPMarket fpMarket = ORFPMarket(market);
        IERC20 collateralToken = fpMarket.collateralToken();
        
        collateralToken.transferFrom(msg.sender,address(this),investmentAmount);
        collateralToken.approve(address(fpMarket),investmentAmount);
        
        uint256 pFee = investmentAmount * protocolFee / 1e18;
        fees[address(collateralToken)] += pFee;
        
        buyRoom(address(collateralToken));
        
        fpMarket.buyTo(msg.sender,investmentAmount-pFee,outcomeIndex,minOutcomeTokensToBu);
        
        RP.tradeAmount(market, msg.sender, investmentAmount, true);
    }
    
    function marketSell(address market, uint256 amount, uint256 index) public{
        ORMarketLib.MarketState marketState = getMarketState(market);
        require(marketState == ORMarketLib.MarketState.Active, "Market is not in active state");
        
        ORFPMarket fpMarket = ORFPMarket(market);
        uint256[] memory PositionIds = fpMarket.getPositionIds();
        ct.setApprovalForAll(address(fpMarket),true);
        ct.safeTransferFrom(msg.sender, address(this), PositionIds[index], amount, "");
        uint256 tradeVolume = fpMarket.sellTo(address(this),amount,index);
       
        IERC20 collateralToken = ORFPMarket(market).collateralToken();
        
        
        uint256 pFee = tradeVolume * protocolFee / 1e18;
        fees[address(collateralToken)] += pFee;
        
        buyRoom(address(collateralToken));
        
        collateralToken.transfer(msg.sender,tradeVolume - pFee);
        RP.tradeAmount(market, msg.sender, tradeVolume, false);
    }
    
    function buyRoom(address IERCaddress) internal{
        if(fees[IERCaddress] >= buyRoomThreshold){
            if(roomOracleAddress != address(0)){
                IERC20 erc20 = IERC20(IERCaddress);
                erc20.approve(roomOracleAddress,fees[IERCaddress]);
                IRoomOraclePrice(roomOracleAddress).buyRoom(IERCaddress,fees[IERCaddress],rewardCenterAddress);
                fees[IERCaddress] = 0;
            }
        }
    }
    
    function withdrawFees(address erc20Address, address to) public  onlyGovOrGur{
        IERC20 erc20 = IERC20(erc20Address);
        
        erc20.transfer(to, erc20.balanceOf(address(this)));
    }
    
    
    //
    function setTemplateAddress(address templateAddress) public onlyGovOrGur{
        
        implementationMasterAddr = templateAddress;
    }
    
    function setIORGoverner(address orGovernorAddress) public onlyGovOrGur{
        
        orGovernor = IORGovernor(orGovernorAddress);
    }
    
    function setRewardProgram(address rewardProgramAddress) public onlyGovOrGur{
       
        RP = IRewardProgram(rewardProgramAddress);
    }
    
    function setConditionalToken(address conditionalTokensAddress) public onlyGovOrGur{
        ct = ConditionalTokens(conditionalTokensAddress);
    }
    
    function setRoomoracleAddress(address newAddress) public onlyGovOrGur{
        roomOracleAddress = newAddress;
    }
    
    function setRewardCenter(address newAddress) public onlyGovOrGur{
        rewardCenterAddress = newAddress;
    }
    
    // market configuration
    function setMarketMinShareLiq(uint256 minLiq) public onlyGovOrGur {
        marketMinShareLiq = minLiq;
    }

    function setMarketValidatingPeriod(uint256 p) public onlyGovOrGur{
        marketValidatingPeriod = p;
    }

    function setMarketDisputePeriod(uint256 p) public onlyGovOrGur{
        marketDisputePeriod = p;
    }

    function setMarketReCastResolvingPeriod(uint256 p) public onlyGovOrGur{
        marketReCastResolvingPeriod = p;
    }

    function setDisputeThreshold(uint256 t) public onlyGovOrGur{
        disputeThreshold = t;
    }
    
    function setMarketLPFee(uint256 numerator, uint256 denominator) public onlyGovOrGur{
        marketLPFee = numerator * 1e18 / denominator;
    }
    
    function setProtocolFee(uint256 numerator, uint256 denominator) public onlyGovOrGur{
        protocolFee = numerator * 1e18 /denominator;
    }


}
