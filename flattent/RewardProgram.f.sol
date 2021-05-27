// File: openzeppelin-solidity\contracts\math\SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity\contracts\token\ERC20\IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\RewardCenter\IRewardCenter.sol

pragma solidity ^0.5.1;


interface IRewardCenter {
    
    function sendRoomReward(address beneficiary, uint256 amount, string calldata comment) external;
    
    function sendRoomRewardByDollarAmount(address beneficiary, uint256 amount, string calldata comment) external;
}


contract DummyRewardCenter is IRewardCenter {
    
    function sendRoomReward(address beneficiary, uint256 amount, string calldata comment) external{
    }
    
    function sendRoomRewardByERC20Value(address beneficiary, uint256 amount, IERC20 erc20, string calldata comment) external{
    }
    
    function sendRoomRewardByDollarAmount(address beneficiary, uint256 amount, string calldata comment) external{
        
    }
    
}

// File: contracts\RewardCenter\IRewardProgram.sol

pragma solidity ^0.5.1;

interface IRewardProgram {
    function addMarket(address market) external;
    
    function lpMarketAdd(address market, address account, uint256 amount) external;

    function lpMarketRemove(address market, address account, uint256 amount) external;

    function resolveVote(address market, uint8 selection, address account, uint256 votePower) external;

    function validationVote(address market, bool validationFlag, address account, uint256 votePower) external;
    
    function tradeAmount(address market, address account, uint256 amount, bool buyFlag) external;
    
}


contract DummyRewardProgram {
    
    function addMarket(address market) external{
        
    }
    
    function lpMarketAdd(address market, address account, uint256 amount) external{
        
    }

    function lpMarketRemove(address market, address account, uint256 amount) external{
        
    }

    function resolveVote(address market, uint8 selection, address account, uint256 votePower) external{
        
    }

    function validationVote(address market, bool validationFlag, address account, uint256 votePower) external{
        
    }
    
    function tradeAmount(address market, address account, uint256 amount, bool buyFlag) external
    {
        
    }
}

// File: contracts\Guardian\GnGOwnable.sol

pragma solidity ^0.5.0;


contract GnGOwnable {
    address public guardianAddress;
    address public governorAddress;
    
    event GuardianTransferred(address indexed oldGuardianAddress, address indexed newGuardianAddress);
    event GovernorTransferred(address indexed oldGuardianAddress, address indexed newGuardianAddress);
    
    constructor() public{
        guardianAddress = msg.sender;
    }
    
    modifier onlyGovOrGur{
        require(msg.sender == governorAddress || msg.sender == guardianAddress, "caller is not governor or guardian");
        _;
    }
    
    modifier onlyGuardian {
        require(msg.sender == guardianAddress, "caller is not guardian");
        _;
    }
    
    
    function transferGuardian(address newGuardianAddress) public onlyGovOrGur {
        emit GuardianTransferred(guardianAddress, newGuardianAddress);
        guardianAddress = newGuardianAddress;
    }
    
    function transferGovernor(address newGovernorAddress) public onlyGovOrGur {
        emit GuardianTransferred(governorAddress, newGovernorAddress);
        governorAddress = newGovernorAddress;
    }
}

// File: contracts\OR\ORMarketLib.sol

pragma solidity ^0.5.1;

library ORMarketLib{
    enum MarketState {
        Invalid,
        Validating, // governance voting for validation
        Rejected,
        Active,
        Inactive,
        Resolving, // governance voting for result
        Resolved,  // can redeem
        DisputePeriod, // Dispute
        ResolvingAfterDispute,
        ForcedResolved
    }
}

// File: contracts\OR\IORMarketController.sol

pragma solidity ^0.5.1;


interface IORMarketController {

    function payoutsAction(address marketAddress) external;
    
    function getMarketState(address marketAddress) external view returns (ORMarketLib.MarketState);
}

// File: contracts\RewardCenter\RewardProgram.sol

pragma solidity ^0.5.1;






contract RewardProgram is IRewardProgram, GnGOwnable {

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

    
    mapping(uint256 => uint256) gRewardPerDay; 
    mapping(uint256 => uint256) gLastRewardsDistributedDay;
    mapping(uint256 => mapping(uint256 => uint256))  gTotalVolumePerDay;
    mapping(uint256 => mapping(uint256 => uint256))  gRewardsPerDay;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))  gTotalVolumePerDayPerUser;
    mapping(uint256 => mapping(address => uint256))  gLastClaimedDayPerUser;
    mapping(uint256 => mapping(address => uint256))  gClaimedPerUser;
    
    
    constructor() public {
        initialize();
        
    }

    function initialize() internal {
        uint256 cDay = getCurrentTime() / 1 days;
        deploymentDay = cDay;
        gLastRewardsDistributedDay[uint256(RewardType.Validation)] = cDay;
        gLastRewardsDistributedDay[uint256(RewardType.Resolve)] = cDay;
        gLastRewardsDistributedDay[uint256(RewardType.Trade)] = cDay;
        gRewardPerDay[uint256(RewardType.Validation)] = validationRewardPerDay;
        gRewardPerDay[uint256(RewardType.Resolve)] = resolveRewardPerDay;
        gRewardPerDay[uint256(RewardType.Trade)] = tradeRewardPerDay;
    }
    
    function addMarket(address market) external{
        require(msg.sender == marketControllerAddress , "caller is not market controller");
        _setMarketWeight(market,1);
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
        lpUpdateReward(market, msg.sender);

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
            lpUser.totalRewards = lpUser.totalRewards.add(newRewardsForUser.div(1e18));

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
        
        gInstallRewards(poolID);
        
        address account = msg.sender;
        uint256 cDay = getCurrentTime() / 1 days;

        uint256 rewardsCanClaim;
        
        uint256 lastClaimedDay = gLastClaimedDayPerUser[poolID][account];
        if (lastClaimedDay < deploymentDay) {
            lastClaimedDay = deploymentDay;
        }
        
        for ( ; lastClaimedDay < cDay; lastClaimedDay++) {
            if (gTotalVolumePerDay[poolID][lastClaimedDay] != 0) {
                rewardsCanClaim += gRewardsPerDay[poolID][lastClaimedDay] * gTotalVolumePerDayPerUser[poolID][lastClaimedDay][account] * 1e18 / gTotalVolumePerDay[poolID][lastClaimedDay];
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
    
 
    function setMarketControllerAddress(address controllerAddress) public onlyGovOrGur{

        marketControllerAddress = controllerAddress;
    }
    
    function setRewardCenter(address rewardCenterAddress) public onlyGovOrGur {
        rewardCenter = IRewardCenter(rewardCenterAddress);
    }
    
    function getBlockNumber() public view returns (uint256) {
        
        return block.number;
    }

    function getCurrentTime() public view returns(uint256){

        return block.timestamp;
    }

}
