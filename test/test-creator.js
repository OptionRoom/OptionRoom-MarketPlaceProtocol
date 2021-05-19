const ORMarketLib = artifacts.require('ORMarketLib')
const { expectEvent } = require('openzeppelin-test-helpers')

const {
  prepareContracts, createNewMarket,
  executeControllerMethod, moveToActive, callControllerMethod,setDeployer,
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

  it('Should check proposer', async function() {
    let proposer = await fixedProductMarketMaker.proposer.call();
    expect(proposer).to.equal(creator)
  })

  it('Should check proposer totalProposerFee for a market', async function() {
    let totalProposerFee = await fixedProductMarketMaker.totalProposerFee.call();
    expect(new BigNumber(totalProposerFee).isEqualTo(new BigNumber(0))).to.equal(true)
  })

  it('Should check proposer withdrawnProposerFee for a market', async function() {
    let withdrawnProposerFee = await fixedProductMarketMaker.withdrawnProposerFee.call();
    expect(new BigNumber(withdrawnProposerFee).isEqualTo(new BigNumber(0))).to.equal(true)
  })

  const addedFunds1 = toBN(1e18)
  it('can be funded', async function() {
    await collateralTokenInstance.deposit({ value: addedFunds1, from: investor1 })
    await collateralTokenInstance.approve(controller.address, addedFunds1, { from: investor1 })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds1, { from: investor1 })

    // All of the amount have been converted...
    expect((await collateralTokenInstance.balanceOf(investor1)).toString()).to.equal('0')
    expect((await fixedProductMarketMaker.balanceOf(investor1)).toString()).to.equal(addedFunds1.toString())
  })

  it('Should keep totalProposerFee same after adding liquidity', async function() {
    let totalProposerFee = await fixedProductMarketMaker.totalProposerFee.call();
    expect(new BigNumber(totalProposerFee).isEqualTo(new BigNumber(0))).to.equal(true)
  })

  it('Should keep withdrawnProposerFee same after adding liquidity', async function() {
    let withdrawnProposerFee = await fixedProductMarketMaker.withdrawnProposerFee.call();
    expect(new BigNumber(withdrawnProposerFee).isEqualTo(new BigNumber(0))).to.equal(true)
  })


  it('Should vote for the approval of this created market', async function() {
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
  
  it('Should check totalProposerFee change after market buy', async function() {
    let totalProposerFee = await fixedProductMarketMaker.totalProposerFee.call();
    expect(new BigNumber(totalProposerFee).isGreaterThan(new BigNumber(0))).to.equal(true)
  })

  it('Should check withdrawnProposerFee and stay the same, because proposer did not get them', async function() {
    let withdrawnProposerFee = await fixedProductMarketMaker.withdrawnProposerFee.call();
    expect(new BigNumber(withdrawnProposerFee).isEqualTo(new BigNumber(0))).to.equal(true)
  })
  
})

