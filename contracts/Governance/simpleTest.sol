pragma solidity ^0.5.16;

contract simpleTest{
    
    function get1abiencode(uint256 _a) public pure returns(bytes memory){
        return abi.encode(_a);
    }
    
    function get2abiencode(uint256 _a, bool _b, int256 _c) public pure returns(bytes memory){
        return abi.encode(_a,_b,_c);
    }
    
   
    
    
    function justToTest(address target, string memory signature, bytes memory data) public{
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
       
        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(0)(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");
    }
}


contract targetTest{
    
    bool  public test1Flag;
    uint256 public aa;
    bool public bb;
    int256 public cc;
    
    // test1()
    function test1() public{
       test1Flag = true;
    }
    
    
    // setAA(uint256)
    function setAA(uint256 _a) public {
        aa = _a;
    }
    
    // setAAandBB(uint256,bool,int256)
    function setAAandBB(uint256 _a, bool _b, int256 _c)public {
        aa = _a;
        bb= _b;
        cc = _c;
    }
}