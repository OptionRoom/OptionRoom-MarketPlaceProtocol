pragma solidity ^0.5.1;

import "./ORMarketLib.sol";
import "./FixedProductMarketMakerOR.sol";
import "../Governance/IORMarketGovernor.sol";

/**
    @title ORFPMarket Extended version of the FixedProductMarketMaker
*/
contract ORFPMarket is FixedProductMarketMaker {

    address public proposer;
    bytes32 public questionId;

    uint256 public minShareLiq;
    
    bool private initializationPhase2;

    string public marketQuestionID;
    
    IORGovernor public ORGovernor;


    function setConfig(
            string memory _marketQuestionID,
            address _proposer,
            address _governor,
            uint256 _marketCreatedTime,
            uint256 _marketParticipationEndTime,
            uint256 _marketResolvingEndTime,
            bytes32 _questionId
    ) public {
        require(initializationPhase2 == false, "Initialization already called");
        initializationPhase2 = true;
        ORGovernor = IORGovernor(_governor);
        marketQuestionID = _marketQuestionID;
        proposer = _proposer;
        questionId = _questionId;
        
        minShareLiq = ORGovernor.addMarket(_marketCreatedTime,_marketParticipationEndTime,_marketResolvingEndTime);
    }

    function _beforeBuy() internal {
        require(state() == ORMarketLib.MarketState.Active, "Market is not in active state");
    }

    function _beforeSell() internal {
        require(state() == ORMarketLib.MarketState.Active, "Market is not in active state");
    }

     function state() public view returns (ORMarketLib.MarketState) {
         return ORGovernor.state(address(this));
     }

    function addLiquidity(uint256 amount) public {
        uint[] memory distributionHint;
        if (totalSupply() > 0) {
            addFunding(amount, distributionHint);
        } else {
            distributionHint = new uint[](2);
            distributionHint[0] = 1;
            distributionHint[1] = 1;
            addFunding(amount, distributionHint);
        }
    }

    function removeLiquidity(uint256 shares, bool autoMerge) public {
        removeFunding(shares);
        if(autoMerge == true){
            merge();
        }
    }

    function merge() public {
        uint[] memory balances = getBalances(msg.sender);
        uint minBalance = balances[0];
        for (uint256 i = 0; i < balances.length; i++) {
            if (balances[i] < minBalance) {
                minBalance = balances[i];
            }
        }

        uint[] memory sendAmounts = new uint[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            sendAmounts[i] = minBalance;
        }

        conditionalTokens.safeBatchTransferFrom(msg.sender, address(this), positionIds, sendAmounts, "");
        mergePositionsThroughAllConditions(minBalance);

        require(collateralToken.transfer(msg.sender, minBalance), "return transfer failed");
    }

    function getPercentage() public view returns (uint256[] memory percentage) {
        percentage = new uint256[](2);
        uint256[] memory balances = getPoolBalances();
        uint256 totalBalances = balances[0] + balances[1] ;
        if(totalBalances == 0){
            percentage[0] = 500000 ;
            percentage[1] = 500000 ;

        }else{
            percentage[0] = balances[1] * 1000000 / totalBalances;
            percentage[1] = balances[0] * 1000000 / totalBalances;

        }
    }

    function getPositionIds() public view returns (uint256[] memory) {
        return positionIds;
    }

    

    function getMarketQuestionID() public view returns(string memory){
        return marketQuestionID;
    }
    
    
    function getConditionalTokenAddress() public view returns(address){
        return address(conditionalTokens);
    }


    function _beforeRemoveFunding(uint sharesToBurn) internal {
        if(msg.sender == proposer) {
            ORMarketLib.MarketState marketState = state();
            if(marketState == ORMarketLib.MarketState.Pending || marketState == ORMarketLib.MarketState.Active){
                require(balanceOf(msg.sender).sub(sharesToBurn) >= minShareLiq, "The remaining shares dropped under the minimum");
            }
        }
    }

    function getSharesPercentage(address account) public view returns(uint256) {
        return balanceOf(account) * 100 * 10000 / totalSupply();
    }
    
    function getIndexSet() public pure returns (uint256[] memory indexSet) {
        indexSet = new uint256[](2);
        indexSet[0] = 1;
        indexSet[1] = 2;
    }
   
    function getCurrentTime() public view returns (uint256) {
         return block.timestamp;
     }
     
     

}

//TODO just for testing remove them
contract  ORFPMarketFotTest{
    uint256 timeIncrease;

    function increaseTime(uint256 t) public {
        timeIncrease += t;
    }

    function resetTimeIncrease() public {
        timeIncrease = 0;
    }

    function getCurrentTime() public view returns (uint256) {
        //TODO
        //return block.timestamp;
        return block.timestamp + timeIncrease;
    }
}
