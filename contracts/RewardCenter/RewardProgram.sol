pragma solidity ^0.5.1;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../TimeDependent/TimeDependent.sol";
import "./IRewardCenter.sol";
import "./IRewardProgram.sol";

contract RewardProgram is TimeDependent, IRewardProgram{
    using SafeMath for uint256;
    
    struct LPUserInfoPMarket{
        uint256 totalVolume;
        uint256 prevAccRewardsPerToken;
        uint256 totalRewards;
        uint256 claimedRewards;
    }

    IRewardCenter rewardCenter ;
    
    uint256 public validationRewardPerDay = 1700e18; // todo
    uint256 public resolveRewardPerDay = 1700e18; // todo
    uint256 public tradeRewardPerDay = 1700e18; // todo
    uint256 public lpRewardPerDay = 1700e18; // todo

   
    bool public includeSellInTradeFlag = true; //todo

    
    uint256 public lpRewardPerBlock = lpRewardPerDay*1e18/5760;  // 1e18 math prec , 5,760 block per days
    uint256 public lpAccRewardsPerToken;
    uint256 public lpLastUpdateDate;
    uint256 public lpTotalEfectiveVolume;
    
    mapping(address => uint256) public lpMarketsWeight;
    mapping(address => uint256) public lpMarketsTotalVolume;
    mapping(address => bool) public lpMarketsStopRewards;
    
    mapping(address => mapping(address => LPUserInfoPMarket)) public lpUsers;

    mapping(address => bool) payoutsMarkets;
    

    uint256 public validationLastRewardsDistributedDay;
    mapping(uint256 => uint256) validationTotalPowerCastedPerDay;
    mapping(uint256 => uint256) validationRewardsPerDay;
    mapping(uint256 => mapping(address => uint256)) validationTotalPowerCastedPerDayPerUser;
    mapping(address => uint256) validationLastClaimedDayPerUser;
    
    uint256 public resolveLastRewardsDistributedDay;
    mapping(uint256 => uint256) resolveTotalPowerCastedPerDay;
    mapping(uint256 => uint256) resolveRewardsPerDay;
    mapping(uint256 => mapping(address => uint256)) resolveTotalPowerCastedPerDayPerUser;
    mapping(address => uint256) resolveLastClaimedDayPerUser;
    
    uint256 public tradeLastRewardsDistributedDay;
    mapping(uint256 => uint256) tradeTotalVolumePerDay;
    mapping(uint256 => uint256) tradeRewardsPerDay;
    mapping(uint256 => mapping(address => uint256)) tradeTotalVolumePerDayPerUser;
    mapping(address => uint256) tradeLastClaimedDayPerUser;
    
    
    constructor() public{
        uint256 cDay = getCurrentTime() / 1 days;
        validationLastRewardsDistributedDay =cDay;
        resolveLastRewardsDistributedDay = cDay;
    }
    
    function validationInstallRewards() public{
        uint256 dayPefore = (getCurrentTime() / 1 days) - 1;
        if(dayPefore > validationLastRewardsDistributedDay){
            for(uint256 index=dayPefore; index > validationLastRewardsDistributedDay; index--){
                validationRewardsPerDay[index] = validationRewardPerDay;
            }
            validationLastRewardsDistributedDay = dayPefore;
        }
    }
  
    function resolveInstallRewards() public{
        uint256 dayPefore = (getCurrentTime() / 1 days) - 1;
        if(dayPefore > resolveLastRewardsDistributedDay){
            for(uint256 index=dayPefore; index > resolveLastRewardsDistributedDay; index--){
                resolveRewardsPerDay[index] = resolveRewardPerDay;
            }
            resolveLastRewardsDistributedDay = dayPefore;
        }
    }

    function tradeInstallRewards() public{
        uint256 dayPefore = (getCurrentTime() / 1 days) - 1;
        if(dayPefore > tradeLastRewardsDistributedDay){
            for(uint256 index=dayPefore; index > tradeLastRewardsDistributedDay; index--){
                tradeRewardsPerDay[index] = tradeRewardPerDay;
            }
            tradeLastRewardsDistributedDay = dayPefore;
        }
    }

    function validationRewards(address account) public view returns(uint256 todayReward, uint256 rewardsCanClaim){
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

    function resolveRewards(address account) public view returns(uint256 todayReward, uint256 rewardsCanClaim){
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

    function tradeRewards(address account) public view returns(uint256 todayReward, uint256 rewardsCanClaim){
        uint256 cDay = getCurrentTime() /1 days;
        uint256 tCPtoday = tradeTotalVolumePerDay[cDay];
        if(tCPtoday != 0){
            uint256 userTotalVolumeToday = tradeTotalVolumePerDayPerUser[cDay][account];
            todayReward = tradeRewardPerDay * userTotalVolumeToday * 1e18/ tCPtoday;
            todayReward = todayReward / 1e18;
        }
        
        uint256 LastClaimedDay = tradeLastClaimedDayPerUser[account];
        for(uint256 index = LastClaimedDay + 1; index < cDay; index++){
            if(tradeTotalVolumePerDay[cDay] != 0){
                rewardsCanClaim += tradeRewardsPerDay[index] * tradeTotalVolumePerDayPerUser[index][account] * 1e18/ tradeTotalVolumePerDay[cDay];
            }
        }
        rewardsCanClaim = rewardsCanClaim / 1e18;
    }
    
    function validationClaimUserRewards() public {
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
    
    function resolveClaimUserRewards() public {
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

    function tradeClaimUserRewards() public {
        //todo: check if ther is punlty
        
        require(address(rewardCenter) != address(0), "Reward center is not set");
        
        address account = msg.sender;
        uint256 cDay = getCurrentTime() /1 days;
        
        uint256 rewardsCanClaim;
        uint256 LastClaimedDay = tradeLastClaimedDayPerUser[account];
        for(uint256 index = LastClaimedDay + 1; index < cDay; index++){
            if(tradeTotalVolumePerDay[cDay] != 0){
                rewardsCanClaim += tradeRewardsPerDay[index] * tradeTotalVolumePerDayPerUser[index][account] * 1e18/ tradeTotalVolumePerDay[cDay];
            }
        }
        
        tradeLastClaimedDayPerUser[account] = cDay -1;
        
        // todo: ask the reward center to send rewardsCanClaim
        rewardCenter.sendReward(account,rewardsCanClaim);
        
    }
    
    
    function claimRewards(bool ValidationRewardsFlag, bool resolveRewardsFlag, bool tradeRewardsFalg ) public{
       
        if(ValidationRewardsFlag){
            validationClaimUserRewards();
        }
        if(resolveRewardsFlag){
            resolveClaimUserRewards();
        }
        if(tradeRewardsFalg){
            tradeClaimUserRewards();
        }
        
    }
    
    function lpUpdateReward(address market, address account) public{
        uint256 cBlockNumber = getBlockNumber();
                
        if(cBlockNumber > lpLastUpdateDate){
            
            uint256 addedRewardPerToken;
            if(lpTotalEfectiveVolume != 0){
                addedRewardPerToken = cBlockNumber.sub(lpLastUpdateDate).mul(lpRewardPerBlock).div(lpTotalEfectiveVolume);
            }
            lpAccRewardsPerToken = lpAccRewardsPerToken.add(addedRewardPerToken);
            
        }
        
        lpLastUpdateDate = cBlockNumber;
        
        
        if(account != address(0))
        {
            LPUserInfoPMarket storage lpUser = lpUsers[market][account];
            uint256 accRewardPerTokenForUser = lpAccRewardsPerToken.sub(lpUser.prevAccRewardsPerToken);
            uint256 userEvectivetotalVolume = lpUser.totalVolume.mul(lpMarketsWeight[market]);
            uint256 newRewardsForUser =  accRewardPerTokenForUser.mul(userEvectivetotalVolume);
            lpUser.totalRewards = lpUser.totalRewards.add(newRewardsForUser);
            
            lpUser.prevAccRewardsPerToken = lpAccRewardsPerToken;
        }
        
    }
    
    function setMarketWeight(address market, uint256 weight) public{
        address account = msg.sender;
        lpUpdateReward(market, account);
        
        lpTotalEfectiveVolume = lpTotalEfectiveVolume.sub(lpMarketsTotalVolume[market].mul(lpMarketsWeight[market]));
        lpMarketsWeight[market] = weight;
        
        lpTotalEfectiveVolume = lpTotalEfectiveVolume.add(lpMarketsTotalVolume[market].mul(weight));
    }
    
    
    
    function cliamLPReward(address market) public returns(uint256){
        
        // Todo: can not claimed in aproving state or rejcted state
        LPUserInfoPMarket storage lpUser = lpUsers[market][msg.sender];
        
        uint256 amountToClaim = lpUser.totalRewards.sub(lpUser.claimedRewards);
        lpUser.claimedRewards = lpUser.totalRewards;
        
        //todo ask reward center to send amountToClaim
        return amountToClaim;
    }
    
    function getLPReward(address market, address account, uint256 cBlockNumber) public view returns(uint256 pendingRewards, uint256 claimedRewards){
       
        //cBlockNumber = getBlockNumber();
        
        // update accRewardPerToken, in case totalVolume is zero; do not increment accRewardPerToken
        
        uint256 lpAccRewardsPerTokenView = lpAccRewardsPerToken;
        if(cBlockNumber > lpLastUpdateDate){
            
            uint256 addedRewardPerToken;
            if(lpTotalEfectiveVolume != 0){
                addedRewardPerToken = cBlockNumber.sub(lpLastUpdateDate).mul(lpRewardPerBlock).div(lpTotalEfectiveVolume);
            }
            lpAccRewardsPerTokenView = lpAccRewardsPerTokenView.add(addedRewardPerToken);
            
        }
        
        //lpLastUpdateDate = cBlockNumber;
        
        
        if(account != address(0))
        {
            LPUserInfoPMarket memory lpUser = lpUsers[market][account];
            //UserInfoPPool memory user = users[market][account];
            uint256 accRewardPerTokenForUser = lpAccRewardsPerTokenView.sub(lpUser.prevAccRewardsPerToken);
            uint256 userEvectivetotalVolume = lpUser.totalVolume.mul(lpMarketsWeight[market]);
            uint256 newRewardsForUser =  accRewardPerTokenForUser.mul(userEvectivetotalVolume);
            lpUser.totalRewards = lpUser.totalRewards.add(newRewardsForUser);
            
            lpUser.prevAccRewardsPerToken = lpAccRewardsPerToken;
            
            claimedRewards = lpUser.claimedRewards;
            pendingRewards = lpUser.totalRewards - claimedRewards;
        }
        
    }
    
    
    function tradeAmount(address marketAddress, address account, uint256 amount, bool byeFlag) public{
        
        if(byeFlag  || includeSellInTradeFlag){
            uint256 cDay = getCurrentTime() / 1 days;
            
            tradeTotalVolumePerDay[cDay]+= amount;
            tradeTotalVolumePerDayPerUser[cDay][account]+= amount;
        }
    }
   
    function validationVote(address marketAddress,bool validationFlag,address account, uint256 votePower) public {
        // todo sec
        validationInstallRewards(); // first user in a day will mark the previous day to be distrubted
         
        uint256 cDay = getCurrentTime() /1 days;
        validationTotalPowerCastedPerDay[cDay]+= votePower;
        validationTotalPowerCastedPerDayPerUser[cDay][account]+= votePower;
        
    }

    
    function resolveVote(address marketAddress,uint8 selection, address account, uint256 votePower) public {
        // todo sec
        resolveInstallRewards(); // first user in a day will mark the previous day to be distrubted
        
        if(lpMarketsStopRewards[marketAddress] == false){ // first user vote for Resolving will stop the market from get rewards
            lpMarketsStopRewards[marketAddress] == true;
            setMarketWeight(marketAddress,0);
        }

        uint256 cDay = getCurrentTime() /1 days;
        resolveTotalPowerCastedPerDay[cDay]+= votePower;
        resolveTotalPowerCastedPerDayPerUser[cDay][account]+= votePower;
       
    }
    
    function lpMarketAdd(address market, address account, uint256 amount) public{
        
        lpUpdateReward(market, account);
        
        LPUserInfoPMarket storage lpUser = lpUsers[market][account];
        lpUser.totalVolume = lpUser.totalVolume.add(amount);
        
        lpMarketsTotalVolume[market] = lpMarketsTotalVolume[market].add(amount);
        lpTotalEfectiveVolume = lpTotalEfectiveVolume.add(amount.mul(lpMarketsWeight[market]));
    }
    
    function lpMarketRemove(address market, address account, uint256 amount) public{
       
        lpUpdateReward(market, account);
        
        LPUserInfoPMarket storage lpUser = lpUsers[market][account];
        lpUser.totalVolume = lpUser.totalVolume.sub(amount);
        
        lpMarketsTotalVolume[market] =lpMarketsTotalVolume[market].sub(amount);
        lpTotalEfectiveVolume = lpTotalEfectiveVolume.sub(amount.mul(lpMarketsWeight[market]));
    }
    
    
    //////////////////////
    
    uint256 cbn;

    function getBlockNumber() public view returns (uint256) {
        return cbn;
        //return block.number;
    }
    
    function increaseBlockNumber(uint256 n) public {
        cbn+=n;
    }


}