const ORMarketLib = artifacts.require('ORMarketLib')

const {
  prepareContracts, createNewMarket,setDeployer,
} = require('./utils/market.js')

contract('Option room market controller permissions', function([deployer,
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
})
