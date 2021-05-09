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
    await executeControllerMethod('castGovernanceValidatingVote', inv1Attr)
  })

  it('Should return the correct validation reward value for the invistor because he validated system', async function() {
    let rewards = await rewardsProgram.validationRewards(investor1);
    expect(new BigNumber(rewards['todayExpectedReward']).isGreaterThan(new BigNumber('0'))).to.equal(true)

    let investor2Rewards = await rewardsProgram.validationRewards(investor2);
    expect(new BigNumber(investor2Rewards['todayExpectedReward']).isEqualTo(new BigNumber('0'))).to.equal(true)

    let oracleRewards = await rewardsProgram.validationRewards(oracle);
    expect(new BigNumber(oracleRewards['todayExpectedReward']).isEqualTo(new BigNumber('0'))).to.equal(true)
  })


  it('Should vote for the approval of this created market', async function() {
    const inv2Attr = [fixedProductMarketMaker.address, false, { from: investor2 }]
    const oracleAttr = [fixedProductMarketMaker.address, false, { from: oracle }]

    await executeControllerMethod('castGovernanceValidatingVote', inv2Attr)
    await executeControllerMethod('castGovernanceValidatingVote', oracleAttr)

    let rewards = await rewardsProgram.validationRewards(investor1);
    expect(new BigNumber(rewards['todayExpectedReward']).isGreaterThan(new BigNumber('0'))).to.equal(true)

    let investor2Rewards = await rewardsProgram.validationRewards(investor2);
    expect(new BigNumber(investor2Rewards['todayExpectedReward']).isGreaterThan(new BigNumber('0'))).to.equal(true)

    let oracleRewards = await rewardsProgram.validationRewards(oracle);
    expect(new BigNumber(oracleRewards['todayExpectedReward']).isGreaterThan(new BigNumber('0'))).to.equal(true)
  })

})
