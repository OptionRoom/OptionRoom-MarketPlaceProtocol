const ORMarketLib = artifacts.require('ORMarketLib')

const {
  prepareContracts, createNewMarket,
  executeControllerMethod, moveToActive, conditionalApproveForAll, callControllerMethod,
  conditionalBalanceOf, moveToResolving, resetTimeIncrease, increaseTime, moveToResolved,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('OR: test min liquidity and withdrawal', function([, creator, oracle, investor1, trader, investor2]) {

  let governanceMock

  const minLiquidityFunding = toBN(1e18)

  const addedFunds = toBN(2e18)
  const toRemoveFunds1 = toBN(1e18)

  let collateralToken
  let fixedProductMarketMaker
  let positionIds

  // let positionIds
  before(async function() {
    governanceMock = await prepareContracts(creator, oracle, investor1, trader, investor2)
    // set the min liquidity from here
    await governanceMock.setMarketMinShareLiq(minLiquidityFunding)
  })

  it('can be created by factory', async function() {
    let retValues = await createNewMarket(creator)
    fixedProductMarketMaker = retValues[0]
    collateralToken = retValues[1]
    positionIds = retValues[2]
  })

  it('can be funded', async function() {
    await collateralToken.deposit({ value: addedFunds, from: creator })
    await collateralToken.approve(fixedProductMarketMaker.address, addedFunds, { from: creator })
    await fixedProductMarketMaker.addLiquidity(addedFunds, { from: creator })
  })

  it('Should return the correct values for market min liq and controller min liq', async function() {
    const minLiq = await governanceMock.marketMinShareLiq.call()
    const marketCreatedMinLiq = await fixedProductMarketMaker.minShareLiq.call()

    // Checking that the value is the min liquidity
    expect(new BigNumber(minLiq).isEqualTo(new BigNumber(minLiquidityFunding))).to.equal(true)
    expect(new BigNumber(marketCreatedMinLiq).isEqualTo(new BigNumber(minLiquidityFunding))).to.equal(true)
  })

  it('Should fail to withdraw trying to remove more liquidity than min liquidity', async function() {
    const REVERT = 'The remaining shares dropped under the minimum'

    try {
      await fixedProductMarketMaker.removeLiquidity(addedFunds, false, { from: creator })
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should withdraw, amount is lesser then the min liquidity and state in validation.', async function() {
    // let accountBalance =  await fixedProductMarketMaker.balanceOf(creator);
    await fixedProductMarketMaker.removeLiquidity(toRemoveFunds1, false, { from: creator })
  })


  it('Should fail to withdraw trying to remove more liquidity than min liquidity', async function() {
    const REVERT = 'The remaining shares dropped under the minimum'

    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address, false, { from: investor1 })
    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address, false, { from: oracle })
    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: investor2 })

    await moveToActive()

    let state = await governanceMock.getMarketState(fixedProductMarketMaker.address)

    // Rejected...
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Rejected))).to.equal(true)

    // Got to manage to remove all of the rest of the liquidity because we are rejected.
    await fixedProductMarketMaker.removeLiquidity(toRemoveFunds1, false, { from: creator })
  })
})
