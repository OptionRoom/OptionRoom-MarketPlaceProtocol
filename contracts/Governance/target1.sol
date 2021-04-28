pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;
import "./Timelock.sol";
import "./GovernorAlpha.sol";


contract AA0{
    
    uint256 aa;
    function actToIncreasBlockNumber() public{
        aa+=1;
    }
    function getblocknumber() public view returns(uint256){
        return block.number;
    }
}

contract AA1TimeLock is Timelock{
    constructor() Timelock(msg.sender,1) public{
        
    }
}

contract AA2CompDummy{
    function getPriorVotes(address account, uint blockNumber) public pure returns (uint96){
        bool a;
        if(a){
            account = address(0);
            blockNumber =0;
        }
        return 100;
    }
}


contract AA3Governor is GovernorAlpha{
    
    address a1 = 0xB63976A2cbC28C8fb8E804D6f3753A9C775111E6;
    address a2 = 0x38a4934145FBD547a4Adb7468e3E536101adFA6b;
    constructor() GovernorAlpha(a1,a2,msg.sender) public{
        
    }
    
}


contract AA4TargetDummy{
    bool  public test1Flag;
    
    // test1()
    function test1() public{
       test1Flag = true;
    }
    
    uint256 public aa;
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
    
    
    function get1abiencode(uint256 _a) public pure returns(bytes memory){
        return abi.encode(_a);
    }
    
    function get2abiencode(uint256 _a, bool _b, int256 _c) public pure returns(bytes memory){
        return abi.encode(_a,_b,_c);
    }
    
    int256 public cc;
    bool public bb;
    
    
    
    function justToTest(string memory signature, bytes memory data) public{
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        address target = address(this);
        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(0)(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");
    }
}

