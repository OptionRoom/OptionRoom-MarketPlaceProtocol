const ORMarketLib = artifacts.require('ORMarketLib')

const {
  prepareContracts, createNewMarket, moveToActive,setDeployer
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('OR: test min liquidity and withdrawal', function([deployer, creator, oracle, investor1, trader, investor2]) {

  let controller

  const minLiquidityFunding = toBN(1e18)

  const addedFunds = toBN(2e18)
  const toRemoveFunds1 = toBN(1e18)
  const addedFunds1 = toBN(1e18)

  let collateralToken
  let fixedProductMarketMaker
  let positionIds

  // let positionIds
  before(async function() {
    setDeployer(deployer);
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2,deployer)
    controller = retArray[0];
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
    await controller.marketRemoveLiquidity(fixedProductMarketMaker.address, addedFunds1,false,false,  { from: investor2 })
  })

  it('Should return the correct balance of investor2 after removing liq', async function() {
    let iBalance = await fixedProductMarketMaker.balanceOf(investor2);
    expect(new BigNumber(iBalance).isEqualTo(new BigNumber(0))).to.equal(true)
  })
  
  it('Should revert when trying to remove more liquidity than min liquidity', async function() {
    const REVERT = 'The remaining shares dropped under the minimum'
    
    try {
      await controller.marketRemoveLiquidity(fixedProductMarketMaker.address, addedFunds, false,false, { from: creator })
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should withdraw, amount is lesser then the min liquidity and state in validation.', async function() {
    await controller.marketRemoveLiquidity(fixedProductMarketMaker.address, toRemoveFunds1, false,false, { from: creator })
  })

  it('Should revert when trying to remove more liquidity than min liquidity after removing some liquidity before', async function() {
    const REVERT = 'The remaining shares dropped under the minimum'

    try {
      await controller.marketRemoveLiquidity(fixedProductMarketMaker.address, toRemoveFunds1, false,false, { from: creator })
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
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
    await controller.marketRemoveLiquidity(fixedProductMarketMaker.address, toRemoveFunds1, false,false, { from: creator })
  })

  it('Should revert, removing liquidity not in the proper state.', async function() {
    const REVERT = ' liquidity can be added only in active/Validating state'

    try {
      await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds, { from: creator })
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })
  
})
