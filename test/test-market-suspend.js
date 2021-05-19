const ORMarketLib = artifacts.require('ORMarketLib')
const { expectEvent } = require('openzeppelin-test-helpers')

const {
  prepareContracts, createNewMarket,setDeployer,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('Markets proposer feeds and creation', function([deployer, creator, oracle, investor1, trader, investor2]) {

  let collateralTokenInstance
  let fixedProductMarketMaker
  let positionIds

  let controller;
  let conditionalTokens;

  before(async function() {
    setDeployer(deployer);
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2,deployer)
    controller = retArray[0];
    conditionalTokens = retArray[3];
  })

  it('can be created by factory', async function() {
    let retValues = await createNewMarket(creator)
    fixedProductMarketMaker = retValues[0]
    collateralTokenInstance = retValues[1]
    positionIds = retValues[2]
  })

  it('Should revert because called is not allowed to act', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await controller.marketStop(fixedProductMarketMaker.address, {from : creator});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should suspend the market', async function() {
      await controller.marketStop(fixedProductMarketMaker.address, {from : deployer});
  })

  const addedFunds1 = toBN(1e18)
  it('can be funded', async function() {
    const REVERT = 'liquidity can be added only in active/Validating state';
    try {
      await collateralTokenInstance.deposit({ value: addedFunds1, from: investor1 })
      await collateralTokenInstance.approve(controller.address, addedFunds1, { from: investor1 })
      await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds1, { from: investor1 })
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should vote for the approval of this created market', async function() {
    const REVERT = 'Market is not in validation state';
    try {
      await controller.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: investor1 })
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })
})

