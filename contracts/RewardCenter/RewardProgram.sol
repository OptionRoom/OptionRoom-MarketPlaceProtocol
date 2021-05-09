pragma solidity ^0.5.1;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../TimeDependent/TimeDependent.sol";
import "./IRewardCenter.sol";
import "./IRewardProgram.sol";

contract RewardProgram is TimeDependent, IRewardProgram {

    using SafeMath for uint256;

    IRewardCenter rewardCenter;
    address marketControllerAddress;

    struct LPUserInfoPMarket {
        uint256 totalVolume;
        uint256 prevAccRewardsPerToken;
        uint256 totalRewards;
        uint256 claimedRewards;
    }

    uint256 public validationRewardPerDay = 1700e18; // todo
    uint256 public resolveRewardPerDay = 1700e18; // todo
    uint256 public tradeRewardPerDay = 1700e18; // todo
    uint256 public lpRewardPerDay = 1700e18; // todo

    bool public includeSellInTradeFlag = true; //todo

    uint256 deploymentDay = 0;

    uint256 public lpRewardPerBlock = lpRewardPerDay * 1e18 / 5760;  // 1e18 math prec , 5,760 block per days
    uint256 public lpAccRewardsPerToken;
    uint256 public lpLastUpdateDate;
    uint256 public lpTotalEffectiveVolume;

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


    constructor() public {
        initialize();
    }

    function initialize() internal {
        uint256 cDay = getCurrentTime() / 1 days;
        validationLastRewardsDistributedDay = cDay;
        resolveLastRewardsDistributedDay = cDay;
        tradeLastRewardsDistributedDay = cDay;
        deploymentDay = cDay;
    }
    
    function validationInstallRewards() public {
        uint256 dayBefore = (getCurrentTime() / 1 days) - 1;
        if (dayBefore > validationLastRewardsDistributedDay) {
            for (uint256 index = dayBefore; index > validationLastRewardsDistributedDay; index--) {
                validationRewardsPerDay[index] = validationRewardPerDay;
            }
            validationLastRewardsDistributedDay = dayBefore;
        }
    }

    function resolveInstallRewards() public {
        uint256 dayBefore = (getCurrentTime() / 1 days) - 1;
        if (dayBefore > resolveLastRewardsDistributedDay) {
            for (uint256 index = dayBefore; index > resolveLastRewardsDistributedDay; index--) {
                resolveRewardsPerDay[index] = resolveRewardPerDay;
            }
            resolveLastRewardsDistributedDay = dayBefore;
        }
    }

    function tradeInstallRewards() public {
        uint256 dayBefore = (getCurrentTime() / 1 days) - 1;
        if (dayBefore > tradeLastRewardsDistributedDay) {
            for (uint256 index = dayBefore; index > tradeLastRewardsDistributedDay; index--) {
                tradeRewardsPerDay[index] = tradeRewardPerDay;
            }
            tradeLastRewardsDistributedDay = dayBefore;
        }
    }

    function validationRewards(address account) public view returns (uint256 todayReward, uint256 rewardsCanClaim){
        uint256 cDay = getCurrentTime() / 1 days;
        uint256 tCPtoday = validationTotalPowerCastedPerDay[cDay];
        if (tCPtoday != 0) {
            uint256 userTotalPowerVotesToday = validationTotalPowerCastedPerDayPerUser[cDay][account];
            todayReward = validationRewardPerDay * userTotalPowerVotesToday * 1e18 / tCPtoday;
            todayReward = todayReward / 1e18;
        }

        uint256 LastClaimedDay = validationLastClaimedDayPerUser[account];
        if (LastClaimedDay < deploymentDay) {
            LastClaimedDay = deploymentDay;
        }
        for (uint256 index = LastClaimedDay; index < cDay; index++) {
            if (validationTotalPowerCastedPerDay[index] != 0) {
                rewardsCanClaim += validationRewardsPerDay[index] * validationTotalPowerCastedPerDayPerUser[index][account] * 1e18 / validationTotalPowerCastedPerDay[index];
            }
        }
        rewardsCanClaim = rewardsCanClaim / 1e18;
    }

    function resolveRewards(address account) public view returns (uint256 todayReward, uint256 rewardsCanClaim){
        uint256 cDay = getCurrentTime() / 1 days;
        uint256 tCPtoday = resolveTotalPowerCastedPerDay[cDay];
        if (tCPtoday != 0) {
            uint256 userTotalPowerVotesToday = resolveTotalPowerCastedPerDayPerUser[cDay][account];
            todayReward = resolveRewardPerDay * userTotalPowerVotesToday * 1e18 / tCPtoday;
            todayReward = todayReward / 1e18;
        }

        uint256 LastClaimedDay = resolveLastClaimedDayPerUser[account];
        if (LastClaimedDay < deploymentDay) {
            LastClaimedDay = deploymentDay;
        }
        for (uint256 index = LastClaimedDay; index < cDay; index++) {
            if (resolveTotalPowerCastedPerDay[index] != 0) {
                rewardsCanClaim += resolveRewardsPerDay[index] * resolveTotalPowerCastedPerDayPerUser[index][account] * 1e18 / resolveTotalPowerCastedPerDay[index];
            }
        }
        rewardsCanClaim = rewardsCanClaim / 1e18;
    }

    function tradeRewards(address account) public view returns (uint256 todayReward, uint256 rewardsCanClaim){
        uint256 cDay = getCurrentTime() / 1 days;
        uint256 tCPtoday = tradeTotalVolumePerDay[cDay];
        if (tCPtoday != 0) {
            uint256 userTotalVolumeToday = tradeTotalVolumePerDayPerUser[cDay][account];
            todayReward = tradeRewardPerDay * userTotalVolumeToday * 1e18 / tCPtoday;
            todayReward = todayReward / 1e18;
        }

        uint256 LastClaimedDay = tradeLastClaimedDayPerUser[account];
        if (LastClaimedDay < deploymentDay) {
            LastClaimedDay = deploymentDay;
        }
        for (uint256 index = LastClaimedDay; index < cDay; index++) {
            if (tradeTotalVolumePerDay[index] != 0) {
                rewardsCanClaim += tradeRewardsPerDay[index] * tradeTotalVolumePerDayPerUser[index][account] * 1e18 / tradeTotalVolumePerDay[index];
            }
        }
        rewardsCanClaim = rewardsCanClaim / 1e18;
    }

    function validationClaimUserRewards() public {
        //todo: check if there is penalty
        require(address(rewardCenter) != address(0), "Reward center is not set");
        address account = msg.sender;
        uint256 cDay = getCurrentTime() / 1 days;

        uint256 rewardsCanClaim;
        uint256 LastClaimedDay = validationLastClaimedDayPerUser[account];
        if (LastClaimedDay < deploymentDay) {
            LastClaimedDay = deploymentDay;
        }
        for (uint256 index = LastClaimedDay + 1; index < cDay; index++) {
            if (validationTotalPowerCastedPerDay[cDay] != 0) {
                rewardsCanClaim += validationRewardsPerDay[index] * validationTotalPowerCastedPerDayPerUser[index][account] * 1e18 / validationTotalPowerCastedPerDay[cDay];
            }
        }

        validationLastClaimedDayPerUser[account] = cDay - 1;

        // todo: ask the reward center to send rewardsCanClaim
        rewardCenter.sendReward(account, rewardsCanClaim);

    }

    function resolveClaimUserRewards() public {
        //todo: check if there is penalty

        require(address(rewardCenter) != address(0), "Reward center is not set");

        address account = msg.sender;
        uint256 cDay = getCurrentTime() / 1 days;

        uint256 rewardsCanClaim;
        uint256 LastClaimedDay = resolveLastClaimedDayPerUser[account];
        if (LastClaimedDay < deploymentDay) {
            LastClaimedDay = deploymentDay;
        }
        for (uint256 index = LastClaimedDay + 1; index < cDay; index++) {
            if (resolveTotalPowerCastedPerDay[cDay] != 0) {
                rewardsCanClaim += resolveRewardsPerDay[index] * resolveTotalPowerCastedPerDayPerUser[index][account] * 1e18 / resolveTotalPowerCastedPerDay[cDay];
            }
        }

        resolveLastClaimedDayPerUser[account] = cDay - 1;

        // todo: ask the reward center to send rewardsCanClaim
        rewardCenter.sendReward(account, rewardsCanClaim);

    }

    function tradeClaimUserRewards() public {
        //todo: check if there is penalty

        require(address(rewardCenter) != address(0), "Reward center is not set");

        address account = msg.sender;
        uint256 cDay = getCurrentTime() / 1 days;

        uint256 rewardsCanClaim;
        uint256 LastClaimedDay = tradeLastClaimedDayPerUser[account];
        if (LastClaimedDay < deploymentDay) {
            LastClaimedDay = deploymentDay;
        }
        for (uint256 index = LastClaimedDay + 1; index < cDay; index++) {
            if (tradeTotalVolumePerDay[cDay] != 0) {
                rewardsCanClaim += tradeRewardsPerDay[index] * tradeTotalVolumePerDayPerUser[index][account] * 1e18 / tradeTotalVolumePerDay[cDay];
            }
        }

        tradeLastClaimedDayPerUser[account] = cDay - 1;

        // todo: ask the reward center to send rewardsCanClaim
        rewardCenter.sendReward(account, rewardsCanClaim);

    }


    function claimRewards(bool ValidationRewardsFlag, bool resolveRewardsFlag, bool tradeRewardsFlag) public {

        if (ValidationRewardsFlag) {
            validationClaimUserRewards();
        }
        if (resolveRewardsFlag) {
            resolveClaimUserRewards();
        }
        if (tradeRewardsFlag) {
            tradeClaimUserRewards();
        }

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

    function setMarketWeight(address market, uint256 weight) public {
        // todo sec chec
        address account = msg.sender;
        lpUpdateReward(market, account);

        lpTotalEffectiveVolume = lpTotalEffectiveVolume.sub(lpMarketsTotalVolume[market].mul(lpMarketsWeight[market]));
        lpMarketsWeight[market] = weight;

        lpTotalEffectiveVolume = lpTotalEffectiveVolume.add(lpMarketsTotalVolume[market].mul(weight));
    }


    function claimLPReward(address market) public returns (uint256) {
        // Todo: can not claim in the following proposal states (approving, rejected)
        LPUserInfoPMarket storage lpUser = lpUsers[market][msg.sender];

        uint256 amountToClaim = lpUser.totalRewards.sub(lpUser.claimedRewards);
        lpUser.claimedRewards = lpUser.totalRewards;

        //todo ask reward center to send amountToClaim
        return amountToClaim;
    }

    function getLPReward(address market, address account, uint256 cBlockNumber) public view returns (uint256 pendingRewards, uint256 claimedRewards){
        //cBlockNumber = getBlockNumber();

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


    function tradeAmount(address market, address account, uint256 amount, bool buyFlag) public {
        require(msg.sender == marketControllerAddress , "caller is not market controller");

        tradeInstallRewards();
        
        if (buyFlag || includeSellInTradeFlag) {
            uint256 cDay = getCurrentTime() / 1 days;

            tradeTotalVolumePerDay[cDay] += amount;
            tradeTotalVolumePerDayPerUser[cDay][account] += amount;
        }
    }

    function validationVote(address market, bool validationFlag, address account, uint256 votePower) public {
        require(msg.sender == marketControllerAddress , "caller is not market controller");
        
        validationInstallRewards();
        // first user in a day will mark the previous day to be distributed

        uint256 cDay = getCurrentTime() / 1 days;
        validationTotalPowerCastedPerDay[cDay] += votePower;
        validationTotalPowerCastedPerDayPerUser[cDay][account] += votePower;
    }


    function resolveVote(address market, uint8 selection, address account, uint256 votePower) public {
        require(msg.sender == marketControllerAddress , "caller is not market controller");
        
        resolveInstallRewards();
        // first caller in a day will mark the previous day to be distributed

        if (lpMarketsStopRewards[market] == false) {// first caller vote for Resolving will stop the market from get rewards
            lpMarketsStopRewards[market] == true;
            setMarketWeight(market, 0);
        }

        uint256 cDay = getCurrentTime() / 1 days;
        resolveTotalPowerCastedPerDay[cDay] += votePower;
        resolveTotalPowerCastedPerDayPerUser[cDay][account] += votePower;
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
    
    
    function setMarketControllerAddress(address controllerAddress) public{
        // sec only deployer
        marketControllerAddress = controllerAddress;
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
