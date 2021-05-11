/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

pragma solidity ^0.5.0;



pragma solidity ^0.5.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface ICourtStake{

    function lockedStake(uint256 amount, address beneficiar,  uint256 StartReleasingTime, uint256 batchCount, uint256 batchPeriod) external;

}

interface IMERC20 {
    function mint(address account, uint amount) external;
}




contract Demo_CourtFarming {


    IMERC20 public  courtToken ;

    address public owner;

    enum TransferRewardState {
        Succeeded,
        RewardsStillLocked
    }


    address public courtStakeAddress;

    mapping(address => uint256) _incvRewards;
    uint256 incvStartReleasingTime; 
    uint256 incvBatchCount; 
    uint256 incvBatchPeriod;

    event CourtStakeChanged(address oldAddress, address newAddress);
    event StakeRewards(address indexed user, uint256 amount, uint256 lockTime);
    
    constructor () public {

        owner = msg.sender;

        
    }
    
    function setCourtToken(address courtTokenAddress) public{
        courtToken = IMERC20(courtTokenAddress);
    }

    
    function setCourtStake(address courtStakeAdd) public {
        require(msg.sender == owner, "only contract owner can change");

        address oldAddress = courtStakeAddress;
        courtStakeAddress = courtStakeAdd;

        IERC20 courtTokenERC20 = IERC20(address(courtToken));

        courtTokenERC20.approve(courtStakeAdd, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

        emit CourtStakeChanged(oldAddress, courtStakeAdd);
    }

    

   
    function demo_SetIncRewards(address account, uint256 incRewards) public{
        _incvRewards[account] = incRewards;
    }
    

    function rewards(address account) public view returns (uint256 reward, uint256 incvReward) {
        return (0, _incvRewards[account]);
    }

   
    function updateReward(address) public{
        
    }
    
    
}


contract Demo_HnM_CourtFarming is Demo_CourtFarming{
    function stakeIncvRewards(uint256 amount) public returns (bool) {
        updateReward(msg.sender);
        uint256 incvReward = _incvRewards[msg.sender];


        if (amount > incvReward || courtStakeAddress == address(0)) {
            return false;
        }

        _incvRewards[msg.sender] -= amount;  // no need to use safe math sub, since there is check for amount > reward

        courtToken.mint(address(this), amount);

        ICourtStake courtStake = ICourtStake(courtStakeAddress);
        courtStake.lockedStake(amount,  msg.sender, incvStartReleasingTime, incvBatchCount, incvBatchPeriod);
        emit StakeRewards(msg.sender, amount, incvStartReleasingTime);
    }
}

contract Demo_RnLP_CourtFarming is Demo_CourtFarming{
    function incvRewardClaim() public returns(uint256 amount){
       
        amount = _incvRewards[msg.sender];
        courtToken.mint(msg.sender,amount );
        
        _incvRewards[msg.sender] =0;
    }

}