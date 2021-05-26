const ORMarketLib = artifacts.require('ORMarketLib')

const {
  prepareContracts, createNewMarket, moveToActive,setDeployer,getOracleMock,getRoomFakeToken,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('OR: tests rewards for providing liquidity for proposals', function([deployer, creator, oracle, investor1, trader, investor2]) {

  let controller

  const minLiquidityFunding = toBN(1e18)

  const addedFunds = toBN(2e18)
  const toRemoveFunds1 = toBN(1e18)
  const addedFunds1 = toBN(1e18)

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
    await collateralToken.deposit({ value: addedFunds, from: creator })
    await collateralToken.approve(controller.address, addedFunds, { from: creator })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds, { from: creator })
  })

  it('Should return the correct balance of creator', async function() {
    let creatorBalanace = await fixedProductMarketMaker.balanceOf(creator);
    expect(new BigNumber(creatorBalanace).isEqualTo(new BigNumber(addedFunds))).to.equal(true)
  })

  it('Should allow another account to put liquidity', async function() {
    await collateralToken.deposit({ value: addedFunds1, from: investor2 })
    await collateralToken.approve(controller.address, addedFunds1, { from: investor2 })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds1, { from: investor2 })

    // All of the amount have been converted...
    expect((await collateralToken.balanceOf(investor2)).toString()).to.equal('0')
    expect((await fixedProductMarketMaker.balanceOf(investor2)).toString()).to.equal(addedFunds1.toString())
  })

  it('Should return the correct balance of investor2', async function() {
    let iBalance = await fixedProductMarketMaker.balanceOf(investor2);
    expect(new BigNumber(iBalance).isEqualTo(new BigNumber(addedFunds1))).to.equal(true)
  })

  it('Should allow other account to withdraw liquidity with no issues', async function() {
    await controller.marketRemoveLiquidity(fixedProductMarketMaker.address, addedFunds1,false,true,  { from: investor2 })
  })

  it('Should return the correct balance of investor2 after removing liq', async function() {
    let iBalance = await fixedProductMarketMaker.balanceOf(investor2);
    expect(new BigNumber(iBalance).isEqualTo(new BigNumber(0))).to.equal(true)
  })
  
  it('Should withdraw, amount is lesser then the min liquidity and state in validation.', async function() {
    await controller.marketRemoveLiquidity(fixedProductMarketMaker.address, toRemoveFunds1, false,true, { from: creator })
  })


  it('Should show the correct values', async function() {
    let collectedFees = await fixedProductMarketMaker.collectedFees();

    let amounts = await fixedProductMarketMaker.feeProposerWithdrawable();
    let collateralAmount = amounts['collateralAmount'];
    let roomAmount = amounts['roomAmount'];

  })

  it('Should fail to withdraw trying to remove more liquidity than min liquidity', async function() {
    await controller.castGovernanceValidatingVote(fixedProductMarketMaker.address, false, { from: investor1 })
    await controller.castGovernanceValidatingVote(fixedProductMarketMaker.address, false, { from: oracle })
    await controller.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: investor2 })

    await moveToActive()

    let state = await controller.getMarketState(fixedProductMarketMaker.address)

    // Rejected...
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Rejected))).to.equal(true)

    // Got to manage to remove all of the rest of the liquidity because we are rejected.
    await controller.marketRemoveLiquidity(fixedProductMarketMaker.address, toRemoveFunds1, false,true, { from: creator })
  })
  

})
