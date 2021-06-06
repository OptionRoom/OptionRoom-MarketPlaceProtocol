// File: contracts\RewardCenter\RoomOraclePrice.sol

pragma solidity ^0.6.1;

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
    
    
    function transfeerGuardian(address newGuardianAddress) public onlyGovOrGur {
        emit GuardianTransferred(guardianAddress, newGuardianAddress);
        guardianAddress = newGuardianAddress;
    }
    
    function transfeerGovernor(address newGovernorAddress) public onlyGovOrGur {
        emit GuardianTransferred(governorAddress, newGovernorAddress);
        governorAddress = newGovernorAddress;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    function pairFor(address tokenA, address tokenB) external view returns (address pair);

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB) external view returns (uint reserveA, uint reserveB);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

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

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}



contract RoomOraclePrice  is GnGOwnable{
    
    address public WBNB_Address = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public ROOM_Address = 0xAd4f86a25bbc20FfB751f2FAC312A0B4d8F88c64;
    
    IUniswapV2Router02 public routerV2 = IUniswapV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    
    address public BUSD_Address = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    uint8 public USDdecimals = 18;
    
    uint256 public roomAvgPrice = 1e18;
    
    mapping(address => bool) hasUpdatePricePermission;
    
    event PriceUpdated(address account, uint256 roomAmount, uint256 usdAmount, uint8 decimals);
    
    function setWBNB_Address(address newAddress) public onlyGovOrGur {
        WBNB_Address = newAddress;
    }
    
    function setROOM_Address(address newAddress) public onlyGovOrGur {
        ROOM_Address = newAddress;
    }
    
    function setBUSD_Address(address newAddress, uint8 decimals) public onlyGovOrGur{
        BUSD_Address = newAddress;
        USDdecimals = decimals;
    }
    
    function setRouter(address newAddress) public onlyGovOrGur{
        routerV2 = IUniswapV2Router02(newAddress);
    }
    
    // updateRoomPrice: to set the room avg price , planed to be called dailly at 12:00 AM GMT based on previous day or week avg price
    function updateRoomPrice(uint256 roomPrice, uint8 decimals) public{
        require(hasUpdatePricePermission[msg.sender] == true, "caller has no permission to update rom price");
        roomAvgPrice = roomPrice;
        USDdecimals = decimals;
        
        emit PriceUpdated(msg.sender, 1e18, roomAvgPrice, USDdecimals);
    }
    
    
    // used to get the avarge price for Room, which will be used by rewrd center to determine how much room will be sent based on Reward
    function getPrice() external view returns(uint256 roomAmount, uint256 usdAmount, uint8 decimals){
       roomAmount = 1e18;
       usdAmount = roomAvgPrice;
       decimals = USDdecimals;
    }
   
    // getExpectedRoomByToken: used to display how much room will be get from Uniswap/bancake agains tokaneA amount
    function getExpectedRoomByToken(address tokenA, uint256 tokenAmount) external view returns(uint256){
        address[] memory path = new address[](3);
        path[0] = tokenA;
        path[1] = WBNB_Address;
        path[2] = ROOM_Address;
        
        uint[] memory amounts = routerV2.getAmountsOut(tokenAmount,path);
        
        return amounts[2];
    }
    
    
    
    function getExpectedTokenByRoom(address tokenA, uint256 roomAmount) external view returns(uint256) {
        
        address[] memory path = new address[](3);
        path[0] = ROOM_Address;
        path[1] = WBNB_Address;
        path[2] = tokenA;
        
        uint[] memory amounts = routerV2.getAmountsOut(roomAmount,path);
        
        return amounts[2];
    }
    
    function buyRoom(address tokenA, uint256 tokenAmount, uint256  minRoom, address to) external {
        
        if(tokenA == ROOM_Address){
            TransferHelper.safeTransferFrom(tokenA, msg.sender, to, tokenAmount );
            return;
        }
        
        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), tokenAmount );
        TransferHelper.safeApprove(tokenA, address(routerV2), tokenAmount);
        
        address[] memory path = new address[](3);
        path[0] = tokenA;
        path[1] = WBNB_Address;
        path[2] = ROOM_Address;
        
        routerV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount,minRoom,path,to, block.timestamp);
    }
    
    function setUpdatePricePermission(address account, bool permissionFlag) public onlyGovOrGur{
        hasUpdatePricePermission[account] = permissionFlag;
    }
    
    
}
