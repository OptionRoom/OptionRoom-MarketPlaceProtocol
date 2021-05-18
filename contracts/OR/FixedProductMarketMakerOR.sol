pragma solidity ^0.5.1;

import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {IERC20} from "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import {ConditionalTokens} from "../../gnosis.pm/conditional-tokens-contracts/contracts/ConditionalTokens.sol";
import {CTHelpers} from "../../gnosis.pm/conditional-tokens-contracts/contracts/CTHelpers.sol";
import {ERC1155TokenReceiver} from "../../gnosis.pm/conditional-tokens-contracts/contracts/ERC1155/ERC1155TokenReceiver.sol";
import {ERC20} from "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

library CeilDiv {
    // calculates ceil(x/y)
    function ceildiv(uint x, uint y) internal pure returns (uint) {
        if (x > 0) return ((x - 1) / y) + 1;
        return x / y;
    }
}


contract FixedProductMarketMaker is ERC1155TokenReceiver {
    using SafeERC20 for IERC20;
    
    event FPMMFundingAdded(
        address indexed funder,
        uint[] amountsAdded,
        uint sharesMinted
    );
    event FPMMFundingRemoved(
        address indexed funder,
        uint[] amountsRemoved,
        uint collateralRemovedFromFeePool,
        uint sharesBurnt
    );
    event FPMMBuy(
        address indexed buyer,
        uint investmentAmount,
        uint feeAmount,
        uint indexed outcomeIndex,
        uint outcomeTokensBought
    );
    event FPMMSell(
        address indexed seller,
        uint returnAmount,
        uint feeAmount,
        uint indexed outcomeIndex,
        uint outcomeTokensSold
    );

    using SafeMath for uint;
    using CeilDiv for uint;

    uint constant ONE = 10 ** 18;

    ConditionalTokens public conditionalTokens;
    IERC20 public collateralToken;
    bytes32[] public conditionIds;
    uint public fee;
    uint internal feePoolWeight;

    uint[] outcomeSlotCounts;
    bytes32[][] collectionIds;
    uint[] positionIds;
    mapping(address => uint256) withdrawnFees;
    uint internal totalWithdrawnFees;

    bool initiated;

    function init(
        ConditionalTokens _conditionalTokens,
        IERC20 _collateralToken,
        bytes32[] memory _conditionIds,
        uint _fee
    ) public {
        require(initiated == false, "Market Already initiated");

        conditionalTokens = _conditionalTokens;
        collateralToken = _collateralToken;
        conditionIds = _conditionIds;
        fee = _fee;

        uint atomicOutcomeSlotCount = 1;
        outcomeSlotCounts = new uint[](conditionIds.length);
        for (uint i = 0; i < conditionIds.length; i++) {
            uint outcomeSlotCount = conditionalTokens.getOutcomeSlotCount(conditionIds[i]);
            atomicOutcomeSlotCount *= outcomeSlotCount;
            outcomeSlotCounts[i] = outcomeSlotCount;
        }
        require(atomicOutcomeSlotCount > 1, "conditions must be valid");

        collectionIds = new bytes32[][](conditionIds.length);
        _recordCollectionIDsForAllConditions(conditionIds.length, bytes32(0));
        require(positionIds.length == atomicOutcomeSlotCount, "position IDs construction failed!?");
    }

    function _recordCollectionIDsForAllConditions(uint conditionsLeft, bytes32 parentCollectionId) private {
        if (conditionsLeft == 0) {
            positionIds.push(CTHelpers.getPositionId(collateralToken, parentCollectionId));
            return;
        }

        conditionsLeft--;

        uint outcomeSlotCount = outcomeSlotCounts[conditionsLeft];

        collectionIds[conditionsLeft].push(parentCollectionId);
        for (uint i = 0; i < outcomeSlotCount; i++) {
            _recordCollectionIDsForAllConditions(
                conditionsLeft,
                CTHelpers.getCollectionId(
                    parentCollectionId,
                    conditionIds[conditionsLeft],
                    1 << i
                )
            );
        }
    }


    function getPoolBalances() internal view returns (uint[] memory) {
        return getBalances(address(this));
    }

    function getBalances(address account) public view returns (uint[] memory){
        address[] memory thises = new address[](positionIds.length);
        for (uint i = 0; i < positionIds.length; i++) {
            thises[i] = account;
        }
        return conditionalTokens.balanceOfBatch(thises, positionIds);
    }

    function getMarketCollateralTotalSupply() public view returns(uint256){
        uint256 collateralTotalSupply = 0;
        for (uint i = 0; i < positionIds.length; i++) {
            collateralTotalSupply = conditionalTokens.totalBalances(positionIds[i]).add(collateralTotalSupply);
        }
        return collateralTotalSupply.div(positionIds.length);
    }

    function generateBasicPartition(uint outcomeSlotCount)
    private
    pure
    returns (uint[] memory partition)
    {
        partition = new uint[](outcomeSlotCount);
        for (uint i = 0; i < outcomeSlotCount; i++) {
            partition[i] = 1 << i;
        }
    }

    function splitPositionThroughAllConditions(uint amount)
    private
    {
        for (uint i = conditionIds.length - 1; int(i) >= 0; i--) {
            uint[] memory partition = generateBasicPartition(outcomeSlotCounts[i]);
            for (uint j = 0; j < collectionIds[i].length; j++) {
                conditionalTokens.splitPosition(collateralToken, collectionIds[i][j], conditionIds[i], partition, amount);
            }
        }
    }

    function mergePositionsThroughAllConditions(uint amount) internal {
        for (uint i = 0; i < conditionIds.length; i++) {
            uint[] memory partition = generateBasicPartition(outcomeSlotCounts[i]);
            for (uint j = 0; j < collectionIds[i].length; j++) {
                conditionalTokens.mergePositions(collateralToken, collectionIds[i][j], conditionIds[i], partition, amount);
            }
        }
    }

    function collectedFees() external view returns (uint) {
        return feePoolWeight.sub(totalWithdrawnFees);
    }

    function feesWithdrawableBy(address account) public view returns (uint) {
        uint rawAmount = feePoolWeight.mul(balanceOf(account)) / totalSupply();
        return rawAmount.sub(withdrawnFees[account]);
    }

    function withdrawFees(address account) public {
        uint rawAmount = feePoolWeight.mul(balanceOf(account)) / totalSupply();
        uint withdrawableAmount = rawAmount.sub(withdrawnFees[account]);
        if (withdrawableAmount > 0) {
            withdrawnFees[account] = rawAmount;
            totalWithdrawnFees = totalWithdrawnFees.add(withdrawableAmount);
            collateralToken.safeTransfer(account, withdrawableAmount);
        }
    }
    /*
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal {
        if (from != address(0)) {
            withdrawFees(from);
        }

        uint totalSupply = totalSupply();
        uint withdrawnFeesTransfer = totalSupply == 0 ?
        amount :
        feePoolWeight.mul(amount) / totalSupply;

        if (from != address(0)) {
            withdrawnFees[from] = withdrawnFees[from].sub(withdrawnFeesTransfer);
            totalWithdrawnFees = totalWithdrawnFees.sub(withdrawnFeesTransfer);
        } else {
            feePoolWeight = feePoolWeight.add(withdrawnFeesTransfer);
        }
        if (to != address(0)) {
            withdrawnFees[to] = withdrawnFees[to].add(withdrawnFeesTransfer);
            totalWithdrawnFees = totalWithdrawnFees.add(withdrawnFeesTransfer);
        } else {
            feePoolWeight = feePoolWeight.sub(withdrawnFeesTransfer);
        }
    }
    */

    function addFundingTo(address beneficiary, uint addedFunds, uint[] memory distributionHint) internal returns(uint)
    {
        require(addedFunds > 0, "funding must be non-zero");
        _beforeAddFundingTo(beneficiary,addedFunds);

        uint[] memory sendBackAmounts = new uint[](positionIds.length);
        uint poolShareSupply = totalSupply();
        uint mintAmount;
        if (poolShareSupply > 0) {
            require(distributionHint.length == 0, "cannot use distribution hint after initial funding");
            uint[] memory poolBalances = getPoolBalances();
            uint poolWeight = 0;
            for (uint i = 0; i < poolBalances.length; i++) {
                uint balance = poolBalances[i];
                if (poolWeight < balance)
                    poolWeight = balance;
            }

            for (uint i = 0; i < poolBalances.length; i++) {
                uint remaining = addedFunds.mul(poolBalances[i]) / poolWeight;
                sendBackAmounts[i] = addedFunds.sub(remaining);
            }

            mintAmount = addedFunds.mul(poolShareSupply) / poolWeight;
        } else {
            if (distributionHint.length > 0) {
                require(distributionHint.length == positionIds.length, "hint length off");
                uint maxHint = 0;
                for (uint i = 0; i < distributionHint.length; i++) {
                    uint hint = distributionHint[i];
                    if (maxHint < hint)
                        maxHint = hint;
                }

                for (uint i = 0; i < distributionHint.length; i++) {
                    uint remaining = addedFunds.mul(distributionHint[i]) / maxHint;
                    require(remaining > 0, "must hint a valid distribution");
                    sendBackAmounts[i] = addedFunds.sub(remaining);
                }
            }

            mintAmount = addedFunds;
        }

        collateralToken.safeTransferFrom(msg.sender, address(this), addedFunds);
        require(collateralToken.approve(address(conditionalTokens), addedFunds), "approval for splits failed");
        splitPositionThroughAllConditions(addedFunds);

        _mint(beneficiary, mintAmount);

        conditionalTokens.safeBatchTransferFrom(address(this), beneficiary, positionIds, sendBackAmounts, "");

        // transform sendBackAmounts to array of amounts added
        for (uint i = 0; i < sendBackAmounts.length; i++) {
            sendBackAmounts[i] = addedFunds.sub(sendBackAmounts[i]);
        }

        emit FPMMFundingAdded(beneficiary, sendBackAmounts, mintAmount);
        return mintAmount;
    }
    

    function removeFundingTo(address beneficiary, uint sharesToBurn) internal {

        _beforeRemoveFundingTo(beneficiary, sharesToBurn);

        uint[] memory poolBalances = getPoolBalances();

        uint[] memory sendAmounts = new uint[](poolBalances.length);

        uint poolShareSupply = totalSupply();
        for (uint i = 0; i < poolBalances.length; i++) {
            sendAmounts[i] = poolBalances[i].mul(sharesToBurn) / poolShareSupply;
        }

        uint collateralRemovedFromFeePool = collateralToken.balanceOf(address(this));
        withdrawFees(beneficiary);
        _burn(beneficiary, sharesToBurn);
        collateralRemovedFromFeePool = collateralRemovedFromFeePool.sub(
            collateralToken.balanceOf(address(this))
        );

        conditionalTokens.safeBatchTransferFrom(address(this), beneficiary, positionIds, sendAmounts, "");

        emit FPMMFundingRemoved(beneficiary, sendAmounts, collateralRemovedFromFeePool, sharesToBurn);
    }
    
    
    function onERC1155Received(
        address operator,
        address,
        uint256,
        uint256,
        bytes calldata
    )
    external
    returns (bytes4)
    {
        if (operator == address(this)) {
            return this.onERC1155Received.selector;
        }
        return 0x0;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    )
    external
    returns (bytes4)
    {
        if (operator == address(this) && from == address(0)) {
            return this.onERC1155BatchReceived.selector;
        }
        return 0x0;
    }

    function calcBuyAmount(uint investmentAmount, uint outcomeIndex) public view returns (uint) {
        require(outcomeIndex < positionIds.length, "invalid outcome index");

        uint[] memory poolBalances = getPoolBalances();
        uint investmentAmountMinusFees = investmentAmount.sub(investmentAmount.mul(fee) / ONE);
        uint buyTokenPoolBalance = poolBalances[outcomeIndex];
        uint endingOutcomeBalance = buyTokenPoolBalance.mul(ONE);
        for (uint i = 0; i < poolBalances.length; i++) {
            if (i != outcomeIndex) {
                uint poolBalance = poolBalances[i];
                endingOutcomeBalance = endingOutcomeBalance.mul(poolBalance).ceildiv(
                    poolBalance.add(investmentAmountMinusFees)
                );
            }
        }
        require(endingOutcomeBalance > 0, "must have non-zero balances");

        return buyTokenPoolBalance.add(investmentAmountMinusFees).sub(endingOutcomeBalance.ceildiv(ONE));
    }
    
    
    function calcBuyAmountProtocolFeesIncluded(uint investmentAmount, uint outcomeIndex, uint256 protocolFee) public view returns (uint) {
        uint256 pFee = investmentAmount * protocolFee / 1e18;
        
        return calcBuyAmount(investmentAmount - pFee, outcomeIndex);
        
    }


    function calcSellAmount(uint returnAmount, uint outcomeIndex) internal view returns (uint outcomeTokenSellAmount) {
        require(outcomeIndex < positionIds.length, "invalid outcome index");

        uint[] memory poolBalances = getPoolBalances();
        //uint returnAmountPlusFees = returnAmount.mul(ONE) / ONE.sub(fee);
        uint returnAmountPlusFees = returnAmount.mul(ONE.add(fee)) / ONE;
        uint sellTokenPoolBalance = poolBalances[outcomeIndex];
        uint endingOutcomeBalance = sellTokenPoolBalance.mul(ONE);
        for (uint i = 0; i < poolBalances.length; i++) {
            if (i != outcomeIndex) {
                uint poolBalance = poolBalances[i];
                endingOutcomeBalance = endingOutcomeBalance.mul(poolBalance).ceildiv(
                    poolBalance.sub(returnAmountPlusFees)
                );
            }
        }
        require(endingOutcomeBalance > 0, "must have non-zero balances");

        return returnAmountPlusFees.add(endingOutcomeBalance.ceildiv(ONE)).sub(sellTokenPoolBalance);
    }

    function calcSellReturnInv(uint amount, uint inputIndex) public view returns (uint256 ret){
        uint256[] memory poolBalance0 = getPoolBalances();

        uint256 c = poolBalance0[0] * poolBalance0[1];

        uint256 m = 0;
        if (inputIndex == 0) {
            m = amount + poolBalance0[0] - poolBalance0[1];

        } else {
            m = amount + poolBalance0[1] - poolBalance0[0];
        }

        uint256 f = sqrt((m * m) + 4 * c);

        if (inputIndex == 0) {
            ret = ((2 * poolBalance0[1]) - (f - m)) / 2;
        } else {
            ret = ((2 * poolBalance0[0]) - (f - m)) / 2;
        }

        ret = ret.mul(ONE.sub(fee)) / ONE;
    }
    
    function calcSellReturnInvMinusMarketFees(uint amount, uint inputIndex, uint256 protocolFee) public view returns (uint256 ret){
        ret = calcSellReturnInv(amount,inputIndex);
        
        uint256 pFee = ret * protocolFee / 1e18;
        
        ret -= pFee;
    }
    

    function buyTo(address beneficiary, uint investmentAmount, uint outcomeIndex, uint minOutcomeTokensToBuy) public{
        _beforeBuyTo(beneficiary, investmentAmount);
        uint outcomeTokensToBuy = calcBuyAmount(investmentAmount, outcomeIndex);
        require(outcomeTokensToBuy >= minOutcomeTokensToBuy, "minimum buy amount not reached");

        collateralToken.safeTransferFrom(msg.sender, address(this), investmentAmount);

        uint feeAmount = investmentAmount.mul(fee) / ONE;
        feePoolWeight = feePoolWeight.add(feeAmount);
        uint investmentAmountMinusFees = investmentAmount.sub(feeAmount);
        require(collateralToken.approve(address(conditionalTokens), investmentAmountMinusFees), "approval for splits failed");
        splitPositionThroughAllConditions(investmentAmountMinusFees);

        conditionalTokens.safeTransferFrom(address(this), beneficiary, positionIds[outcomeIndex], outcomeTokensToBuy, "");

        emit FPMMBuy(beneficiary, investmentAmount, feeAmount, outcomeIndex, outcomeTokensToBuy);
    }

    function sellByReturnAmountTo(address beneficiary, uint returnAmount, uint outcomeIndex, uint maxOutcomeTokensToSell) internal {
        uint outcomeTokensToSell = calcSellAmount(returnAmount, outcomeIndex);
        require(outcomeTokensToSell <= maxOutcomeTokensToSell, "maximum sell amount exceeded");

        conditionalTokens.safeTransferFrom(msg.sender, address(this), positionIds[outcomeIndex], outcomeTokensToSell, "");

        //uint feeAmount = returnAmount.mul(fee) / (ONE.sub(fee));
        uint feeAmount = returnAmount.mul(fee) / ONE;
        feePoolWeight = feePoolWeight.add(feeAmount);
        uint returnAmountPlusFees = returnAmount.add(feeAmount);
        mergePositionsThroughAllConditions(returnAmountPlusFees);

        collateralToken.safeTransfer(beneficiary, returnAmount);

        emit FPMMSell(msg.sender, returnAmount, feeAmount, outcomeIndex, outcomeTokensToSell);
    }

    
    function sellTo(address beneficiary, uint256 amount, uint256 index) public returns(uint256){
        uint256 expectedRet = calcSellReturnInv(amount, index);
        _beforeSellTo(beneficiary, expectedRet);
        sellByReturnAmountTo(beneficiary,expectedRet, index, amount * 105 / 100);
        
        return expectedRet;
        
    }
    
    uint256 totalLiq;
    mapping(address => uint256) balances;
    function totalSupply() public view returns(uint256){
        return totalLiq;
    }
    
    function balanceOf(address account) public view returns(uint256){
        return balances[account];
    }
    
    function _mint(address account, uint256 amount) internal{
        if(account != address(0)){
            balances[account] += amount;
            totalLiq += amount;
        }
    }
    
    function _burn(address account, uint256 amount) internal{
        if(account != address(0)){
            require(amount <= balances[account], "insufficient balance");
            balances[account] -= amount;
            totalLiq -= amount;
        }
    }

    function _beforeBuyTo(address account, uint256 amount) internal;

    function _beforeSellTo(address account, uint256 amount) internal;
    
    function _beforeAddFundingTo(address beneficiary, uint addedFunds) internal;

    function _beforeRemoveFundingTo(address beneficiary, uint sharesToBurn) internal;

    function sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        z = z + 1;
    }

}
