pragma solidity ^0.5.0;

contract CentralTimeForTesting{
    
    uint256 ct ;
    function getCurrentTime() public view returns(uint256){
        return ct + timeIncrease;
    }
    
    uint256 timeIncrease;

    function increaseTime(uint256 t) public {
        timeIncrease += t;
    }

    function resetTimeIncrease() public {
        timeIncrease = 0;
    }
    
}


contract TimeDependent{
    CentralTimeForTesting centralTimeForTesting = CentralTimeForTesting(0x3c4Fca7B5944A750C3EBF732dBf04591aCbb821d);
    
    function setCentralTimeForTesting(CentralTimeForTesting _centralTimeForTesting) public{
        centralTimeForTesting = _centralTimeForTesting;
    }
    
    function getCurrentTime1() public view returns(uint256){
        require(address(centralTimeForTesting) != address(0), "central time is not set");
        return centralTimeForTesting.getCurrentTime();
        //return block.timestamp;
    }
    
    function getCurrentTime() public view returns(uint256){
       
        return block.timestamp;
    }
}