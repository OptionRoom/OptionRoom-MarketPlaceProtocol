pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;
import "./ORMarketController.sol";
import "../Guardian/GnGOwnable.sol";

contract ORMarketsQuery is GnGOwnable{
    ORMarketController  marketsController;
    
    function setMarketsController(address marketController) public onlyGovOrGur{
        marketsController = ORMarketController(marketController);
    }
    
    
    function getMarketsCount(ORMarketLib.MarketState marketState) external view returns(uint256 marketsInStateCount){
        (marketsInStateCount, ,) = _getMarketsCount(marketState);
    }
    
    function _getMarketsCount(ORMarketLib.MarketState marketState) internal view returns(uint256 marketsInStateCount, uint256 marketsCount, ORFPMarket[] memory fpMarkets){
        
        marketsCount = marketsController.getAllMarketsCount();
        fpMarkets = marketsController.getAllMarkets();
        for(uint256 marketIndex=0;marketIndex < marketsCount; marketIndex ++){
            if(fpMarkets[marketIndex].state() == marketState){
                marketsInStateCount++;
            }
        }

    }
    
    
    function getMarketCountByProposer(address account) external view returns(uint256 marketsByProposerCount){
        
        (marketsByProposerCount, , ) = _getMarketCountByProposer(account);
    }
    
    function _getMarketCountByProposer(address account) internal view returns(uint256 marketsByProposerCount, uint256 marketsCount, ORFPMarket[] memory fpMarkets){
        
        marketsCount = marketsController.getAllMarketsCount();
        fpMarkets = marketsController.getAllMarkets();
        
        marketsByProposerCount = 0;
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account){
                marketsByProposerCount++;
            }
        }
    }
    
    function getMarketCountByProposerNState(address account, ORMarketLib.MarketState marketState) external view returns(uint256 marketstByProposerNStateCount){
        
        (marketstByProposerNStateCount, ,) = _getMarketCountByProposerNState(account, marketState);
    }
    
    function _getMarketCountByProposerNState(address account, ORMarketLib.MarketState marketState) internal view returns(uint256 marketstByProposerNStateCount,uint256 marketsCount, ORFPMarket[] memory fpMarkets){
        
        marketsCount = marketsController.getAllMarketsCount();
        fpMarkets = marketsController.getAllMarkets();
        
        marketstByProposerNStateCount = 0;
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account && fpMarkets[marketIndex].state() == marketState){
                marketstByProposerNStateCount++;
            }
        }

    }
    
    function getMarketCountByTrader(address trader) external view returns(uint256 marketsCountByTrader){
        
        (marketsCountByTrader, , ) = _getMarketCountByTrader(trader);
    }
    
    function _getMarketCountByTrader(address trader) internal view returns(uint256 marketsCountByTrader, uint256 marketsCount, ORFPMarket[] memory fpMarkets){
        
        marketsCount = marketsController.getAllMarketsCount();
        fpMarkets = marketsController.getAllMarkets();
        
        marketsCountByTrader = 0;
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].traders(trader) == true){
                marketsCountByTrader++;
            }
        }
    }
    
    
    function getMarketCountByTraderNState(address trader, ORMarketLib.MarketState marketState) external view returns(uint256 marketCountByTraderNState){
        
        (marketCountByTraderNState, ,) = _getMarketCountByTraderNState(trader, marketState);
    }
    
    function _getMarketCountByTraderNState(address trader, ORMarketLib.MarketState marketState) internal view returns(uint256 marketCountByTraderNState, uint256 marketsCount, ORFPMarket[] memory fpMarkets){
        
        marketsCount = marketsController.getAllMarketsCount();
        fpMarkets = marketsController.getAllMarkets();
        
        marketCountByTraderNState = 0;
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].traders(trader) == true && fpMarkets[marketIndex].state() == marketState){
                marketCountByTraderNState++;
            }
        }

    }
    
    ///////////////
    function getMarket(string memory marketQuestionID) public view returns(ORFPMarket  market){
        uint256 marketsCount = marketsController.getAllMarketsCount();
        ORFPMarket[] memory fpMarkets = marketsController.getAllMarkets();
        
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
             string memory mqID = fpMarkets[marketIndex].getMarketQuestionID();
             if(hashCompareWithLengthCheck(mqID,marketQuestionID) == true){
                 return fpMarkets[marketIndex];
             }
        }
    }
    
    
    function getMarkets(ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;
        uint256 marketsCount;
        ORFPMarket[] memory fpMarkets;
        
        if(length <0){
            uint256 mc;
            (mc, marketsCount, fpMarkets) = _getMarketsCount(marketState);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
            marketsCount = marketsController.getAllMarketsCount();
            fpMarkets = marketsController.getAllMarkets();
        }

        markets = new ORFPMarket[](uLength);
       
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }
    
    function getMarketsQuestionIDs(ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets,string[] memory questionsIDs){
        uint256 uLength;
        uint256 marketsCount;
        ORFPMarket[] memory fpMarkets;
        
        if(length <0){
            uint256 mc;
            (mc, marketsCount, fpMarkets) = _getMarketsCount(marketState);
            if(startIndex >= mc){
                return (markets,questionsIDs);
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
            marketsCount = marketsController.getAllMarketsCount();
            fpMarkets = marketsController.getAllMarkets();
        }

        markets = new ORFPMarket[](uLength);
        questionsIDs = new string[](uLength);
        
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return (markets,questionsIDs);
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                    questionsIDs[currentIndex] = fpMarkets[marketIndex].getMarketQuestionID();
                }
                marketInStateIndex++;
            }
        }

        return (markets,questionsIDs);
    }
    
    
    function getMarketsByProposer(address account, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;
        uint256 marketsCount;
        ORFPMarket[] memory fpMarkets;
        
        if(length <0){
            uint256 mc;
            (mc, marketsCount, fpMarkets) = _getMarketCountByProposer(account);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
            marketsCount = marketsController.getAllMarketsCount();
            fpMarkets = marketsController.getAllMarkets();
        }

        markets = new ORFPMarket[](uLength);
        
        
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }
    
    
    function getMarketsQuestionIDsByProposer(address account, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets,string[] memory questionsIDs){
        uint256 uLength;
        uint256 marketsCount;
        ORFPMarket[] memory fpMarkets;
        
        if(length <0){
            uint256 mc;
            (mc, marketsCount, fpMarkets) = _getMarketCountByProposer(account);
            if(startIndex >= mc){
                return  (markets,questionsIDs);
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
            marketsCount = marketsController.getAllMarketsCount();
            fpMarkets = marketsController.getAllMarkets();
        }

        markets = new ORFPMarket[](uLength);
        questionsIDs = new string[](uLength);
        
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return (markets,questionsIDs);
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                    questionsIDs[currentIndex] = fpMarkets[marketIndex].getMarketQuestionID();
                }
                marketInStateIndex++;
            }
        }

        return (markets,questionsIDs);
    }
    
    function getMarketsByProposerNState(address account, ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;
        uint256 marketsCount;
        ORFPMarket[] memory fpMarkets;

        if(length <0){
            uint256 mc;
            (mc, marketsCount, fpMarkets)= _getMarketCountByProposerNState(account,marketState);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
            marketsCount = marketsController.getAllMarketsCount();
            fpMarkets = marketsController.getAllMarkets();
        
        }

        markets = new ORFPMarket[](uLength);
        
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account && fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }
    
    
    function getMarketsQuestionIDsByProposerNState(address account, ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets,string[] memory questionsIDs){
        uint256 uLength;
        uint256 marketsCount;
        ORFPMarket[] memory fpMarkets;

        if(length <0){
            uint256 mc;
            (mc, marketsCount, fpMarkets)= _getMarketCountByProposerNState(account,marketState);
            if(startIndex >= mc){
                return(markets,questionsIDs);
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
            marketsCount = marketsController.getAllMarketsCount();
            fpMarkets = marketsController.getAllMarkets();
        
        }

        markets = new ORFPMarket[](uLength);
        questionsIDs = new string[](uLength);
        
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account && fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return (markets,questionsIDs);
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                    questionsIDs[currentIndex] = fpMarkets[marketIndex].getMarketQuestionID();
                }
                marketInStateIndex++;
            }
        }

        return (markets,questionsIDs);
    }
    
    function getMarketsByTrader(address trader, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;
        uint256 marketsCount;
        ORFPMarket[] memory fpMarkets;

        if(length <0){
            uint256 mc;
            (mc, marketsCount, fpMarkets) = _getMarketCountByTrader(trader);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
            marketsCount = marketsController.getAllMarketsCount();
            fpMarkets = marketsController.getAllMarkets();
        }

        markets = new ORFPMarket[](uLength);
        
        
        
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].traders(trader) == true){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }
    
    
    function getMarketsByTraderNState(address trader, ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;
        uint256 marketsCount;
        ORFPMarket[] memory fpMarkets;

        if(length <0){
            uint256 mc;
            (mc, marketsCount, fpMarkets)= _getMarketCountByTraderNState(trader,marketState);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
            marketsCount = marketsController.getAllMarketsCount();
            fpMarkets = marketsController.getAllMarkets();
        }

        markets = new ORFPMarket[](uLength);
        
        
        
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].traders(trader) == true && fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }
    
    
    function getMarketsQuestionIDsByTraderNState(address trader, ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets,string[] memory questionsIDs){
        uint256 uLength;
        uint256 marketsCount;
        ORFPMarket[] memory fpMarkets;

        if(length <0){
            uint256 mc;
            (mc, marketsCount, fpMarkets)= _getMarketCountByTraderNState(trader,marketState);
            if(startIndex >= mc){
                return(markets,questionsIDs);
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
            marketsCount = marketsController.getAllMarketsCount();
            fpMarkets = marketsController.getAllMarkets();
        }

        markets = new ORFPMarket[](uLength);
        questionsIDs = new string[](uLength);
        
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].traders(trader) == true && fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return (markets,questionsIDs);
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                    questionsIDs[currentIndex] = fpMarkets[marketIndex].getMarketQuestionID();
                }
                marketInStateIndex++;
            }
        }

        return (markets,questionsIDs);
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
