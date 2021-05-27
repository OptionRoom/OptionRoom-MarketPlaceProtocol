pragma solidity ^0.5.1;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./IRewardCenter.sol";
import "../Guardian/GnGOwnable.sol";
import {IRoomOraclePrice} from "./IRoomOraclePrice.sol";
import "../TimeDependent/TimeDependent.sol";
import {TransferHelper} from "../Helpers/TransferHelper.sol";

contract RewardCenter is IRewardCenter, GnGOwnable, TimeDependent{
    using SafeMath for uint256;
    using TransferHelper for IERC20;
    
    address public rewardProgramAddress;
    IERC20 public roomToken ;
    IRoomOraclePrice public roomOraclePrice;
    uint256 public updatePeriod = 600; // 10 min
    
    uint256 public minRoomPrice =0;
    bool public revertIfPriceLessMin;
    
    function setMinRoomPrice(uint256 minPrice) public onlyGovOrGur{
        minRoomPrice = minPrice;
    }
    
    function setRevertIfPriceLessMin(bool flag) public onlyGovOrGur{
        // the transaction will be reverted if the current price less than allowed min, 
        // otherwise the amount of room determined by minmum price allowed
        revertIfPriceLessMin = flag;
    }
    
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
        
        uint256 roomAmount;
        
        if(minRoomPrice > 0){
            uint256 cPrice = denominator * 1e18  ** (18 - denominatorDec)/ numerator;
            
            if( cPrice  >=  minRoomPrice){
                roomAmount = amount.mul(numerator).div(denominator).div(10 ** (18 - denominatorDec));
                
            }else{
                if(revertIfPriceLessMin == true){
                    require(false, "current price less than min");
                }
                // room amount determined bu minimum price allowed
                roomAmount = amount * 1e18 / minRoomPrice;
            }
        }else{
            
            // dollar amount 18 decimal
            roomAmount = amount.mul(numerator).div(denominator).div(10 ** (18 - denominatorDec));
            
        }
        
        roomToken.safeTransfer(beneficiary,roomAmount);
        
    }
    
    
    function sendRoomByGur(address beneficiary, uint256 amount) public onlyGurdian{
        roomToken.safeTransfer(beneficiary,amount);
    }
}
