pragma solidity ^0.5.1;
import {IERC20} from "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IRewardCenter {
    
    function sendRoomReward(address beneficiary, uint256 amount, string calldata comment) external;
    
    function sendRoomRewardByERC20Value(address beneficiary, uint256 amount, IERC20 erc20, string calldata comment) external;
    
}
