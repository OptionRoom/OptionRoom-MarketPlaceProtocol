const ORMarketLib = artifacts.require('ORMarketLib')
const IERC20Contract = artifacts.require("../../contracts/mocks/ERC20DemoToken.sol");
const OracleMockContract = artifacts.require("../../contracts/mocks/RoomOraclePriceMock.sol");

const {
  prepareContracts, createNewMarket,
  executeControllerMethod, moveToActive, callControllerMethod,
  moveOneDay,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('Options room trade rewards tests', function([deployer, creator, oracle, investor1, trader, investor2]) {

  let collateralToken
  let fixedProductMarketMaker
  let positionIds

  let controller;
  let rewardsProgram;
  let rewardCenter;
  
  let roomTokenFake;
  let oracleInstance;

  let rewardCenterBalance;
  
  before(async function() {
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2)
    controller = retArray[0];
    rewardsProgram = retArray[1];
    rewardCenter = retArray[2];
    roomTokenFake = await IERC20Contract.new();
    oracleInstance = await OracleMockContract.new();

    // Mint some of the rooms at the system.
    await roomTokenFake.mint(toBN(200e18), {from : creator});
    await roomTokenFake.mint(toBN(200e18), {from : deployer});

    await rewardCenter.setRoomOracleAddress(oracleInstance.address, {from : deployer});
    await rewardCenter.setRoomAddress(roomTokenFake.address, {from : deployer});

    await roomTokenFake.mint(toBN(200e18), {from : deployer});
    await roomTokenFake.transfer(rewardCenter.address, toBN(200e18), {from : deployer});

    rewardCenterBalance = await roomTokenFake.balanceOf(rewardCenter.address);

    await rewardsProgram.setValidationRewardPerDay(toBN(10e18));
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
    const inv1Attr = [fixedProductMarketMaker.address, false, { from: investor1 }]
    const inv2Attr = [fixedProductMarketMaker.address, false, { from: investor2 }]
    const oracleAttr = [fixedProductMarketMaker.address, false, { from: oracle }]

    await executeControllerMethod('castGovernanceValidatingVote', inv1Attr)
    // await executeControllerMethod('castGovernanceValidatingVote', inv2Attr)
    // await executeControllerMethod('castGovernanceValidatingVote', oracleAttr)
  })

  it('Should check rewards for the resolved investor 1', async function() {
    
    let investor1Rewards = await rewardsProgram.validationRewards(investor1);
    expect(new BigNumber(investor1Rewards['todayExpectedReward']).isGreaterThan(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(investor1Rewards['rewardsCanClaim']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(investor1Rewards['claimedRewards']).isEqualTo(new BigNumber('0'))).to.equal(true)

    let investor2Rewards = await rewardsProgram.validationRewards(investor2);
    expect(new BigNumber(investor2Rewards['todayExpectedReward']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(investor2Rewards['rewardsCanClaim']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(investor2Rewards['claimedRewards']).isEqualTo(new BigNumber('0'))).to.equal(true)

    let traderRewards = await rewardsProgram.validationRewards(trader);
    expect(new BigNumber(traderRewards['todayExpectedReward']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(traderRewards['rewardsCanClaim']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(traderRewards['claimedRewards']).isEqualTo(new BigNumber('0'))).to.equal(true)

    await moveOneDay();
  })
  
  let todayClaimedBalance = 0;

  it('Should be able to claim user rewards', async function() {

    let balance = await roomTokenFake.balanceOf(investor1);
    await rewardsProgram.claimRewards(true, false, false, {from : investor1});
    todayClaimedBalance = new BigNumber(await roomTokenFake.balanceOf(investor1));
    expect(todayClaimedBalance.isGreaterThan(new BigNumber(0)))


    let rewardCenterBalanceAfter = new BigNumber( await roomTokenFake.balanceOf(rewardCenter.address));
    expect(rewardCenterBalanceAfter.isLessThan(new BigNumber(rewardCenterBalance)))

  })

  it('Should keep claimable if another user buys', async function() {
    let rewards = await rewardsProgram.validationRewards(investor1);
    expect(new BigNumber(rewards['todayExpectedReward']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(rewards['rewardsCanClaim']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(rewards['claimedRewards']).isGreaterThan(new BigNumber('0'))).to.equal(true)

  })

  it('Should be able to claim user rewards', async function() {
    await rewardsProgram.claimRewards(true, false, false, {from : investor1});
    let balance = new BigNumber(await roomTokenFake.balanceOf(investor1));

    expect(balance.isGreaterThan(new BigNumber(0)))
    expect(new BigNumber(todayClaimedBalance).isEqualTo(new BigNumber(balance)));
  })


})
