const ORMarketLib = artifacts.require('ORMarketLib')
const IERC20Contract = artifacts.require("../../contracts/mocks/ERC20DemoToken.sol");
const OracleMockContract = artifacts.require("../../contracts/mocks/RoomOraclePriceMock.sol");

const {
  prepareContracts, createNewMarket,
  executeControllerMethod, moveToActive, callControllerMethod,
  moveOneDay,createNewMarketWithCollateral,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('Options room rewards with multiple markets: Should be extended further', function([deployer, creator, oracle, investor1, trader, investor2]) {
  let controller;
  let rewardsProgram;
  let rewardCenter;

  let roomTokenFake;
  let oracleInstance;

  let rewardCenterBalance;
  
  let marketsCreated = new Map()
  const minLiquidityFunding = toBN(1e18)

  before(async function() {
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2)
    controller = retArray[0];
    rewardsProgram = retArray[1];
    rewardCenter = retArray[2];

    await controller.setMarketMinShareLiq(minLiquidityFunding)
    
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

    // Changing rewards values so that I can send
    await rewardsProgram.setTradeRewardPerDay(toBN(10e18));
    await rewardsProgram.setValidationRewardPerDay(toBN(10e18));
    await rewardsProgram.setResolveRewardPerDay(toBN(10e18));
  })

  it('can be to create multiple markets', async function() {
    const marketMinToProvide1 = toBN(1e18);
    const marketMinToProvide2 = toBN(1e18);

    let retValues = await createNewMarketWithCollateral(creator, false, marketMinToProvide2, "test");
    marketsCreated.set(1,retValues );
    
    retValues = await createNewMarketWithCollateral(creator, false, marketMinToProvide2, "test 1");
    marketsCreated.set(2,retValues );
    
    retValues = await createNewMarketWithCollateral(creator, true, marketMinToProvide1, "test 2");
    marketsCreated.set(3,retValues);
  })


  it('Should vote for the approval of this created market', async function() {
    let mapToArray = Array.from(marketsCreated.values());
    for (let i = 0; i < mapToArray.length ;i++) {
      let marketDetails = mapToArray[i];
      let fixedProductMarketMaker = marketDetails[0]

      let inv1Attr = [fixedProductMarketMaker.address, true, { from: investor1 }]
      let inv2Attr = [fixedProductMarketMaker.address, false, { from: investor2 }]
      let oracleAttr = [fixedProductMarketMaker.address, false, { from: oracle }]

      await executeControllerMethod('castGovernanceValidatingVote', inv1Attr)
      await executeControllerMethod('castGovernanceValidatingVote', inv2Attr)
      await executeControllerMethod('castGovernanceValidatingVote', oracleAttr)
    }
  })

  it('Should move the markets and buy tokens for all of the created markets', async function() {
    let mapToArray = Array.from(marketsCreated.values());
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 1
    await moveToActive()
    const FeeProtocol = await controller.FeeProtocol.call();

    for (let i = 0; i < mapToArray.length ;i++) {
      let marketDetails = mapToArray[i];
      let fixedProductMarketMaker = marketDetails[0]
      let collateralToken = marketDetails[1]
      
      let state = await callControllerMethod('getMarketState', [fixedProductMarketMaker.address])
      expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Active))).to.equal(true)

      // we already have 2 yeses and 2 nos
      await collateralToken.deposit({ value: investmentAmount, from: investor1 })
      await collateralToken.approve(controller.address, investmentAmount, { from: investor1 })
      let outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
      await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: investor1 })


      //  buying for the other user.
      await collateralToken.deposit({ value: investmentAmount, from: trader })
      await collateralToken.approve(controller.address, investmentAmount, { from: trader })
      outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
      await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: trader })
    }
  })
  
  let expectedToDay;
  
  it('Should vote for the approval of this created market', async function() {
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
    expect(claimable.isEqualTo(expectedToDay)).to.equal(true)

    // The other user should have some rewards as well.
    rewards = await rewardsProgram.tradeRewards( trader);
    expect(new BigNumber(rewards['todayExpectedReward']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(rewards['rewardsCanClaim']).isGreaterThan(new BigNumber('0'))).to.equal(true)
    expect(new BigNumber(rewards['claimedRewards']).isEqualTo(new BigNumber('0'))).to.equal(true)
    expect(claimable.isEqualTo(expectedToDay)).to.equal(true)
  })
  
  let todayClaimedBalance = 0;

  it('Should be able to claim investor1 rewards', async function() {
    let balance = await roomTokenFake.balanceOf(investor1);
    await rewardsProgram.claimRewards(false, false, true, {from : investor1});
    todayClaimedBalance = new BigNumber(await roomTokenFake.balanceOf(investor1));
    expect(todayClaimedBalance.isGreaterThan(new BigNumber(0)))
    
    let rewardCenterBalanceAfter = new BigNumber( await roomTokenFake.balanceOf(rewardCenter.address));
    expect(rewardCenterBalanceAfter.isLessThan(new BigNumber(rewardCenterBalance)))
  })


  it('Should be able to claim trader rewards', async function() {
    let balance = await roomTokenFake.balanceOf(trader);
    await rewardsProgram.claimRewards(false, false, true, {from : trader});
    todayClaimedBalance = new BigNumber(await roomTokenFake.balanceOf(trader));
    expect(todayClaimedBalance.isGreaterThan(new BigNumber(0)))
    
    let rewardCenterBalanceAfter = new BigNumber( await roomTokenFake.balanceOf(rewardCenter.address));
    expect(rewardCenterBalanceAfter.isLessThan(new BigNumber(rewardCenterBalance)))
  })

})
