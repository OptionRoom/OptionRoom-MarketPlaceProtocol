pragma solidity ^0.5.1;
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IRoomOraclePrice{
    function getPrice() external view returns(uint256 roomAmount, uint256 usdAmount, uint8 usdDecimals);
    function getExpectedRoomByToken(address tokenA, uint256 amountTokenA) external view returns(uint256);
    function buyRoom(address tokenA, uint256 amountTokenA, uint256  minRoom, address to) external;
}

contract RoomOraclePriceDummy is IRoomOraclePrice{
    
    address roomDemoAddress;
    
    function getPrice() external view returns(uint256 roomAmount, uint256 usdAmount, uint8 usdDecimals){
        roomAmount = 1e18;
        usdAmount = 1250000000000000000;
        usdDecimals = 18;
        
        return (roomAmount,usdAmount,usdDecimals);
    }
    
    
    function getExpectedRoomByToken(address , uint256 amountTokenA) external view returns(uint256){
        
        return  amountTokenA * 1e18 / 1250000000000000000;
    }
    
    function buyRoom(address tokenA, uint256 amountTokenA, uint256  minRoom, address to) external{
        
        uint256 expectedAmount = amountTokenA * 1e18 / 1250000000000000000;
        
        require(expectedAmount >= minRoom, "expectedAmount < minRoom");
        
        IERC20(roomDemoAddress).transfer(to,expectedAmount);
        IERC20(tokenA).transferFrom(msg.sender,address(this),amountTokenA);
    }
    
    function setRoomAddress(address roomAddres) public{
        roomDemoAddress = roomAddres;
    }
}