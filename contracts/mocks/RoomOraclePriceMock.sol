pragma solidity ^0.5.16;
import "../RewardCenter/IRoomOraclePrice.sol";
import "../Helpers/TransferHelper.sol";


contract RoomOraclePriceMock is IRoomOraclePrice {
    
    uint256 roomAmountValue = 1e18;
    uint256 usdAmountValue = 1000000;
    uint8 usdDecimalsValue = 6;

    address public ROOM_Address;

    function setValues(uint256 roomAmount, uint256 usdAmount, uint8 usdDecimals) public {
        roomAmountValue = roomAmount;
        usdAmountValue = usdAmount;
        usdDecimalsValue = usdDecimals;
    }
    
    function setROOM_Address(address newAddress) public {
        ROOM_Address = newAddress;
    }
    
    function getPrice() external view returns(uint256 roomAmount, uint256 usdAmount, uint8 usdDecimals){
        return (roomAmountValue,usdAmountValue,usdDecimalsValue);
    }

    function buyRoom(address tokenA, uint256 tokenAmount, uint256  minRoom, address to) external {
        TransferHelper.safeTransferFrom(IERC20(ROOM_Address), msg.sender, to, tokenAmount );
    }


    function getExpectedRoomByToken(address tokenA, uint256 amountTokenA) external view returns(uint256) {
        return 1e18;
    }

    function getExpectedTokenByRoom(address tokenA, uint256 roomAmount) external view returns(uint256) {
        return 1e18;
    }
}
