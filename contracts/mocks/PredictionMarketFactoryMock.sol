pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

import '../OR/ORMarketController.sol';

contract PredictionMarketFactoryMock is ORMarketController {

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
        setIORGoverner(governanceAddAssign);
    }

    function assignCollateralTokenAddress(address collateralTokenAddress) public {
        collateralToken = collateralTokenAddress;
    }

//    function createMarketProposalWithCollateralTest(string memory marketQuestionID, uint256 participationEndTime, uint256 resolvingEndTime, uint256 initialLiq,
//        uint fees) public {
//        bytes32 questionId = bytes32(marketsCount);
//        require(proposalIds[questionId] == address(0), "proposal Id already used");
//
//        ct.prepareCondition(address(this), questionId, 2);
//        bytes32[]  memory conditionIds = new bytes32[](1);
//        conditionIds[0] = ct.getConditionId(address(this), questionId, 2);
//        //ORMarketController marketController =  ORMarketController(governanceAdd);
//
//        ORFPMarket fpMarket = createFixedProductMarketMaker(ct, IERC20( collateralToken ), conditionIds, marketFee);
//        fpMarket.setConfig(marketQuestionID, msg.sender, address(this), marketMinShareLiq ,questionId);
//        addMarket(address(fpMarket),getCurrentTime(), participationEndTime, resolvingEndTime);
//
//        proposalIds[questionId] = address(fpMarket);
//
//        marketAddLiquidity(address(fpMarket),initialLiq);
//        //TODO: check collateralToken is from the list
//    }

    function createMarketProposalTest(string memory marketQuestionID, uint256 participationEndTime, uint256 resolvingEndTime,
        uint fees) public returns (ORFPMarket) {
        bytes32 questionId = bytes32(marketsCount);
        require(proposalIds[questionId] == address(0), "proposal Id already used");

        ct.prepareCondition(address(this), questionId, 2);
        bytes32[]  memory conditionIds = new bytes32[](1);
        conditionIds[0] = ct.getConditionId(address(this), questionId, 2);
        
        ORFPMarket fpMarket = createFixedProductMarketMaker(ct,IERC20( collateralToken ), conditionIds, marketFee);
        fpMarket.setConfig(marketQuestionID, msg.sender, address(this), marketMinShareLiq ,questionId);
        addMarket(address(fpMarket),getCurrentTime(), participationEndTime, resolvingEndTime);

        proposalIds[questionId] = address(fpMarket);
        
        return fpMarket;
    }
    

    function getCurrentMarketQuestionId() external view returns (bytes32) {
        return bytes32(marketsCount);
    }
}
