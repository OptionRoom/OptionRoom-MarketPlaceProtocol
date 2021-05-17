const ORMarketLib = artifacts.require('ORMarketLib')

const {
  prepareContracts, createNewMarket,setDeployer,
} = require('./utils/market.js')
const { toBN } = web3.utils

contract('Option room market controller permissions', function([deployer,
                                                                    creator, oracle, investor1, trader, investor2]) {

  let collateralToken
  let fixedProductMarketMaker
  let positionIds
  let controller;
  let rewardsProgram;
  const minLiquidityFunding = toBN(1e18)
  const marketDisputePeriod = 4 * 1800
  const marketReCastResolvingPeriod = 4 * 1800
  const disputeThreshold = toBN(100e18)
  const numerator = toBN(1e18)
  const denominator = toBN(1e18)
  
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
      await controller.setTemplateAddress(fixedProductMarketMaker.address, {from : controller.address});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass and change the controller address because I am the guardian.', async function() {
    await controller.setTemplateAddress(fixedProductMarketMaker.address, {from : deployer});
  })


  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await controller.setIORGoverner(fixedProductMarketMaker.address, {from : controller.address});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass and change the controller address because I am the guardian.', async function() {
    await controller.setIORGoverner(fixedProductMarketMaker.address, {from : deployer});
  })


  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await controller.setRewardCenter(fixedProductMarketMaker.address, {from : controller.address});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass and change the controller address because I am the guardian.', async function() {
    await controller.setRewardCenter(fixedProductMarketMaker.address, {from : deployer});
  })

  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await controller.setConditionalToken(fixedProductMarketMaker.address, {from : controller.address});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass and change the controller address because I am the guardian.', async function() {
    await controller.setConditionalToken(fixedProductMarketMaker.address, {from : deployer});
  })

  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await controller.setMarketMinShareLiq(minLiquidityFunding, {from : controller.address});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass and change the controller address because I am the guardian.', async function() {
    await controller.setMarketMinShareLiq(minLiquidityFunding, {from : deployer});
  })

  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await controller.setMarketDisputePeriod(marketDisputePeriod, {from : controller.address});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass and change the controller address because I am the guardian.', async function() {
    await controller.setMarketDisputePeriod(marketDisputePeriod, {from : deployer});
  })

  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await controller.setMarketReCastResolvingPeriod(marketReCastResolvingPeriod, {from : controller.address});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass and change the controller address because I am the guardian.', async function() {
    await controller.setMarketReCastResolvingPeriod(marketReCastResolvingPeriod, {from : deployer});
  })

  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await controller.setDisputeThreshold(disputeThreshold, {from : controller.address});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass and change the controller address because I am the guardian.', async function() {
    await controller.setDisputeThreshold(disputeThreshold, {from : deployer});
  })
})
