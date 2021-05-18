pragma solidity ^0.5.1;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../TimeDependent/TimeDependent.sol";
import "./IRewardCenter.sol";
import "./IRewardProgram.sol";
import "../Guardian/GnGOwnable.sol";
import "../OR/IORMarketController.sol";

contract RewardProgram is TimeDependent, IRewardProgram, GnGOwnable {

    using SafeMath for uint256;

    IRewardCenter rewardCenter;
    address marketControllerAddress;

    struct LPUserInfoPMarket {
        uint256 totalVolume;
        uint256 prevAccRewardsPerToken;
        uint256 totalRewards;
        uint256 claimedRewards;
    }
    
    enum RewardType{
        Trade,
        Validation,
        Resolve
    }
    
    bool public includeSellInTradeRewards = true; //todo

    uint256 public validationRewardPerDay = 1000e18; // todo
    uint256 public resolveRewardPerDay = 1000e18; // todo
    uint256 public tradeRewardPerDay = 1000e18; // todo
    uint256 public lpRewardPerDay = 1000e18; // todo

    bool public includeSellInTradeFlag = true; //todo

    uint256 deploymentDay = 0;

    uint256 public lpRewardPerBlock = lpRewardPerDay * 1e18 / 5760;  // 1e18 math prec , 5,760 block per days 
    uint256 public lpAccRewardsPerToken;
    uint256 public lpLastUpdateDate;
    uint256 public lpTotalEffectiveVolume;

    mapping(address => uint256) public lpMarketsWeight;
    mapping(address => uint256) public lpMarketsTotalVolume;
    mapping(address => bool)    public lpMarketsStopRewards;
    mapping(address => mapping(address => LPUserInfoPMarket)) public lpUsers;

    
    mapping(uint256 => uint256) gRewardPerDay; // todo
    mapping(uint256 => uint256) gLastRewardsDistributedDay;
    mapping(uint256 => mapping(uint256 => uint256))  gTotalVolumePerDay;
    mapping(uint256 => mapping(uint256 => uint256))  gRewardsPerDay;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))  gTotalVolumePerDayPerUser;
    mapping(uint256 => mapping(address => uint256))  gLastClaimedDayPerUser;
    mapping(uint256 => mapping(address => uint256))  gClaimedPerUser;
    
    
    constructor() public {
        
        
    }

    function initialize() internal {
        uint256 cDay = getCurrentTime() / 1 days;
        deploymentDay = cDay;
        gLastRewardsDistributedDay[0] = cDay;
        gLastRewardsDistributedDay[1] = cDay;
        gLastRewardsDistributedDay[2] = cDay;
        gRewardPerDay[0] = validationRewardPerDay;
        gRewardPerDay[1] = resolveRewardPerDay;
        gRewardPerDay[2] = tradeRewardPerDay;
    }
    
    function setCentralTimeForTesting(CentralTimeForTesting _centralTimeForTesting) public{
        centralTimeForTesting = _centralTimeForTesting;
        initialize();
    }
    
    
    function lpUpdateReward(address market, address account) public {
        uint256 cBlockNumber = getBlockNumber();

        if (cBlockNumber > lpLastUpdateDate) {
            uint256 addedRewardPerToken;
            if (lpTotalEffectiveVolume != 0) {
                addedRewardPerToken = cBlockNumber.sub(lpLastUpdateDate).mul(lpRewardPerBlock).div(lpTotalEffectiveVolume);
            }
            lpAccRewardsPerToken = lpAccRewardsPerToken.add(addedRewardPerToken);
        }

        lpLastUpdateDate = cBlockNumber;

        if (account != address(0)) {
            LPUserInfoPMarket storage lpUser = lpUsers[market][account];
            uint256 accRewardPerTokenForUser = lpAccRewardsPerToken.sub(lpUser.prevAccRewardsPerToken);
            
            uint256 userEffectiveTotalVolume = lpUser.totalVolume.mul(lpMarketsWeight[market]);
            uint256 newRewardsForUser = accRewardPerTokenForUser.mul(userEffectiveTotalVolume);
            lpUser.totalRewards = lpUser.totalRewards.add(newRewardsForUser.div(1e18));

            lpUser.prevAccRewardsPerToken = lpAccRewardsPerToken;
        }
    }

    function _setMarketWeight(address market, uint256 weight) internal {
        
        address account = msg.sender;
        lpUpdateReward(market, account);

        lpTotalEffectiveVolume = lpTotalEffectiveVolume.sub(lpMarketsTotalVolume[market].mul(lpMarketsWeight[market]));
        lpMarketsWeight[market] = weight;

        lpTotalEffectiveVolume = lpTotalEffectiveVolume.add(lpMarketsTotalVolume[market].mul(weight));
    }


    function claimLPReward(address market) public returns (uint256) {
        IORMarketController marketController = IORMarketController(marketControllerAddress);
        ORMarketLib.MarketState marketState = marketController.getMarketState(market);
        require(marketState >= ORMarketLib.MarketState.Active, "can not claim in Invalid, Validating, Rejected state"); //can not claim in the following proposal states (Invalid, Validating, Rejected )
        LPUserInfoPMarket storage lpUser = lpUsers[market][msg.sender];

        uint256 amountToClaim = lpUser.totalRewards.sub(lpUser.claimedRewards);
        lpUser.claimedRewards = lpUser.totalRewards;

        rewardCenter.sendRoomRewardByDollarAmount(msg.sender,amountToClaim, "");
        return amountToClaim;
    }

    function getLPReward(address market, address account) public view returns (uint256 pendingRewards, uint256 claimedRewards){
        uint256 cBlockNumber = getBlockNumber();

        // update accRewardPerToken, in case totalVolume is zero; do not increment accRewardPerToken

        uint256 lpAccRewardsPerTokenView = lpAccRewardsPerToken;
        if (cBlockNumber > lpLastUpdateDate) {

            uint256 addedRewardPerToken;
            if (lpTotalEffectiveVolume != 0) {
                addedRewardPerToken = cBlockNumber.sub(lpLastUpdateDate).mul(lpRewardPerBlock).div(lpTotalEffectiveVolume);
            }
            lpAccRewardsPerTokenView = lpAccRewardsPerTokenView.add(addedRewardPerToken);

        }

        //lpLastUpdateDate = cBlockNumber;


        if (account != address(0))
        {
            LPUserInfoPMarket memory lpUser = lpUsers[market][account];
            //UserInfoPPool memory user = users[market][account];
            uint256 accRewardPerTokenForUser = lpAccRewardsPerTokenView.sub(lpUser.prevAccRewardsPerToken);
            uint256 userEffectiveTotalVolume = lpUser.totalVolume.mul(lpMarketsWeight[market]);
            uint256 newRewardsForUser = accRewardPerTokenForUser.mul(userEffectiveTotalVolume);
            lpUser.totalRewards = lpUser.totalRewards.add(newRewardsForUser);

            lpUser.prevAccRewardsPerToken = lpAccRewardsPerToken;

            claimedRewards = lpUser.claimedRewards;
            pendingRewards = lpUser.totalRewards - claimedRewards;
        }
    }

    function lpMarketAdd(address market, address account, uint256 amount) public {
        require(msg.sender == marketControllerAddress , "caller is not market controller");
        
        lpUpdateReward(market, account);

        LPUserInfoPMarket storage lpUser = lpUsers[market][account];
        lpUser.totalVolume = lpUser.totalVolume.add(amount);

        lpMarketsTotalVolume[market] = lpMarketsTotalVolume[market].add(amount);
        lpTotalEffectiveVolume = lpTotalEffectiveVolume.add(amount.mul(lpMarketsWeight[market]));
    }

    function lpMarketRemove(address market, address account, uint256 amount) public {
        require(msg.sender == marketControllerAddress , "caller is not market controller");
        
        lpUpdateReward(market, account);

        LPUserInfoPMarket storage lpUser = lpUsers[market][account];
        lpUser.totalVolume = lpUser.totalVolume.sub(amount);

        lpMarketsTotalVolume[market] = lpMarketsTotalVolume[market].sub(amount);
        lpTotalEffectiveVolume = lpTotalEffectiveVolume.sub(amount.mul(lpMarketsWeight[market]));
    }
    
    //////////////////////////////////
    
    function gInstallRewards(uint256 poolID) internal {
        uint256 cDay = (getCurrentTime() / 1 days) ;
       
            for (uint256 index = gLastRewardsDistributedDay[poolID]; index < cDay; index++) {
                gRewardsPerDay[poolID][index] = gRewardPerDay[poolID];
            }
            gLastRewardsDistributedDay[poolID] = cDay;
        
    }

   

    function gRewards(uint256 poolID, address account) internal view returns (uint256 todayExpectedReward, uint256 rewardsCanClaim, uint256 claimedRewards){
        uint256 cDay = getCurrentTime() / 1 days;
        uint256 tCPtoday = gTotalVolumePerDay[poolID][cDay];
        if (tCPtoday != 0) {
            uint256 userTotalPowerVotesToday = gTotalVolumePerDayPerUser[poolID][cDay][account];
            todayExpectedReward = gRewardPerDay[poolID] * userTotalPowerVotesToday * 1e18 / tCPtoday;
            todayExpectedReward = todayExpectedReward / 1e18;
        }

       
        
        uint256 lastClaimedDay = gLastClaimedDayPerUser[poolID][account];
        if (lastClaimedDay < deploymentDay) {
            lastClaimedDay = deploymentDay;
        }
        
        for (uint256 index = lastClaimedDay ; index < cDay; index++) {
            if (gTotalVolumePerDay[poolID][index] != 0) { //gRewardPerDay
                uint256 localgRewardPerDay = gRewardsPerDay[poolID][index];
                if(localgRewardPerDay == 0){
                    localgRewardPerDay = gRewardPerDay[poolID];
                }
                rewardsCanClaim += localgRewardPerDay * gTotalVolumePerDayPerUser[poolID][index][account] * 1e18 / gTotalVolumePerDay[poolID][index];
            }
        }
        rewardsCanClaim = rewardsCanClaim / 1e18;
        claimedRewards = gClaimedPerUser[poolID][account];
    }
    
    function gClaimUserRewards(uint256 poolID) internal {
        //todo: check if there is penalty
        
        gInstallRewards(poolID);
        
        address account = msg.sender;
        uint256 cDay = getCurrentTime() / 1 days;

        uint256 rewardsCanClaim;
        
        uint256 lastClaimedDay = gLastClaimedDayPerUser[poolID][account];
        if (lastClaimedDay < deploymentDay) {
            lastClaimedDay = deploymentDay;
        }
        
        for (uint256 index = lastClaimedDay ; index < cDay; index++) {
            if (gTotalVolumePerDay[poolID][index] != 0) {
                rewardsCanClaim += gRewardsPerDay[poolID][index] * gTotalVolumePerDayPerUser[poolID][index][account] * 1e18 / gTotalVolumePerDay[poolID][index];
            }
        }
        rewardsCanClaim = rewardsCanClaim / 1e18;
        gLastClaimedDayPerUser[poolID][account] = lastClaimedDay;

        rewardCenter.sendRoomRewardByDollarAmount(msg.sender,rewardsCanClaim, "");
        gClaimedPerUser[poolID][msg.sender] += rewardsCanClaim;
    }



    function gAdd(uint256 poolID,  address account, uint256 v) internal {
       require(msg.sender == marketControllerAddress , "caller is not market controller");
        
        gInstallRewards(poolID);
        // first user in a day will mark the previous day to be distributed

        uint256 cDay = getCurrentTime() / 1 days;
        gTotalVolumePerDay[poolID][cDay] += v;
        gTotalVolumePerDayPerUser[poolID][cDay][account] += v;
    }
    
    /////////
    
    function resolveVote(address market, uint8 , address account, uint256 votePower) external{
        gAdd( uint256(RewardType.Resolve) ,account, votePower);
        _setMarketWeight(market,0); // when start Resolve the market, no need to give rewards for LP
    }
    
    function validationVote(address , bool , address account, uint256 votePower) external{
        gAdd( uint256(RewardType.Validation) ,account, votePower);
    }
    
    function tradeAmount(address , address account, uint256 amount, bool buyFlag) external{
        require(msg.sender == marketControllerAddress , "caller is not market controller");
        
        if(buyFlag || includeSellInTradeRewards){
            gAdd( uint256(RewardType.Trade) ,account, amount);
        }
    }
    
    
    function resolveRewards(address account) public view returns (uint256 todayExpectedReward, uint256 rewardsCanClaim, uint256 claimedRewards){
        return gRewards(uint256(RewardType.Resolve), account);
    }
    
    function validationRewards(address account) public view returns (uint256 todayExpectedReward, uint256 rewardsCanClaim, uint256 claimedRewards){
        return gRewards(uint256(RewardType.Validation), account);
    }
    
    function tradeRewards(address account) public view returns (uint256 todayExpectedReward, uint256 rewardsCanClaim, uint256 claimedRewards){
        return gRewards(uint256(RewardType.Trade), account);
    }
    
    
    function claimRewards(bool validationFlag, bool resolveFlag, bool tradeFlag) public{
        if(validationFlag){
            gClaimUserRewards(uint256(RewardType.Validation));
        }
        
        if(resolveFlag){
            gClaimUserRewards(uint256(RewardType.Resolve));
        }
        
        if(tradeFlag){
            gClaimUserRewards(uint256(RewardType.Trade));
        }
    }
    ////////////////////
    
    
    
    function setValidationRewardPerDay(uint256 rewardPerDay) public onlyGovOrGur{
        validationRewardPerDay = rewardPerDay;
        gRewardPerDay[uint256(RewardType.Validation)] = validationRewardPerDay;
    }
    
    function setResolveRewardPerDay(uint256 rewardPerDay) public onlyGovOrGur{
        resolveRewardPerDay = rewardPerDay;
        gRewardPerDay[uint256(RewardType.Resolve)] = resolveRewardPerDay;

    }
    
    function setTradeRewardPerDay(uint256 rewardPerDay) public onlyGovOrGur{
        tradeRewardPerDay = rewardPerDay;
        gRewardPerDay[uint256(RewardType.Trade)] = tradeRewardPerDay;
    }
    
    function setLPRewardPerDay(uint256 rewardPerDay) public onlyGovOrGur{
        lpRewardPerDay = rewardPerDay;
        lpRewardPerBlock = lpRewardPerDay * 1e18 / 5760;
    }
    
    function setMarketWeight(address market, uint256 weight) public onlyGovOrGur {
        _setMarketWeight(market,weight);
    }
    
    function setIncludeSellInTradeRewards(bool includeSellInTradeRewardsFlag) public onlyGovOrGur{
        includeSellInTradeRewards = includeSellInTradeRewardsFlag;
    }
    
    /////////////////
    
    function setMarketControllerAddress(address controllerAddress) public onlyGovOrGur{

        marketControllerAddress = controllerAddress;
    }
    
    function setRewardCenter(address rewardCenterAddress) public onlyGovOrGur {
        rewardCenter = IRewardCenter(rewardCenterAddress);
    }
    


    //////////////////////

    uint256 cbn; // todo

    function getBlockNumber() public view returns (uint256) {
        return cbn;
        //return block.number;
    }

    function increaseBlockNumber(uint256 n) public {
        cbn += n;
    }


}
