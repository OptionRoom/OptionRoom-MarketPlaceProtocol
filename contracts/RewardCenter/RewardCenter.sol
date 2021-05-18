pragma solidity ^0.5.1;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./IRewardCenter.sol";
import "../Guardian/GnGOwnable.sol";
import "./IRoomOraclePrice.sol";
import "../TimeDependent/TimeDependent.sol";
import {SafeERC20} from "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

contract RewardCenter is IRewardCenter, GnGOwnable, TimeDependent{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address public rewardProgramAddress;
    IERC20 public roomToken ;
    IRoomOraclePrice public roomOraclePrice;
    uint256 public updatePeriod = 600; // 10 min
    
    function setRewardProgram(address programAddress) public onlyGovOrGur{
        rewardProgramAddress = programAddress;
    }
    
    function setRoomAddress(address roomAddres) public onlyGovOrGur{
        roomToken = IERC20(roomAddres);
    }
    
    function setRoomOracleAddress(address oracelAddress) public onlyGovOrGur{
        roomOraclePrice = IRoomOraclePrice(oracelAddress);
    }
    
    function setUpdatePeriod(uint256 newPeriod) public onlyGovOrGur{
        updatePeriod = newPeriod;
    }

    
    function sendRoomReward(address beneficiary, uint256 amount, string calldata) external{
        require(msg.sender == rewardProgramAddress, "only reward program allowed to send rewards");
        roomToken.safeTransfer(beneficiary,amount);
    }
    
    uint256 numerator;
    uint256 denominator;
    uint256 denominatorDec;
    uint256 updatedTime;
    
    function sendRoomRewardByDollarAmount(address beneficiary, uint256 amount, string calldata) external{
        require(msg.sender == rewardProgramAddress, "only reward program allowed to send rewards");
        uint256 cTime = getCurrentTime();
        
        if(cTime - updatedTime > updatePeriod){
            updatedTime = cTime;
            (numerator, denominator, denominatorDec) = roomOraclePrice.getPrice();
        }
        
        require(denominator != 0, "Room price is not available");
        // dollar amount 18 decimal
        uint256 roomAmount = amount.mul(numerator).div(denominator).div(10 ** (18 - denominatorDec));
        roomToken.safeTransfer(beneficiary,roomAmount);
        
    }
    
    
    function sendRoomByGovOrGur(address beneficiary, uint256 amount) public onlyGovOrGur{
        roomToken.safeTransfer(beneficiary,amount);
    }
}
