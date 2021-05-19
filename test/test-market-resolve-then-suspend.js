const ORMarketLib = artifacts.require('ORMarketLib')
const { expectEvent } = require('openzeppelin-test-helpers')

const {
  prepareContracts, createNewMarket,
  executeControllerMethod, moveToActive, callControllerMethod, 
  moveToResolving,resetTimeIncrease,increaseTime,moveToResolved,setDeployer,
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

    await collateralTokenInstance.deposit({ value: addedFunds1, from: investor2 })
    await collateralTokenInstance.approve(controller.address, addedFunds1, { from: investor2 })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds1, { from: investor2 })

    const inv1Attr = [fixedProductMarketMaker.address, true, { from: investor1 }]
    const inv2Attr = [fixedProductMarketMaker.address, false, { from: investor2 }]
    const oracleAttr = [fixedProductMarketMaker.address, false, { from: oracle }]

    await executeControllerMethod('castGovernanceValidatingVote', inv1Attr)
    await executeControllerMethod('castGovernanceValidatingVote', inv2Attr)
    await executeControllerMethod('castGovernanceValidatingVote', oracleAttr)

    let investmentAmount = toBN(1e18)
    let buyOutcomeIndex = 1

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

    investmentAmount = toBN(1e18)
    buyOutcomeIndex = 0

    // we already have 2 yeses and 2 nos
    await collateralTokenInstance.deposit({ value: investmentAmount, from: investor1 })
    await collateralTokenInstance.approve(controller.address, investmentAmount, { from: investor1 })

    const outcomeTokensToBuyFinal1 = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal1, { from: investor1 })
  })

  it('Should move to resolved state', async function() {
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

    state = await callControllerMethod('getMarketState', [fixedProductMarketMaker.address])
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Resolved))).to.equal(true)
  })

  // Suspending the market should have some changes, 
  // all will resolve to 1, 1
  it('Should suspend the market', async function() {
    await controller.marketStop(fixedProductMarketMaker.address, {from : deployer});
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

    expect((new BigNumber(payoutNumerators[0])).isEqualTo(new BigNumber(1))).to.equal(true)
    expect((new BigNumber(payoutNumerators[1])).isEqualTo(new BigNumber(1))).to.equal(true)

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

    const { indexSets } = createTx.logs.find(
      ({ event }) => event === 'PayoutRedemption'
    ).args;
    
    const { payout } = createTx.logs.find(
      ({ event }) => event === 'PayoutRedemption'
    ).args;
    
    expect((new BigNumber(payout)).isGreaterThan(new BigNumber(0))).to.equal(true)
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

    const { indexSets } = createTx.logs.find(
      ({ event }) => event === 'PayoutRedemption'
    ).args;

    expect((new BigNumber(payout)).isEqualTo(new BigNumber(0))).to.equal(true)
  })

})

