pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
//import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


contract MarketsLPSRewards {
    using SafeMath for uint256;

    
    
     struct UserInfoPPool{
        uint256 totalStake;
        uint256 prevAccRewardsPerToken;
        uint256 totalRewards;
        uint256 claimedRewards;
    }
    
    uint256 public rewardPerBlock = 1e18;
    uint256 public accRewardsPerToken;
    uint256 public lastUpdateDate;
    uint256 public totalEfectiveStake;
    
    
    mapping(uint256 => uint256) public poolsWeight;
    mapping(uint256 => uint256) public poolsTotalStake;
    
    
   
    mapping(uint256 => mapping(address => UserInfoPPool)) public users;
    
    
    function updateReward(uint256 poolID, address account) public{
        uint256 cBlockNumber = getBlockNumber();
        
        // update accRewardPerToken, in case totalStake is zero; do not increment accRewardPerToken
        
        if(cBlockNumber > lastUpdateDate){
            
            uint256 addedRewardPerToken;
            if(totalEfectiveStake != 0){
                addedRewardPerToken = cBlockNumber.sub(lastUpdateDate).mul(rewardPerBlock).div(totalEfectiveStake);
            }
            accRewardsPerToken = accRewardsPerToken.add(addedRewardPerToken);
            
        }
        
        lastUpdateDate = cBlockNumber;
        
        
        if(account != address(0))
        {
            UserInfoPPool storage user = users[poolID][account];
            uint256 accRewardPerTokenForUser = accRewardsPerToken.sub(user.prevAccRewardsPerToken);
            uint256 userEvectiveTotalStake = user.totalStake.mul(poolsWeight[poolID]);
            uint256 newRewardsForUser =  accRewardPerTokenForUser.mul(userEvectiveTotalStake);
            user.totalRewards = user.totalRewards.add(newRewardsForUser);
            
            user.prevAccRewardsPerToken = accRewardsPerToken;
        }
        
    }
    
    function setPool(uint256 poolID, uint256 weight) public{
        address account = msg.sender;
        updateReward(poolID, account);
        
        totalEfectiveStake = totalEfectiveStake.sub(poolsTotalStake[poolID].mul(poolsWeight[poolID]));
        poolsWeight[poolID] = weight;
        
        totalEfectiveStake = totalEfectiveStake.add(poolsTotalStake[poolID].mul(weight));
    }
    
    function stake(uint256 poolID, uint256 amount) public{
        address account = msg.sender;
        updateReward(poolID, account);
        
        UserInfoPPool storage user = users[poolID][account];
        user.totalStake = user.totalStake.add(amount);
        
        poolsTotalStake[poolID] = poolsTotalStake[poolID].add(amount);
        totalEfectiveStake = totalEfectiveStake.add(amount.mul(poolsWeight[poolID]));
    }
    
    function unstake(uint256 poolID, uint256 amount) public{
        address account = msg.sender;
        updateReward(poolID, account);
        
        UserInfoPPool storage user = users[poolID][account];
        user.totalStake = user.totalStake.sub(amount);
        
        poolsTotalStake[poolID] =poolsTotalStake[poolID].sub(amount);
        totalEfectiveStake = totalEfectiveStake.sub(amount.mul(poolsWeight[poolID]));
    }
    
    function cliamReward(uint256 poolID) public returns(uint256){
        
        // Todo: can not claimed in aproving state or rejcted state
        UserInfoPPool storage user = users[poolID][msg.sender];
        
        uint256 amountToClaim = user.totalRewards.sub(user.claimedRewards);
        user.claimedRewards = user.totalRewards;
        
        //todo ask reward center to send amountToClaim
        return amountToClaim;
    }
    
    function getReward(uint256 poolID, address account, uint256 cBlockNumber) public view returns(uint256 pendingRewards, uint256 claimedRewards){
       
        //cBlockNumber = getBlockNumber();
        
        // update accRewardPerToken, in case totalStake is zero; do not increment accRewardPerToken
        
        uint256 accRewardsPerTokenView = accRewardsPerToken;
        if(cBlockNumber > lastUpdateDate){
            
            uint256 addedRewardPerToken;
            if(totalEfectiveStake != 0){
                addedRewardPerToken = cBlockNumber.sub(lastUpdateDate).mul(rewardPerBlock).div(totalEfectiveStake);
            }
            accRewardsPerTokenView = accRewardsPerTokenView.add(addedRewardPerToken);
            
        }
        
        //lastUpdateDate = cBlockNumber;
        
        
        if(account != address(0))
        {
            UserInfoPPool memory user = users[poolID][account];
            //UserInfoPPool memory user = users[poolID][account];
            uint256 accRewardPerTokenForUser = accRewardsPerTokenView.sub(user.prevAccRewardsPerToken);
            uint256 userEvectiveTotalStake = user.totalStake.mul(poolsWeight[poolID]);
            uint256 newRewardsForUser =  accRewardPerTokenForUser.mul(userEvectiveTotalStake);
            user.totalRewards = user.totalRewards.add(newRewardsForUser);
            
            user.prevAccRewardsPerToken = accRewardsPerToken;
            
            claimedRewards = user.claimedRewards;
            pendingRewards = user.totalRewards - claimedRewards;
        }
        
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


