const ORMarketLib = artifacts.require('ORMarketLib')
const { expectEvent } = require('openzeppelin-test-helpers')

const {
  prepareContracts, createNewMarket,
  executeControllerMethod, moveToActive, conditionalApproveForAll, callControllerMethod,
  conditionalBalanceOf, moveToResolving,resetTimeIncrease,increaseTime,moveToResolved,setDeployer,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('Markets buy sell redeem test', function([deployer, creator, oracle, investor1, trader, investor2]) {

  let collateralTokenInstance
  let fixedProductMarketMaker
  let positionIds
  
  let controller;
  let conditionalTokens;

  before(async function() {
    setDeployer(deployer);
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2,deployer)
    controller = retArray[0];
    conditionalTokens = retArray[3];
  })

  it('can be created by factory', async function() {
    let retValues = await createNewMarket(creator)
    fixedProductMarketMaker = retValues[0]
    collateralTokenInstance = retValues[1]
    positionIds = retValues[2]
  })

  const addedFunds1 = toBN(1e18)
  it('can be funded', async function() {
    await collateralTokenInstance.deposit({ value: addedFunds1, from: investor1 })
    await collateralTokenInstance.approve(controller.address, addedFunds1, { from: investor1 })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds1, { from: investor1 })

    // All of the amount have been converted...
    expect((await collateralTokenInstance.balanceOf(investor1)).toString()).to.equal('0')
    expect((await fixedProductMarketMaker.balanceOf(investor1)).toString()).to.equal(addedFunds1.toString())
  })

  it('Should be able to add more liquidity from another account', async function() {
    await collateralTokenInstance.deposit({ value: addedFunds1, from: investor2 })
    await collateralTokenInstance.approve(controller.address, addedFunds1, { from: investor2 })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds1, { from: investor2 })

    // All of the amount have been converted...
    expect((await collateralTokenInstance.balanceOf(investor2)).toString()).to.equal('0')
    expect((await fixedProductMarketMaker.balanceOf(investor2)).toString()).to.equal(addedFunds1.toString())
  })

  it('Should be able to add more liquidity from another account', async function() {
    await controller.marketRemoveLiquidity(fixedProductMarketMaker.address, addedFunds1,false, true,  { from: investor2 })
  })
  

  it('Should return balance of account', async function() {
    // This should be zeros because we have the same ratios of the both options.
    let retArray = await fixedProductMarketMaker.getBalances(investor1)
    expect(new BigNumber(retArray[0]).isEqualTo(0)).to.equal(true)
    expect(new BigNumber(retArray[1]).isEqualTo(0)).to.equal(true)

  })

  let marketMakerPool
  it('Can not buy when the market is not in active state', async function() {
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 1

    // we already have 2 yeses and 2 nosNN
    await collateralTokenInstance.deposit({ value: investmentAmount, from: trader })
    await collateralTokenInstance.approve(controller.address, investmentAmount, { from: trader })

    const FeeProtocol = await controller.FeeProtocol.call();
    const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
    
    const REVERT = 'Market is not in active state'
    try {
      await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: trader })
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should not be able to sell while market is not active', async function() {
    let traderNoBalanceBefore = (await fixedProductMarketMaker.getBalances(trader))[1]
    let expectedSellValue = await fixedProductMarketMaker.calcSellReturnInv(toBN(traderNoBalanceBefore), 1, { from: trader })

    await conditionalApproveForAll(controller, trader)
    await collateralTokenInstance.approve(controller.address, expectedSellValue, { from: trader })
    
    const REVERT = 'Market is not in active state'
    try {
      await controller.marketSell(fixedProductMarketMaker.address, expectedSellValue, 1, { from: trader })
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should vote for the approval of this created market', async function() {
    const inv1Attr = [fixedProductMarketMaker.address, true, { from: investor1 }]
    const inv2Attr = [fixedProductMarketMaker.address, false, { from: investor2 }]
    const oracleAttr = [fixedProductMarketMaker.address, false, { from: oracle }]

    await executeControllerMethod('castGovernanceValidatingVote', inv1Attr)
    await executeControllerMethod('castGovernanceValidatingVote', inv2Attr)
    await executeControllerMethod('castGovernanceValidatingVote', oracleAttr)
  })

  it('can buy tokens from it', async function() {
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 1

    await moveToActive()

    let state = await callControllerMethod('getMarketState', [fixedProductMarketMaker.address])
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Active))).to.equal(true)

    // we already have 2 yeses and 2 nos
    await collateralTokenInstance.deposit({ value: investmentAmount, from: trader })
    await collateralTokenInstance.approve(controller.address, investmentAmount, { from: trader })

    // const outcomeTokensToBuy = await fixedProductMarketMaker.calcBuyAmount(investmentAmount, buyOutcomeIndex)
    const FeeProtocol = await controller.FeeProtocol.call();
    const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: trader })
  })

  // buying the different outcome
  it('can again buy tokens from it', async function() {
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 0

    // we already have 2 yeses and 2 nos
    await collateralTokenInstance.deposit({ value: investmentAmount, from: investor1 })
    await collateralTokenInstance.approve(controller.address, investmentAmount, { from: investor1 })

    const FeeProtocol = await controller.FeeProtocol.call();
    const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: investor1 })
  })
  
  const addedFunds2 = toBN(1e18)
  it('can continue being funded', async function() {
    await collateralTokenInstance.deposit({ value: addedFunds2, from: investor2 })
    await collateralTokenInstance.approve(controller.address, addedFunds2, { from: investor2 })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds2, { from: investor2 })

    expect((await collateralTokenInstance.balanceOf(investor2))).to.eql(toBN(0))
    let inv2Balance = new BigNumber(await fixedProductMarketMaker.balanceOf(investor2))
    expect(inv2Balance.isGreaterThan(new BigNumber('0'))).to.equal(true)
  })

  it('Should return balance of account', async function() {
    let outcome1 = new BigNumber(await conditionalBalanceOf(investor2, positionIds[0]))
    let outcome2 = new BigNumber(await conditionalBalanceOf(investor2, positionIds[1]))

    let inv1outcome1 = new BigNumber(await conditionalBalanceOf(investor1, positionIds[0]))
    let inv1outcome2 = new BigNumber(await conditionalBalanceOf(investor1, positionIds[1]))

    // This should be zeros because we have the same rations of the both options.
    let retArray = await fixedProductMarketMaker.getBalances(investor1)
    expect(new BigNumber(retArray[0]).isEqualTo(new BigNumber(inv1outcome1))).to.equal(true)
    expect(new BigNumber(retArray[1]).isEqualTo(new BigNumber(inv1outcome2))).to.equal(true)

    retArray = await fixedProductMarketMaker.getBalances(investor2)
    expect(new BigNumber(retArray[0]).isEqualTo(new BigNumber(outcome1))).to.equal(true)
    expect(new BigNumber(retArray[1]).isEqualTo(new BigNumber(outcome2))).to.equal(true)
  })

  let traderNoBalanceBefore
  let expectedSellValue

  it('Should be able to sell', async function() {
    traderNoBalanceBefore = (await fixedProductMarketMaker.getBalances(trader))[1]
    expectedSellValue = await fixedProductMarketMaker.calcSellReturnInv(toBN(traderNoBalanceBefore), 1, { from: trader })
    
    await collateralTokenInstance.approve(controller.address, expectedSellValue, { from: trader })
    
    // the first attribute is the amount, then the index you want to sell.
    await controller.marketSell(fixedProductMarketMaker.address, expectedSellValue, 1, { from: trader })
  })

  it('Should give the correct results after selling options', async function() {
    let traderNoBalanceAfterSell = (await fixedProductMarketMaker.getBalances(trader))[1]
    let summation = new BigNumber(expectedSellValue).plus(new BigNumber(traderNoBalanceAfterSell))

    traderNoBalanceBefore = new BigNumber(traderNoBalanceBefore)

    let divisionResult = summation.dividedBy(traderNoBalanceBefore).toFixed(0, BigNumber.ROUND_FLOOR)
    expect(new BigNumber(divisionResult).isEqualTo(new BigNumber(1))).to.equal(true)

    let colTokenBalance = new BigNumber((await collateralTokenInstance.balanceOf(trader)))
    expect(colTokenBalance.isGreaterThan(new BigNumber(0)))
  })

  it('Should fail because we sent number not within range', async function() {
    const REVERT = 'Outcome should be within range!'
    try {
      await controller.castGovernanceResolvingVote(fixedProductMarketMaker.address, 4, {from: investor1});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })
  
  it('Should move the market to the resolved state', async function() {
    await resetTimeIncrease();
    await moveToResolving()

    let days = ((86400 * 3) + 10);
    await increaseTime(days);
    
    let state = await callControllerMethod('getMarketState', [fixedProductMarketMaker.address])
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Resolving))).to.equal(true)

    const inv1Attr = [fixedProductMarketMaker.address, 1, { from: investor1 }]
    const inv2Attr = [fixedProductMarketMaker.address, 1, { from: investor2 }]
    const oracleAttr = [fixedProductMarketMaker.address, 1, { from: oracle }]

    await executeControllerMethod('castGovernanceResolvingVote', inv1Attr)
    await executeControllerMethod('castGovernanceResolvingVote', inv2Attr)
    await executeControllerMethod('castGovernanceResolvingVote', oracleAttr)

    await moveToResolved();
  })

  it('Should check weather market in resolved state', async function() {
    let state = await callControllerMethod('getMarketState', [fixedProductMarketMaker.address])
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Resolved))).to.equal(true)
  })

  it('Should pass with no issues', async function() {
    await callControllerMethod('payoutsAction', [fixedProductMarketMaker.address])
  })

  it('Should pass and send tokens to the person bought', async function() {
    const createTx = await conditionalTokens.redeem(fixedProductMarketMaker.address, {from : trader});

    const { conditionId } = createTx.logs.find(
      ({ event }) => event === 'ConditionResolution'
    ).args;

    const { payoutNumerators } = createTx.logs.find(
      ({ event }) => event === 'ConditionResolution'
    ).args;
    
    const { redeemer } = createTx.logs.find(
      ({ event }) => event === 'PayoutRedemption'
    ).args;
    
    // Must be the trader that got things here.
    expect(redeemer).to.equal(trader)

    const { collateralToken } = createTx.logs.find(
      ({ event }) => event === 'PayoutRedemption'
    ).args;

    const { indexSets } = createTx.logs.find(
      ({ event }) => event === 'PayoutRedemption'
    ).args;

    const { payout } = createTx.logs.find(
      ({ event }) => event === 'PayoutRedemption'
    ).args;
    
    expect(collateralTokenInstance.address).to.equal(collateralToken)
    expect((new BigNumber(payout)).isGreaterThan(new BigNumber(0))).to.equal(true)
  })

  it('Should pass and send nothing the lost user', async function() {
    const createTx = await conditionalTokens.redeem(fixedProductMarketMaker.address, {from : investor1});

    const { redeemer } = createTx.logs.find(
      ({ event }) => event === 'PayoutRedemption'
    ).args;

    // Must be the trader that got things here.
    expect(redeemer).to.equal(investor1)

    const { payout } = createTx.logs.find(
      ({ event }) => event === 'PayoutRedemption'
    ).args;

    expect((new BigNumber(payout)).isEqualTo(new BigNumber(0))).to.equal(true)
  })
  
  it('Should pass and send nothing the other user', async function() {
    const createTx = await conditionalTokens.redeem(fixedProductMarketMaker.address, {from : oracle});

    const { redeemer } = createTx.logs.find(
      ({ event }) => event === 'PayoutRedemption'
    ).args;

    // Must be the trader that got things here.
    expect(redeemer).to.equal(oracle)

    const { payout } = createTx.logs.find(
      ({ event }) => event === 'PayoutRedemption'
    ).args;

    expect((new BigNumber(payout)).isEqualTo(new BigNumber(0))).to.equal(true)
  })
  
})

