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

// File: contracts\RewardCenter\IRoomOraclePrice.sol

pragma solidity ^0.5.1;


interface IRoomOraclePrice{
    function getPrice() external view returns(uint256 roomAmount, uint256 usdAmount, uint8 usdDecimals);
    function getExpectedRoomByToken(address tokenA, uint256 tokenAmount) external view returns(uint256);
    function getExpectedTokenByRoom(address tokenA, uint256 roomAmount) external view returns(uint256);
    function buyRoom(address tokenA, uint256 amountTokenA, uint256  minRoom, address to) external;
}

// File: contracts\Helpers\TransferHelper.sol

pragma solidity ^0.5.0;


library TransferHelper {
    function safeApprove(IERC20 token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x095ea7b3, to, value)); 
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(IERC20 token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    
    
}

// File: contracts\RewardCenter\RewardCenter.sol

pragma solidity ^0.5.1;






contract RewardCenter is IRewardCenter, GnGOwnable {
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
        // otherwise the amount of room determined by minimum price allowed
        revertIfPriceLessMin = flag;
    }
    
    function setRewardProgram(address programAddress) public onlyGovOrGur{
        rewardProgramAddress = programAddress;
    }
    
    function setRoomAddress(address roomAddress) public onlyGovOrGur{
        roomToken = IERC20(roomAddress);
    }
    
    function setRoomOracleAddress(address oracleAddress) public onlyGovOrGur{
        roomOraclePrice = IRoomOraclePrice(oracleAddress);
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
    
    
    function sendRoomByGur(address beneficiary, uint256 amount) public onlyGuardian {
        roomToken.safeTransfer(beneficiary,amount);
    }
    
    function getCurrentTime() public view returns(uint256){

        return block.timestamp;
    }
}
