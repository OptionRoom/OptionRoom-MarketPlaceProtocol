pragma experimental ABIEncoderV2;
import '../OR/ORPredictionMarket.sol';

contract PredictionMarketFactoryMock is ORPredictionMarket {

    address public collateralToken;

    struct tokenBalance {
        address holder;
        uint yesBalance;
        uint noBalance;
    }

    struct accountBalance {
        address account;
        uint256 balance;
    }

    function conditionalTokens111() external view returns (ConditionalTokens) {
        return ct;
    }

    function assign(address ddd) public {
        ct = ConditionalTokens(ddd);
    }

    function assignGovernanceContract(address governanceAddAssign) public {
        governanceAdd = governanceAddAssign;
    }

    function assignCollateralTokenAddress(address collateralTokenAddress) public {
        collateralToken = collateralTokenAddress;
    }

    function createMarketProposalWithCollateralTest(string memory marketQuestionID, uint256 participationEndTime, uint256 resolvingEndTime, IERC20 collateralToken, uint256 initialLiq,
        uint fees) public {
        bytes32 questionId = bytes32(marketsCount);
        require(proposalIds[questionId] == address(0), "proposal Id already used");

        ct.prepareCondition(governanceAdd, questionId, 2);
        bytes32[]  memory conditionIds = new bytes32[](1);
        conditionIds[0] = ct.getConditionId(governanceAdd, questionId, 2);
        ORMarketController marketController =  ORMarketController(governanceAdd);

        ORFPMarket fpMarket = createFixedProductMarketMaker(ct, collateralToken, conditionIds, marketController.marketFee());
        fpMarket.setConfig(marketQuestionID, msg.sender, governanceAdd, marketController.marketMinShareLiq() ,questionId);
        marketController.addMarket(address(fpMarket),getCurrentTime(), participationEndTime, resolvingEndTime);

        proposalIds[questionId] = address(fpMarket);

        marketAddLiquidity(address(fpMarket),initialLiq);
        //TODO: check collateralToken is from the list
    }

    function getCurrentMarketQuestionId() external view returns (bytes32) {
        return bytes32(marketsCount);
    }
}
