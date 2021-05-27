const ORMarketLib = artifacts.require('ORMarketLib')
const { expectEvent } = require('openzeppelin-test-helpers')

const {
  prepareContracts, createNewMarket,
  executeControllerMethod, moveToActive, conditionalApproveForAll, callControllerMethod,setDeployer,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('Markets buy sell boundary', function([deployer, creator, oracle, investor1, trader, investor2]) {

  let collateralTokenInstance
  let fixedProductMarketMaker
  let positionIds

  let controller;
  let conditionalTokens;
  const addedFunds1 = toBN(1e18)

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

  it('can be funded', async function() {
    await collateralTokenInstance.deposit({ value: addedFunds1, from: investor1 })
    await collateralTokenInstance.approve(controller.address, addedFunds1, { from: investor1 })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds1, { from: investor1 })

    await collateralTokenInstance.deposit({ value: addedFunds1, from: investor2 })
    await collateralTokenInstance.approve(controller.address, addedFunds1, { from: investor2 })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds1, { from: investor2 })


    const inv1Attr = [fixedProductMarketMaker.address, true, { from: investor1 }]
    const inv2Attr = [fixedProductMarketMaker.address, false, { from: investor2 }]
    const oracleAttr = [fixedProductMarketMaker.address, false, { from: oracle }]

    await executeControllerMethod('castGovernanceValidatingVote', inv1Attr)
    await executeControllerMethod('castGovernanceValidatingVote', inv2Attr)
    await executeControllerMethod('castGovernanceValidatingVote', oracleAttr)
  })

  it('can buy tokens from it', async function() {
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 1

    await moveToActive()

    let state = await callControllerMethod('getMarketState', [fixedProductMarketMaker.address])
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Active))).to.equal(true)

    // we already have 2 yeses and 2 nos
    await collateralTokenInstance.deposit({ value: investmentAmount, from: trader })
    await collateralTokenInstance.approve(controller.address, investmentAmount, { from: trader })
    
    // const outcomeTokensToBuy = await fixedProductMarketMaker.calcBuyAmount(investmentAmount, buyOutcomeIndex)
    const FeeProtocol = await controller.FeeProtocol.call();
    const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: trader })
  })

  // buying the different outcome
  it('can again buy tokens from it', async function() {
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 0

    // we already have 2 yeses and 2 nos
    await collateralTokenInstance.deposit({ value: investmentAmount, from: investor1 })
    await collateralTokenInstance.approve(controller.address, investmentAmount, { from: investor1 })

    const FeeProtocol = await controller.FeeProtocol.call();
    const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: investor1 })
  })

  it('Should revert because I am not a market contorller.', async function() {
      const REVERT = 'caller is not market controller'
      try {
        await fixedProductMarketMaker.sellTo(oracle, toBN(1e17), 1, {from: investor1});
        throw null
      } catch (error) {
        assert(error, 'Expected an error but did not get one')
        assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
      }
  })

  it('Should revert because I am not a market contorller.', async function() {
    const REVERT = 'caller is not market controller'
    try {
      await fixedProductMarketMaker.buyTo(oracle, toBN(1e17), 1,toBN(1e17),  {from: investor1});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should be able to sell', async function() {
    await conditionalApproveForAll(controller, trader)
    let traderNoBalanceBefore = (await fixedProductMarketMaker.getBalances(trader))[1]
    let traderNoBalanceBefore2 = (await fixedProductMarketMaker.getBalances(trader))[0]
    
    let expectedSellValue = toBN(2e17);
    let eee = await collateralTokenInstance.balanceOf(trader);
    for (let i = 0; i < 5 ;i ++) {
      // the first attribute is the amount, then the index you want to sell.
      await controller.marketSell(fixedProductMarketMaker.address, expectedSellValue, 1, { from: trader })
    }
    
    let afterBalance = await collateralTokenInstance.balanceOf(trader);
    expect(new BigNumber(afterBalance).isGreaterThan(new BigNumber(0)))
  })


  it('Should do nothing because user only have one tokens', async function() {
    await conditionalApproveForAll(fixedProductMarketMaker, investor1)
    let tokens1Before = (await fixedProductMarketMaker.getBalances(investor1))[1]
    let tokens2dBefore = (await fixedProductMarketMaker.getBalances(investor1))[0]

    await fixedProductMarketMaker.merge({from : investor1});

    let tokens1After = (await fixedProductMarketMaker.getBalances(investor1))[1]
    let tokens2dAfter = (await fixedProductMarketMaker.getBalances(investor1))[0]

    expect(new BigNumber(tokens1Before).isEqualTo(new BigNumber(tokens1After)))
    expect(new BigNumber(tokens2dBefore).isEqualTo(new BigNumber(tokens2dAfter)))

  })

  it('can buy again in the other option', async function() {
    const investmentAmount = toBN(2e18)
    const buyOutcomeIndex = 1

    // we already have 2 yeses and 2 nos
    await collateralTokenInstance.deposit({ value: investmentAmount, from: investor1 })
    await collateralTokenInstance.approve(controller.address, investmentAmount, { from: investor1 })

    const FeeProtocol = await controller.FeeProtocol.call();
    const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: investor1 })
  })

  it('Should do nothing because user only have one tokens', async function() {
    await conditionalApproveForAll(fixedProductMarketMaker, investor1)
    let tokens1Before = new BigNumber( (await fixedProductMarketMaker.getBalances(investor1))[1]);
    let tokens2Before = new BigNumber( (await fixedProductMarketMaker.getBalances(investor1))[0]);
    
    await fixedProductMarketMaker.merge({from : investor1});

    let tokens1After = new BigNumber((await fixedProductMarketMaker.getBalances(investor1))[1]);
    let tokens2After = new BigNumber((await fixedProductMarketMaker.getBalances(investor1))[0]);
    
    if (tokens1Before.isGreaterThan(tokens2Before)) {
      expect(new BigNumber(tokens1After).isGreaterThan(new BigNumber(tokens2After)))
    } else if(tokens1Before.isLessThan(tokens2Before)) {
      expect(new BigNumber(tokens2After).isGreaterThan(new BigNumber(tokens1After)))
    }
  })


  it('can buy again in the other option', async function() {
    const investmentAmount = toBN(2e18)
    const buyOutcomeIndex = 0

    // we already have 2 yeses and 2 nos
    await collateralTokenInstance.deposit({ value: investmentAmount, from: investor2 })
    await collateralTokenInstance.approve(controller.address, investmentAmount, { from: investor2 })

    const FeeProtocol = await controller.FeeProtocol.call();
    const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: investor2 })
  })

  it('can buy again in the other option', async function() {
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 1

    // we already have 2 yeses and 2 nos
    await collateralTokenInstance.deposit({ value: investmentAmount, from: investor2 })
    await collateralTokenInstance.approve(controller.address, investmentAmount, { from: investor2 })

    const FeeProtocol = await controller.FeeProtocol.call();
    const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: investor2 })
  })

  it('Should do nothing because user only have one tokens', async function() {
    // await conditionalApproveForAll(fixedProductMarketMaker, {from : investor2})
    await conditionalTokens.setApprovalForAll(fixedProductMarketMaker.address, true, {from : investor2});
    await fixedProductMarketMaker.merge({from : investor2});

    let tokens1After = new BigNumber((await fixedProductMarketMaker.getBalances(investor2))[1]);
    let tokens2After = new BigNumber((await fixedProductMarketMaker.getBalances(investor2))[0]);

    expect(new BigNumber(tokens2After).isGreaterThan(new BigNumber(tokens1After)))
  })
})

