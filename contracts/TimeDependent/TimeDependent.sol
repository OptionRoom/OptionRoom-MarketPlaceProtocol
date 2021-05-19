pragma solidity ^0.5.0;

contract CentralTimeForTesting{

    uint256 ct = 1000000;
    function getCurrentTime() public view returns(uint256){
        return ct + timeIncreased;
    }

    
    uint256 public timeIncreased =0;
    function increaseTime(uint256 t) public {
        timeIncreased += t;
    }

  
}


contract TimeDependent{
    CentralTimeForTesting centralTimeForTesting = CentralTimeForTesting(0x3c4Fca7B5944A750C3EBF732dBf04591aCbb821d);

    function setCentralTimeForTesting(CentralTimeForTesting _centralTimeForTesting) public{
        centralTimeForTesting = _centralTimeForTesting;
    }
    
    function setCentralTimeAddressForTesting(address _centralTimeForTesting) public{
        centralTimeForTesting = CentralTimeForTesting(_centralTimeForTesting);
    }

    function getCurrentTime() public view returns(uint256){
        require(address(centralTimeForTesting) != address(0), "central time is not set");
        return centralTimeForTesting.getCurrentTime();
        //return block.timestamp;
    }

    function getCurrentTime1() public view returns(uint256){

        return block.timestamp;
    }
}
