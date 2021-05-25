pragma solidity ^0.5.1;

import "./ORMarketLib.sol";
import "./FixedProductMarketMakerOR.sol";
import "../OR/IORMarketController.sol";
import {TransferHelper} from "../Helpers/TransferHelper.sol";

/**
    @title ORFPMarket Extended version of the FixedProductMarketMaker
*/
contract ORFPMarket is FixedProductMarketMaker {
    using TransferHelper for IERC20;
    

    
    bytes32 public questionId;


    bool private initializationPhase2;

    string public marketQuestionID;
    
    IORMarketController public marketController;
    
    mapping(address => bool) public traders;

    function setConfig(
            string memory _marketQuestionID,
            address _controller,
            bytes32 _questionId
    ) public {
        require(initializationPhase2 == false, "Initialization already called");
        initializationPhase2 = true;
        marketController = IORMarketController(_controller);
        marketQuestionID = _marketQuestionID;
        questionId = _questionId;
    }
    
    

    
    function addLiquidityTo(address beneficiary, uint256 amount) public returns(uint) {
        uint shares;
        uint[] memory distributionHint;
        if (totalSupply() > 0) {
            shares = addFundingTo(beneficiary,amount, distributionHint);
        } else {
            distributionHint = new uint[](2);
            distributionHint[0] = 1;
            distributionHint[1] = 1;
            shares= addFundingTo(beneficiary,amount, distributionHint);
        }
        
        return shares;
    }

    function removeLiquidityTo(address beneficiary, uint256 shares, bool autoMerge, bool withdrawFees) public {
        removeFundingTo(beneficiary, shares, withdrawFees);
        if(autoMerge == true){
            _merge(beneficiary);
        }
    }

    function merge() public {
       _merge(msg.sender);
    }
    
    function _merge(address account) internal {
        uint[] memory balances = getBalances(account);
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

        conditionalTokens.safeBatchTransferFrom(account, address(this), positionIds, sendAmounts, "");
        mergePositionsThroughAllConditions(minBalance);

        collateralToken.safeTransfer(account, minBalance);
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


    

    function getSharesPercentage(address account) public view returns(uint256) {
        uint256  totalSupply = totalSupply();
        if(totalSupply == 0){
            return 0;
        }
        return balanceOf(account) * 100 * 10000 / totalSupply;
    }
    
    function getIndexSet() public pure returns (uint256[] memory indexSet) {
        indexSet = new uint256[](2);
        indexSet[0] = 1;
        indexSet[1] = 2;
    }
    
    
    function _beforeAddFundingTo(address , uint ) internal {
        require(msg.sender == address(marketController), "caller is not market controller");
        
    }
    
    function _beforeRemoveFundingTo(address , uint ) internal{
        require(msg.sender == address(marketController), "caller is not market controller");
    }

    function _beforeBuyTo(address beneficiary, uint256 ) internal {
        
        require(msg.sender == address(marketController), "caller is not market controller");
        
        if(traders[beneficiary] == false){
            traders[beneficiary] == true;
        }
    }

    function _beforeSellTo(address beneficiary, uint256 ) internal {
        
        require(msg.sender == address(marketController), "caller is not market controller");
        
        if(traders[beneficiary] == false){
            traders[beneficiary] == true;
        }
    }

     function state() public view returns (ORMarketLib.MarketState) {
         return marketController.getMarketState(address(this));
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
