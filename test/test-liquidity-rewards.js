const ORMarketLib = artifacts.require('ORMarketLib')

const {
  prepareContracts, createMarket, moveToActive,setDeployer,
  getOracleMock,
} = require('./utils/market-proper-collateral.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('OR: tests for the rewards for the liquidity providers when adding liquidity', 
    function([deployer, creator, oracle, investor1, trader, investor2]) {

  let controller

  const minLiquidityFunding = toBN(1e18)

  const addedFunds = toBN(2e18)

  let collateralToken
  let fixedProductMarketMaker
  let positionIds

  let rewardsProgram;
  let rewardCenter;

  let roomTokenFake;
  let oracleInstance;

  let rewardCenterBalance;
   
  // let positionIds
  before(async function() {
    setDeployer(deployer);
    
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2,deployer)
    controller = retArray[0];

    rewardsProgram = retArray[1];

    rewardCenter = retArray[2];

    roomTokenFake = retArray[5];

    oracleInstance = getOracleMock();

    // Mint some of the rooms at the system.
    await roomTokenFake.mint(toBN(200e18), {from : creator});
    await roomTokenFake.mint(toBN(200e18), {from : deployer});

    await rewardCenter.setRoomOracleAddress(oracleInstance.address, {from : deployer});
    await rewardCenter.setRoomAddress(roomTokenFake.address, {from : deployer});

    await roomTokenFake.mint(toBN(200e18), {from : deployer});
    await roomTokenFake.transfer(rewardCenter.address, toBN(200e18), {from : deployer});

    rewardCenterBalance = await roomTokenFake.balanceOf(rewardCenter.address);

    // setting the reward value here.
    await rewardsProgram.setLPRewardPerDay(toBN(10e18));
    
    // set the min liquidity from here
    await controller.setMarketMinShareLiq(minLiquidityFunding)
  })

  it('can be created by factory', async function() {
    let retValues = await createMarket(creator)
    fixedProductMarketMaker = retValues[0]
    collateralToken = retValues[1]
    positionIds = retValues[2]

    // Transfer some amount of money to the market created to be able to get
    // some rewards.
    await roomTokenFake.mint(toBN(200e18), {from : deployer});
    await roomTokenFake.transfer(fixedProductMarketMaker.address, toBN(200e18), {from : deployer});
  })

  it('can be funded', async function() {
    await collateralToken.deposit({ value: addedFunds, from: creator })
    await collateralToken.approve(controller.address, addedFunds, { from: creator })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds, { from: creator })
  })

  it('Should allow another account to put liquidity', async function() {
    await collateralToken.deposit({ value: addedFunds, from: investor2 })
    await collateralToken.approve(controller.address, addedFunds, { from: investor2 })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds, { from: investor2 })

    let investor2Balance = await fixedProductMarketMaker.balanceOf(investor2);
    expect(new BigNumber(investor2Balance).isEqualTo(new BigNumber(addedFunds))).to.equal(true)
  })

  it('Should show the correct values', async function() {
    let collectedFees = await fixedProductMarketMaker.collectedFees();
    expect(new BigNumber(collectedFees).isEqualTo(new BigNumber(0))).to.equal(true)

    let amounts = await fixedProductMarketMaker.feeProposerWithdrawable();
    let collateralAmount = amounts['collateralAmount'];
    let roomAmount = amounts['roomAmount'];
    expect(new BigNumber(roomAmount).isGreaterThan(new BigNumber(0))).to.equal(true)
  })

  it('Should revert because I am trying to get the fees from a none proposer', async function() {
    const REVERT = 'only proposer can call'
    try {
      let amounts = await fixedProductMarketMaker.withdrawProposerFee(toBN(0), {from : trader});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should with draw fees of the proposer', async function() {
      await fixedProductMarketMaker.withdrawProposerFee(toBN(0), {from : creator});
  })

  it('Should fail to withdraw trying to remove more liquidity than min liquidity', async function() {
    await controller.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: investor1 })
    await controller.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: oracle })
    await controller.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: investor2 })
    await moveToActive()
    let state = await controller.getMarketState(fixedProductMarketMaker.address)
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Active))).to.equal(true)
  })

  // buying the different outcome
  it('can buy ', async function() {
    const investmentAmount = toBN(2e18)
    const buyOutcomeIndex = 0

    // we already have 2 yeses and 2 nos
    await collateralToken.deposit({ value: investmentAmount, from: investor1 })
    await collateralToken.approve(controller.address, investmentAmount, { from: investor1 })

    const FeeProtocol = await controller.FeeProtocol.call();
    const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: investor1 })

    // add more liquidity.
    await collateralToken.deposit({ value: investmentAmount, from: creator })
    await collateralToken.approve(controller.address, investmentAmount, { from: creator })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, investmentAmount, { from: creator })
    
    await collateralToken.deposit({ value: investmentAmount, from: investor2 })
    await collateralToken.approve(controller.address, investmentAmount, { from: investor2 })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, investmentAmount, { from: investor2 })
  })

  it('Should with draw fees of the proposer', async function() {
    // We will try to remove some of the liquidity of the inv2.
    let roomBalance = await roomTokenFake.balanceOf(investor2);
    expect(new BigNumber(roomBalance).isEqualTo(new BigNumber(toBN(0)))).to.equal(true)

    await controller.marketRemoveLiquidity(fixedProductMarketMaker.address, toBN(0), false,true, { from: investor2 })
    let roomBalanceAfter = await roomTokenFake.balanceOf(investor2);
    expect(new BigNumber(roomBalanceAfter).isGreaterThan(new BigNumber(toBN(0)))).to.equal(true)
  })
})
