pragma solidity ^0.5.1;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./IRewardCenter.sol";
import "../Guardian/GnGOwnable.sol";
import "./IRoomOraclePrice.sol";

contract RewardCenter is IRewardCenter, GnGOwnable{
    using SafeMath for uint256;
    
    address public rewardProgramAddress;
    IERC20 roomToken ;
    IRoomOraclePrice roomOraclePrice;
    
    function setRewardProgram(address programAddress) public onlyGovOrGur{
        rewardProgramAddress = programAddress;
    }
    
    function setRoomAddress(address roomAddres) public onlyGovOrGur{
        roomToken = IERC20(roomAddres);
    }
    
    function setRoomOracle(address oracelAddress) public onlyGovOrGur{
        roomOraclePrice = IRoomOraclePrice(oracelAddress);
    }
    

    
    function sendRoomReward(address beneficiary, uint256 amount, string calldata) external{
        require(msg.sender == rewardProgramAddress, "only reward program allowed to send rewards");
        roomToken.transfer(beneficiary,amount);
    }
    
    
    function sendRoomRewardByDollarAmount(address beneficiary, uint256 amount, string calldata) external{
        require(msg.sender == rewardProgramAddress, "only reward program allowed to send rewards");
        (uint256 numerator, uint256 denominator, uint256 denominatorDec) = roomOraclePrice.getPrice();
        
        require(denominator != 0, "Room price is not available");
        // dollar amount 18 decimal
        uint256 roomAmount = amount.mul(numerator).div(denominator).div(10 ** (18 - denominatorDec));
        roomToken.transfer(beneficiary,roomAmount);
        
    }
    
    
    function sendRoomByGovOrGur(address beneficiary, uint256 amount) public onlyGovOrGur{
        roomToken.transfer(beneficiary,amount);
    }
}
