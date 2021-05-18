const ORMarketLib = artifacts.require('ORMarketLib')

const {
  prepareContracts, createNewMarket,setDeployer,
  executeControllerMethod, moveToActive, callControllerMethod,increaseTime,resetTimeIncrease,
  moveOneDay,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('Option room Reward program permissions check', function([deployer,
                                                          creator, oracle, investor1, trader, investor2]) {

  let collateralToken
  let fixedProductMarketMaker
  let positionIds
  let controller;
  let rewardsProgram;

  before(async function() {
    // assign the deployer for now, I will have to refactor things later.
    setDeployer(deployer);
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2,deployer)
    controller = retArray[0];
    rewardsProgram = retArray[1];
  })

  it('can be created by factory', async function() {
    let retValues = await createNewMarket(creator)
    fixedProductMarketMaker = retValues[0]
    collateralToken = retValues[1]
    positionIds = retValues[2]
  })

  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await rewardsProgram.setMarketControllerAddress(trader, {from : controller.address});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass and change the controller address because I am the guardian.', async function() {
      await rewardsProgram.setMarketControllerAddress(trader, {from : deployer});
  })


  it('Should not be able to transfer the governance address because you are not deployer.', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await rewardsProgram.transfeerGovernor(trader, {from : controller.address});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }  
  })

  it('Should be able to change the governance because I am a deployer', async function() {
    await rewardsProgram.transfeerGovernor(trader, {from : deployer});
  })

  it('Should pass changing attributes because I am a guadrian', async function() {
    await rewardsProgram.setValidationRewardPerDay(toBN(1e17), {from : deployer});
    await rewardsProgram.setResolveRewardPerDay(toBN(1e17), {from : deployer});
    await rewardsProgram.setTradeRewardPerDay(toBN(1e17), {from : deployer});
    await rewardsProgram.setLPRewardPerDay(toBN(1e17), {from : deployer});
    await rewardsProgram.setMarketWeight(fixedProductMarketMaker.address, toBN(1e18), {from : deployer});
    await rewardsProgram.setIncludeSellInTradeRewards(false, {from : deployer});

    let validationRewardPerDay = await rewardsProgram.validationRewardPerDay.call();
    expect(new BigNumber(validationRewardPerDay).isEqualTo(new BigNumber(toBN(1e17)))).to.equal(true)

    let resolveRewardPerDay = await rewardsProgram.resolveRewardPerDay.call();
    expect(new BigNumber(resolveRewardPerDay).isEqualTo(new BigNumber(toBN(1e17)))).to.equal(true)

    let tradeRewardPerDay = await rewardsProgram.tradeRewardPerDay.call();
    expect(new BigNumber(tradeRewardPerDay).isEqualTo(new BigNumber(toBN(1e17)))).to.equal(true)

    let lpRewardPerDay = await rewardsProgram.lpRewardPerDay.call();
    expect(new BigNumber(lpRewardPerDay).isEqualTo(new BigNumber(toBN(1e17)))).to.equal(true)

    let lpMarketsWeights = await rewardsProgram.lpMarketsWeight.call(fixedProductMarketMaker.address);
    expect(new BigNumber(lpMarketsWeights).isEqualTo(new BigNumber(toBN(1e18)))).to.equal(true)

    let includeSellInTradeRewards = await rewardsProgram.includeSellInTradeRewards.call();
    expect(includeSellInTradeRewards).to.equal(false);
  })

  it('Should not be able to transfer the governance address because you are not deployer.', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await rewardsProgram.setValidationRewardPerDay(toBN(1e17), {from : oracle});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })


  it('Should not be able to transfer the governance address because you are not deployer.', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await rewardsProgram.setResolveRewardPerDay(toBN(1e17), {from : oracle});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should not be able to transfer the governance address because you are not deployer.', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await rewardsProgram.setTradeRewardPerDay(toBN(1e17), {from : oracle});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })


  it('Should not be able to transfer the governance address because you are not deployer.', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await rewardsProgram.setLPRewardPerDay(toBN(1e17), {from : oracle});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should not be able to transfer the governance address because you are not deployer.', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await rewardsProgram.setMarketWeight(fixedProductMarketMaker.address, toBN(1e18), {from : oracle});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })


  it('Should not be able to transfer the governance address because you are not deployer.', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await rewardsProgram.setIncludeSellInTradeRewards(toBN(1e17), {from : oracle});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })
  
})
