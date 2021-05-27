pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./IORMarketController.sol";
import "../Governance/IORGovernor.sol";
import "../TimeDependent/TimeDependent.sol";

import "./FixedProductMarketMakerFactoryOR.sol";
import "../RewardCenter/IRewardCenter.sol";
import "../RewardCenter/IRewardProgram.sol";
import {IRoomOraclePrice} from "../RewardCenter/IRoomOraclePrice.sol";
import "../Guardian/GnGOwnable.sol";
import {TransferHelper} from "../Helpers/TransferHelper.sol";


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
    using TransferHelper for IERC20;
    
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
    
    
    
    mapping(address => address[]) public marketsProposedByUser;
    mapping(address => address[]) public marketsLiquidityByUser;
    mapping(address => address[]) public marketsTradeByUser;
    
    mapping(address => mapping(address => bool)) marketsLiquidityFlag;
    mapping(address => mapping(address => bool)) marketsTradeFlag;
    
    IORGovernor public orGovernor;
    ConditionalTokens public ct; 
    IERC20 roomToken;
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
    
    mapping(address => bool) allowedCollaterals;
   
    mapping(address => bool) payoutsMarkets;

    uint256 public marketMinShareLiq = 100e18; //todo
    uint256 public feeMarketLP = 20000000000000000;  //2% todo
    uint256 public FeeProtocol = 10000000000000000; //1%t todo
    uint256 public FeeProposer = 10000000000000000; //1%t todo
    uint256 public buyRoomThreshold = 1e18; // todo
    uint256 public marketValidatingPeriod = 1800; // todo
    uint256 public marketDisputePeriod = 4 * 1800; // todo
    uint256 public marketReCastResolvingPeriod = 4 * 1800; //todo
    uint256 public disputeThreshold = 100e18; // todo
    uint256 public marketCreationFees = 100e18;
    
    bool penaltyOnWrongResolving;
    mapping(address => address[]) marketsVotedPerUser;
    
    mapping(bytes32 => address) public proposalIds;
    
    
    event DisputeSubmittedEvent(address indexed disputer, address indexed market, uint256 disputeTotalBalances, bool reachThresholdFlag);
    
    constructor() public{
        
        
    }
    
    
    function addMarket(address marketAddress, uint256 _marketCreatedTime,  uint256 _marketParticipationEndTime,  uint256 _marketResolvingEndTime) internal returns(uint256){
        
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
        
        ORMarketLib.MarketState marketState = getMarketState(marketAddress);
        require(marketState == ORMarketLib.MarketState.Resolved || marketState == ORMarketLib.MarketState.ForcedResolved, "market is not in resolved/ forces resolve state");

        IReportPayouts orConditionalTokens = IReportPayouts(address(market.getConditionalTokenAddress()));
        if(marketState == ORMarketLib.MarketState.Resolved){
            orConditionalTokens.reportPayouts(market.questionId(), getResolvingOutcome(marketAddress));
        }else{
            uint256[] memory indexSet = new uint256[](2);
            indexSet[0] = 1;
            indexSet[1] = 1;
            orConditionalTokens.reportPayouts(market.questionId(), indexSet);
        }
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
        if(marketsStopped[marketAddress] == true){
            return ORMarketLib.MarketState.ForcedResolved;
        }
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
        require( outcomeIndex < 2 , "Outcome should be within range!");
        address account = msg.sender;
        ORMarketLib.MarketState marketState = getMarketState(marketAddress);

        require(marketState == ORMarketLib.MarketState.Resolving || marketState == ORMarketLib.MarketState.ResolvingAfterDispute, "Market is not in resolving/ResolvingAfterDispute states");

        MarketVotersInfo storage marketVotersInfo = marketResolvingVotersInfo[marketAddress][account];
        require(marketVotersInfo.voteFlag == false, "user already voted");
        
        if(penaltyOnWrongResolving){
            address[] memory wrongVoting = checkForWrongVoting(account);
            bool doNoteVoteFalg = orGovernor.userhasWrongVoting(account, wrongVoting);
            if(doNoteVoteFalg){
                return;
            }
        }
        
        bool canVote;
        uint256 votePower;
        (canVote,votePower) = getAccountInfo(account);
        require(canVote == true, "user can not vote");


        if(marketState == ORMarketLib.MarketState.Resolving){
             marketsInfo[marketAddress].lastResolvingVoteTime = getCurrentTime();
        }else{
             marketsInfo[marketAddress].lastDisputeResolvingVoteTime = getCurrentTime();
        }
        
        if(penaltyOnWrongResolving){
            marketsVotedPerUser[account].push(marketAddress);
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
        
        if(penaltyOnWrongResolving){
            deleteMarketVoting(account,marketAddress);
        }
        require(marketVotersInfo.voteFlag == true, "user did not vote");

        marketVotersInfo.voteFlag = false;

        uint8 outcomeIndex = marketVotersInfo.selection;
        marketsInfo[marketAddress].resolvingVotesCount[outcomeIndex] -= marketVotersInfo.power;
        marketVotersInfo.power = 0;
        
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
    
    function deleteMarketVoting(address account, address market) internal{
        address[] storage marketsVoted = marketsVotedPerUser[account];
        for(uint256 i = 0; i < marketsVoted.length; i++){
            if(marketsVoted[i] == market){
               marketsVoted[i] = marketsVoted[marketsVoted.length -1];
               marketsVoted.length--;
                break;
            }
        }
    }
    
    function checkForWrongVoting(address account) internal returns(address[] memory wrongVoting){
       
        address[] storage marketsVoted = marketsVotedPerUser[account];
        wrongVoting = new address[](marketsVoted.length);
        uint256 wrongVoteIndex =0;
        for(int i = int(marketsVoted.length) -1; i >= 0; i--){
            address marketAddress = marketsVoted[uint256(i)];
            if(getMarketState(marketAddress) == ORMarketLib.MarketState.Resolved){
                //todo check wrongVoting
                
                // delete it
                marketsVoted[uint256(i)] = marketsVoted[marketsVoted.length -1];
                marketsVoted.length--;
                
                uint256[] memory indexSet = getResolvingOutcome(marketAddress);
                uint8 userSelection = marketResolvingVotersInfo[marketAddress][account].selection;
                if( indexSet[userSelection] != 1){
                    
                    wrongVoting[wrongVoteIndex] = marketAddress;
                    wrongVoteIndex++;
                }
            }
        }
        
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
    function createMarketProposal(string memory marketQuestionID, uint256 participationEndTime, uint256 resolvingEndTime, IERC20 collateralToken, uint256 initialLiq) public returns(address){
        require(allowedCollaterals[address(collateralToken)] == true, "Collateral token is not allowed");
    
        roomToken.safeTransferFrom(msg.sender, rewardCenterAddress ,marketCreationFees);
        bytes32 questionId = bytes32(marketsCount);
        require(proposalIds[questionId] == address(0), "proposal Id already used");
        require(initialLiq >= marketMinShareLiq, "initial liquidity less than minimum liquidity required" );
        ct.prepareCondition(address(this), questionId, 2);
        bytes32[]  memory conditionIds = new bytes32[](1);
        conditionIds[0] = ct.getConditionId(address(this), questionId, 2);
        //ORMarketController marketController =  ORMarketController(governanceAdd);
        
        ORFPMarket fpMarket = createFixedProductMarketMaker(ct, collateralToken, conditionIds, feeMarketLP, FeeProposer, msg.sender, roomOracleAddress);
        
        marketsProposedByUser[msg.sender].push(address(fpMarket));
        
        fpMarket.setConfig(marketQuestionID, address(this), questionId);
        addMarket(address(fpMarket),getCurrentTime(), participationEndTime, resolvingEndTime);
        
        proposalIds[questionId] = address(fpMarket);
        
        RP.addMarket(address(fpMarket));
        
        _marketAddLiquidity(address(fpMarket),initialLiq);
        
        
        return address(fpMarket);
    }
    
    
    function marketAddLiquidity(address market,uint256 amount) public{
        ORMarketLib.MarketState marketState = getMarketState(market);
        
        require(marketState == ORMarketLib.MarketState.Active || marketState == ORMarketLib.MarketState.Validating," liquidity can be added only in active/Validating state");
       _marketAddLiquidity(market,amount);
    }
    
    
    function _marketAddLiquidity(address market,uint256 amount) internal{
        ORFPMarket fpMarket = ORFPMarket(market);
        IERC20 collateralToken = fpMarket.collateralToken();
         // Add liquidity
        collateralToken.safeTransferFrom(msg.sender,address(this),amount);
        collateralToken.safeApprove(address(fpMarket),amount);
        uint sharesAmount = fpMarket.addLiquidityTo(msg.sender,amount);
        
        RP.lpMarketAdd(market, msg.sender, sharesAmount);
        
       
        if( marketsLiquidityFlag[msg.sender][market] == false){
            marketsLiquidityFlag[msg.sender][market] = true;
            marketsLiquidityByUser[msg.sender].push(market);
        }
    }
    
    function marketRemoveLiquidity(address market,uint256 sharesAmount, bool autoMerg, bool withdrawFees) public{
        
        address beneficiary = msg.sender;
        
        ORFPMarket fpMarket = ORFPMarket(market);
        
        address proposer = fpMarket.proposer();
        
         if(beneficiary == proposer) {
            ORMarketLib.MarketState marketState = getMarketState(market);
            
            if(marketState == ORMarketLib.MarketState.Validating || marketState == ORMarketLib.MarketState.Active){
                require(fpMarket.balanceOf(beneficiary).sub(sharesAmount) >= marketMinShareLiq, "The remaining shares dropped under the minimum");
            }
        }
        
        fpMarket.removeLiquidityTo(beneficiary,sharesAmount, autoMerg, withdrawFees);
        
        RP.lpMarketRemove(market, msg.sender, sharesAmount);
    }
    
    mapping(address => uint256) fees;
   
    function marketBuy(address market,uint investmentAmount, uint outcomeIndex, uint minOutcomeTokensToBu) public{
        ORMarketLib.MarketState marketState = getMarketState(market);
        require(marketState == ORMarketLib.MarketState.Active, "Market is not in active state");
        
        ORFPMarket fpMarket = ORFPMarket(market);
        IERC20 collateralToken = fpMarket.collateralToken();
        
        collateralToken.safeTransferFrom(msg.sender,address(this),investmentAmount);
        collateralToken.safeApprove(address(fpMarket),investmentAmount);
        
        uint256 pFee = investmentAmount * FeeProtocol / 1e18;
        fees[address(collateralToken)] += pFee;
        
        buyRoom(address(collateralToken));
        
        fpMarket.buyTo(msg.sender,investmentAmount-pFee,outcomeIndex,minOutcomeTokensToBu);
        
        RP.tradeAmount(market, msg.sender, investmentAmount, true);
       
        if( marketsTradeFlag[msg.sender][market] == false){
            marketsTradeFlag[msg.sender][market] = true;
            marketsTradeByUser[msg.sender].push(market);
        }
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
        
        
        uint256 pFee = tradeVolume * FeeProtocol / 1e18;
        fees[address(collateralToken)] += pFee;
        
        buyRoom(address(collateralToken));
        
        collateralToken.safeTransfer(msg.sender,tradeVolume - pFee);
        RP.tradeAmount(market, msg.sender, tradeVolume, false);
        
        if( marketsTradeFlag[msg.sender][market] == false){
            marketsTradeFlag[msg.sender][market] = true;
            marketsTradeByUser[msg.sender].push(market);
        }
    }
    
    function buyRoom(address IERCaddress) internal{
        if(fees[IERCaddress] >= buyRoomThreshold){
            if(roomOracleAddress != address(0)){
                IERC20 erc20 = IERC20(IERCaddress);
                erc20.safeApprove(roomOracleAddress,fees[IERCaddress]);
                IRoomOraclePrice(roomOracleAddress).buyRoom(IERCaddress,fees[IERCaddress],0,rewardCenterAddress);
                fees[IERCaddress] = 0;
            }
        }
    }
    
    function withdrawFees(address erc20Address, address to) public  onlyGovOrGur{
        IERC20 erc20 = IERC20(erc20Address);
        
        erc20.safeTransfer(to, erc20.balanceOf(address(this)));
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
    
    function setRoomAddress(address roomAddres) public onlyGovOrGur{
        roomToken =IERC20(roomAddres);
    }
    
    // market configuration
    
    function setMarketCreationFees(uint256 fees) public onlyGovOrGur{
        marketCreationFees = fees;    
    }
    
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
    
    function setFeeMarketLP(uint256 numerator, uint256 denominator) public onlyGovOrGur{
        
        feeMarketLP = numerator * 1e18 / denominator;
    }
    
    function setFeeProtocol(uint256 numerator, uint256 denominator) public onlyGovOrGur{
        FeeProtocol = numerator * 1e18 /denominator;
    }
    
    function setFeeProposer(uint256 numerator, uint256 denominator) public onlyGovOrGur{
        FeeProposer = numerator * 1e18 /denominator;
    }
    
    function setpenaltyOnWrongResolving(bool plentyFlag) public onlyGovOrGur{
        penaltyOnWrongResolving = plentyFlag;
    }
    
    function setCollateralAllowed(address token, bool allowdFlag) public onlyGovOrGur{
        allowedCollaterals[token] = allowdFlag;
    }
    
    mapping(address =>bool) marketsStopped;
    function marketStop(address market) public onlyGovOrGur{
        marketsStopped[market] = true;
    }


    function setBuyRoomThreshold(uint256 value) public onlyGovOrGur {
        buyRoomThreshold = value;
    }

}
