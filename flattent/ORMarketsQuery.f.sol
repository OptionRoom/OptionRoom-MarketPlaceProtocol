// File: openzeppelin-solidity\contracts\math\SafeMath.sol

pragma solidity ^0.5.16;

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

// File: contracts\OR\ORMarketLib.sol

pragma solidity ^0.5.16;

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

pragma solidity ^0.5.16;


interface IORMarketController {

    function payoutsAction(address marketAddress) external;
    
    function getMarketState(address marketAddress) external view returns (ORMarketLib.MarketState);
}

// File: contracts\Governance\IORGovernor.sol

pragma solidity ^0.5.16;

interface IORGovernor{
    function getAccountInfo(address account) external view returns(bool governorFlag, bool suspendedFlag, uint256 power) ;
    function getSuspendReason(address account) external view returns(string memory reason);
    function userHasWrongVoting(address account, address[] calldata markets) external  returns (bool);
}

// File: openzeppelin-solidity\contracts\token\ERC20\IERC20.sol

pragma solidity ^0.5.16;

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

// File: openzeppelin-solidity\contracts\introspection\IERC165.sol

pragma solidity ^0.5.16;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: gnosis.pm\conditional-tokens-contracts\contracts\ERC1155\IERC1155.sol

pragma solidity ^0.5.16;


/**
    @title ERC-1155 Multi Token Standard basic interface
    @dev See https://eips.ethereum.org/EIPS/eip-1155
 */
contract IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address owner, uint256 id) public view returns (uint256);

    function balanceOfBatch(address[] memory owners, uint256[] memory ids) public view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external;
}

// File: gnosis.pm\conditional-tokens-contracts\contracts\ERC1155\IERC1155TokenReceiver.sol

pragma solidity ^0.5.16;


/**
    @title ERC-1155 Multi Token Receiver Interface
    @dev See https://eips.ethereum.org/EIPS/eip-1155
*/
contract IERC1155TokenReceiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// File: openzeppelin-solidity\contracts\utils\Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


// File: openzeppelin-solidity\contracts\introspection\ERC165.sol

pragma solidity ^0.5.16;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: gnosis.pm\conditional-tokens-contracts\contracts\ERC1155\ERC1155.sol

pragma solidity ^0.5.16;






/**
 * @title Standard ERC1155 token
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 */
contract ERC1155 is ERC165, IERC1155
{
    using SafeMath for uint256;
    using Address for address;
    
    // totalBalances
    mapping(uint256 => uint256) public totalBalances;

    // Mapping from token ID to owner balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from owner to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    constructor()
        public
    {
        _registerInterface(
            ERC1155(0).safeTransferFrom.selector ^
            ERC1155(0).safeBatchTransferFrom.selector ^
            ERC1155(0).balanceOf.selector ^
            ERC1155(0).balanceOfBatch.selector ^
            ERC1155(0).setApprovalForAll.selector ^
            ERC1155(0).isApprovedForAll.selector
        );
    }

    /**
        @dev Get the specified address' balance for token with specified ID.
        @param owner The address of the token holder
        @param id ID of the token
        @return The owner's balance of the token type requested
     */
    function balanceOf(address owner, uint256 id) public view returns (uint256) {
        require(owner != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][owner];
    }

    /**
        @dev Get the balance of multiple account/token pairs
        @param owners The addresses of the token holders
        @param ids IDs of the tokens
        @return Balances for each owner and token id pair
     */
    function balanceOfBatch(
        address[] memory owners,
        uint256[] memory ids
    )
        public
        view
        returns (uint256[] memory)
    {
        require(owners.length == ids.length, "ERC1155: owners and IDs must have same lengths");

        uint256[] memory batchBalances = new uint256[](owners.length);

        for (uint256 i = 0; i < owners.length; ++i) {
            require(owners[i] != address(0), "ERC1155: some address in batch balance query is zero");
            batchBalances[i] = _balances[ids[i]][owners[i]];
        }

        return batchBalances;
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf
     * @param operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param owner     The owner of the Tokens
        @param operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
        @dev Transfers `value` amount of an `id` from the `from` address to the `to` address specified.
        Caller must be approved to manage the tokens being transferred out of the `from` account.
        If `to` is a smart contract, will call `onERC1155Received` on `to` and act appropriately.
        @param from Source address
        @param to Target address
        @param id ID of the token type
        @param value Transfer amount
        @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
    {
        require(to != address(0), "ERC1155: target address must be non-zero");
        require(
            from == msg.sender || _operatorApprovals[from][msg.sender] == true,
            "ERC1155: need operator approval for 3rd party transfers."
        );

        _balances[id][from] = _balances[id][from].sub(value);
        _balances[id][to] = value.add(_balances[id][to]);

        emit TransferSingle(msg.sender, from, to, id, value);

        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, value, data);
    }

    /**
        @dev Transfers `values` amount(s) of `ids` from the `from` address to the
        `to` address specified. Caller must be approved to manage the tokens being
        transferred out of the `from` account. If `to` is a smart contract, will
        call `onERC1155BatchReceived` on `to` and act appropriately.
        @param from Source address
        @param to Target address
        @param ids IDs of each token type
        @param values Transfer amounts per token type
        @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
    */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
    {
        require(ids.length == values.length, "ERC1155: IDs and values must have same lengths");
        require(to != address(0), "ERC1155: target address must be non-zero");
        require(
            from == msg.sender || _operatorApprovals[from][msg.sender] == true,
            "ERC1155: need operator approval for 3rd party transfers."
        );

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];

            _balances[id][from] = _balances[id][from].sub(value);
            _balances[id][to] = value.add(_balances[id][to]);
        }

        emit TransferBatch(msg.sender, from, to, ids, values);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, values, data);
    }

    /**
     * @dev Internal function to mint an amount of a token with the given ID
     * @param to The address that will own the minted token
     * @param id ID of the token to be minted
     * @param value Amount of the token to be minted
     * @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
     */
    function _mint(address to, uint256 id, uint256 value, bytes memory data) internal {
        require(to != address(0), "ERC1155: mint to the zero address");

        _balances[id][to] = value.add(_balances[id][to]);
        emit TransferSingle(msg.sender, address(0), to, id, value);
        totalBalances[id] = value.add(totalBalances[id]);
        _doSafeTransferAcceptanceCheck(msg.sender, address(0), to, id, value, data);
    }
    
    /**
     * @dev Internal function to batch mint amounts of tokens with the given IDs
     * @param to The address that will own the minted token
     * @param ids IDs of the tokens to be minted
     * @param values Amounts of the tokens to be minted
     * @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
     */
    function _batchMint(address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal {
        require(to != address(0), "ERC1155: batch mint to the zero address");
        require(ids.length == values.length, "ERC1155: IDs and values must have same lengths");

        for(uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = values[i].add(_balances[ids[i]][to]);
            totalBalances[ids[i]] = values[i].add(totalBalances[ids[i]]);
        }

        emit TransferBatch(msg.sender, address(0), to, ids, values);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, address(0), to, ids, values, data);
    }

    /**
     * @dev Internal function to burn an amount of a token with the given ID
     * @param owner Account which owns the token to be burnt
     * @param id ID of the token to be burnt
     * @param value Amount of the token to be burnt
     */
    function _burn(address owner, uint256 id, uint256 value) internal {
        _balances[id][owner] = _balances[id][owner].sub(value);
        totalBalances[id] = totalBalances[id].sub(value);
        emit TransferSingle(msg.sender, owner, address(0), id, value);
    }

    /**
     * @dev Internal function to batch burn an amounts of tokens with the given IDs
     * @param owner Account which owns the token to be burnt
     * @param ids IDs of the tokens to be burnt
     * @param values Amounts of the tokens to be burnt
     */
    function _batchBurn(address owner, uint256[] memory ids, uint256[] memory values) internal {
        require(ids.length == values.length, "ERC1155: IDs and values must have same lengths");

        for(uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][owner] = _balances[ids[i]][owner].sub(values[i]);
            totalBalances[ids[i]] = totalBalances[ids[i]].sub(values[i]);
        }

        emit TransferBatch(msg.sender, owner, address(0), ids, values);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    )
        internal
    {
        /*
        if(to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155Received(operator, from, id, value, data) ==
                    IERC1155TokenReceiver(to).onERC1155Received.selector,
                "ERC1155: got unknown value from onERC1155Received"
            );
        }
        */
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    )
        internal
    {
        /*if(to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155BatchReceived(operator, from, ids, values, data) == IERC1155TokenReceiver(to).onERC1155BatchReceived.selector,
                "ERC1155: got unknown value from onERC1155BatchReceived"
            );
        }*/
    }
}

// File: gnosis.pm\conditional-tokens-contracts\contracts\CTHelpers.sol

pragma solidity ^0.5.16;


