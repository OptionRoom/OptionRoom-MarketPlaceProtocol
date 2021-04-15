import '../OR/ORPredictionMarket.sol';

contract PredictionMarketFactoryMock is ORPredictionMarket {

    function conditionalTokens111() external view returns (ConditionalTokens) {
        return ct;
    }

    function assign(address ddd) public {
        ct = ConditionalTokens(ddd);
    }

    function assignCollateralTokenAddress(address collateralTokenAddress) public {
        collateralToken = collateralTokenAddress;
    }

    // Override this method to do the same as before at the
    // return value.
    function createMarketProposalTest(string memory marketQuestion,
            uint256 participationEndTime,
            uint256 resolvingPeriodInDays,
            uint fees) public returns (ORFPMarket) {
        bytes32 questionId = bytes32(marketsCount);
        require(proposalIds[questionId] == address(0),"proposal Id already used");


        ct.prepareCondition(governanceAdd, questionId, 2);
        bytes32[]  memory conditionIds = new bytes32[](1);
        conditionIds[0] = ct.getConditionId(governanceAdd, questionId, 2);

        ORFPMarket fpMarket = createFixedProductMarketMaker(ct,IERC20(collateralToken),conditionIds,fees);

        fpMarket.init2(marketQuestion,msg.sender,getCurrentTime(),participationEndTime,resolvingPeriodInDays * 86400,governanceAdd,questionId);

        proposalIds[questionId] = address(fpMarket);

        return fpMarket;
    }

    function getCurrentMarketQuestionId() external view returns (bytes32) {
        return bytes32(marketsCount);
    }
}
