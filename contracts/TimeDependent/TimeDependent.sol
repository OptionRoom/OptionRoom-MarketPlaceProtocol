pragma solidity ^0.5.0;

contract CentralTimeForTesting{

    uint256 crt = 1000000;
    function getCurrentTime() public view returns(uint256){
        return crt ;
    }

    

    function increaseTime(uint256 t) public {
        crt += t;
    }

   

    function setTime(uint256 t) public {
        crt = t;
    }

    
}


contract TimeDependent{
    CentralTimeForTesting centralTimeForTesting = CentralTimeForTesting(0x8665FCdb7616e14ab017b63F438fbC42fdc1A7Be);

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