library CTHelpers {
    /// @dev Constructs a condition ID from an oracle, a question ID, and the outcome slot count for the question.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function getConditionId(address oracle, bytes32 questionId, uint outcomeSlotCount) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount));
    }

    uint constant P = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint constant B = 3;

    function sqrt(uint x) private pure returns (uint y) {
        uint p = P;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // add chain generated via https://crypto.stackexchange.com/q/27179/71252
            // and transformed to the following program:

            // x=1; y=x+x; z=y+y; z=z+z; y=y+z; x=x+y; y=y+x; z=y+y; t=z+z; t=z+t; t=t+t;
            // t=t+t; z=z+t; x=x+z; z=x+x; z=z+z; y=y+z; z=y+y; z=z+z; z=z+z; z=y+z; x=x+z;
            // z=x+x; z=z+z; z=z+z; z=x+z; y=y+z; x=x+y; z=x+x; z=z+z; y=y+z; z=y+y; t=z+z;
            // t=t+t; t=t+t; z=z+t; x=x+z; y=y+x; z=y+y; z=z+z; z=z+z; x=x+z; z=x+x; z=z+z;
            // z=x+z; z=z+z; z=z+z; z=x+z; y=y+z; z=y+y; t=z+z; t=t+t; t=z+t; t=y+t; t=t+t;
            // t=t+t; t=t+t; t=t+t; z=z+t; x=x+z; z=x+x; z=x+z; y=y+z; z=y+y; z=y+z; z=z+z;
            // t=z+z; t=z+t; w=t+t; w=w+w; w=w+w; w=w+w; w=w+w; t=t+w; z=z+t; x=x+z; y=y+x;
            // z=y+y; x=x+z; y=y+x; x=x+y; y=y+x; x=x+y; z=x+x; z=x+z; z=z+z; y=y+z; z=y+y;
            // z=z+z; x=x+z; y=y+x; z=y+y; z=y+z; x=x+z; y=y+x; x=x+y; y=y+x; z=y+y; z=z+z;
            // z=y+z; x=x+z; z=x+x; z=x+z; y=y+z; x=x+y; y=y+x; x=x+y; y=y+x; z=y+y; z=y+z;
            // z=z+z; x=x+z; y=y+x; z=y+y; z=y+z; z=z+z; x=x+z; z=x+x; t=z+z; t=t+t; t=z+t;
            // t=x+t; t=t+t; t=t+t; t=t+t; t=t+t; z=z+t; y=y+z; x=x+y; y=y+x; x=x+y; z=x+x;
            // z=x+z; z=z+z; z=z+z; z=z+z; z=x+z; y=y+z; z=y+y; z=y+z; z=z+z; x=x+z; z=x+x;
            // z=x+z; y=y+z; x=x+y; z=x+x; z=z+z; y=y+z; x=x+y; z=x+x; y=y+z; x=x+y; y=y+x;
            // z=y+y; z=y+z; x=x+z; y=y+x; z=y+y; z=y+z; z=z+z; z=z+z; x=x+z; z=x+x; z=z+z;
            // z=z+z; z=x+z; y=y+z; x=x+y; z=x+x; t=x+z; t=t+t; t=t+t; z=z+t; y=y+z; z=y+y;
            // x=x+z; y=y+x; x=x+y; y=y+x; x=x+y; y=y+x; z=y+y; t=y+z; z=y+t; z=z+z; z=z+z;
            // z=t+z; x=x+z; y=y+x; x=x+y; y=y+x; x=x+y; z=x+x; z=x+z; y=y+z; x=x+y; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x; x=x+x;
            // x=x+x; x=x+x; x=x+x; x=x+x; res=y+x
            // res == (P + 1) // 4

            y := mulmod(x, x, p)
            {
                let z := mulmod(y, y, p)
                z := mulmod(z, z, p)
                y := mulmod(y, z, p)
                x := mulmod(x, y, p)
                y := mulmod(y, x, p)
                z := mulmod(y, y, p)
                {
                    let t := mulmod(z, z, p)
                    t := mulmod(z, t, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    z := mulmod(z, t, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    z := mulmod(z, z, p)
                    y := mulmod(y, z, p)
                    z := mulmod(y, y, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(y, z, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(x, z, p)
                    y := mulmod(y, z, p)
                    x := mulmod(x, y, p)
                    z := mulmod(x, x, p)
                    z := mulmod(z, z, p)
                    y := mulmod(y, z, p)
                    z := mulmod(y, y, p)
                    t := mulmod(z, z, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    z := mulmod(z, t, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    z := mulmod(z, z, p)
                    z := mulmod(x, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(x, z, p)
                    y := mulmod(y, z, p)
                    z := mulmod(y, y, p)
                    t := mulmod(z, z, p)
                    t := mulmod(t, t, p)
                    t := mulmod(z, t, p)
                    t := mulmod(y, t, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    z := mulmod(z, t, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    z := mulmod(x, z, p)
                    y := mulmod(y, z, p)
                    z := mulmod(y, y, p)
                    z := mulmod(y, z, p)
                    z := mulmod(z, z, p)
                    t := mulmod(z, z, p)
                    t := mulmod(z, t, p)
                    {
                        let w := mulmod(t, t, p)
                        w := mulmod(w, w, p)
                        w := mulmod(w, w, p)
                        w := mulmod(w, w, p)
                        w := mulmod(w, w, p)
                        t := mulmod(t, w, p)
                    }
                    z := mulmod(z, t, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    x := mulmod(x, y, p)
                    z := mulmod(x, x, p)
                    z := mulmod(x, z, p)
                    z := mulmod(z, z, p)
                    y := mulmod(y, z, p)
                    z := mulmod(y, y, p)
                    z := mulmod(z, z, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    z := mulmod(y, z, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    z := mulmod(z, z, p)
                    z := mulmod(y, z, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    z := mulmod(x, z, p)
                    y := mulmod(y, z, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    z := mulmod(y, z, p)
                    z := mulmod(z, z, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    z := mulmod(y, z, p)
                    z := mulmod(z, z, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    t := mulmod(z, z, p)
                    t := mulmod(t, t, p)
                    t := mulmod(z, t, p)
                    t := mulmod(x, t, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    z := mulmod(z, t, p)
                    y := mulmod(y, z, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    x := mulmod(x, y, p)
                    z := mulmod(x, x, p)
                    z := mulmod(x, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(x, z, p)
                    y := mulmod(y, z, p)
                    z := mulmod(y, y, p)
                    z := mulmod(y, z, p)
                    z := mulmod(z, z, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    z := mulmod(x, z, p)
                    y := mulmod(y, z, p)
                    x := mulmod(x, y, p)
                    z := mulmod(x, x, p)
                    z := mulmod(z, z, p)
                    y := mulmod(y, z, p)
                    x := mulmod(x, y, p)
                    z := mulmod(x, x, p)
                    y := mulmod(y, z, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    z := mulmod(y, z, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    z := mulmod(y, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    x := mulmod(x, z, p)
                    z := mulmod(x, x, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(x, z, p)
                    y := mulmod(y, z, p)
                    x := mulmod(x, y, p)
                    z := mulmod(x, x, p)
                    t := mulmod(x, z, p)
                    t := mulmod(t, t, p)
                    t := mulmod(t, t, p)
                    z := mulmod(z, t, p)
                    y := mulmod(y, z, p)
                    z := mulmod(y, y, p)
                    x := mulmod(x, z, p)
                    y := mulmod(y, x, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    x := mulmod(x, y, p)
                    y := mulmod(y, x, p)
                    z := mulmod(y, y, p)
                    t := mulmod(y, z, p)
                    z := mulmod(y, t, p)
                    z := mulmod(z, z, p)
                    z := mulmod(z, z, p)
                    z := mulmod(t, z, p)
                }
                x := mulmod(x, z, p)
                y := mulmod(y, x, p)
                x := mulmod(x, y, p)
                y := mulmod(y, x, p)
                x := mulmod(x, y, p)
                z := mulmod(x, x, p)
                z := mulmod(x, z, p)
                y := mulmod(y, z, p)
            }
            x := mulmod(x, y, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            x := mulmod(x, x, p)
            y := mulmod(y, x, p)
        }
    }

    /// @dev Constructs an outcome collection ID from a parent collection and an outcome collection.
    /// @param parentCollectionId Collection ID of the parent outcome collection, or bytes32(0) if there's no parent.
    /// @param conditionId Condition ID of the outcome collection to combine with the parent outcome collection.
    /// @param indexSet Index set of the outcome collection to combine with the parent outcome collection.
    function getCollectionId(bytes32 parentCollectionId, bytes32 conditionId, uint indexSet) internal view returns (bytes32) {
        uint x1 = uint(keccak256(abi.encodePacked(conditionId, indexSet)));
        bool odd = x1 >> 255 != 0;
        uint y1;
        uint yy;
        do {
            x1 = addmod(x1, 1, P);
            yy = addmod(mulmod(x1, mulmod(x1, x1, P), P), B, P);
            y1 = sqrt(yy);
        } while(mulmod(y1, y1, P) != yy);
        if(odd && y1 % 2 == 0 || !odd && y1 % 2 == 1)
            y1 = P - y1;

        uint x2 = uint(parentCollectionId);
        if(x2 != 0) {
            odd = x2 >> 254 != 0;
            x2 = (x2 << 2) >> 2;
            yy = addmod(mulmod(x2, mulmod(x2, x2, P), P), B, P);
            uint y2 = sqrt(yy);
            if(odd && y2 % 2 == 0 || !odd && y2 % 2 == 1)
                y2 = P - y2;
            require(mulmod(y2, y2, P) == yy, "invalid parent collection ID");

            (bool success, bytes memory ret) = address(6).staticcall(abi.encode(x1, y1, x2, y2));
            require(success, "ecadd failed");
            (x1, y1) = abi.decode(ret, (uint, uint));
        }

        if(y1 % 2 == 1)
            x1 ^= 1 << 254;

        return bytes32(x1);
    }

    /// @dev Constructs a position ID from a collateral token and an outcome collection. These IDs are used as the ERC-1155 ID for this contract.
    /// @param collateralToken Collateral token which backs the position.
    /// @param collectionId ID of the outcome collection associated with this position.
    function getPositionId(IERC20 collateralToken, bytes32 collectionId) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(collateralToken, collectionId)));
    }
}

// File: gnosis.pm\conditional-tokens-contracts\contracts\ConditionalTokens.sol

pragma solidity ^0.5.16;




contract ConditionalTokens is ERC1155 {

    /// @dev Emitted upon the successful preparation of a condition.
    /// @param conditionId The condition's ID. This ID may be derived from the other three parameters via ``keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount))``.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    event ConditionPreparation(
        bytes32 indexed conditionId,
        address indexed oracle,
        bytes32 indexed questionId,
        uint outcomeSlotCount
    );

    event ConditionResolution(
        bytes32 indexed conditionId,
        address indexed oracle,
        bytes32 indexed questionId,
        uint outcomeSlotCount,
        uint[] payoutNumerators
    );

    /// @dev Emitted when a position is successfully split.
    event PositionSplit(
        address indexed stakeholder,
        IERC20 collateralToken,
        bytes32 indexed parentCollectionId,
        bytes32 indexed conditionId,
        uint[] partition,
        uint amount
    );
    /// @dev Emitted when positions are successfully merged.
    event PositionsMerge(
        address indexed stakeholder,
        IERC20 collateralToken,
        bytes32 indexed parentCollectionId,
        bytes32 indexed conditionId,
        uint[] partition,
        uint amount
    );
    event PayoutRedemption(
        address indexed redeemer,
        IERC20 indexed collateralToken,
        bytes32 indexed parentCollectionId,
        bytes32 conditionId,
        uint[] indexSets,
        uint payout
    );


    /// Mapping key is an condition ID. Value represents numerators of the payout vector associated with the condition. This array is initialized with a length equal to the outcome slot count. E.g. Condition with 3 outcomes [A, B, C] and two of those correct [0.5, 0.5, 0]. In Ethereum there are no decimal values, so here, 0.5 is represented by fractions like 1/2 == 0.5. That's why we need numerator and denominator values. Payout numerators are also used as a check of initialization. If the numerators array is empty (has length zero), the condition was not created/prepared. See getOutcomeSlotCount.
    mapping(bytes32 => uint[]) public payoutNumerators;
    /// Denominator is also used for checking if the condition has been resolved. If the denominator is non-zero, then the condition has been resolved.
    mapping(bytes32 => uint) public payoutDenominator;

    /// @dev This function prepares a condition by initializing a payout vector associated with the condition.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function prepareCondition(address oracle, bytes32 questionId, uint outcomeSlotCount) external {
        // Limit of 256 because we use a partition array that is a number of 256 bits.
        require(outcomeSlotCount <= 256, "too many outcome slots");
        require(outcomeSlotCount > 1, "there should be more than one outcome slot");
        bytes32 conditionId = CTHelpers.getConditionId(oracle, questionId, outcomeSlotCount);
        require(payoutNumerators[conditionId].length == 0, "condition already prepared");
        payoutNumerators[conditionId] = new uint[](outcomeSlotCount);
        emit ConditionPreparation(conditionId, oracle, questionId, outcomeSlotCount);
    }

    /// @dev Called by the oracle for reporting results of conditions. Will set the payout vector for the condition with the ID ``keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount))``, where oracle is the message sender, questionId is one of the parameters of this function, and outcomeSlotCount is the length of the payouts parameter, which contains the payoutNumerators for each outcome slot of the condition.
    /// @param questionId The question ID the oracle is answering for
    /// @param payouts The oracle's answer
    function reportPayouts(bytes32 questionId, uint[] calldata payouts) external {
        uint outcomeSlotCount = payouts.length;
        require(outcomeSlotCount > 1, "there should be more than one outcome slot");
        // IMPORTANT, the oracle is enforced to be the sender because it's part of the hash.
        bytes32 conditionId = CTHelpers.getConditionId(msg.sender, questionId, outcomeSlotCount);
        require(payoutNumerators[conditionId].length == outcomeSlotCount, "condition not prepared or found");
        require(payoutDenominator[conditionId] == 0, "payout denominator already set");

        uint den = 0;
        for (uint i = 0; i < outcomeSlotCount; i++) {
            uint num = payouts[i];
            den = den.add(num);

            require(payoutNumerators[conditionId][i] == 0, "payout numerator already set");
            payoutNumerators[conditionId][i] = num;
        }
        require(den > 0, "payout is all zeroes");
        payoutDenominator[conditionId] = den;
        emit ConditionResolution(conditionId, msg.sender, questionId, outcomeSlotCount, payoutNumerators[conditionId]);
    }

    /// @dev This function splits a position. If splitting from the collateral, this contract will attempt to transfer `amount` collateral from the message sender to itself. Otherwise, this contract will burn `amount` stake held by the message sender in the position being split worth of EIP 1155 tokens. Regardless, if successful, `amount` stake will be minted in the split target positions. If any of the transfers, mints, or burns fail, the transaction will revert. The transaction will also revert if the given partition is trivial, invalid, or refers to more slots than the condition is prepared with.
    /// @param collateralToken The address of the positions' backing collateral token.
    /// @param parentCollectionId The ID of the outcome collections common to the position being split and the split target positions. May be null, in which only the collateral is shared.
    /// @param conditionId The ID of the condition to split on.
    /// @param partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
    /// @param amount The amount of collateral or stake to split.
    function splitPosition(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint[] calldata partition,
        uint amount
    ) external {
        require(partition.length > 1, "got empty or singleton partition");
        uint outcomeSlotCount = payoutNumerators[conditionId].length;
        require(outcomeSlotCount > 0, "condition not prepared yet");

        // For a condition with 4 outcomes fullIndexSet's 0b1111; for 5 it's 0b11111...
        uint fullIndexSet = (1 << outcomeSlotCount) - 1;
        // freeIndexSet starts as the full collection
        uint freeIndexSet = fullIndexSet;
        // This loop checks that all condition sets are disjoint (the same outcome is not part of more than 1 set)
        uint[] memory positionIds = new uint[](partition.length);
        uint[] memory amounts = new uint[](partition.length);
        for (uint i = 0; i < partition.length; i++) {
            uint indexSet = partition[i];
            require(indexSet > 0 && indexSet < fullIndexSet, "got invalid index set");
            require((indexSet & freeIndexSet) == indexSet, "partition not disjoint");
            freeIndexSet ^= indexSet;
            positionIds[i] = CTHelpers.getPositionId(collateralToken, CTHelpers.getCollectionId(parentCollectionId, conditionId, indexSet));
            amounts[i] = amount;
        }

        if (freeIndexSet == 0) {
            // Partitioning the full set of outcomes for the condition in this branch
            if (parentCollectionId == bytes32(0)) {
                require(collateralToken.transferFrom(msg.sender, address(this), amount), "could not receive collateral tokens");
            } else {
                _burn(
                    msg.sender,
                    CTHelpers.getPositionId(collateralToken, parentCollectionId),
                    amount
                );
            }
        } else {
            // Partitioning a subset of outcomes for the condition in this branch.
            // For example, for a condition with three outcomes A, B, and C, this branch
            // allows the splitting of a position $:(A|C) to positions $:(A) and $:(C).
            _burn(
                msg.sender,
                CTHelpers.getPositionId(collateralToken,
                    CTHelpers.getCollectionId(parentCollectionId, conditionId, fullIndexSet ^ freeIndexSet)),
                amount
            );
        }

        _batchMint(
            msg.sender,
            // position ID is the ERC 1155 token ID
            positionIds,
            amounts,
            ""
        );
        emit PositionSplit(msg.sender, collateralToken, parentCollectionId, conditionId, partition, amount);
    }

    function mergePositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint[] calldata partition,
        uint amount
    ) external {
        require(partition.length > 1, "got empty or singleton partition");
        uint outcomeSlotCount = payoutNumerators[conditionId].length;
        require(outcomeSlotCount > 0, "condition not prepared yet");

        uint fullIndexSet = (1 << outcomeSlotCount) - 1;
        uint freeIndexSet = fullIndexSet;
        uint[] memory positionIds = new uint[](partition.length);
        uint[] memory amounts = new uint[](partition.length);
        for (uint i = 0; i < partition.length; i++) {
            uint indexSet = partition[i];
            require(indexSet > 0 && indexSet < fullIndexSet, "got invalid index set");
            require((indexSet & freeIndexSet) == indexSet, "partition not disjoint");
            freeIndexSet ^= indexSet;
            positionIds[i] = CTHelpers.getPositionId(collateralToken, CTHelpers.getCollectionId(parentCollectionId, conditionId, indexSet));
            amounts[i] = amount;
        }
        _batchBurn(
            msg.sender,
            positionIds,
            amounts
        );

        if (freeIndexSet == 0) {
            if (parentCollectionId == bytes32(0)) {
                require(collateralToken.transfer(msg.sender, amount), "could not send collateral tokens");
            } else {
                _mint(
                    msg.sender,
                    CTHelpers.getPositionId(collateralToken, parentCollectionId),
                    amount,
                    ""
                );
            }
        } else {
            _mint(
                msg.sender,
                CTHelpers.getPositionId(collateralToken,
                    CTHelpers.getCollectionId(parentCollectionId, conditionId, fullIndexSet ^ freeIndexSet)),
                amount,
                ""
            );
        }

        emit PositionsMerge(msg.sender, collateralToken, parentCollectionId, conditionId, partition, amount);
    }

    function redeemPositions(IERC20 collateralToken, bytes32 parentCollectionId, bytes32 conditionId, uint[] memory indexSets) public {
        uint den = payoutDenominator[conditionId];
        require(den > 0, "result for condition not received yet");
        uint outcomeSlotCount = payoutNumerators[conditionId].length;
        require(outcomeSlotCount > 0, "condition not prepared yet");

        uint totalPayout = 0;

        uint fullIndexSet = (1 << outcomeSlotCount) - 1;
        for (uint i = 0; i < indexSets.length; i++) {
            uint indexSet = indexSets[i];
            require(indexSet > 0 && indexSet < fullIndexSet, "got invalid index set");
            uint positionId = CTHelpers.getPositionId(collateralToken,
                CTHelpers.getCollectionId(parentCollectionId, conditionId, indexSet));

            uint payoutNumerator = 0;
            for (uint j = 0; j < outcomeSlotCount; j++) {
                if (indexSet & (1 << j) != 0) {
                    payoutNumerator = payoutNumerator.add(payoutNumerators[conditionId][j]);
                }
            }

            uint payoutStake = balanceOf(msg.sender, positionId);
            if (payoutStake > 0) {
                totalPayout = totalPayout.add(payoutStake.mul(payoutNumerator).div(den));
                _burn(msg.sender, positionId, payoutStake);
            }
        }

        if (totalPayout > 0) {
            if (parentCollectionId == bytes32(0)) {
                require(collateralToken.transfer(msg.sender, totalPayout), "could not transfer payout to message sender");
            } else {
                _mint(msg.sender, CTHelpers.getPositionId(collateralToken, parentCollectionId), totalPayout, "");
            }
        }
        emit PayoutRedemption(msg.sender, collateralToken, parentCollectionId, conditionId, indexSets, totalPayout);
    }

    /// @dev Gets the outcome slot count of a condition.
    /// @param conditionId ID of the condition.
    /// @return Number of outcome slots associated with a condition, or zero if condition has not been prepared yet.
    function getOutcomeSlotCount(bytes32 conditionId) external view returns (uint) {
        return payoutNumerators[conditionId].length;
    }

    /// @dev Constructs a condition ID from an oracle, a question ID, and the outcome slot count for the question.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function getConditionId(address oracle, bytes32 questionId, uint outcomeSlotCount) external pure returns (bytes32) {
        return CTHelpers.getConditionId(oracle, questionId, outcomeSlotCount);
    }

    /// @dev Constructs an outcome collection ID from a parent collection and an outcome collection.
    /// @param parentCollectionId Collection ID of the parent outcome collection, or bytes32(0) if there's no parent.
    /// @param conditionId Condition ID of the outcome collection to combine with the parent outcome collection.
    /// @param indexSet Index set of the outcome collection to combine with the parent outcome collection.
    function getCollectionId(bytes32 parentCollectionId, bytes32 conditionId, uint indexSet) external view returns (bytes32) {
        return CTHelpers.getCollectionId(parentCollectionId, conditionId, indexSet);
    }

    /// @dev Constructs a position ID from a collateral token and an outcome collection. These IDs are used as the ERC-1155 ID for this contract.
    /// @param collateralToken Collateral token which backs the position.
    /// @param collectionId ID of the outcome collection associated with this position.
    function getPositionId(IERC20 collateralToken, bytes32 collectionId) external pure returns (uint) {
        return CTHelpers.getPositionId(collateralToken, collectionId);
    }
}

// File: gnosis.pm\conditional-tokens-contracts\contracts\ERC1155\ERC1155TokenReceiver.sol

pragma solidity ^0.5.16;



contract ERC1155TokenReceiver is ERC165, IERC1155TokenReceiver {
    constructor() public {
        _registerInterface(
            ERC1155TokenReceiver(0).onERC1155Received.selector ^
            ERC1155TokenReceiver(0).onERC1155BatchReceived.selector
        );
    }
}

// File: node_modules\openzeppelin-solidity\contracts\GSN\Context.sol

pragma solidity ^0.5.16;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity\contracts\token\ERC20\ERC20.sol

pragma solidity ^0.5.16;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: contracts\Helpers\TransferHelper.sol

pragma solidity ^0.5.16;


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

// File: contracts\RewardCenter\IRoomOraclePrice.sol

pragma solidity ^0.5.16;


interface IRoomOraclePrice{
    function getPrice() external view returns(uint256 roomAmount, uint256 usdAmount, uint8 usdDecimals);
    function getExpectedRoomByToken(address tokenA, uint256 tokenAmount) external view returns(uint256);
    function getExpectedTokenByRoom(address tokenA, uint256 roomAmount) external view returns(uint256);
    function buyRoom(address tokenA, uint256 amountTokenA, uint256  minRoom, address to) external;
}

// File: contracts\OR\FixedProductMarketMakerOR.sol

pragma solidity ^0.5.16;









library CeilDiv {
    // calculates ceil(x/y)
    function ceildiv(uint x, uint y) internal pure returns (uint) {
        if (x > 0) return ((x - 1) / y) + 1;
        return x / y;
    }
}


contract FixedProductMarketMaker is ERC1155TokenReceiver {
    using TransferHelper for IERC20;
    
    event FPMMFundingAdded(
        address indexed funder,
        uint[] amountsAdded,
        uint sharesMinted
    );
    event FPMMFundingRemoved(
        address indexed funder,
        uint[] amountsRemoved,
        uint collateralRemovedFromFeePool,
        uint sharesBurnt
    );
    /*event FPMMBuy(
        address indexed buyer,
        uint investmentAmount,
        uint feeAmount,
        uint indexed outcomeIndex,
        uint outcomeTokensBought
    );
    event FPMMSell(
        address indexed seller,
        uint returnAmount,
        uint feeAmount,
        uint indexed outcomeIndex,
        uint outcomeTokensSold
    );*/

    using SafeMath for uint;
    using CeilDiv for uint;
    
    address public proposer;
    
    uint constant ONE = 10 ** 18;
    address roomOracle;
    ConditionalTokens public conditionalTokens;
    IERC20 public collateralToken;
    bytes32[] public conditionIds;
    uint public totalFee;
    uint public lpFee;
    uint public proposerFee;
    uint internal feePoolWeight;
    
    uint public totalProposerFee;
    uint public withdrawnProposerFee;
    
    uint[] outcomeSlotCounts;
    bytes32[][] collectionIds;
    uint[] positionIds;
    mapping(address => uint256) withdrawnFees;
    uint internal totalWithdrawnFees;

    bool initiated;

    function init(
        ConditionalTokens _conditionalTokens,
        IERC20 _collateralToken,
        bytes32[] memory _conditionIds,
        uint _lpfee,
        uint _propserFee,
        address _proposer,
        address _roomOracle
    ) public {
        require(initiated == false, "Market Already initiated");
		initiated = true;

        conditionalTokens = _conditionalTokens;
        collateralToken = _collateralToken;
        conditionIds = _conditionIds;
        lpFee = _lpfee;
        proposerFee = _propserFee;
        proposer = _proposer;
        totalFee = lpFee + proposerFee;
        roomOracle =_roomOracle;
        
        uint atomicOutcomeSlotCount = 1;
        outcomeSlotCounts = new uint[](conditionIds.length);
        for (uint i = 0; i < conditionIds.length; i++) {
            uint outcomeSlotCount = conditionalTokens.getOutcomeSlotCount(conditionIds[i]);
            atomicOutcomeSlotCount *= outcomeSlotCount;
            outcomeSlotCounts[i] = outcomeSlotCount;
        }
        require(atomicOutcomeSlotCount > 1, "conditions must be valid");

        collectionIds = new bytes32[][](conditionIds.length);
        _recordCollectionIDsForAllConditions(conditionIds.length, bytes32(0));
        require(positionIds.length == atomicOutcomeSlotCount, "position IDs construction failed!?");
    }

    function _recordCollectionIDsForAllConditions(uint conditionsLeft, bytes32 parentCollectionId) private {
        if (conditionsLeft == 0) {
            positionIds.push(CTHelpers.getPositionId(collateralToken, parentCollectionId));
            return;
        }

        conditionsLeft--;

        uint outcomeSlotCount = outcomeSlotCounts[conditionsLeft];

        collectionIds[conditionsLeft].push(parentCollectionId);
        for (uint i = 0; i < outcomeSlotCount; i++) {
            _recordCollectionIDsForAllConditions(
                conditionsLeft,
                CTHelpers.getCollectionId(
                    parentCollectionId,
                    conditionIds[conditionsLeft],
                    1 << i
                )
            );
        }
    }


    function getPoolBalances() internal view returns (uint[] memory) {
        return getBalances(address(this));
    }

    function getBalances(address account) public view returns (uint[] memory){
        address[] memory thises = new address[](positionIds.length);
        for (uint i = 0; i < positionIds.length; i++) {
            thises[i] = account;
        }
        return conditionalTokens.balanceOfBatch(thises, positionIds);
    }

    function getMarketCollateralTotalSupply() public view returns(uint256){
        uint256 collateralTotalSupply = 0;
        for (uint i = 0; i < positionIds.length; i++) {
            collateralTotalSupply = conditionalTokens.totalBalances(positionIds[i]).add(collateralTotalSupply);
        }
        return collateralTotalSupply.div(positionIds.length);
    }

    function generateBasicPartition(uint outcomeSlotCount)
    private
    pure
    returns (uint[] memory partition)
    {
        partition = new uint[](outcomeSlotCount);
        for (uint i = 0; i < outcomeSlotCount; i++) {
            partition[i] = 1 << i;
        }
    }

    function splitPositionThroughAllConditions(uint amount)
    private
    {
        for (uint i = conditionIds.length - 1; int(i) >= 0; i--) {
            uint[] memory partition = generateBasicPartition(outcomeSlotCounts[i]);
            for (uint j = 0; j < collectionIds[i].length; j++) {
                conditionalTokens.splitPosition(collateralToken, collectionIds[i][j], conditionIds[i], partition, amount);
            }
        }
    }

    function mergePositionsThroughAllConditions(uint amount) internal {
        for (uint i = 0; i < conditionIds.length; i++) {
            uint[] memory partition = generateBasicPartition(outcomeSlotCounts[i]);
            for (uint j = 0; j < collectionIds[i].length; j++) {
                conditionalTokens.mergePositions(collateralToken, collectionIds[i][j], conditionIds[i], partition, amount);
            }
        }
    }

    function collectedFees() external view returns (uint) {
        return feePoolWeight.sub(totalWithdrawnFees);
    }

    function feeLPWithdrawableBy(address account) public view returns (uint collateralAmount, uint roomAmount) {
        uint rawAmount = feePoolWeight.mul(balanceOf(account)) / totalSupply();
        collateralAmount = rawAmount.sub(withdrawnFees[account]);
        roomAmount = IRoomOraclePrice(roomOracle).getExpectedRoomByToken(address(collateralToken),collateralAmount);
       
    }
    
    function feeProposerWithdrawable() public view returns(uint collateralAmount, uint roomAmount) {
        collateralAmount = totalProposerFee.sub(withdrawnProposerFee);
        roomAmount = IRoomOraclePrice(roomOracle).getExpectedRoomByToken(address(collateralToken),collateralAmount);
    }
    
    function withdrawProposerFee(uint256 minRoom) public {
        require(msg.sender == proposer, "only proposer can call");
        (uint withdrawableAmount, ) = feeProposerWithdrawable();
        if(withdrawableAmount > 0){
            withdrawnProposerFee = withdrawnProposerFee.add(withdrawableAmount);
            
            collateralToken.safeApprove(roomOracle,withdrawableAmount);
            IRoomOraclePrice(roomOracle).buyRoom(address(collateralToken),withdrawableAmount,minRoom,msg.sender);
        }
        
    }
    
    function withdrawFees(uint256 minRoom) public {
        _withdrawFees(msg.sender,minRoom);
    }

    function _withdrawFees(address account, uint256 minRoom) internal {
        uint rawAmount = feePoolWeight.mul(balanceOf(account)) / totalSupply();
        uint withdrawableAmount = rawAmount.sub(withdrawnFees[account]);
        if (withdrawableAmount > 0) {
            withdrawnFees[account] = rawAmount;
            totalWithdrawnFees = totalWithdrawnFees.add(withdrawableAmount);
            
            collateralToken.safeApprove(roomOracle,withdrawableAmount);
            IRoomOraclePrice(roomOracle).buyRoom(address(collateralToken),withdrawableAmount,minRoom,account);
        }
    }
    
    /*
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal {
        if (from != address(0)) {
            withdrawFees(from);
        }

        uint totalSupply = totalSupply();
        uint withdrawnFeesTransfer = totalSupply == 0 ?
        amount :
        feePoolWeight.mul(amount) / totalSupply;

        if (from != address(0)) {
            withdrawnFees[from] = withdrawnFees[from].sub(withdrawnFeesTransfer);
            totalWithdrawnFees = totalWithdrawnFees.sub(withdrawnFeesTransfer);
        } else {
            feePoolWeight = feePoolWeight.add(withdrawnFeesTransfer);
        }
        if (to != address(0)) {
            withdrawnFees[to] = withdrawnFees[to].add(withdrawnFeesTransfer);
            totalWithdrawnFees = totalWithdrawnFees.add(withdrawnFeesTransfer);
        } else {
            feePoolWeight = feePoolWeight.sub(withdrawnFeesTransfer);
        }
    }
    */

    function addFundingTo(address beneficiary, uint addedFunds, uint[] memory distributionHint) internal returns(uint)
    {
        require(addedFunds > 0, "funding must be non-zero");
        _beforeAddFundingTo(beneficiary,addedFunds);

        uint[] memory sendBackAmounts = new uint[](positionIds.length);
        uint poolShareSupply = totalSupply();
        uint mintAmount;
        if (poolShareSupply > 0) {
            require(distributionHint.length == 0, "cannot use distribution hint after initial funding");
            uint[] memory poolBalances = getPoolBalances();
            uint poolWeight = 0;
            for (uint i = 0; i < poolBalances.length; i++) {
                uint balance = poolBalances[i];
                if (poolWeight < balance)
                    poolWeight = balance;
            }

            for (uint i = 0; i < poolBalances.length; i++) {
                uint remaining = addedFunds.mul(poolBalances[i]) / poolWeight;
                sendBackAmounts[i] = addedFunds.sub(remaining);
            }

            mintAmount = addedFunds.mul(poolShareSupply) / poolWeight;
        } else {
            if (distributionHint.length > 0) {
                require(distributionHint.length == positionIds.length, "hint length off");
                uint maxHint = 0;
                for (uint i = 0; i < distributionHint.length; i++) {
                    uint hint = distributionHint[i];
                    if (maxHint < hint)
                        maxHint = hint;
                }

                for (uint i = 0; i < distributionHint.length; i++) {
                    uint remaining = addedFunds.mul(distributionHint[i]) / maxHint;
                    require(remaining > 0, "must hint a valid distribution");
                    sendBackAmounts[i] = addedFunds.sub(remaining);
                }
            }

            mintAmount = addedFunds;
        }

        collateralToken.safeTransferFrom(msg.sender, address(this), addedFunds);
        require(collateralToken.approve(address(conditionalTokens), addedFunds), "approval for splits failed");
        splitPositionThroughAllConditions(addedFunds);

        _mint(beneficiary, mintAmount);

        conditionalTokens.safeBatchTransferFrom(address(this), beneficiary, positionIds, sendBackAmounts, "");

        // transform sendBackAmounts to array of amounts added
        for (uint i = 0; i < sendBackAmounts.length; i++) {
            sendBackAmounts[i] = addedFunds.sub(sendBackAmounts[i]);
        }

        emit FPMMFundingAdded(beneficiary, sendBackAmounts, mintAmount);
        return mintAmount;
    }
    

    function removeFundingTo(address beneficiary, uint sharesToBurn, bool withdrawFeesFlag) internal {

        _beforeRemoveFundingTo(beneficiary, sharesToBurn);

        uint[] memory poolBalances = getPoolBalances();

        uint[] memory sendAmounts = new uint[](poolBalances.length);

        uint poolShareSupply = totalSupply();
        for (uint i = 0; i < poolBalances.length; i++) {
            sendAmounts[i] = poolBalances[i].mul(sharesToBurn) / poolShareSupply;
        }

        uint collateralRemovedFromFeePool = collateralToken.balanceOf(address(this));
        
        if(withdrawFeesFlag){
            _withdrawFees(beneficiary,0);
        }
        
        _burn(beneficiary, sharesToBurn);
        collateralRemovedFromFeePool = collateralRemovedFromFeePool.sub(
            collateralToken.balanceOf(address(this))
        );

        conditionalTokens.safeBatchTransferFrom(address(this), beneficiary, positionIds, sendAmounts, "");

        emit FPMMFundingRemoved(beneficiary, sendAmounts, collateralRemovedFromFeePool, sharesToBurn);
    }
    
    
    function onERC1155Received(
        address operator,
        address,
        uint256,
        uint256,
        bytes calldata
    )
    external
    returns (bytes4)
    {
        if (operator == address(this)) {
            return this.onERC1155Received.selector;
        }
        return 0x0;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    )
    external
    returns (bytes4)
    {
        if (operator == address(this) && from == address(0)) {
            return this.onERC1155BatchReceived.selector;
        }
        return 0x0;
    }

    function calcBuyAmount(uint investmentAmount, uint outcomeIndex) public view returns (uint) {
        require(outcomeIndex < positionIds.length, "invalid outcome index");

        uint[] memory poolBalances = getPoolBalances();
        uint investmentAmountMinusFees = investmentAmount.sub(investmentAmount.mul(totalFee) / ONE);
        uint buyTokenPoolBalance = poolBalances[outcomeIndex];
        uint endingOutcomeBalance = buyTokenPoolBalance.mul(ONE);
        for (uint i = 0; i < poolBalances.length; i++) {
            if (i != outcomeIndex) {
                uint poolBalance = poolBalances[i];
                endingOutcomeBalance = endingOutcomeBalance.mul(poolBalance).ceildiv(
                    poolBalance.add(investmentAmountMinusFees)
                );
            }
        }
        require(endingOutcomeBalance > 0, "must have non-zero balances");

        return buyTokenPoolBalance.add(investmentAmountMinusFees).sub(endingOutcomeBalance.ceildiv(ONE));
    }
    
    
    function calcBuyAmountProtocolFeesIncluded(uint investmentAmount, uint outcomeIndex, uint256 protocolFee) public view returns (uint) {
        uint256 pFee = investmentAmount * protocolFee / 1e18;
        
        return calcBuyAmount(investmentAmount - pFee, outcomeIndex);
        
    }


    function calcSellAmount(uint returnAmount, uint outcomeIndex) internal view returns (uint outcomeTokenSellAmount) {
        require(outcomeIndex < positionIds.length, "invalid outcome index");

        uint[] memory poolBalances = getPoolBalances();
        //uint returnAmountPlusFees = returnAmount.mul(ONE) / ONE.sub(fee);
        uint returnAmountPlusFees = returnAmount.mul(ONE.add(totalFee)) / ONE;
        uint sellTokenPoolBalance = poolBalances[outcomeIndex];
        uint endingOutcomeBalance = sellTokenPoolBalance.mul(ONE);
        for (uint i = 0; i < poolBalances.length; i++) {
            if (i != outcomeIndex) {
                uint poolBalance = poolBalances[i];
                endingOutcomeBalance = endingOutcomeBalance.mul(poolBalance).ceildiv(
                    poolBalance.sub(returnAmountPlusFees)
                );
            }
        }
        require(endingOutcomeBalance > 0, "must have non-zero balances");

        return returnAmountPlusFees.add(endingOutcomeBalance.ceildiv(ONE)).sub(sellTokenPoolBalance);
    }

    function calcSellReturnInv(uint amount, uint inputIndex) public view returns (uint256 ret){
        uint256[] memory poolBalance0 = getPoolBalances();

        uint256 c = poolBalance0[0] * poolBalance0[1];

        uint256 m = 0;
        if (inputIndex == 0) {
            m = amount + poolBalance0[0] - poolBalance0[1];

        } else {
            m = amount + poolBalance0[1] - poolBalance0[0];
        }

        uint256 f = sqrt((m * m) + 4 * c);

        if (inputIndex == 0) {
            ret = ((2 * poolBalance0[1]) - (f - m)) / 2;
        } else {
            ret = ((2 * poolBalance0[0]) - (f - m)) / 2;
        }

        ret = ret.mul(ONE.sub(totalFee)) / ONE;
    }
    
    function calcSellReturnInvMinusMarketFees(uint amount, uint inputIndex, uint256 protocolFee) public view returns (uint256 ret){
        ret = calcSellReturnInv(amount,inputIndex);
        
        uint256 pFee = ret * protocolFee / 1e18;
        
        ret -= pFee;
    }
    
    
    function buyTo(address beneficiary, uint investmentAmount, uint outcomeIndex, uint minOutcomeTokensToBuy) public returns(uint256) {
        _beforeBuyTo(beneficiary, investmentAmount);
        uint outcomeTokensToBuy = calcBuyAmount(investmentAmount, outcomeIndex);
        require(outcomeTokensToBuy >= minOutcomeTokensToBuy, "minimum buy amount not reached");

        collateralToken.safeTransferFrom(msg.sender, address(this), investmentAmount);

        uint feeLPAmount = investmentAmount.mul(lpFee) / ONE;
        uint feeProposer = investmentAmount.mul(proposerFee) / ONE;
        totalProposerFee += feeProposer;
        feePoolWeight = feePoolWeight.add(feeLPAmount);
        uint investmentAmountMinusFees = investmentAmount.sub(feeLPAmount).sub(feeProposer);
        require(collateralToken.approve(address(conditionalTokens), investmentAmountMinusFees), "approval for splits failed");
        splitPositionThroughAllConditions(investmentAmountMinusFees);

        conditionalTokens.safeTransferFrom(address(this), beneficiary, positionIds[outcomeIndex], outcomeTokensToBuy, "");
        return outcomeTokensToBuy;
        //emit FPMMBuy(beneficiary, investmentAmount, feeLPAmount + feeProposer, outcomeIndex, outcomeTokensToBuy);
    }

    function sellByReturnAmountTo(address beneficiary, uint returnAmount, uint outcomeIndex, uint maxOutcomeTokensToSell) internal {
        uint outcomeTokensToSell = calcSellAmount(returnAmount, outcomeIndex);
        require(outcomeTokensToSell <= maxOutcomeTokensToSell, "maximum sell amount exceeded");

        conditionalTokens.safeTransferFrom(msg.sender, address(this), positionIds[outcomeIndex], outcomeTokensToSell, "");

        uint feeProposer = returnAmount.mul(proposerFee) / ONE;
        totalProposerFee += feeProposer;
        
        //uint feeAmount = returnAmount.mul(fee) / (ONE.sub(fee));
        uint feeLPAmount = returnAmount.mul(lpFee) / ONE;
        
        feePoolWeight = feePoolWeight.add(feeLPAmount);
        uint returnAmountPlusFees = returnAmount.add(feeLPAmount);
        mergePositionsThroughAllConditions(returnAmountPlusFees);

        collateralToken.safeTransfer(beneficiary, returnAmount);

        //emit FPMMSell(msg.sender, returnAmount, feeLPAmount + feeProposer, outcomeIndex, outcomeTokensToSell);
    }

    
    function sellTo(address beneficiary, uint256 amount, uint256 index) public returns(uint256){
        uint256 expectedRet = calcSellReturnInv(amount, index);
        _beforeSellTo(beneficiary, expectedRet);
        sellByReturnAmountTo(beneficiary,expectedRet, index, amount * 105 / 100);
        
        return expectedRet;
        
    }
    
    uint256 totalLiq;
    mapping(address => uint256) balances;
    function totalSupply() public view returns(uint256){
        return totalLiq;
    }
    
    function balanceOf(address account) public view returns(uint256){
        return balances[account];
    }
    
    function _mint(address account, uint256 amount) internal{
        if(account != address(0)){
            balances[account] += amount;
            totalLiq += amount;
        }
    }
    
    function _burn(address account, uint256 amount) internal{
        if(account != address(0)){
            require(amount <= balances[account], "insufficient balance");
            balances[account] -= amount;
            totalLiq -= amount;
        }
    }

    function _beforeBuyTo(address account, uint256 amount) internal;

    function _beforeSellTo(address account, uint256 amount) internal;
    
    function _beforeAddFundingTo(address beneficiary, uint addedFunds) internal;

    function _beforeRemoveFundingTo(address beneficiary, uint sharesToBurn) internal;

    function sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        z = z + 1;
    }

}

// File: contracts\OR\ORFPMarket.sol

pragma solidity ^0.5.16;





/**
    @title ORFPMarket Extended version of the FixedProductMarketMaker
*/
contract ORFPMarket is FixedProductMarketMaker {
    using TransferHelper for IERC20;
    

    
    bytes32 public questionId;


    bool private initializationPhase2;

    string public marketQuestionID;
    
    IORMarketController public marketController;
    
    //mapping(address => bool) public traders;

    function setConfig(
            string memory _marketQuestionID,
            address _controller,
            bytes32 _questionId
    ) public {
        require(initializationPhase2 == false, "Initialization already called");
        initializationPhase2 = true;
        marketController = IORMarketController(_controller);
        marketQuestionID = _marketQuestionID;
        questionId = _questionId;
    }
    
    

    
    function addLiquidityTo(address beneficiary, uint256 amount) public returns(uint) {
        uint shares;
        uint[] memory distributionHint;
        if (totalSupply() > 0) {
            shares = addFundingTo(beneficiary,amount, distributionHint);
        } else {
            distributionHint = new uint[](2);
            distributionHint[0] = 1;
            distributionHint[1] = 1;
            shares= addFundingTo(beneficiary,amount, distributionHint);
        }
        
        return shares;
    }

    function removeLiquidityTo(address beneficiary, uint256 shares, bool autoMerge, bool withdrawFees) public {
        removeFundingTo(beneficiary, shares, withdrawFees);
        if(autoMerge == true){
            _merge(beneficiary);
        }
    }

    function merge() public {
       _merge(msg.sender);
    }
    
    function _merge(address account) internal {
        uint[] memory balances = getBalances(account);
        uint minBalance = balances[0];
        for (uint256 i = 0; i < balances.length; i++) {
            if (balances[i] < minBalance) {
                minBalance = balances[i];
            }
        }

        uint[] memory sendAmounts = new uint[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            sendAmounts[i] = minBalance;
        }

        conditionalTokens.safeBatchTransferFrom(account, address(this), positionIds, sendAmounts, "");
        mergePositionsThroughAllConditions(minBalance);

        collateralToken.safeTransfer(account, minBalance);
    }

    function getPercentage() public view returns (uint256[] memory percentage) {
        percentage = new uint256[](2);
        uint256[] memory balances = getPoolBalances();
        uint256 totalBalances = balances[0] + balances[1] ;
        if(totalBalances == 0){
            percentage[0] = 500000 ;
            percentage[1] = 500000 ;

        }else{
            percentage[0] = balances[1] * 1000000 / totalBalances;
            percentage[1] = balances[0] * 1000000 / totalBalances;

        }
    }

    function getPositionIds() public view returns (uint256[] memory) {
        return positionIds;
    }

    

    function getMarketQuestionID() public view returns(string memory){
        return marketQuestionID;
    }
    
    
    function getConditionalTokenAddress() public view returns(address){
        return address(conditionalTokens);
    }


    

    function getSharesPercentage(address account) public view returns(uint256) {
        uint256  totalSupply = totalSupply();
        if(totalSupply == 0){
            return 0;
        }
        return balanceOf(account) * 100 * 10000 / totalSupply;
    }
    
    function getIndexSet() public pure returns (uint256[] memory indexSet) {
        indexSet = new uint256[](2);
        indexSet[0] = 1;
        indexSet[1] = 2;
    }
    
    
    function _beforeAddFundingTo(address , uint ) internal {
        require(msg.sender == address(marketController), "caller is not market controller");
        
    }
    
    function _beforeRemoveFundingTo(address , uint ) internal{
        require(msg.sender == address(marketController), "caller is not market controller");
    }

    function _beforeBuyTo(address , uint256 ) internal {
        
        require(msg.sender == address(marketController), "caller is not market controller");
        
    }

    function _beforeSellTo(address , uint256 ) internal {
        
        require(msg.sender == address(marketController), "caller is not market controller");
        
        
    }

     function state() public view returns (ORMarketLib.MarketState) {
         return marketController.getMarketState(address(this));
     }
   
}


// File: contracts\OR\CloneFactory.sol

pragma solidity ^0.5.16;

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

// File: contracts\OR\FixedProductMarketMakerFactoryOR.sol

pragma solidity ^0.5.16;







contract FixedProductMarketMakerFactory is CloneFactory {
    event FixedProductMarketMakerCreation(
        address indexed creator,
        ORFPMarket fixedProductMarketMaker,
        ConditionalTokens indexed conditionalTokens,
        IERC20 indexed collateralToken,
        bytes32[] conditionIds,
        uint fee
    );

    ORFPMarket public implementationMaster;
    address implementationMasterAddr;

    uint public marketsCount;
    ORFPMarket[] public fpMarkets;

    address deployer;
    constructor() public {
        //implementationMaster = new ORFPMarket();
        //implementationMasterAddr = address(implementationMaster);
        
        //implementationMasterAddr = marketTemplateAdd; 
        deployer = msg.sender;
    }
    
    
    /*
        function cloneConstructor(bytes calldata consData) external {
            (
            ConditionalTokens _conditionalTokens,
            IERC20 _collateralToken,
            bytes32[] memory _conditionIds,
            uint _fee
            ) = abi.decode(consData, (ConditionalTokens, IERC20, bytes32[], uint));

            _supportedInterfaces[_INTERFACE_ID_ERC165] = true;
            _supportedInterfaces[
            ERC1155TokenReceiver(0).onERC1155Received.selector ^
            ERC1155TokenReceiver(0).onERC1155BatchReceived.selector
            ] = true;

            conditionalTokens = _conditionalTokens;
            collateralToken = _collateralToken;
            conditionIds = _conditionIds;
            fee = _fee;

            uint atomicOutcomeSlotCount = 1;
            outcomeSlotCounts = new uint[](conditionIds.length);
            for (uint i = 0; i < conditionIds.length; i++) {
                uint outcomeSlotCount = conditionalTokens.getOutcomeSlotCount(conditionIds[i]);
                atomicOutcomeSlotCount *= outcomeSlotCount;
                outcomeSlotCounts[i] = outcomeSlotCount;
            }
            require(atomicOutcomeSlotCount > 1, "conditions must be valid");

            collectionIds = new bytes32[][](conditionIds.length);
            _recordCollectionIDsForAllConditions(conditionIds.length, bytes32(0));
            require(positionIds.length == atomicOutcomeSlotCount, "position IDs construction failed!?");
        }

        function _recordCollectionIDsForAllConditions(uint conditionsLeft, bytes32 parentCollectionId) private {
            if(conditionsLeft == 0) {
                positionIds.push(CTHelpers.getPositionId(collateralToken, parentCollectionId));
                return;
            }

            conditionsLeft--;

            uint outcomeSlotCount = outcomeSlotCounts[conditionsLeft];

            collectionIds[conditionsLeft].push(parentCollectionId);
            for(uint i = 0; i < outcomeSlotCount; i++) {
                _recordCollectionIDsForAllConditions(
                    conditionsLeft,
                    CTHelpers.getCollectionId(
                        parentCollectionId,
                        conditionIds[conditionsLeft],
                        1 << i
                    )
                );
            }
        }
    */
    function createFixedProductMarketMaker(
        ConditionalTokens conditionalTokens,
        IERC20 collateralToken,
        bytes32[] memory conditionIds,
        uint feeLP,
        uint feeProposer,
        address proposer,
        address roomOracle
    )
    internal
    returns (ORFPMarket)
    {
        ORFPMarket fixedProductMarketMaker = ORFPMarket(createClone(implementationMasterAddr));

        fixedProductMarketMaker.init(conditionalTokens, collateralToken, conditionIds, feeLP, feeProposer, proposer, roomOracle);

        emit FixedProductMarketMakerCreation(
            msg.sender,
            fixedProductMarketMaker,
            conditionalTokens,
            collateralToken,
            conditionIds,
            feeLP + feeProposer
        );

        fpMarkets.push(fixedProductMarketMaker);
        marketsCount++;
        return fixedProductMarketMaker;
    }

    function getAllMarkets() public view returns (ORFPMarket[] memory) {
        return fpMarkets;
    }
    
    function getAllMarketsCount() public view returns(uint256){
        return marketsCount; 
    }


}

// File: contracts\RewardCenter\IRewardCenter.sol

pragma solidity ^0.5.16;


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

pragma solidity ^0.5.16;

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

pragma solidity ^0.5.16;


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

// File: contracts\OR\ORMarketController.sol

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;











interface IORMarketForMarketGovernor{
    function getBalances(address account) external view returns (uint[] memory);
    function getConditionalTokenAddress() external view returns(address);
    function questionId() external view returns(bytes32);
}

interface IReportPayouts{
    function reportPayouts(bytes32 questionId, uint[] calldata payouts) external;
}


contract ORMarketController is IORMarketController, FixedProductMarketMakerFactory, GnGOwnable{
    using SafeMath for uint256;
    using TransferHelper for IERC20;
    
    event MCBuy(
        address indexed market,
        address indexed buyer,
        uint investmentAmount,
        uint indexed outcomeIndex,
        uint outcomeTokensBought
    );
    event MCSell(
        address indexed market,
        address indexed seller,
        uint returnAmount,
        uint indexed outcomeIndex,
        uint outcomeTokensSold
    );
    
    struct MarketVotersInfo{
        uint256 power;
        bool voteFlag;
        uint8 selection;
        uint8 insertedFlag;
    }

    struct MarketDisputersInfo{
        uint256[2] balances;
        string reason;
    }

    struct MarketInfo{
        //address marketAddress;
        uint256 createdTime;
        uint256 participationEndTime;
        uint256 resolvingEndTime;
        uint256 lastResolvingVoteTime;
        uint256 lastDisputeResolvingVoteTime;
        uint256 disputeTotalBalances;
        uint256[2] validatingVotesCount;
        uint256[2] resolvingVotesCount;
        bool    disputedFlag;
    }
    
    
    
    mapping(address => address[]) public marketsProposedByUser;
    mapping(address => address[]) public marketsLiquidityByUser;
    mapping(address => address[]) public marketsTradeByUser;
    
    mapping(address => mapping(address => bool)) marketsLiquidityFlag;
    mapping(address => mapping(address => bool)) marketsTradeFlag;
    
    IORGovernor public orGovernor;
    ConditionalTokens public ct; 
    IERC20 roomToken;
    IRewardProgram  public RP; //reward program
    address public roomOracleAddress;
    address public rewardCenterAddress;
    
    mapping(address => MarketInfo) marketsInfo;

    mapping(address => address[]) public marketValidatingVoters;
    mapping(address => mapping(address => MarketVotersInfo)) public marketValidatingVotersInfo;

    mapping(address => address[]) public marketResolvingVoters;
    mapping(address => mapping(address => MarketVotersInfo)) public marketResolvingVotersInfo;

    mapping(address => address[]) public marketDisputers;
    mapping(address => mapping(address => MarketDisputersInfo)) public marketDisputersInfo;
    
    mapping(address => bool) allowedCollaterals;
   
    mapping(address => bool) payoutsMarkets;

    uint256 public marketMinShareLiq = 100e18; //todo
    uint256 public feeMarketLP = 20000000000000000;  //2% todo
    uint256 public FeeProtocol = 10000000000000000; //1%t todo
    uint256 public FeeProposer = 10000000000000000; //1%t todo
    uint256 public buyRoomThreshold = 1e18; // todo
    uint256 public marketValidatingPeriod = 1800; // todo
    uint256 public marketDisputePeriod = 4 * 1800; // todo
    uint256 public marketReCastResolvingPeriod = 4 * 1800; //todo
    uint256 public disputeThreshold = 100e18; // todo
    uint256 public marketCreationFees =100e18;// todo
    
    bool penaltyOnWrongResolving;
    mapping(address => address[]) marketsVotedPerUser;
    
    mapping(bytes32 => address) public proposalIds;
    
    
    event DisputeSubmittedEvent(address indexed disputer, address indexed market, uint256 disputeTotalBalances, bool reachThresholdFlag);
    
    constructor() public{
        
        
    }
    
    
    function addMarket(address marketAddress, uint256 _marketCreatedTime,  uint256 _marketParticipationEndTime,  uint256 _marketResolvingEndTime) internal returns(uint256){
        
        MarketInfo storage marketInfo = marketsInfo[marketAddress];
        marketInfo.createdTime = _marketCreatedTime;
        marketInfo.participationEndTime = _marketParticipationEndTime;
        marketInfo.resolvingEndTime = _marketResolvingEndTime;
        
    }
    
    
    
    

    function payoutsAction(address marketAddress) external {

        if (payoutsMarkets[marketAddress] == true) {
            return;
        }

        payoutsMarkets[marketAddress] = true;
        IORMarketForMarketGovernor market = IORMarketForMarketGovernor(marketAddress);
        
        ORMarketLib.MarketState marketState = getMarketState(marketAddress);
        require(marketState == ORMarketLib.MarketState.Resolved || marketState == ORMarketLib.MarketState.ForcedResolved, "market is not in resolved/ forces resolve state");

        IReportPayouts orConditionalTokens = IReportPayouts(address(market.getConditionalTokenAddress()));
        if(marketState == ORMarketLib.MarketState.Resolved){
            orConditionalTokens.reportPayouts(market.questionId(), getResolvingOutcome(marketAddress));
        }else{
            uint256[] memory indexSet = new uint256[](2);
            indexSet[0] = 1;
            indexSet[1] = 1;
            orConditionalTokens.reportPayouts(market.questionId(), indexSet);
        }
    }

    function getAccountInfo(address account) public view returns(bool canVote, uint256 votePower){
        bool governorFlag; bool suspendedFlag;
        (governorFlag, suspendedFlag,  votePower) = orGovernor.getAccountInfo(account);
        canVote = governorFlag && !suspendedFlag;
        return (canVote, votePower);
    }
    
    
    function getMarketState(address marketAddress) public view returns (ORMarketLib.MarketState) {

        MarketInfo memory marketInfo = marketsInfo[marketAddress];

        uint256 time = getCurrentTime();
        if(marketsStopped[marketAddress] == true){
            return ORMarketLib.MarketState.ForcedResolved;
        }
        if(marketInfo.createdTime == 0){
            return ORMarketLib.MarketState.Invalid;

        } else if (time <marketInfo.createdTime + marketValidatingPeriod ) {
            return ORMarketLib.MarketState.Validating;

        } else if (marketInfo.validatingVotesCount[0] >= marketInfo.validatingVotesCount[1] ) {
            return ORMarketLib.MarketState.Rejected;

        } else if (time < marketInfo.participationEndTime) {
            return ORMarketLib.MarketState.Active;

        } else if ( time < marketInfo.resolvingEndTime){
            return ORMarketLib.MarketState.Resolving;

        } else if(marketInfo.resolvingVotesCount[0] == marketInfo.resolvingVotesCount[1]){
            if(marketInfo.disputedFlag){
                return ORMarketLib.MarketState.ResolvingAfterDispute;
            }
            return ORMarketLib.MarketState.Resolving;

        }

        uint256 resolvingDisputeEndTime;
        if(marketInfo.resolvingEndTime > marketInfo.lastResolvingVoteTime)
        {
            resolvingDisputeEndTime = marketInfo.resolvingEndTime + marketDisputePeriod;
        }else{
            resolvingDisputeEndTime = marketInfo.lastResolvingVoteTime + marketDisputePeriod;
        }

        if(time < resolvingDisputeEndTime){
          return ORMarketLib.MarketState.DisputePeriod;
        }

        if(marketInfo.disputedFlag){
             if(time < resolvingDisputeEndTime + marketReCastResolvingPeriod){
                 return ORMarketLib.MarketState.ResolvingAfterDispute;
             }
        }

        return ORMarketLib.MarketState.Resolved;

    }


    function castGovernanceValidatingVote(address marketAddress,bool validationFlag) public {
       
        address account = msg.sender;
        require(getMarketState(marketAddress) == ORMarketLib.MarketState.Validating, "Market is not in validation state");

        MarketVotersInfo storage marketVotersInfo = marketValidatingVotersInfo[marketAddress][account];
        require(marketVotersInfo.voteFlag == false, "user already voted");

        bool canVote;
        uint256 votePower;
        (canVote,votePower) = getAccountInfo(account);
        require(canVote == true, "user can not vote");

        uint8 validationSelection = 0;
        if(validationFlag) { validationSelection = 1; }

        if(marketVotersInfo.insertedFlag == 0){ // action on 1'st vote for the user
            marketVotersInfo.insertedFlag = 1;
            marketValidatingVoters[marketAddress].push(account);
            
            RP.validationVote(marketAddress, validationFlag, msg.sender, votePower);
        }

        marketVotersInfo.voteFlag = true;
        marketVotersInfo.power = votePower;
        marketVotersInfo.selection = validationSelection;

        marketsInfo[marketAddress].validatingVotesCount[validationSelection] += votePower;
    }

    function withdrawGovernanceValidatingVote(address marketAddress) public {
        address account = msg.sender;
        require(getMarketState(marketAddress) == ORMarketLib.MarketState.Validating, "Market is not in validation state");

        MarketVotersInfo storage marketVotersInfo = marketValidatingVotersInfo[marketAddress][account];
        require(marketVotersInfo.voteFlag == true, "user did not vote");

        marketVotersInfo.voteFlag = false;

        uint8 validationSelection = marketVotersInfo.selection;
        marketsInfo[marketAddress].validatingVotesCount[validationSelection] -= marketVotersInfo.power;
        marketVotersInfo.power = 0;

    }
 
    function castGovernanceResolvingVote(address marketAddress,uint8 outcomeIndex) public {
        require( outcomeIndex < 2 , "Outcome should be within range!");
        address account = msg.sender;
        ORMarketLib.MarketState marketState = getMarketState(marketAddress);

        require(marketState == ORMarketLib.MarketState.Resolving || marketState == ORMarketLib.MarketState.ResolvingAfterDispute, "Market is not in resolving/ResolvingAfterDispute states");

        MarketVotersInfo storage marketVotersInfo = marketResolvingVotersInfo[marketAddress][account];
        require(marketVotersInfo.voteFlag == false, "user already voted");
        
        if(penaltyOnWrongResolving){
            address[] memory checkedWrongVotingResult = checkForWrongVoting(account);
            bool cannotVoteFlag = orGovernor.userHasWrongVoting(account, checkedWrongVotingResult);
            if(cannotVoteFlag){
                return;
            }
        }
        
        bool canVote;
        uint256 votePower;
        (canVote,votePower) = getAccountInfo(account);
        require(canVote == true, "user can not vote");


        if(marketState == ORMarketLib.MarketState.Resolving){
             marketsInfo[marketAddress].lastResolvingVoteTime = getCurrentTime();
        }else{
             marketsInfo[marketAddress].lastDisputeResolvingVoteTime = getCurrentTime();
        }
        
        if(penaltyOnWrongResolving){
            marketsVotedPerUser[account].push(marketAddress);
        }
        
        if(marketVotersInfo.insertedFlag == 0){
            marketVotersInfo.insertedFlag = 1;
            marketResolvingVoters[marketAddress].push(account);
            
            RP.resolveVote(marketAddress, outcomeIndex, msg.sender, votePower);
        }

        marketVotersInfo.voteFlag = true;
        marketVotersInfo.power = votePower;
        marketVotersInfo.selection = outcomeIndex;

        marketsInfo[marketAddress].resolvingVotesCount[outcomeIndex] += votePower;
    }
    

    function withdrawGovernanceResolvingVote(address marketAddress) public{
        address account = msg.sender;
        ORMarketLib.MarketState marketState = getMarketState(marketAddress);

        require(marketState == ORMarketLib.MarketState.Resolving || marketState == ORMarketLib.MarketState.ResolvingAfterDispute, "Market is not in resolving/ResolvingAfterDispute states");

        MarketVotersInfo storage marketVotersInfo = marketResolvingVotersInfo[marketAddress][account];
        
        if(penaltyOnWrongResolving){
            deleteMarketVoting(account,marketAddress);
        }
        require(marketVotersInfo.voteFlag == true, "user did not vote");

        marketVotersInfo.voteFlag = false;

        uint8 outcomeIndex = marketVotersInfo.selection;
        marketsInfo[marketAddress].resolvingVotesCount[outcomeIndex] -= marketVotersInfo.power;
        marketVotersInfo.power = 0;
        
    }

    function disputeMarket(address marketAddress, string memory disputeReason) public{
        require(getMarketState(marketAddress) == ORMarketLib.MarketState.DisputePeriod, "Market is not in dispute state");
        address account = msg.sender;
        uint[] memory balances = IORMarketForMarketGovernor(marketAddress).getBalances(account);
        uint256 userTotalBalances = balances[0] + balances[1];

        require(userTotalBalances > 0, "Low holding to dispute");

        MarketDisputersInfo storage disputersInfo = marketDisputersInfo[marketAddress][account];
        require(disputersInfo.balances[0] == 0 && disputersInfo.balances[1] == 0, "User already dispute");

        marketDisputers[marketAddress].push(account);
        disputersInfo.balances[0] = balances[0];
        disputersInfo.balances[1] = balances[1];
        disputersInfo.reason = disputeReason;
        marketsInfo[marketAddress].disputeTotalBalances += userTotalBalances;

        if(marketsInfo[marketAddress].disputeTotalBalances >= disputeThreshold){
            marketsInfo[marketAddress].disputedFlag = true;
        }

        emit DisputeSubmittedEvent(account,marketAddress,marketsInfo[marketAddress].disputeTotalBalances,marketsInfo[marketAddress].disputedFlag);
    }
    
    function deleteMarketVoting(address account, address market) internal{
        address[] storage marketsVoted = marketsVotedPerUser[account];
        for(uint256 i = 0; i < marketsVoted.length; i++){
            if(marketsVoted[i] == market){
               marketsVoted[i] = marketsVoted[marketsVoted.length -1];
               marketsVoted.length--;
                break;
            }
        }
    }
    
    function checkForWrongVoting(address account) internal returns(address[] memory wrongVoting){
       
        address[] storage marketsVoted = marketsVotedPerUser[account];
        wrongVoting = new address[](marketsVoted.length);
        uint256 wrongVoteIndex =0;
        for(int i = int(marketsVoted.length) -1; i >= 0; i--){
            address marketAddress = marketsVoted[uint256(i)];
            if(getMarketState(marketAddress) == ORMarketLib.MarketState.Resolved){
                
                // delete it
                marketsVoted[uint256(i)] = marketsVoted[marketsVoted.length -1];
                marketsVoted.length--;
                
                uint256[] memory indexSet = getResolvingOutcome(marketAddress);
                uint8 userSelection = marketResolvingVotersInfo[marketAddress][account].selection;
                if( indexSet[userSelection] != 1){
                    
                    wrongVoting[wrongVoteIndex] = marketAddress;
                    wrongVoteIndex++;
                }
            }
        }
        
    }


    function isValidatingVoter(address marketAddress, address account) public view returns(MarketVotersInfo memory){
        return marketValidatingVotersInfo[marketAddress][account];
    }

    function isResolvingVoter(address marketAddress, address account) public view returns(MarketVotersInfo memory){
        return marketResolvingVotersInfo[marketAddress][account];
    }

    function getResolvingVotesCount(address marketAddress) public view returns (uint256[2] memory) {
        return marketsInfo[marketAddress].resolvingVotesCount;
    }

    function getResolvingOutcome(address marketAddress) public view returns (uint256[] memory indexSet) {
        indexSet = new uint256[](2);
        indexSet[0] = 1;
        indexSet[1] = 1;

        if (marketsInfo[marketAddress].resolvingVotesCount[0] > marketsInfo[marketAddress].resolvingVotesCount[1]) {
            indexSet[1] = 0;
        }
        if (marketsInfo[marketAddress].resolvingVotesCount[1] > marketsInfo[marketAddress].resolvingVotesCount[0]) {
            indexSet[0] = 0;
        }
    }

    function getMarketInfo(address marketAddress) public view returns (MarketInfo memory) {
        return marketsInfo[marketAddress];
    }
    ////////////////////////
    function createMarketProposal(string memory marketQuestionID, uint256 participationEndTime, uint256 resolvingEndTime, IERC20 collateralToken, uint256 initialLiq) public returns(address){
        require(allowedCollaterals[address(collateralToken)] == true, "Collateral token is not allowed");
    
        roomToken.safeTransferFrom(msg.sender, rewardCenterAddress ,marketCreationFees);
        bytes32 questionId = bytes32(marketsCount);
        require(proposalIds[questionId] == address(0), "proposal Id already used");
        require(initialLiq >= marketMinShareLiq, "initial liquidity less than minimum liquidity required" );
        ct.prepareCondition(address(this), questionId, 2);
        bytes32[]  memory conditionIds = new bytes32[](1);
        conditionIds[0] = ct.getConditionId(address(this), questionId, 2);
        //ORMarketController marketController =  ORMarketController(governanceAdd);
        
        ORFPMarket fpMarket = createFixedProductMarketMaker(ct, collateralToken, conditionIds, feeMarketLP, FeeProposer, msg.sender, roomOracleAddress);
        
        marketsProposedByUser[msg.sender].push(address(fpMarket));
        
        fpMarket.setConfig(marketQuestionID, address(this), questionId);
        addMarket(address(fpMarket),getCurrentTime(), participationEndTime, resolvingEndTime);
        
        proposalIds[questionId] = address(fpMarket);
        
        RP.addMarket(address(fpMarket));
        
        _marketAddLiquidity(address(fpMarket),initialLiq);
        
        
        return address(fpMarket);
    }
    
    
    function marketAddLiquidity(address market,uint256 amount) public{
        ORMarketLib.MarketState marketState = getMarketState(market);
        
        require(marketState == ORMarketLib.MarketState.Active || marketState == ORMarketLib.MarketState.Validating," liquidity can be added only in active/Validating state");
       _marketAddLiquidity(market,amount);
    }
    
    
    function _marketAddLiquidity(address market,uint256 amount) internal{
        ORFPMarket fpMarket = ORFPMarket(market);
        IERC20 collateralToken = fpMarket.collateralToken();
         // Add liquidity
        collateralToken.safeTransferFrom(msg.sender,address(this),amount);
        collateralToken.safeApprove(address(fpMarket),amount);
        uint sharesAmount = fpMarket.addLiquidityTo(msg.sender,amount);
        
        RP.lpMarketAdd(market, msg.sender, sharesAmount);
        
       
        if( marketsLiquidityFlag[msg.sender][market] == false){
            marketsLiquidityFlag[msg.sender][market] = true;
            marketsLiquidityByUser[msg.sender].push(market);
        }
    }
    
    function marketRemoveLiquidity(address market,uint256 sharesAmount, bool autoMerg, bool withdrawFees) public{
        
        address beneficiary = msg.sender;
        
        ORFPMarket fpMarket = ORFPMarket(market);
        
        address proposer = fpMarket.proposer();
        
         if(beneficiary == proposer) {
            ORMarketLib.MarketState marketState = getMarketState(market);
            
            if(marketState == ORMarketLib.MarketState.Validating || marketState == ORMarketLib.MarketState.Active){
                require(fpMarket.balanceOf(beneficiary).sub(sharesAmount) >= marketMinShareLiq, "The remaining shares dropped under the minimum");
            }
        }
        
        fpMarket.removeLiquidityTo(beneficiary,sharesAmount, autoMerg, withdrawFees);
        
        RP.lpMarketRemove(market, msg.sender, sharesAmount);
    }
    
    mapping(address => uint256) fees;
   
    function marketBuy(address market,uint investmentAmount, uint outcomeIndex, uint minOutcomeTokensToBu) public{
        ORMarketLib.MarketState marketState = getMarketState(market);
        require(marketState == ORMarketLib.MarketState.Active, "Market is not in active state");
        
        ORFPMarket fpMarket = ORFPMarket(market);
        IERC20 collateralToken = fpMarket.collateralToken();
        
        collateralToken.safeTransferFrom(msg.sender,address(this),investmentAmount);
        collateralToken.safeApprove(address(fpMarket),investmentAmount);
        
        uint256 pFee = investmentAmount * FeeProtocol / 1e18;
        fees[address(collateralToken)] += pFee;
        
        buyRoom(address(collateralToken));
        
        uint256 outcomeTokensToBuy = fpMarket.buyTo(msg.sender,investmentAmount-pFee,outcomeIndex,minOutcomeTokensToBu);
        
        RP.tradeAmount(market, msg.sender, investmentAmount, true);
       
        if( marketsTradeFlag[msg.sender][market] == false){
            marketsTradeFlag[msg.sender][market] = true;
            marketsTradeByUser[msg.sender].push(market);
        }
        
        emit MCBuy(market, msg.sender, investmentAmount, outcomeIndex, outcomeTokensToBuy);
    }
    
    function marketSell(address market, uint256 amount, uint256 index) public{
        ORMarketLib.MarketState marketState = getMarketState(market);
        require(marketState == ORMarketLib.MarketState.Active, "Market is not in active state");
        
        ORFPMarket fpMarket = ORFPMarket(market);
        uint256[] memory PositionIds = fpMarket.getPositionIds();
        ct.setApprovalForAll(address(fpMarket),true);
        ct.safeTransferFrom(msg.sender, address(this), PositionIds[index], amount, "");
        uint256 tradeVolume = fpMarket.sellTo(address(this),amount,index);
       
        IERC20 collateralToken = ORFPMarket(market).collateralToken();
        
        
        uint256 pFee = tradeVolume * FeeProtocol / 1e18;
        fees[address(collateralToken)] += pFee;
        
        buyRoom(address(collateralToken));
        
        collateralToken.safeTransfer(msg.sender,tradeVolume - pFee);
        RP.tradeAmount(market, msg.sender, tradeVolume, false);
        
        if( marketsTradeFlag[msg.sender][market] == false){
            marketsTradeFlag[msg.sender][market] = true;
            marketsTradeByUser[msg.sender].push(market);
        }
        
        emit MCSell(market, msg.sender, tradeVolume - pFee, index, amount);
    }
    
    function buyRoom(address IERCaddress) internal{
        if(fees[IERCaddress] >= buyRoomThreshold){
            if(roomOracleAddress != address(0)){
                IERC20 erc20 = IERC20(IERCaddress);
                erc20.safeApprove(roomOracleAddress,fees[IERCaddress]);
                IRoomOraclePrice(roomOracleAddress).buyRoom(IERCaddress,fees[IERCaddress],0,rewardCenterAddress);
                fees[IERCaddress] = 0;
            }
        }
    }
    
    function withdrawFees(address erc20Address, address to) public  onlyGovOrGur{
        IERC20 erc20 = IERC20(erc20Address);
        
        erc20.safeTransfer(to, erc20.balanceOf(address(this)));
    }
    
	function getMarketsCountByTrader(address trader) public view returns(uint256){
        return marketsTradeByUser[trader].length;
    }
    
    function getMarketsByTrader(address trader) public view returns(address[] memory){
        return marketsTradeByUser[trader];
    }
    
    //
    function setTemplateAddress(address templateAddress) public onlyGovOrGur{
        
        implementationMasterAddr = templateAddress;
    }
    
    function setIORGoverner(address orGovernorAddress) public onlyGovOrGur{
        
        orGovernor = IORGovernor(orGovernorAddress);
    }
    
    function setRewardProgram(address rewardProgramAddress) public onlyGovOrGur{
       
        RP = IRewardProgram(rewardProgramAddress);
    }
    
    function setConditionalToken(address conditionalTokensAddress) public onlyGovOrGur{
        ct = ConditionalTokens(conditionalTokensAddress);
    }
    
    function setRoomoracleAddress(address newAddress) public onlyGovOrGur{
        roomOracleAddress = newAddress;
    }
    
    function setRewardCenter(address newAddress) public onlyGovOrGur{
        rewardCenterAddress = newAddress;
    }
    
    function setRoomAddress(address roomAddres) public onlyGovOrGur{
        roomToken =IERC20(roomAddres);
    }
    
    // market configuration
    
    function setMarketCreationFees(uint256 newfees) public onlyGovOrGur{
        marketCreationFees = newfees;    
    }
    
    function setMarketMinShareLiq(uint256 minLiq) public onlyGovOrGur {
        marketMinShareLiq = minLiq;
    }

    function setMarketValidatingPeriod(uint256 p) public onlyGovOrGur{
        marketValidatingPeriod = p;
    }

    function setMarketDisputePeriod(uint256 p) public onlyGovOrGur{
        marketDisputePeriod = p;
    }

    function setMarketReCastResolvingPeriod(uint256 p) public onlyGovOrGur{
        marketReCastResolvingPeriod = p;
    }

    function setDisputeThreshold(uint256 t) public onlyGovOrGur{
        disputeThreshold = t;
    }
    
    function setFeeMarketLP(uint256 numerator, uint256 denominator) public onlyGovOrGur{
        
        feeMarketLP = numerator * 1e18 / denominator;
    }
    
    function setFeeProtocol(uint256 numerator, uint256 denominator) public onlyGovOrGur{
        FeeProtocol = numerator * 1e18 /denominator;
    }
    
    function setFeeProposer(uint256 numerator, uint256 denominator) public onlyGovOrGur{
        FeeProposer = numerator * 1e18 /denominator;
    }
    
    function setpenaltyOnWrongResolving(bool plentyFlag) public onlyGovOrGur{
        penaltyOnWrongResolving = plentyFlag;
    }
    
    function setCollateralAllowed(address token, bool allowdFlag) public onlyGovOrGur{
        allowedCollaterals[token] = allowdFlag;
    }
    
    mapping(address =>bool) marketsStopped;
    function marketStop(address market) public onlyGovOrGur{
        marketsStopped[market] = true;
    }


    function setBuyRoomThreshold(uint256 value) public onlyGovOrGur {
        buyRoomThreshold = value;
    }
    
    function getCurrentTime() public view returns(uint256){

        return block.timestamp;
    }

}

// File: contracts\OR\ORMarketsQuery.sol

pragma solidity ^0.5.16;


contract ORMarketsQuery is GnGOwnable{
    ORMarketController  marketsController;
    
    function setMarketsController(address marketController) public onlyGovOrGur{
        marketsController = ORMarketController(marketController);
    }
    
    
    function getMarketsCount(ORMarketLib.MarketState marketState) external view returns(uint256 marketsInStateCount){
        (marketsInStateCount, ,) = _getMarketsCount(marketState);
    }
    
    function _getMarketsCount(ORMarketLib.MarketState marketState) internal view returns(uint256 marketsInStateCount, uint256 marketsCount, ORFPMarket[] memory fpMarkets){
        
        marketsCount = marketsController.getAllMarketsCount();
        fpMarkets = marketsController.getAllMarkets();
        for(uint256 marketIndex=0;marketIndex < marketsCount; marketIndex ++){
            if(fpMarkets[marketIndex].state() == marketState){
                marketsInStateCount++;
            }
        }

    }
    
    
    function getMarketCountByProposer(address account) external view returns(uint256 marketsByProposerCount){
        
        (marketsByProposerCount, , ) = _getMarketCountByProposer(account);
    }
    
    function _getMarketCountByProposer(address account) internal view returns(uint256 marketsByProposerCount, uint256 marketsCount, ORFPMarket[] memory fpMarkets){
        
        marketsCount = marketsController.getAllMarketsCount();
        fpMarkets = marketsController.getAllMarkets();
        
        marketsByProposerCount = 0;
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account){
                marketsByProposerCount++;
            }
        }
    }
    
    function getMarketCountByProposerNState(address account, ORMarketLib.MarketState marketState) external view returns(uint256 marketstByProposerNStateCount){
        
        (marketstByProposerNStateCount, ,) = _getMarketCountByProposerNState(account, marketState);
    }
    
    function _getMarketCountByProposerNState(address account, ORMarketLib.MarketState marketState) internal view returns(uint256 marketstByProposerNStateCount,uint256 marketsCount, ORFPMarket[] memory fpMarkets){
        
        marketsCount = marketsController.getAllMarketsCount();
        fpMarkets = marketsController.getAllMarkets();
        
        marketstByProposerNStateCount = 0;
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account && fpMarkets[marketIndex].state() == marketState){
                marketstByProposerNStateCount++;
            }
        }

    }
    
    ///////////////
    function getMarket(string memory marketQuestionID) public view returns(ORFPMarket  market){
        uint256 marketsCount = marketsController.getAllMarketsCount();
        ORFPMarket[] memory fpMarkets = marketsController.getAllMarkets();
        
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
             string memory mqID = fpMarkets[marketIndex].getMarketQuestionID();
             if(hashCompareWithLengthCheck(mqID,marketQuestionID) == true){
                 return fpMarkets[marketIndex];
             }
        }
    }
    
    
    function getMarkets(ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;
        uint256 marketsCount;
        ORFPMarket[] memory fpMarkets;
        
        if(length <0){
            uint256 mc;
            (mc, marketsCount, fpMarkets) = _getMarketsCount(marketState);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
            marketsCount = marketsController.getAllMarketsCount();
            fpMarkets = marketsController.getAllMarkets();
        }

        markets = new ORFPMarket[](uLength);
       
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }
    
    function getMarketsQuestionIDs(ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets,string[] memory questionsIDs){
        uint256 uLength;
        uint256 marketsCount;
        ORFPMarket[] memory fpMarkets;
        
        if(length <0){
            uint256 mc;
            (mc, marketsCount, fpMarkets) = _getMarketsCount(marketState);
            if(startIndex >= mc){
                return (markets,questionsIDs);
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
            marketsCount = marketsController.getAllMarketsCount();
            fpMarkets = marketsController.getAllMarkets();
        }

        markets = new ORFPMarket[](uLength);
        questionsIDs = new string[](uLength);
        
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return (markets,questionsIDs);
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                    questionsIDs[currentIndex] = fpMarkets[marketIndex].getMarketQuestionID();
                }
                marketInStateIndex++;
            }
        }

        return (markets,questionsIDs);
    }
    
    
    function getMarketsByProposer(address account, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;
        uint256 marketsCount;
        ORFPMarket[] memory fpMarkets;
        
        if(length <0){
            uint256 mc;
            (mc, marketsCount, fpMarkets) = _getMarketCountByProposer(account);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
            marketsCount = marketsController.getAllMarketsCount();
            fpMarkets = marketsController.getAllMarkets();
        }

        markets = new ORFPMarket[](uLength);
        
        
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }
    
    
    function getMarketsQuestionIDsByProposer(address account, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets,string[] memory questionsIDs){
        uint256 uLength;
        uint256 marketsCount;
        ORFPMarket[] memory fpMarkets;
        
        if(length <0){
            uint256 mc;
            (mc, marketsCount, fpMarkets) = _getMarketCountByProposer(account);
            if(startIndex >= mc){
                return  (markets,questionsIDs);
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
            marketsCount = marketsController.getAllMarketsCount();
            fpMarkets = marketsController.getAllMarkets();
        }

        markets = new ORFPMarket[](uLength);
        questionsIDs = new string[](uLength);
        
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return (markets,questionsIDs);
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                    questionsIDs[currentIndex] = fpMarkets[marketIndex].getMarketQuestionID();
                }
                marketInStateIndex++;
            }
        }

        return (markets,questionsIDs);
    }
    
    function getMarketsByProposerNState(address account, ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;
        uint256 marketsCount;
        ORFPMarket[] memory fpMarkets;

        if(length <0){
            uint256 mc;
            (mc, marketsCount, fpMarkets)= _getMarketCountByProposerNState(account,marketState);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
            marketsCount = marketsController.getAllMarketsCount();
            fpMarkets = marketsController.getAllMarkets();
        
        }

        markets = new ORFPMarket[](uLength);
        
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account && fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }
    
    
    function getMarketsQuestionIDsByProposerNState(address account, ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets,string[] memory questionsIDs){
        uint256 uLength;
        uint256 marketsCount;
        ORFPMarket[] memory fpMarkets;

        if(length <0){
            uint256 mc;
            (mc, marketsCount, fpMarkets)= _getMarketCountByProposerNState(account,marketState);
            if(startIndex >= mc){
                return(markets,questionsIDs);
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
            marketsCount = marketsController.getAllMarketsCount();
            fpMarkets = marketsController.getAllMarkets();
        
        }

        markets = new ORFPMarket[](uLength);
        questionsIDs = new string[](uLength);
        
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account && fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return (markets,questionsIDs);
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                    questionsIDs[currentIndex] = fpMarkets[marketIndex].getMarketQuestionID();
                }
                marketInStateIndex++;
            }
        }

        return (markets,questionsIDs);
    }
    
    function hashCompareWithLengthCheck(string memory a, string memory b) internal pure returns (bool) {
        bytes memory bytesA = bytes(a);
        bytes memory bytesB = bytes(b);

        if(bytesA.length != bytesB.length) {
            return false;
        } else {
            return keccak256(bytesA) == keccak256(bytesB);
        }
    }
}
