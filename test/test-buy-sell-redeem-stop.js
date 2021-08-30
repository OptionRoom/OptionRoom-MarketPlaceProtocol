const ORMarketLib = artifacts.require('ORMarketLib')
const { expectEvent } = require('openzeppelin-test-helpers')

const {
  prepareContracts, createNewMarket,
  executeControllerMethod, moveToActive, conditionalApproveForAll, callControllerMethod,
  conditionalBalanceOf, moveToResolving,resetTimeIncrease,increaseTime,moveToResolved,setDeployer,createNewMarketWithCollateral,
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
    const addedFunds1 = toBN(1e18)
    await controller.setMarketMinShareLiq(addedFunds1);

    conditionalTokens = retArray[3];
  })

  it('can be created by factory', async function() {
    // let retValues = await createNewMarket(creator)
    const addedFunds1 = toBN(100e18)

    let retValues = await createNewMarketWithCollateral(creator, true, addedFunds1, "test");
    fixedProductMarketMaker = retValues[0]
    collateralTokenInstance = retValues[1]
    positionIds = retValues[2]
  })

  const addedFunds1 = toBN(10e18)
  it('can be funded', async function() {
    await collateralTokenInstance.deposit({ value: addedFunds1, from: investor1 })
    await collateralTokenInstance.approve(controller.address, addedFunds1, { from: investor1 })
    let roomBalance = await collateralTokenInstance.balanceOf(investor1);

    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds1, { from: investor1 })
    roomBalance = await collateralTokenInstance.balanceOf(investor1);

    // All of the amount have been converted...
    expect((await collateralTokenInstance.balanceOf(investor1)).toString()).to.equal('0')
    expect((await fixedProductMarketMaker.balanceOf(investor1)).toString()).to.equal(addedFunds1.toString())
  })

  let marketMakerPool
  it('Should vote for the approval of this created market', async function() {
    const inv1Attr = [fixedProductMarketMaker.address, true, { from: investor1 }]
    const inv2Attr = [fixedProductMarketMaker.address, false, { from: investor2 }]
    const oracleAttr = [fixedProductMarketMaker.address, false, { from: oracle }]

    await executeControllerMethod('castGovernanceValidatingVote', inv1Attr)
    await executeControllerMethod('castGovernanceValidatingVote', inv2Attr)
    await executeControllerMethod('castGovernanceValidatingVote', oracleAttr)
  })

  it('can buy tokens from it', async function() {
    const investmentAmount = toBN(10e18)
    const buyOutcomeIndex = 1

    await moveToActive()

    let state = await callControllerMethod('getMarketState', [fixedProductMarketMaker.address])
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Active))).to.equal(true)

    // we already have 2 yeses and 2 nos
    await collateralTokenInstance.deposit({ value: investmentAmount, from: trader })
    await collateralTokenInstance.approve(controller.address, investmentAmount, { from: trader })

    const FeeProtocol = await controller.FeeProtocol.call();
    const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: trader })
  })

  it('can buy tokens from it', async function() {
    const investmentAmount = toBN(10e18)
    const buyOutcomeIndex = 0

    // we already have 2 yeses and 2 nos
    await collateralTokenInstance.deposit({ value: investmentAmount, from: oracle })
    await collateralTokenInstance.approve(controller.address, investmentAmount, { from: oracle })

    const FeeProtocol = await controller.FeeProtocol.call();
    const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: oracle })
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


  it('Should suspend the market', async function() {
    await controller.marketStop(fixedProductMarketMaker.address, {from : deployer});
  })


  it('Should pass and send tokens to the person bought', async function() {
    let colBalance = await collateralTokenInstance.balanceOf(trader);
    let marketBalance = await fixedProductMarketMaker.balanceOf(trader);

    const createTx = await conditionalTokens.redeem(fixedProductMarketMaker.address, {from : trader});

    let colBalance1 = await collateralTokenInstance.balanceOf(trader);

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
    let colBalance = await collateralTokenInstance.balanceOf(oracle);

    const createTx = await conditionalTokens.redeem(fixedProductMarketMaker.address, {from : oracle});

    colBalance = await collateralTokenInstance.balanceOf(oracle);

    const { redeemer } = createTx.logs.find(
      ({ event }) => event === 'PayoutRedemption'
    ).args;

    // Must be the trader that got things here.
    expect(redeemer).to.equal(oracle)

    const { payout } = createTx.logs.find(
      ({ event }) => event === 'PayoutRedemption'
    ).args;

    // expect((new BigNumber(payout)).isEqualTo(new BigNumber(0))).to.equal(true)
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


  it('Should be able to remove liquidity', async function() {
    // We will try to remove some of the liquidity of the inv2.
    let roomBalance = await collateralTokenInstance.balanceOf(investor1);
    let marketBalance = await fixedProductMarketMaker.balanceOf(investor1);

    await conditionalTokens.setApprovalForAll(fixedProductMarketMaker.address, true, { from: investor1 });

    await controller.marketRemoveLiquidity(fixedProductMarketMaker.address,
      addedFunds1, true,true, { from: investor1 })

    let moneyInv1After = await collateralTokenInstance.balanceOf(investor1);
  })

})
