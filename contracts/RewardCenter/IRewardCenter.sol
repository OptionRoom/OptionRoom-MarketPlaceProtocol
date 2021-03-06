pragma solidity ^0.5.16;
import {IERC20} from "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

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
