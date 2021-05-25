pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

import '../OR/ORMarketController.sol';

contract PredictionMarketFactoryMock is ORMarketController {

    address public collateralToken;

    function conditionalTokens111() external view returns (ConditionalTokens) {
        return ct;
    }

    function assign(address ddd) public {
        ct = ConditionalTokens(ddd);
    }

    function assignGovernanceContract(address governanceAddAssign) public {
        setIORGoverner(governanceAddAssign);
    }

    function assignCollateralTokenAddress(address collateralTokenAddress) public {
        collateralToken = collateralTokenAddress;
    }

    function createMarketProposalTest(string memory marketQuestionID, uint256 participationEndTime, uint256 resolvingEndTime,
        uint fees) public returns (ORFPMarket) {

        require(allowedCollaterals[address(collateralToken)] == true, "Collateral token is not allowed");

        roomToken.safeTransferFrom(msg.sender, rewardCenterAddress ,marketCreationFees);
        bytes32 questionId = bytes32(marketsCount);
        require(proposalIds[questionId] == address(0), "proposal Id already used");
        ct.prepareCondition(address(this), questionId, 2);
        bytes32[]  memory conditionIds = new bytes32[](1);
        conditionIds[0] = ct.getConditionId(address(this), questionId, 2);
        //ORMarketController marketController =  ORMarketController(governanceAdd);

        ORFPMarket fpMarket = createFixedProductMarketMaker(ct, IERC20( collateralToken ), conditionIds, feeMarketLP, FeeProposer, msg.sender, roomOracleAddress);
        fpMarket.setConfig(marketQuestionID, address(this), questionId);
        addMarket(address(fpMarket),getCurrentTime(), participationEndTime, resolvingEndTime);

        proposalIds[questionId] = address(fpMarket);

        RP.addMarket(address(fpMarket));
        
        return fpMarket;
    }

    function getAddressPenalties(address account) public view returns(address[] memory)  {
        return marketsVotedPerUser[account];
    }
}
