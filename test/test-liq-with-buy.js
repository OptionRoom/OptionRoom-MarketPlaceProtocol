const ORMarketLib = artifacts.require('ORMarketLib')

const {
  prepareContracts, createNewMarket, moveToActive,setDeployer,getOracleMock,getRoomFakeToken,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('OR: tests rewards for providing liquidity for proposals', function([deployer, creator, oracle, investor1, trader, investor2]) {

  let controller

  const minLiquidityFunding = toBN(1e18)

  const toRemoveFunds1 = toBN(1e18)
  // const addedFunds1 = toBN(1e18)

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

    roomTokenFake = getRoomFakeToken();
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
    let retValues = await createNewMarket(creator)
    fixedProductMarketMaker = retValues[0]
    collateralToken = retValues[1]
    positionIds = retValues[2]
  })

  it('Should return correct min liq of controller', async function() {
    const minLiq = await controller.marketMinShareLiq.call()
    // Checking that the value is the min liquidity
    expect(new BigNumber(minLiq).isEqualTo(new BigNumber(minLiquidityFunding))).to.equal(true)
  })

  it('can be funded', async function() {
    const addedFunds = toBN(1e18);

    await collateralToken.deposit({ value: addedFunds, from: creator })
    await collateralToken.approve(controller.address, addedFunds, { from: creator })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds, { from: creator })

    let totalSupply = await fixedProductMarketMaker.totalSupply();
    expect(new BigNumber(totalSupply).isEqualTo(new BigNumber(addedFunds))).to.equal(true)
  })

  it('Should return the correct balance of creator', async function() {
    const addedFunds = toBN(1e18);

    let creatorBalance = await fixedProductMarketMaker.balanceOf(creator);
    expect(new BigNumber(creatorBalance).isEqualTo(new BigNumber(addedFunds))).to.equal(true)
  })

  it('Should allow another account to put liquidity', async function() {
    const addedFunds = toBN(1e18)
    await collateralToken.deposit({ value: addedFunds, from: investor2 })
    await collateralToken.approve(controller.address, addedFunds, { from: investor2 })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds, { from: investor2 })

    let totalSupply = await fixedProductMarketMaker.totalSupply();
    expect(new BigNumber(totalSupply).isEqualTo(new BigNumber(toBN(2e18)))).to.equal(true)

    // All of the amount have been converted...
    expect((await collateralToken.balanceOf(investor2)).toString()).to.equal('0')
    expect((await fixedProductMarketMaker.balanceOf(investor2)).toString()).to.equal(addedFunds.toString())

    let iBalance = await fixedProductMarketMaker.balanceOf(investor2);
    expect(new BigNumber(iBalance).isEqualTo(new BigNumber(addedFunds))).to.equal(true)
    
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
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 0

    // we already have 2 yeses and 2 nos
    await collateralToken.deposit({ value: investmentAmount, from: investor1 })
    await collateralToken.approve(controller.address, investmentAmount, { from: investor1 })

    let investor2Balance = await fixedProductMarketMaker.balanceOf(investor2);
    expect(new BigNumber(investor2Balance).isEqualTo(new BigNumber(toBN(1e18)))).to.equal(true)
    
    // Should be all 0's here.
    let investor2Balances = await fixedProductMarketMaker.getBalances(investor2);
    expect(new BigNumber(investor2Balances[0]).isEqualTo(new BigNumber(0))).to.equal(true)
    expect(new BigNumber(investor2Balances[1]).isEqualTo(new BigNumber(0))).to.equal(true)
    
    const FeeProtocol = await controller.FeeProtocol.call();
    const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: investor1 })

    // Totla supply must stay the same else we are not good at all.
    let totalSupply = await fixedProductMarketMaker.totalSupply();
    expect(new BigNumber(totalSupply).isEqualTo(new BigNumber(toBN(2e18)))).to.equal(true)
    
    let inv2Balance = await fixedProductMarketMaker.balanceOf(investor2);
    expect(new BigNumber(inv2Balance).isEqualTo(new BigNumber(toBN(1e18)))).to.equal(true)

    // Should stay if we have added market buy
    let inv2Balances = await fixedProductMarketMaker.getBalances(investor2);
    expect(new BigNumber(inv2Balances[0]).isEqualTo(new BigNumber(0))).to.equal(true)
    expect(new BigNumber(inv2Balances[1]).isEqualTo(new BigNumber(0))).to.equal(true)
    
    await collateralToken.deposit({ value: investmentAmount, from: oracle })
    await collateralToken.approve(controller.address, investmentAmount, { from: oracle })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, investmentAmount, { from: oracle })
    
    // Because the ratio of the tokens is different we will have a difference in the total supply.
    totalSupply = await fixedProductMarketMaker.totalSupply();
    expect(new BigNumber(totalSupply).isGreaterThan(new BigNumber(toBN(2e18)))).to.equal(true)
    expect(new BigNumber(totalSupply).isLessThan(new BigNumber(toBN(3e18)))).to.equal(true)
    
    inv2Balance = await fixedProductMarketMaker.balanceOf(investor2);
    expect(new BigNumber(inv2Balance).isEqualTo(new BigNumber(toBN(1e18)))).to.equal(true)

    inv2Balances = await fixedProductMarketMaker.getBalances(investor2);
    expect(new BigNumber(inv2Balances[0]).isEqualTo(new BigNumber(0))).to.equal(true)
    expect(new BigNumber(inv2Balances[1]).isEqualTo(new BigNumber(0))).to.equal(true)
    
    let oracleBalance = await fixedProductMarketMaker.balanceOf(oracle);
    expect(new BigNumber(oracleBalance).isGreaterThan(new BigNumber(toBN(0)))).to.equal(true)
    expect(new BigNumber(oracleBalance).isLessThan(new BigNumber(toBN(1e18)))).to.equal(true)

    let oracleBalances = await fixedProductMarketMaker.getBalances(oracle);
    expect(new BigNumber(oracleBalances[0]).isGreaterThan(new BigNumber(0))).to.equal(true)
    expect(new BigNumber(oracleBalances[1]).isEqualTo(new BigNumber(0))).to.equal(true)
  })
})
