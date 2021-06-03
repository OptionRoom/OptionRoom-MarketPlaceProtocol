pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../Governance/ORGovernor.sol";
import "./CourtStakeMock.sol";

contract ORGovernanceMock is ORGovernor {
    
    CourtStakeDummy dummy;

    function setCourtStake(address courtStakeAddress) public onlyGovOrGur{
        courtStake = ICourtStake(courtStakeAddress);
        dummy = CourtStakeDummy(courtStakeAddress);
    }
    
    function getSuspendReason(address account) external view returns(string memory reason){
        "Testing suspension";
    }
    
    function setPower(address account, uint256 power) public {
        dummy.setUserPower(account, power);
    }
}
