pragma solidity ^0.5.0;

contract TimeDependent{
    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }
}