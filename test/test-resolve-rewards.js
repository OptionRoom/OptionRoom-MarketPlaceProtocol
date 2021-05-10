const ORMarketLib = artifacts.require('ORMarketLib')

const {
  prepareContracts, createNewMarket,
  executeControllerMethod, moveToActive, callControllerMethod,increaseTime,resetTimeIncrease,
  moveOneDay,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('Options room resolve rewards tests', function([, creator, oracle, investor1, trader, investor2]) {

  let collateralToken
  let fixedProductMarketMaker
  let positionIds

  let controller;
  let rewardsProgram;
  let marketPendingPeriod = 1800;

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
    
    // Once we are here we will sent to resolved as well to see if I am going to get a resolving votes.

    await resetTimeIncrease();
    await increaseTime(marketPendingPeriod);

    let days = ((86400 * 3) + 10);

    await increaseTime(days);
    await controller.castGovernanceResolvingVote(fixedProductMarketMaker.address, 0, { from: investor1 });
    
  })

  it('Should check rewards for the resolved investor 1', async function() {
    let investor1Rewards = await rewardsProgram.resolveRewards(investor1);
    expect(new BigNumber(investor1Rewards['todayExpectedReward']).isGreaterThan(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(investor1Rewards['rewardsCanClaim']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(investor1Rewards['claimedRewards']).isEqualTo(new BigNumber('0'))).to.equal(true)

    let investor2Rewards = await rewardsProgram.resolveRewards(investor2);
    expect(new BigNumber(investor2Rewards['todayExpectedReward']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(investor2Rewards['rewardsCanClaim']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(investor2Rewards['claimedRewards']).isEqualTo(new BigNumber('0'))).to.equal(true)

    let traderRewards = await rewardsProgram.resolveRewards(trader);
    expect(new BigNumber(traderRewards['todayExpectedReward']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(traderRewards['rewardsCanClaim']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(traderRewards['claimedRewards']).isEqualTo(new BigNumber('0'))).to.equal(true)
  })
})