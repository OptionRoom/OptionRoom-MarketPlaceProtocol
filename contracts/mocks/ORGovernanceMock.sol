pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

import "../Governance/ORGovernor.sol";

contract ORGovernanceMock is DummyORGovernor {

    function getAccountInfo(address account) external returns(bool governorFlag, bool suspendedFlag, uint256 power){
        // Mocking this.
        power = powerPerUser[account];
        governorFlag = true;
        suspendedFlag = false;
    }
    
    function getSuspendReason(address account) external returns(string memory reason){
        // Mocking this.
        "Testing suspension";
    }
}
