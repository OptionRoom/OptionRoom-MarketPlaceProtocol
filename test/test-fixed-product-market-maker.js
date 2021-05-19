var chai = require('chai');

//use default BigNumber
chai.use(require('chai-bignumber')());

const ORMarketLib = artifacts.require('ORMarketLib')
const { expectEvent } = require('openzeppelin-test-helpers')
const {
  prepareContracts, createNewMarket,resetTimeIncrease,increaseTime,
  setDeployer, moveToActive,moveToResolved11
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('FixedProductMarketMaker: general test', function([deployer, creator, oracle, investor1, trader, investor2]) {

  let conditionalTokens
  let collateralToken
  let fixedProductMarketMaker

  let positionIds
  const feeFactor = toBN(3e15) // (0.3%)
  let controller

  before(async function() {
    setDeployer(deployer);
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2,deployer)
    controller = retArray[0];
    conditionalTokens = retArray[3];
  })

  it('can be created by factory', async function() {
    let retValues = await createNewMarket(creator)
    fixedProductMarketMaker = retValues[0]
    collateralToken = retValues[1]
  })

  const addedFunds1 = toBN(1e18)
  const initialDistribution = [1, 1]
  const expectedFundedAmounts = new Array(2).fill(addedFunds1)
  
  it('can be funded', async function() {
    await collateralToken.deposit({ value: addedFunds1, from: investor1 });
    await collateralToken.approve(controller.address, addedFunds1, { from: investor1 })
    const fundingTx = await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds1, { from: investor1 })
    // address indexed funder,
    //   uint[] amountsAdded,
    //   uint sharesMinted
    //
    // expectEvent.inLogs(fundingTx.logs, 'FixedProductMarketMaker.FPMMFundingAdded1', {
    //   funder: investor1
    // });

    // const { amountsAdded } = fundingTx.logs.find(
    //   ({ event }) => event === 'FPMMFundingAdded'
    // ).args;
    //
    // const { sharesMinted } = fundingTx.logs.find(
    //   ({ event }) => event === 'FPMMFundingAdded'
    // ).args;
    //
    // expect(amountsAdded).to.have.lengthOf(expectedFundedAmounts.length);
    // for (let i = 0; i < amountsAdded.length; i++) {
    //   expect(amountsAdded[i].toString()).to.equal(expectedFundedAmounts[i].toString());
    // }
    //
    // All of the amount have been converted...
    expect((await collateralToken.balanceOf(investor1)).toString()).to.equal("0");
    expect((await fixedProductMarketMaker.balanceOf(investor1)).toString()).to.equal(addedFunds1.toString());

    positionIds = await fixedProductMarketMaker.getPositionIds();

    for(let i = 0; i < positionIds.length; i++) {
      let positionBalance =  new BigNumber(await conditionalTokens.balanceOf(fixedProductMarketMaker.address, positionIds[i]));
      expect (positionBalance.isEqualTo(new BigNumber(expectedFundedAmounts[i])))
    }
  });

  // Doing the voting in order to start buying and selling !
  it('Should vote for the approval of this created market', async function() {
    await controller.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: investor1 });
    await controller.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: investor2 });
    await controller.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: oracle });
  });

  let marketMakerPool;
  it('can buy tokens from it', async function() {
    await moveToActive();
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 1;
    await collateralToken.deposit({ value: investmentAmount, from: trader });
    await collateralToken.approve(controller.address, investmentAmount, { from: trader })

    const feeAmount = await controller.protocolFee.call();
    const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, feeAmount);
    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: trader })

    expect((await collateralToken.balanceOf(trader)).toString()).to.equal("0");
    expect((await fixedProductMarketMaker.balanceOf(trader)).toString()).to.equal("0");

    marketMakerPool = []
    positionIds = await fixedProductMarketMaker.getPositionIds();
    for(let i = 0; i < positionIds.length; i++) {
      let newMarketMakerBalance;
      if(i === buyOutcomeIndex) {
        newMarketMakerBalance = expectedFundedAmounts[i].add(investmentAmount).sub(feeAmount).sub(outcomeTokensToBuyFinal);
        let traderBalance =  new BigNumber(await conditionalTokens.balanceOf(trader, positionIds[i]));
        expect(traderBalance.isEqualTo(new BigNumber(outcomeTokensToBuyFinal)));
      } else {
        newMarketMakerBalance = expectedFundedAmounts[i].add(investmentAmount).sub(feeAmount);
        let traderBalance =  new BigNumber(await conditionalTokens.balanceOf(trader, positionIds[i]));
        expect(traderBalance.isEqualTo(new BigNumber(0)));
      }
      
      let marketPositionBalance = new BigNumber(await conditionalTokens.balanceOf(fixedProductMarketMaker.address,positionIds[i]));
      expect(marketPositionBalance.isEqualTo(new BigNumber(newMarketMakerBalance)));

      marketMakerPool[i] = newMarketMakerBalance
    }
  })
  //
  // it('can sell tokens to it', async function() {
  //   const returnAmountWished = toBN(1e18)
  //   const sellOutcomeIndex = 1;
  //   await conditionalTokens.setApprovalForAll(fixedProductMarketMaker.address, true, { from: trader });
  //
  //   const feeAmountWished = returnAmountWished.mul(feeFactor).div(toBN(1e18).sub(feeFactor));
  //
  //   // Getting all transaction information.
  //   const expectedRetValue = await fixedProductMarketMaker.calcSellReturnInv(returnAmountWished, sellOutcomeIndex, { from: trader } );
  //   const sellTx = await fixedProductMarketMaker.sell(returnAmountWished, sellOutcomeIndex, { from: trader } );
  //
  //   const { returnAmount } = sellTx.logs.find(
  //     ({ event }) => event === 'FPMMSell'
  //   ).args;
  //
  //   const { seller } = sellTx.logs.find(
  //     ({ event }) => event === 'FPMMSell'
  //   ).args;
  //
  //   const { feeAmount } = sellTx.logs.find(
  //     ({ event }) => event === 'FPMMSell'
  //   ).args;
  //
  //   const { outcomeIndex } = sellTx.logs.find(
  //     ({ event }) => event === 'FPMMSell'
  //   ).args;
  //
  //   const { outcomeTokensSold } = sellTx.logs.find(
  //     ({ event }) => event === 'FPMMSell'
  //   ).args;
  //
  //   expect((await collateralToken.balanceOf(trader)).toString()).to.equal(expectedRetValue.toString());
  //   expect((await fixedProductMarketMaker.balanceOf(trader)).toString()).to.equal("0");
  //
  //   for(let i = 0; i < positionIds.length; i++) {
  //     let newMarketMakerBalance;
  //     if(i === sellOutcomeIndex) {
  //       newMarketMakerBalance = marketMakerPool[i].sub(returnAmountWished).sub(feeAmountWished).add(expectedRetValue)
  //     } else {
  //       newMarketMakerBalance = marketMakerPool[i].sub(returnAmountWished).sub(feeAmountWished)
  //     }
  //     // expect((await conditionalTokens.balanceOf(fixedProductMarketMaker.address, positionIds[i]))
  //     //   .toString()).to.equal(newMarketMakerBalance.toString());
  //
  //     marketMakerPool[i] = newMarketMakerBalance
  //   }
  // })
  //
  // const addedFunds2 = toBN(5e18)
  // it('can continue being funded', async function() {
  //   await collateralToken.deposit({ value: addedFunds2, from: investor2 });
  //   await collateralToken.approve(fixedProductMarketMaker.address, addedFunds2, { from: investor2 });
  //   await fixedProductMarketMaker.addLiquidity(addedFunds2, {from : investor2 });
  //
  //   expect((await collateralToken.balanceOf(investor2))).to.eql(toBN(0));
  //   let inv2Balance = new BigNumber(await fixedProductMarketMaker.balanceOf(investor2));
  //   expect(inv2Balance.isGreaterThan(new BigNumber("0"))).to.equal(true);
  //
  //   for(let i = 0; i < positionIds.length; i++) {
  //     let newMarketMakerBalance =new BigNumber(await conditionalTokens.balanceOf(fixedProductMarketMaker.address, positionIds[i]))
  //     let marketPoolValueI = new BigNumber(marketMakerPool[i]);
  //     let marketPoolValueFundAdded = new BigNumber(marketMakerPool[i].add(addedFunds2));
  //     expect(newMarketMakerBalance.isGreaterThan(marketPoolValueI)).to.equal(true);
  //
  //     // We need to make small adjustment here.
  //     marketMakerPool[i] = newMarketMakerBalance;
  //
  //     let balanaceOfInvestor = new BigNumber(await conditionalTokens.balanceOf(investor2, positionIds[i]));
  //     expect(balanaceOfInvestor.isGreaterThanOrEqualTo(new BigNumber(0))).to.equal(true);
  //     expect(balanaceOfInvestor.isLessThan(new BigNumber(addedFunds2))).to.equal(true);
  //   }
  // });
  //
  // const burnedShares1 = toBN(1e18)
  // it('can be defunded', async function() {
  //   await fixedProductMarketMaker.removeLiquidity(burnedShares1, false,  {from : investor1 });
  //
  //   let invCollateralToken = new BigNumber(await collateralToken.balanceOf(investor1));
  //   expect(invCollateralToken.isGreaterThanOrEqualTo(new BigNumber(0))).to.equal(true);
  //
  //   let invFixedProductMarketMakerBalance = new BigNumber(await fixedProductMarketMaker.balanceOf(investor1));
  //   expect(invFixedProductMarketMakerBalance.isEqualTo(new BigNumber(addedFunds1.sub(burnedShares1)))).to.equal(true);
  //
  //   for(let i = 0; i < positionIds.length; i++) {
  //     let newMarketMakerBalance = new BigNumber(await conditionalTokens.balanceOf(fixedProductMarketMaker.address, positionIds[i]))
  //     expect(newMarketMakerBalance.isLessThan(marketMakerPool[i])).to.equal(true);
  //
  //     let conditionalTokensBalanace = new BigNumber(await conditionalTokens.balanceOf(investor1, positionIds[i]));
  //
  //     let fundsFinal = new BigNumber(addedFunds1).minus(new BigNumber(expectedFundedAmounts[i]))
  //       .plus(new BigNumber(marketMakerPool[i])).minus(new BigNumber(newMarketMakerBalance));
  //
  //     expect(conditionalTokensBalanace.isEqualTo(fundsFinal)).to.equal(true);
  //
  //     marketMakerPool[i] = newMarketMakerBalance;
  //   }
  // });
})
