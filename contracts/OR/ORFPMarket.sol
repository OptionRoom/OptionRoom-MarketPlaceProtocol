pragma solidity ^0.5.1;
import "./ORMarketLib.sol";
import "./FixedProductMarketMakerOR.sol";


contract ORFPMarket is FixedProductMarketMaker{
    
    address public proposer;
    uint256 public createdTime;
    uint256 public approveVotesCount;
    uint256 public rejectVotesCount;
    uint256 public participationEndTime;
    uint256 public settelingPeriod;
    address public governenceAdd;
    
    bool initedPhase2;
    
    function init2( address _proposer,uint256 _createdTime, uint256 _participationEndTime, uint256 _settelingPeriod, address _governenceAdd) public{
        require(initedPhase2 == false, "init2 already called");
        initedPhase2 = true;
        proposer= _proposer;
        createdTime = _createdTime;
        participationEndTime = _participationEndTime;
        settelingPeriod = _settelingPeriod;
        governenceAdd= _governenceAdd;
    }
}
