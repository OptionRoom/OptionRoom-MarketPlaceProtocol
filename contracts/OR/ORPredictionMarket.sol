pragma solidity ^0.5.1;

import "./FixedProductMarketMakerFactoryOR.sol";

contract ORPredictionMarket is FixedProductMarketMakerFactory {

    address public collateralToken = 0xB1B9C9AbE8CC193467b62F2E2a1Af98183049dB7;
    ConditionalTokens public ct = ConditionalTokens(0x6A6B973E3AF061dB947673801e859159F963C026);

    address governanceAdd;

    mapping(bytes32 => address) public proposalIds;

    constructor() public {
        crntTime = block.timestamp;
        governanceAdd = msg.sender;
    }

    /*
    function state(uint proposalId) public view returns (ORMarketLib.MarketProposalState) {
        if(proposalId > proposalCount || proposalId == 0){
            return ORMarketLib.MarketProposalState.Invalid;
        }

        // todo continue

    }
    */

    function createMarketProposal(string memory marketQuestionID, uint256 participationEndTime, uint256 resolvingEndTime) public {
        bytes32 questionId = bytes32(marketsCount);
        require(proposalIds[questionId] == address(0), "proposal Id already used");

        ct.prepareCondition(governanceAdd, questionId, 2);
        bytes32[]  memory conditionIds = new bytes32[](1);
        conditionIds[0] = ct.getConditionId(governanceAdd, questionId, 2);

        ORFPMarket fpMarket = createFixedProductMarketMaker(ct, IERC20(collateralToken), conditionIds, 20000000000000000);

        fpMarket.init2(marketQuestionID, msg.sender, getCurrentTime(), participationEndTime, resolvingEndTime, governanceAdd, questionId);

        proposalIds[questionId] = address(fpMarket);
    }

    modifier governance {
        require(msg.sender == governanceAdd);
        _;
    } 
     
    function getMarketsCount(ORFPMarket.MarketState marketState) public view returns(uint256){
        uint256 marketsInStateCount = 0;
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].state() == marketState){
                marketsInStateCount++;
            }
        }
        
        return marketsInStateCount;
    }
     
    function getMarkets(ORFPMarket.MarketState marketState, uint256 startIndx, uint256 length) public view returns(ORFPMarket[] memory markets){
        markets = new ORFPMarket[](length);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndx){
                    uint256 currentIndex = marketInStateIndex - startIndx;
                    if(currentIndex >=  length){
                        return markets;
                    }
                    
                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }
        
        return markets;
    }
    
    
   
    function getMarket(string memory marketQuestionID) public view returns(ORFPMarket  market){
     
        
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
             string memory mqID = fpMarkets[marketIndex].getMarketQuestionID(); 
             if(hashCompareWithLengthCheck(mqID,marketQuestionID) == true){
                 return fpMarkets[marketIndex]; 
             }
        }
    }
    
    function hashCompareWithLengthCheck(string memory a, string memory b) internal pure returns (bool) {
        bytes memory bytesA = bytes(a);
        bytes memory bytesB = bytes(b);
        
        if(bytesA.length != bytesB.length) { 
            return false;
        } else {
            return keccak256(bytesA) == keccak256(bytesB); 
        }
    }
}
