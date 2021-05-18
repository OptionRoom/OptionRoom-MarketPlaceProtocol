const ORMarketLib = artifacts.require('ORMarketLib')

const {
  prepareContracts, createNewMarket,
  executeControllerMethod, moveToActive, callControllerMethod,
  moveOneDay,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('Options room trade rewards tests', function([, creator, oracle, investor1, trader, investor2]) {

  let collateralToken
  let fixedProductMarketMaker
  let positionIds

  let controller;
  let rewardsProgram;

  before(async function() {
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2)
    controller = retArray[0];
    rewardsProgram = retArray[1];
  })

  it('can be created by factory', async function() {
    let retValues = await createNewMarket(creator)
    fixedProductMarketMaker = retValues[0]
    collateralToken = retValues[1]
    positionIds = retValues[2]
  })

  const addedFunds1 = toBN(1e18)
  it('can be funded', async function() {
    await collateralToken.deposit({ value: addedFunds1, from: investor1 })
    await collateralToken.approve(controller.address, addedFunds1, { from: investor1 })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds1, { from: investor1 })

    // All of the amount have been converted...
    expect((await collateralToken.balanceOf(investor1)).toString()).to.equal('0')
    expect((await fixedProductMarketMaker.balanceOf(investor1)).toString()).to.equal(addedFunds1.toString())
  })


  it('Should vote for the approval of this created market', async function() {
    const inv1Attr = [fixedProductMarketMaker.address, true, { from: investor1 }]
    const inv2Attr = [fixedProductMarketMaker.address, false, { from: investor2 }]
    const oracleAttr = [fixedProductMarketMaker.address, false, { from: oracle }]

    await executeControllerMethod('castGovernanceValidatingVote', inv1Attr)
    await executeControllerMethod('castGovernanceValidatingVote', inv2Attr)
    await executeControllerMethod('castGovernanceValidatingVote', oracleAttr)
  })

  it('Should vote for the approval of this created market', async function() {
    let rewards = await rewardsProgram.tradeRewards(investor1);
    expect(new BigNumber(rewards['todayExpectedReward']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(rewards['rewardsCanClaim']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(rewards['claimedRewards']).isEqualTo(new BigNumber('0'))).to.equal(true)
  })
  
  async function buyOptions(caller, investmentAmount) {
    const buyOutcomeIndex = 1

    // we already have 2 yeses and 2 nos
    await collateralToken.deposit({ value: investmentAmount, from: caller })
    await collateralToken.approve(controller.address, investmentAmount, { from: caller })

    const outcomeTokensToBuy = await fixedProductMarketMaker.calcBuyAmount(investmentAmount, buyOutcomeIndex)
    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuy, { from: caller })
  }
  
  let expectedToDay;
  let lastestExpecedUser1;
  it('Should have value in trade rewards because we purchased options', async function() {
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 1

    await moveToActive()

    let state = await callControllerMethod('getMarketState', [fixedProductMarketMaker.address])
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Active))).to.equal(true)

    // we already have 2 yeses and 2 nos
    await collateralToken.deposit({ value: investmentAmount, from: investor1 })
    await collateralToken.approve(controller.address, investmentAmount, { from: investor1 })

    const FeeProtocol = await controller.FeeProtocol.call();
    const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);

    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: investor1 })

    let rewards = await rewardsProgram.tradeRewards(investor1);
    expectedToDay = new BigNumber(rewards['todayExpectedReward']);
    expect(new BigNumber(rewards['todayExpectedReward']).isGreaterThan(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(rewards['rewardsCanClaim']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(rewards['claimedRewards']).isEqualTo(new BigNumber('0'))).to.equal(true)
  })

  it('Should give a none expected rewards today, and a correct claim values', async function() {
    await moveOneDay();
    let rewards = await rewardsProgram.tradeRewards( investor1);
    let claimable = new BigNumber(rewards['rewardsCanClaim']);
    expect(new BigNumber(rewards['todayExpectedReward']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(rewards['rewardsCanClaim']).isGreaterThan(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(rewards['claimedRewards']).isEqualTo(new BigNumber('0'))).to.equal(true)

    // Should be the same value.
    expect(claimable.isEqualTo(expectedToDay)).to.equal(true)
  })

  it('Should give the same can claim if I buy again', async function() {
    const investmentAmount = toBN(1)
    await buyOptions(investor1, investmentAmount)
    
    let rewards = await rewardsProgram.tradeRewards( investor1);
    let claimable = new BigNumber(rewards['rewardsCanClaim']);
    expect(new BigNumber(rewards['todayExpectedReward']).isGreaterThan(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(rewards['rewardsCanClaim']).isGreaterThan(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(rewards['claimedRewards']).isEqualTo(new BigNumber('0'))).to.equal(true)

    lastestExpecedUser1 = new BigNumber(rewards['todayExpectedReward']);
    
    // Should be the same value.
    expect(claimable.isEqualTo(expectedToDay)).to.equal(true)
  })

  it('Should keep claimable if another user buys', async function() {
    const investmentAmount = toBN(1)
    await buyOptions(trader, investmentAmount)
    
    let traderRewards = await rewardsProgram.tradeRewards(trader);
    expect(new BigNumber(traderRewards['todayExpectedReward']).isGreaterThan(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(traderRewards['rewardsCanClaim']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(traderRewards['claimedRewards']).isEqualTo(new BigNumber('0'))).to.equal(true)


    let rewards = await rewardsProgram.tradeRewards(investor1);
    expect(new BigNumber(rewards['todayExpectedReward']).isGreaterThan(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(rewards['rewardsCanClaim']).isGreaterThan(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(rewards['claimedRewards']).isEqualTo(new BigNumber('0'))).to.equal(true)
    
    let expectedUserOne = new BigNumber(rewards['todayExpectedReward']);
    expect(expectedUserOne.isLessThan(lastestExpecedUser1)).to.equal(true)

  })
  
})
